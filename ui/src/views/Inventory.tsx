// Inventar (F2): links deine Taschen, rechts Boden oder Behälter. Klick wählt, Ziehen verschiebt, Leiste unten für Aktionen.
import { useEffect, useMemo, useState, type DragEvent } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { ItemIcon } from '../components/ItemIcon';
import { Panel, Kbd } from '../components/Panel';
import { money } from './Hud';

export type InvItem = { slot: number; item: string; amount: number; meta?: Record<string, unknown>; label: string; category: string; weight: number; usable: boolean; money: boolean };
export type InvView = { kind: string; id: number; items: InvItem[]; weight: number; maxWeight: number; title: string; subtitle?: string; name?: string; cash?: number; black?: number; dropId?: number };
export type InventoryData = { self: InvView; other: InvView | null; target?: number | null };

const COLS = 6;
const MIN_CELLS = 36;
const catLabel: Record<string, string> = { money: 'Geld', document: 'Dokumente', daily: 'Alltag', tool: 'Werkzeug', material: 'Rohstoffe', drug: 'Drogen', weapon: 'Waffen', ammo: 'Munition', armor: 'Schutz', food: 'Essen', drink: 'Trinken', leisure: 'Freizeit', jewelry: 'Schmuck', loot: 'Beute' };
const kg = (n: number) => `${n.toLocaleString('de-DE', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} kg`;

type Side = 'self' | 'other';
type Sel = { side: Side; slot: number } | null;
type From = { side: Side; slot: number };

function Grid({ view, side, sel, onSelect, onDrop }: { view: InvView; side: Side; sel: Sel; onSelect: (s: Sel) => void; onDrop: (from: From, toSlot: number) => void }) {
  const bySlot = useMemo(() => new Map(view.items.map((i) => [i.slot, i])), [view.items]);
  const maxSlot = view.items.reduce((m, i) => Math.max(m, i.slot), 0);
  const cells = Math.max(MIN_CELLS, Math.ceil((maxSlot + 1) / COLS) * COLS);
  const over = (e: DragEvent) => e.preventDefault();
  const drop = (e: DragEvent, slot: number) => { e.preventDefault(); try { onDrop(JSON.parse(e.dataTransfer.getData('text/plain')), slot); } catch { /* ignorieren */ } };
  return (
    <div className="grid">
      {Array.from({ length: cells }, (_, i) => i + 1).map((slot) => {
        const it = bySlot.get(slot);
        if (!it) return <div key={slot} className="cell empty" onDragOver={over} onDrop={(e) => drop(e, slot)} />;
        const active = sel?.side === side && sel.slot === slot;
        return (
          <div key={slot} className={'cell' + (active ? ' on' : '')} draggable title={`${it.label} · ${it.money ? money(it.amount) : `${it.amount} Stück · ${kg(it.weight * it.amount)}`}`}
            onDragStart={(e) => { e.dataTransfer.setData('text/plain', JSON.stringify({ side, slot })); onSelect({ side, slot }); }}
            onDragOver={over} onDrop={(e) => drop(e, slot)} onClick={() => onSelect({ side, slot })}>
            <span className="amt num">{it.money ? money(it.amount) : it.amount}</span>
            {!it.money && <span className="wt num">{kg(it.weight * it.amount)}</span>}
            <span className="ico"><ItemIcon item={it.item} category={it.category} size={30} /></span>
            <span className="lbl">{it.label}</span>
          </div>
        );
      })}
    </div>
  );
}

