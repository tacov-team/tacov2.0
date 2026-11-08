// Inventar (F2): links deine Taschen, rechts Boden oder Behälter. Klick wählt, Ziehen verschiebt, Leiste unten für Aktionen.
// Ziehen läuft über Maus-Ereignisse (kein HTML5-Drag&Drop – das liefert in der FiveM-NUI keine Drop-Ereignisse).
import { useEffect, useMemo, useRef, useState, type MouseEvent as RMouseEvent } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { ItemIcon } from '../components/ItemIcon';
import { Panel, Kbd } from '../components/Panel';
import { money } from './Hud';

export type InvItem = { slot: number; item: string; amount: number; meta?: Record<string, unknown>; label: string; category: string; weight: number; usable: boolean; money: boolean };
export type InvView = { kind: string; id: number; items: InvItem[]; weight: number; maxWeight: number; title: string; subtitle?: string; name?: string; cash?: number; black?: number; dropId?: number };
export type InventoryData = { self: InvView; other: InvView | null; target?: number | null; ground?: boolean };

const COLS = 6;
const MIN_CELLS = 36;
const catLabel: Record<string, string> = { money: 'Geld', document: 'Dokumente', daily: 'Alltag', tool: 'Werkzeug', material: 'Rohstoffe', drug: 'Drogen', weapon: 'Waffen', ammo: 'Munition', armor: 'Schutz', food: 'Essen', drink: 'Trinken', leisure: 'Freizeit', jewelry: 'Schmuck', loot: 'Beute' };
const kg = (n: number) => `${n.toLocaleString('de-DE', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} kg`;

type Side = 'self' | 'other';
type Sel = { side: Side; slot: number } | null;
type From = { side: Side; slot: number };
type Drag = { from: From; item: InvItem; x: number; y: number; moved: boolean; startX: number; startY: number };

function Grid({ view, side, sel, drag, onSelect, onGrab }: { view: InvView; side: Side; sel: Sel; drag: Drag | null; onSelect: (s: Sel) => void; onGrab: (from: From, item: InvItem, e: RMouseEvent) => void }) {
  const bySlot = useMemo(() => new Map(view.items.map((i) => [i.slot, i])), [view.items]);
  const maxSlot = view.items.reduce((m, i) => Math.max(m, i.slot), 0);
  const cells = Math.max(MIN_CELLS, Math.ceil((maxSlot + 1) / COLS) * COLS);
  return (
    <div className="grid">
      {Array.from({ length: cells }, (_, i) => i + 1).map((slot) => {
        const it = bySlot.get(slot);
        if (!it) return <div key={slot} className="cell empty" data-side={side} data-slot={slot} />;
        const active = sel?.side === side && sel.slot === slot;
        const dragging = drag?.moved && drag.from.side === side && drag.from.slot === slot;
        return (
          <div key={slot} className={'cell' + (active ? ' on' : '') + (dragging ? ' dragging' : '')} data-side={side} data-slot={slot}
            title={`${it.label} · ${it.money ? money(it.amount) : `${it.amount} Stück · ${kg(it.weight * it.amount)}`}`}
            onMouseDown={(e) => { if (e.button === 0) onGrab({ side, slot }, it, e); }} onClick={() => onSelect({ side, slot })}>
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
  const [drag, setDrag] = useState<Drag | null>(null);
  const dragRef = useRef<Drag | null>(null);
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
    if (toSide === 'other' && !data.other) { if (canGround) act('drop', { slot: from.slot, amount: it.amount }); return; }
    const qty = sel && sel.side === from.side && sel.slot === from.slot ? amount : it.amount;
    act('move', { slot: from.slot, to: toSlot, from: from.side, dest: toSide, amount: qty });
  };
  const canGround = data.ground !== false;

  // Ziehen: Maus gedrückt auf einer Zelle → ab 4 px Bewegung Geist am Zeiger → Loslassen über Zelle/Boden verschiebt
  const onGrab = (from: From, item: InvItem, e: RMouseEvent) => {
    e.preventDefault();
    const d: Drag = { from, item, x: e.clientX, y: e.clientY, startX: e.clientX, startY: e.clientY, moved: false };
    dragRef.current = d;
    setDrag(d);
  };
  useEffect(() => {
    const move = (e: MouseEvent) => {
      const d = dragRef.current;
      if (!d) return;
      const moved = d.moved || Math.abs(e.clientX - d.startX) > 4 || Math.abs(e.clientY - d.startY) > 4;
      const n = { ...d, x: e.clientX, y: e.clientY, moved };
      dragRef.current = n;
      setDrag(n);
    };
    const up = (e: MouseEvent) => {
      const d = dragRef.current;
      dragRef.current = null;
      setDrag(null);
      if (!d || !d.moved) return;
      const el = document.elementFromPoint(e.clientX, e.clientY)?.closest<HTMLElement>('[data-slot],[data-ground]');
      if (!el) return;
      if (el.dataset.ground) { onDrop(d.from, 1, 'other'); return; }
      onDrop(d.from, Number(el.dataset.slot), el.dataset.side as Side);
    };
    window.addEventListener('mousemove', move);
    window.addEventListener('mouseup', up);
    return () => { window.removeEventListener('mousemove', move); window.removeEventListener('mouseup', up); };
  });
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
            <button className="btn danger" disabled={!selected || !canGround} title={canGround ? undefined : 'Im Fahrzeug nicht möglich'} onClick={() => selected && act('drop', { slot: selected.slot, amount })}>Wegwerfen</button>
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
        <Grid view={data.self} side="self" sel={sel} drag={drag} onSelect={setSel} onGrab={onGrab} />
      </Panel>

      <Panel icon="box" title={other ? other.title : (canGround ? 'Boden' : 'Fahrzeug')} sub={other ? (other.subtitle ?? 'Vor dir') : (canGround ? 'Hierher ziehen, um etwas abzulegen' : 'Zum Ablegen aussteigen – Handschuhfach und Kofferraum über das Fahrzeugmenü')} onClose={close}
        foot={<span className="keys"><Kbd>Esc</Kbd> schließen · Ziehen verschiebt · erst wählen, dann Aktion</span>}>
        {other ? (
          <>
            <div className="toolbar">
              <span className="muted" style={{ fontSize: '0.75rem' }}>{other.items.length} Gegenstände</span>
              <div className="weight"><span className="num">{kg(other.weight)} / {other.maxWeight} kg</span><span className="meter"><i style={{ width: `${pct(other)}%` }} /></span></div>
            </div>
            <Grid view={other} side="other" sel={sel} drag={drag} onSelect={setSel} onGrab={onGrab} />
          </>
        ) : canGround ? (
          <div className="grid" style={{ opacity: 0.7 }} data-ground="1">
            {Array.from({ length: MIN_CELLS }, (_, i) => <div key={i} className="cell empty" />)}
          </div>
        ) : (
          <div className="empty-note"><Icon name="car" size={28} /><span>Du sitzt in einem Fahrzeug.</span><span className="muted">Ablegen auf den Boden geht nur draußen.</span></div>
        )}
      </Panel>
      {drag?.moved && (
        <div className="drag-ghost" style={{ left: drag.x, top: drag.y }}>
          <ItemIcon item={drag.item.item} category={drag.item.category} size={30} />
          <span className="num">{drag.item.money ? money(drag.item.amount) : drag.item.amount}</span>
        </div>
      )}
    </div>
  );
}
