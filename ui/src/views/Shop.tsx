// Laden: Sortiment links (Reiter, Suche), Warenkorb rechts, Bar oder Karte.
import { useMemo, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { ItemIcon } from '../components/ItemIcon';
import { Panel } from '../components/Panel';
import { money } from './Hud';

export type ShopItem = { item: string; label: string; category: string; price: number; weight: number; license?: string; locked?: boolean };
export type ShopData = { shop: string; type: string; name: string; cash: number; bank: number; taxPercent: number; weight: number; maxWeight: number; items: ShopItem[] };
const catLabel: Record<string, string> = { food: 'Essen', drink: 'Trinken', daily: 'Alltag', tool: 'Werkzeug', weapon: 'Waffen', ammo: 'Munition', armor: 'Schutz', document: 'Dokumente' };

export function Shop({ data }: { data: ShopData }) {
  const [cat, setCat] = useState('all');
  const [q, setQ] = useState('');
  const [cart, setCart] = useState<Record<string, number>>({});
  const cats = useMemo(() => Array.from(new Set(data.items.map((i) => i.category))), [data.items]);
  const shown = data.items.filter((i) => (cat === 'all' || i.category === cat) && (!q || i.label.toLowerCase().includes(q.toLowerCase())));
  const lines = Object.entries(cart).map(([item, amount]) => ({ def: data.items.find((i) => i.item === item)!, amount })).filter((l) => l.def && l.amount > 0);
  const total = lines.reduce((s, l) => s + l.def.price * l.amount, 0);
  const weight = lines.reduce((s, l) => s + l.def.weight * l.amount, 0);
  const tooHeavy = data.weight + weight > data.maxWeight + 1e-6;
  const add = (item: string, d: number) => setCart((c) => { const n = Math.max(0, Math.min(100, (c[item] ?? 0) + d)); const next = { ...c, [item]: n }; if (n === 0) delete next[item]; return next; });
  const buy = (method: 'cash' | 'card') => { if (lines.length === 0 || tooHeavy) return; nui('action', { view: 'shop', action: 'buy', data: { method, cart: lines.map((l) => ({ item: l.def.item, amount: l.amount })) } }); setCart({}); };
  const close = () => nui('action', { view: 'shop', action: 'close' });

  return (
    <div className="center shop">
      <Panel icon="bag" title={data.type} sub={data.name} onClose={close}>
        <div className="catalog">
          <div className="row-flex">
            <div className="tabs" style={{ flex: 1 }}>
              <button className={cat === 'all' ? 'on' : ''} onClick={() => setCat('all')}>Alle</button>
              {cats.map((c) => <button key={c} className={cat === c ? 'on' : ''} onClick={() => setCat(c)}>{catLabel[c] ?? c}</button>)}
            </div>
            <input className="input" style={{ width: '14rem' }} placeholder="Suchen…" value={q} onChange={(e) => setQ(e.target.value)} />
          </div>
          <div className="grid">
            {shown.map((i) => (
              <div key={i.item} className={'card item' + (cart[i.item] ? ' on' : '') + (i.locked ? ' locked' : '')} onClick={() => { if (!i.locked) add(i.item, 1); }}>
                {i.locked ? <span className="tag qty">Waffenschein</span> : cart[i.item] ? <span className="tag accent qty">{cart[i.item]}×</span> : null}
                <ItemIcon item={i.item} category={i.category} size={40} />
                <span className="name">{i.label}</span>
                <span className="price num">{money(i.price)}</span>
              </div>
            ))}
          </div>
        </div>
        <aside className="cart">
          <div className="row-flex"><b style={{ fontSize: '0.8125rem' }}>Warenkorb</b>{lines.length > 0 && <span className="tag right num">{lines.reduce((s, l) => s + l.amount, 0)}</span>}</div>
          <div className="lines">
            {lines.length === 0 && <span className="muted" style={{ fontSize: '0.8125rem' }}>Klicke Artikel an, um sie hinzuzufügen.</span>}
            {lines.map((l) => (
              <div key={l.def.item} className="line">
                <ItemIcon item={l.def.item} category={l.def.category} size={18} />
                <span className="ellipsis">{l.def.label}</span>
                <span className="ctl"><button onClick={() => add(l.def.item, -1)}>−</button><span className="num" style={{ width: '1.5rem', textAlign: 'center' }}>{l.amount}</span><button onClick={() => add(l.def.item, 1)}>+</button></span>
                <b className="num" style={{ width: '4.5rem', textAlign: 'right' }}>{money(l.def.price * l.amount)}</b>
              </div>
            ))}
          </div>
          <div className="total">
            <span className="lbl">Gesamt{data.taxPercent ? ` · inkl. ${data.taxPercent} % USt` : ''}</span>
            <span className="money-big num">{money(total)}</span>
            <span className="muted" style={{ fontSize: '0.75rem' }}>Bargeld {money(data.cash)} · Konto {money(data.bank)}</span>
          </div>
          {tooHeavy && <span style={{ fontSize: '0.75rem', color: 'var(--danger)' }}>Zu schwer für deine Taschen.</span>}
          <div className="row-flex">
            <button className="btn primary grow" disabled={lines.length === 0 || tooHeavy || data.cash < total} onClick={() => buy('cash')}><Icon name="cash" size={14} /> Bar</button>
            <button className="btn grow" disabled={lines.length === 0 || tooHeavy || data.bank < total} onClick={() => buy('card')}><Icon name="card" size={14} /> Karte</button>
          </div>
        </aside>
      </Panel>
    </div>
  );
}
