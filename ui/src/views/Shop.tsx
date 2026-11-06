// Laden nach Board „Laden“: Kopf, Kategorie-Reiter, Produkte links, Warenkorb rechts mit Bar/Karte.
import { useMemo, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { money } from './Hud';

export type ShopItem = { item: string; label: string; category: string; price: number; weight: number };
export type ShopData = { shop: string; type: string; name: string; cash: number; bank: number; taxPercent: number; weight: number; maxWeight: number; items: ShopItem[] };

const catLabel: Record<string, string> = { food: 'Essen', drink: 'Trinken', daily: 'Alltag', tool: 'Werkzeug', weapon: 'Waffen', document: 'Dokumente' };
const catIcon: Record<string, string> = { food: 'food', drink: 'drop', daily: 'bag', tool: 'tool', weapon: 'gun', document: 'doc' };

export function Shop({ data }: { data: ShopData }) {
  const [cat, setCat] = useState<string>('all');
  const [cart, setCart] = useState<Record<string, number>>({});

  const cats = useMemo(() => Array.from(new Set(data.items.map((i) => i.category))), [data.items]);
  const shown = data.items.filter((i) => cat === 'all' || i.category === cat);
  const lines = Object.entries(cart).map(([item, amount]) => ({ def: data.items.find((i) => i.item === item)!, amount })).filter((l) => l.def && l.amount > 0);
  const total = lines.reduce((s, l) => s + l.def.price * l.amount, 0);
  const weight = lines.reduce((s, l) => s + l.def.weight * l.amount, 0);
  const tooHeavy = data.weight + weight > data.maxWeight + 1e-6;

  const add = (item: string, d: number) => setCart((c) => { const n = Math.max(0, Math.min(100, (c[item] ?? 0) + d)); const next = { ...c, [item]: n }; if (n === 0) delete next[item]; return next; });
  const buy = (method: 'cash' | 'card') => {
    if (lines.length === 0 || tooHeavy) return;
    nui('action', { view: 'shop', action: 'buy', data: { method, cart: lines.map((l) => ({ item: l.def.item, amount: l.amount })) } });
    setCart({});
  };
  const close = () => nui('action', { view: 'shop', action: 'close' });

  return (
    <div className="shop-wrap">
      <section className="shop-panel">
        <span className="top" />
        <div className="inv-head">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <span className="eyebrow">{data.type}</span>
            <h2>{data.name}</h2>
            <span className="sub">Bargeld {money(data.cash)} · Konto {money(data.bank)} · {data.weight.toFixed(1)} / {data.maxWeight} kg</span>
          </div>
          <button className="bank-x" onClick={close} aria-label="Schließen"><Icon name="x" size={16} /></button>
        </div>
        <div className="bank-tabs" style={{ alignSelf: 'flex-start', width: 'auto' }}>
          <button className={cat === 'all' ? 'active' : ''} style={{ padding: '0 18px' }} onClick={() => setCat('all')}>Alle</button>
          {cats.map((c) => <button key={c} className={cat === c ? 'active' : ''} style={{ padding: '0 18px' }} onClick={() => setCat(c)}>{catLabel[c] ?? c}</button>)}
        </div>
        <div className="shop-body">
          <div className="shop-grid">
            {shown.map((i) => (
              <div key={i.item} className={'shop-item' + (cart[i.item] ? ' in' : '')} onClick={() => add(i.item, 1)}>
                <span className="ico"><Icon name={catIcon[i.category] ?? 'box'} size={30} stroke={1.8} /></span>
                <strong>{i.label}</strong>
                <span className="num">{money(i.price)}</span>
                {cart[i.item] ? <span className="badge num">{cart[i.item]}</span> : null}
              </div>
            ))}
          </div>
          <aside className="shop-cart">
            <span className="eyebrow">Warenkorb</span>
            <div className="shop-lines">
              {lines.length === 0 && <span style={{ fontSize: 13, color: 'var(--dim)' }}>Klicke Produkte an.</span>}
              {lines.map((l) => (
                <div key={l.def.item} className="shop-line">
                  <span style={{ display: 'flex', flexDirection: 'column', minWidth: 0, flex: 1 }}>
                    <strong>{l.def.label}</strong>
                    <span style={{ fontSize: 12, color: 'var(--muted)' }}>{l.amount} × {money(l.def.price)}</span>
                  </span>
                  <span className="qty"><button onClick={() => add(l.def.item, -1)}>−</button><span className="num">{l.amount}</span><button onClick={() => add(l.def.item, 1)}>+</button></span>
                  <strong className="num" style={{ minWidth: 64, textAlign: 'right' }}>{money(l.def.price * l.amount)}</strong>
                </div>
              ))}
            </div>
            <div className="shop-sum">
              <span>Summe{data.taxPercent ? ` (inkl. ${data.taxPercent} % Umsatzsteuer)` : ''}</span>
              <strong className="num">{money(total)}</strong>
            </div>
            {tooHeavy && <span style={{ fontSize: 12, color: 'var(--danger)' }}>Zu schwer für deine Taschen.</span>}
            <div style={{ display: 'flex', gap: 8 }}>
              <button className="btn primary" style={{ flex: 1, height: 44 }} disabled={lines.length === 0 || tooHeavy || data.cash < total} onClick={() => buy('cash')}>Bar</button>
              <button className="btn" style={{ flex: 1, height: 44 }} disabled={lines.length === 0 || tooHeavy || data.bank < total} onClick={() => buy('card')}><Icon name="cash" size={16} />Karte</button>
            </div>
          </aside>
        </div>
      </section>
    </div>
  );
}
