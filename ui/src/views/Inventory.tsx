// Inventar (F2) nach Canvas „V4 · Inventar“: Taschen · Auswahl · Boden. Reiter nach Kategorie, gestrichelte leere Plätze.
import { useEffect, useMemo, useState, type DragEvent } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { ItemIcon } from '../components/ItemIcon';
import { Panel, PanelHead } from '../components/Panel';
import { money } from './Hud';

export type InvItem = { slot: number; item: string; amount: number; meta?: Record<string, unknown>; label: string; category: string; weight: number; usable: boolean; money: boolean };
export type InvView = { kind: string; id: number; items: InvItem[]; weight: number; maxWeight: number; title: string; subtitle?: string; name?: string; cash?: number; black?: number; dropId?: number };
export type InventoryData = { self: InvView; other: InvView | null; target?: number | null };

const COLS = 5;
const MIN_CELLS = 30;
const catLabel: Record<string, string> = { money: 'Geld', document: 'Dokumente', daily: 'Alltag', tool: 'Werkzeug', material: 'Rohstoffe', drug: 'Drogen', weapon: 'Waffen', ammo: 'Munition', armor: 'Schutz', food: 'Essen', drink: 'Trinken', leisure: 'Freizeit', jewelry: 'Schmuck', loot: 'Beute' };
const kg = (n: number) => `${n.toLocaleString('de-DE', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} kg`;

type Side = 'self' | 'other';
type Sel = { side: Side; slot: number } | null;
type From = { side: Side; slot: number };

function Grid({ view, side, sel, filter, onSelect, onDrop }: { view: InvView; side: Side; sel: Sel; filter: string; onSelect: (s: Sel) => void; onDrop: (from: From, toSlot: number) => void }) {
  const bySlot = useMemo(() => new Map(view.items.map((i) => [i.slot, i])), [view.items]);
  const maxSlot = view.items.reduce((m, i) => Math.max(m, i.slot), 0);
  const cells = Math.max(MIN_CELLS, Math.ceil((maxSlot + 1) / COLS) * COLS);
  const over = (e: DragEvent) => e.preventDefault();
  const drop = (e: DragEvent, slot: number) => { e.preventDefault(); try { onDrop(JSON.parse(e.dataTransfer.getData('text/plain')), slot); } catch { /* ignorieren */ } };
  return (
    <div className="inv-grid">
      {Array.from({ length: cells }, (_, i) => i + 1).map((slot) => {
        const it = bySlot.get(slot);
        if (!it || (filter !== 'all' && it.category !== filter)) return <div key={slot} className="slot inv-cell" style={{ cursor: 'default' }} onDragOver={over} onDrop={(e) => drop(e, slot)} />;
        const active = sel?.side === side && sel.slot === slot;
        return (
          <div key={slot} className={'card inv-cell' + (active ? ' on' : '')} draggable onDragStart={(e) => { e.dataTransfer.setData('text/plain', JSON.stringify({ side, slot })); onSelect({ side, slot }); }}
            onDragOver={over} onDrop={(e) => drop(e, slot)} onClick={() => onSelect({ side, slot })}>
            <span className="amt num">{it.money ? money(it.amount) : it.amount}</span>
            <span className="wt num">{it.money ? '' : kg(it.weight * it.amount)}</span>
            <span className="ico"><ItemIcon item={it.item} category={it.category} size={40} /></span>
            <span className="lbl">{it.label}</span>
          </div>
        );
      })}
    </div>
  );
}

