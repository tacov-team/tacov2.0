// Inventar (F2) nach Board „Inventar“: Taschen · Auswahl (Anzahl, Benutzen/Geben/Teilen/Wegwerfen) · Boden/Gegenüber
import { useEffect, useMemo, useState, type DragEvent } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { money } from './Hud';

export type InvItem = { slot: number; item: string; amount: number; meta?: Record<string, unknown>; label: string; category: string; weight: number; usable: boolean; money: boolean };
export type InvView = { kind: string; id: number; items: InvItem[]; weight: number; maxWeight: number; title: string; subtitle?: string; name?: string; cash?: number; black?: number; dropId?: number };
export type InventoryData = { self: InvView; other: InvView | null; target?: number | null };

const COLS = 5;
const MIN_CELLS = 30;

const catIcon: Record<string, string> = {
  money: 'cash', document: 'doc', daily: 'bag', tool: 'tool', material: 'box', drug: 'leaf', weapon: 'gun', ammo: 'ammo',
  armor: 'shield', food: 'food', drink: 'drop', leisure: 'fish', jewelry: 'ring', loot: 'box',
};

const kg = (n: number) => `${n.toLocaleString('de-DE', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} kg`;

type Sel = { side: 'self' | 'other'; slot: number } | null;

function Grid({ view, side, sel, onSelect, onDrop }: {
  view: InvView; side: 'self' | 'other'; sel: Sel;
  onSelect: (s: Sel) => void; onDrop: (from: { side: 'self' | 'other'; slot: number }, toSlot: number) => void;
}) {
  const bySlot = useMemo(() => new Map(view.items.map((i) => [i.slot, i])), [view.items]);
  const maxSlot = view.items.reduce((m, i) => Math.max(m, i.slot), 0);
  const cells = Math.max(MIN_CELLS, Math.ceil((maxSlot + 1) / COLS) * COLS);
  const onDragStart = (e: DragEvent, slot: number) => { e.dataTransfer.setData('text/plain', JSON.stringify({ side, slot })); onSelect({ side, slot }); };
  const onDragOver = (e: DragEvent) => e.preventDefault();
  const onDropCell = (e: DragEvent, slot: number) => {
    e.preventDefault();
    try { onDrop(JSON.parse(e.dataTransfer.getData('text/plain')), slot); } catch { /* ignorieren */ }
  };
  return (
    <div className="inv-grid">
      {Array.from({ length: cells }, (_, i) => i + 1).map((slot) => {
        const it = bySlot.get(slot);
        const active = sel?.side === side && sel.slot === slot;
        if (!it) return <div key={slot} className="inv-cell empty" onDragOver={onDragOver} onDrop={(e) => onDropCell(e, slot)} />;
        return (
          <div key={slot} className={'inv-cell' + (active ? ' active' : '')} draggable onDragStart={(e) => onDragStart(e, slot)}
            onDragOver={onDragOver} onDrop={(e) => onDropCell(e, slot)} onClick={() => onSelect({ side, slot })}>
            <span className="amt">{it.money ? money(it.amount) : it.amount}</span>
            <span className="wt">{it.money ? '' : kg(it.weight * it.amount)}</span>
            <span className="ico" style={{ color: it.item === 'black_cash' ? 'var(--black-money)' : undefined }}><Icon name={catIcon[it.category] ?? 'box'} size={34} stroke={1.8} /></span>
            <span className="lbl">{it.label}</span>
          </div>
        );
      })}
    </div>
  );
}

function Panel({ view, side, sel, onSelect, onDrop, extra }: {
  view: InvView; side: 'self' | 'other'; sel: Sel; onSelect: (s: Sel) => void;
  onDrop: (from: { side: 'self' | 'other'; slot: number }, toSlot: number) => void; extra?: string;
}) {
  const pct = Math.min(100, Math.round((view.weight / view.maxWeight) * 100));
  return (
    <section className="inv-panel">
      <span className="top" />
      <div className="inv-head">
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <span className="eyebrow">{view.title}</span>
          <h2>{view.name ?? (side === 'other' ? 'Vor dir' : '')}</h2>
          <span className="sub">{extra ?? view.subtitle ?? ''}</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'flex-end', gap: 6, width: 180 }}>
          <span className="num" style={{ fontSize: 13, fontWeight: 800 }}>{kg(view.weight).replace(' kg', '')} / {view.maxWeight} kg</span>
          <span className="meter"><span style={{ width: `${pct}%`, background: pct >= 100 ? 'var(--danger)' : undefined }} /></span>
        </div>
      </div>
      <Grid view={view} side={side} sel={sel} onSelect={onSelect} onDrop={onDrop} />
    </section>
  );
}