export function Inventory({ data }: { data: InventoryData; key?: string }) {
  const [sel, setSel] = useState<Sel>(null);
  const [amount, setAmount] = useState(1);
  const selected = useMemo(() => {
    if (!sel) return undefined;
    const v = sel.side === 'self' ? data.self : data.other;
    return v?.items.find((i) => i.slot === sel.slot);
  }, [sel, data]);
  useEffect(() => { if (!selected) setSel(null); setAmount(selected?.money ? Math.min(selected.amount, 100) : 1); }, [selected?.slot, selected?.item, selected?.amount]);

  const act = (action: string, extra: Record<string, unknown> = {}) => nui('action', { view: 'inventory', action: 'action', data: { action, ...extra } });
  const close = () => nui('action', { view: 'inventory', action: 'close' });
  const clamp = (n: number) => Math.max(1, Math.min(selected?.amount ?? 1, Math.floor(n) || 1));
  const onDrop = (from: From, toSlot: number, toSide: Side) => {
    if (from.side === toSide && from.slot === toSlot) return;
    const v = from.side === 'self' ? data.self : data.other;
    const it = v?.items.find((i) => i.slot === from.slot);
    if (!it) return;
    if (toSide === 'other' && !data.other) { act('drop', { slot: from.slot, amount: it.amount }); return; }
    const qty = sel && sel.side === from.side && sel.slot === from.slot ? amount : it.amount;
    act('move', { slot: from.slot, to: toSlot, from: from.side, dest: toSide, amount: qty });
  };
  const inOther = sel?.side === 'other';
  const step = selected?.money ? 100 : 1;
  const pct = (v: InvView) => Math.min(100, Math.round((v.weight / v.maxWeight) * 100));

  const selfFoot = (
    <>
      <div className="sel">
        {selected ? <ItemIcon item={selected.item} category={selected.category} size={28} /> : <Icon name="bag" size={22} />}
        <div className="col grow" style={{ gap: 0 }}>
          <span className="name ellipsis">{selected?.label ?? 'Nichts gewählt'}</span>
          <span className="desc">{selected ? (selected.money ? money(selected.amount) : `${catLabel[selected.category] ?? selected.category} · ${kg(selected.weight)} je Stück`) : 'Klicke ein Item an oder ziehe es'}</span>
        </div>
      </div>
      <div className="amount">
        <button className="btn" disabled={!selected} onClick={() => setAmount(clamp(amount - step))}>−</button>
        <input className="input num" value={amount} disabled={!selected} onChange={(e) => setAmount(clamp(Number(e.target.value)))} />
        <button className="btn" disabled={!selected} onClick={() => setAmount(clamp(amount + step))}>+</button>
        <button className="btn sm" disabled={!selected} onClick={() => setAmount(selected?.amount ?? 1)}>Alles</button>
      </div>
      <div className="actions">
        {inOther ? (
          <button className="btn primary" disabled={!selected} onClick={() => selected && act('take', { slot: selected.slot, amount })}>Nehmen</button>
        ) : (
          <>
            <button className="btn primary" disabled={!selected?.usable} onClick={() => selected && act('use', { slot: selected.slot })}>Benutzen</button>
            <button className="btn" disabled={!selected || !data.target} onClick={() => selected && act('give', { slot: selected.slot, amount, target: data.target })}>Geben</button>
            <button className="btn" disabled={!selected || selected.amount < 2}
              onClick={() => { if (!selected) return; let free = 1; const used = new Set(data.self.items.map((i) => i.slot)); while (used.has(free)) free++; act('move', { slot: selected.slot, to: free, from: 'self', dest: 'self', amount: Math.min(amount, selected.amount - 1) }); }}>Teilen</button>
            <button className="btn danger" disabled={!selected} onClick={() => selected && act('drop', { slot: selected.slot, amount })}>Wegwerfen</button>
          </>
        )}
      </div>
    </>
  );

  const other = data.other;
  return (
    <div className="inv">
      <Panel icon="bag" title={data.self.title} sub={`${data.self.name ?? ''} · Bargeld ${money(data.self.cash ?? 0)}${(data.self.black ?? 0) > 0 ? ` · Schwarzgeld ${money(data.self.black ?? 0)}` : ''}`} foot={selfFoot}
        headRight={<span className="keys"><Kbd>F2</Kbd></span>}>
        <div className="toolbar">
          <span className="muted" style={{ fontSize: '0.75rem' }}>{data.self.items.length} Gegenstände</span>
          <div className="weight"><span className="num">{kg(data.self.weight)} / {data.self.maxWeight} kg</span><span className="meter"><i style={{ width: `${pct(data.self)}%`, background: pct(data.self) >= 100 ? 'var(--danger)' : undefined }} /></span></div>
        </div>
        <Grid view={data.self} side="self" sel={sel} onSelect={setSel} onDrop={(f, t) => onDrop(f, t, 'self')} />
      </Panel>

      <Panel icon="box" title={other ? other.title : 'Boden'} sub={other ? (other.subtitle ?? 'Vor dir') : 'Hierher ziehen, um etwas abzulegen'} onClose={close}
        foot={<span className="keys"><Kbd>Esc</Kbd> schließen · Ziehen verschiebt · Doppelklick-frei: erst wählen, dann Aktion</span>}>
        {other ? (
          <>
            <div className="toolbar">
              <span className="muted" style={{ fontSize: '0.75rem' }}>{other.items.length} Gegenstände</span>
              <div className="weight"><span className="num">{kg(other.weight)} / {other.maxWeight} kg</span><span className="meter"><i style={{ width: `${pct(other)}%` }} /></span></div>
            </div>
            <Grid view={other} side="other" sel={sel} onSelect={setSel} onDrop={(f, t) => onDrop(f, t, 'other')} />
          </>
        ) : (
          <div className="grid" style={{ opacity: 0.7 }} onDragOver={(e) => e.preventDefault()} onDrop={(e) => { e.preventDefault(); try { onDrop(JSON.parse(e.dataTransfer.getData('text/plain')), 1, 'other'); } catch { /* ignorieren */ } }}>
            {Array.from({ length: MIN_CELLS }, (_, i) => <div key={i} className="cell empty" />)}
          </div>
        )}
      </Panel>
    </div>
  );
}