function Side({ view, side, sel, onSelect, onDrop, icon, info }: { view: InvView; side: Side; sel: Sel; onSelect: (s: Sel) => void; onDrop: (from: From, toSlot: number) => void; icon: string; info: string }) {
  const [filter, setFilter] = useState('all');
  const cats = useMemo(() => Array.from(new Set(view.items.map((i) => i.category))), [view.items]);
  const pct = Math.min(100, Math.round((view.weight / view.maxWeight) * 100));
  return (
    <Panel className="inv-panel">
      <PanelHead icon={icon} title={view.title} info={info} />
      <div className="inv-body">
        <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'center', gap: 10 }}>
          <div className="seg" style={{ overflow: 'hidden' }}>
            <button className={filter === 'all' ? 'on' : ''} onClick={() => setFilter('all')}>Alle</button>
            {cats.slice(0, 4).map((c) => <button key={c} className={filter === c ? 'on' : ''} onClick={() => setFilter(c)}>{catLabel[c] ?? c}</button>)}
          </div>
          <span style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 4, width: 150, flex: 'none' }}>
            <b className="num" style={{ fontSize: 13 }}>{kg(view.weight).replace(' kg', '')} / {view.maxWeight} kg</b>
            <span className="meter" style={{ width: '100%' }}><i style={{ width: `${pct}%`, background: pct >= 100 ? 'var(--danger)' : undefined }} /></span>
          </span>
        </div>
        <Grid view={view} side={side} sel={sel} filter={filter} onSelect={onSelect} onDrop={onDrop} />
      </div>
    </Panel>
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

  return (
    <div className="inv-wrap">
      <Side view={data.self} side="self" sel={sel} onSelect={setSel} onDrop={(f, t) => onDrop(f, t, 'self')} icon="bag"
        info={`${data.self.name ?? ''} · Bargeld ${money(data.self.cash ?? 0)} · Schwarzgeld ${money(data.self.black ?? 0)}`} />

      <Panel className="inv-select">
        <PanelHead icon={selected?.money ? 'cash' : 'box'} title="Auswahl" info={selected ? `${selected.label} · ${catLabel[selected.category] ?? selected.category}` : 'Klicke ein Item an oder ziehe es'} />
        <div className="body">
          <span className="inv-orb">{selected ? <ItemIcon item={selected.item} category={selected.category} size={52} /> : <Icon name="bag" size={40} stroke={1.6} />}</span>
          <b style={{ fontSize: 22 }}>{selected?.label ?? 'Nichts gewählt'}</b>
          <span className="sub">{selected ? (selected.money ? `${money(selected.amount)} in der Tasche` : `${kg(selected.weight)} je Stück · ${selected.amount} Stück`) : ''}</span>
          <span className="eyebrow" style={{ fontSize: 10 }}>Anzahl</span>
          <div style={{ display: 'flex', gap: 8, width: '100%', alignItems: 'center' }}>
            <button className="btn step" disabled={!selected} onClick={() => setAmount(clamp(amount - step))}>−</button>
            <input className="inv-amount num" value={amount} disabled={!selected} onChange={(e) => setAmount(clamp(Number(e.target.value)))} />
            <button className="btn step" disabled={!selected} onClick={() => setAmount(clamp(amount + step))}>+</button>
          </div>
          <div style={{ display: 'flex', gap: 6, width: '100%' }}>
            <button className="btn sm" style={{ flex: 1, height: 30, fontSize: 11 }} disabled={!selected} onClick={() => setAmount(1)}>1</button>
            <button className="btn sm" style={{ flex: 1, height: 30, fontSize: 11 }} disabled={!selected} onClick={() => setAmount(clamp(Math.ceil((selected?.amount ?? 1) / 2)))}>Hälfte</button>
            <button className="btn sm" style={{ flex: 1, height: 30, fontSize: 11 }} disabled={!selected} onClick={() => setAmount(selected?.amount ?? 1)}>Alles</button>
          </div>
          <div style={{ display: 'flex', flexDirection: 'column', gap: 8, width: '100%' }}>
            {inOther ? (
              <button className="btn primary" style={{ height: 44 }} disabled={!selected} onClick={() => selected && act('take', { slot: selected.slot, amount })}>Aufheben</button>
            ) : (
              <>
                <button className="btn primary" style={{ height: 44 }} disabled={!selected?.usable} onClick={() => selected && act('use', { slot: selected.slot })}>Benutzen</button>
                <button className="btn" style={{ height: 44 }} disabled={!selected || !data.target} onClick={() => selected && act('give', { slot: selected.slot, amount, target: data.target })}>Geben</button>
                <button className="btn" style={{ height: 44 }} disabled={!selected || selected.amount < 2}
                  onClick={() => { if (!selected) return; let free = 1; const used = new Set(data.self.items.map((i) => i.slot)); while (used.has(free)) free++; act('move', { slot: selected.slot, to: free, from: 'self', dest: 'self', amount: Math.min(amount, selected.amount - 1) }); }}>Teilen</button>
                <button className="btn danger" style={{ height: 44 }} disabled={!selected} onClick={() => selected && act('drop', { slot: selected.slot, amount })}>Wegwerfen</button>
              </>
            )}
          </div>
          <div className="keys"><kbd className="kbd">F2</kbd> Schließen · Ziehen verschiebt</div>
        </div>
      </Panel>

      {data.other ? (
        <Side view={data.other} side="other" sel={sel} onSelect={setSel} onDrop={(f, t) => onDrop(f, t, 'other')} icon="box" info={data.other.subtitle ?? 'Vor dir'} />
      ) : (
        <Panel className="inv-panel" style={{ opacity: 0.8 }}>
          <PanelHead icon="box" title="Boden" info="Hier ablegen, um eine Ablage zu erstellen" />
          <div className="inv-body" onDragOver={(e) => e.preventDefault()} onDrop={(e) => { e.preventDefault(); try { onDrop(JSON.parse(e.dataTransfer.getData('text/plain')), 1, 'other'); } catch { /* ignorieren */ } }}>
            <div className="inv-grid" style={{ opacity: 0.5 }}>{Array.from({ length: MIN_CELLS }, (_, i) => <div key={i} className="slot inv-cell" />)}</div>
          </div>
        </Panel>
      )}
      <button className="btn danger sm" style={{ position: 'absolute', right: 0, top: -48 }} onClick={close}>Schliessen <Icon name="x" size={14} /></button>
    </div>
  );
}