export function Inventory({ data }: { data: InventoryData }) {
  const [sel, setSel] = useState<Sel>(null);
  const [amount, setAmount] = useState(1);

  const selected: InvItem | undefined = useMemo(() => {
    if (!sel) return undefined;
    const v = sel.side === 'self' ? data.self : data.other;
    return v?.items.find((i) => i.slot === sel.slot);
  }, [sel, data]);

  useEffect(() => { if (!selected) setSel(null); setAmount(selected?.money ? Math.min(selected.amount, 100) : 1); }, [selected?.slot, selected?.item, selected?.amount]);

  const act = (action: string, extra: Record<string, unknown> = {}) => nui('action', { view: 'inventory', action: 'action', data: { action, ...extra } });
  const close = () => nui('action', { view: 'inventory', action: 'close' });

  const clamp = (n: number) => Math.max(1, Math.min(selected?.amount ?? 1, Math.floor(n) || 1));
  const onDrop = (from: { side: 'self' | 'other'; slot: number }, toSlot: number, toSide: 'self' | 'other') => {
    if (from.side === toSide && from.slot === toSlot) return;
    const v = from.side === 'self' ? data.self : data.other;
    const it = v?.items.find((i) => i.slot === from.slot);
    if (!it) return;
    if (toSide === 'other' && !data.other) { act('drop', { slot: from.slot, amount: it.amount }); return; }
    const qty = sel && sel.side === from.side && sel.slot === from.slot ? amount : it.amount;
    act('move', { slot: from.slot, to: toSlot, from: from.side, dest: toSide, amount: qty });
  };

  const inOther = sel?.side === 'other';
  const desc = selected ? [
    selected.category === 'money' ? 'Geld' : selected.category,
    selected.money ? money(selected.amount) : `${kg(selected.weight)} je Stück · ${selected.amount} Stück`,
  ].join(' · ') : '';

  return (
    <div className="inv-wrap">
      <Panel view={data.self} side="self" sel={sel} onSelect={setSel} onDrop={(f, t) => onDrop(f, t, 'self')}
        extra={`Bargeld ${money(data.self.cash ?? 0)} · Schwarzgeld ${money(data.self.black ?? 0)}`} />

      <div className="inv-select">
        <span className="eyebrow">Auswahl</span>
        <div className="inv-orb">{selected ? <Icon name={catIcon[selected.category] ?? 'box'} size={40} stroke={1.8} /> : <Icon name="bag" size={40} stroke={1.8} />}</div>
        <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center', gap: 4, minHeight: 48 }}>
          <strong className="inv-title">{selected?.label ?? 'Nichts gewählt'}</strong>
          <span style={{ fontSize: 12, color: 'var(--muted)', textAlign: 'center' }}>{selected ? desc : 'Klicke ein Item an oder ziehe es'}</span>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, width: '100%' }}>
          <label className="inv-label">Anzahl</label>
          <div style={{ display: 'flex', gap: 8, alignItems: 'center' }}>
            <button className="inv-step" disabled={!selected} onClick={() => setAmount(clamp(amount - (selected?.money ? 100 : 1)))}>−</button>
            <input className="inv-amount num" value={amount} disabled={!selected} onChange={(e) => setAmount(clamp(Number(e.target.value)))} />
            <button className="inv-step" disabled={!selected} onClick={() => setAmount(clamp(amount + (selected?.money ? 100 : 1)))}>+</button>
          </div>
          <div style={{ display: 'flex', gap: 6 }}>
            <button className="inv-quick" disabled={!selected} onClick={() => setAmount(1)}>1</button>
            <button className="inv-quick" disabled={!selected} onClick={() => setAmount(clamp(Math.ceil((selected?.amount ?? 1) / 2)))}>Hälfte</button>
            <button className="inv-quick" disabled={!selected} onClick={() => setAmount(selected?.amount ?? 1)}>Alles</button>
          </div>
        </div>
        <div style={{ display: 'flex', flexDirection: 'column', gap: 8, width: '100%' }}>
          {inOther ? (
            <button className="btn primary" style={{ height: 44, borderRadius: 12 }} disabled={!selected} onClick={() => selected && act('take', { slot: selected.slot, amount })}>Aufheben</button>
          ) : (
            <>
              <button className="btn primary" style={{ height: 44, borderRadius: 12 }} disabled={!selected?.usable} onClick={() => selected && act('use', { slot: selected.slot })}>Benutzen</button>
              <button className="btn" style={{ height: 44, borderRadius: 12 }} disabled={!selected || !data.target} title={data.target ? '' : 'Niemand in der Nähe'}
                onClick={() => selected && act('give', { slot: selected.slot, amount, target: data.target })}>Geben</button>
              <button className="btn" style={{ height: 44, borderRadius: 12 }} disabled={!selected || selected.amount < 2}
                onClick={() => { if (!selected) return; const v = data.self; let free = 1; const used = new Set(v.items.map((i) => i.slot)); while (used.has(free)) free++; act('move', { slot: selected.slot, to: free, from: 'self', dest: 'self', amount: Math.min(amount, selected.amount - 1) }); }}>Teilen</button>
              <button className="btn danger" style={{ height: 44, borderRadius: 12 }} disabled={!selected} onClick={() => selected && act('drop', { slot: selected.slot, amount })}>Wegwerfen</button>
            </>
          )}
        </div>
        <span className="inv-hint">F2 schließen · Ziehen verschiebt</span>
      </div>

      {data.other ? (
        <Panel view={data.other} side="other" sel={sel} onSelect={setSel} onDrop={(f, t) => onDrop(f, t, 'other')} />
      ) : (
        <section className="inv-panel ghost" onDragOver={(e) => e.preventDefault()}
          onDrop={(e) => { e.preventDefault(); try { onDrop(JSON.parse(e.dataTransfer.getData('text/plain')), 1, 'other'); } catch { /* ignorieren */ } }}>
          <span className="top" />
          <div className="inv-head"><div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}><span className="eyebrow">Boden</span><h2>Vor dir</h2><span className="sub">Hier ablegen, um eine Ablage zu erstellen</span></div></div>
          <div className="inv-grid dim">{Array.from({ length: MIN_CELLS }, (_, i) => <div key={i} className="inv-cell empty" />)}</div>
        </section>
      )}
      <button className="inv-close" onClick={close} aria-label="Schließen"><Icon name="x" size={18} /></button>
    </div>
  );
}
