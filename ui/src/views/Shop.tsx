// Laden nach Canvas „V4 · Laden“: Sortiment mit Suche, Preisfeld + Plus, Warenkorb mit Mengen, Gesamtpreis-Karte, Bar/Karte.
import { useMemo, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { ItemIcon } from '../components/ItemIcon';
import { Panel, PanelHead } from '../components/Panel';
import { money } from './Hud';

export type ShopItem = { item: string; label: string; category: string; price: number; weight: number };
export type ShopData = { shop: string; type: string; name: string; cash: number; bank: number; taxPercent: number; weight: number; maxWeight: number; items: ShopItem[] };

const catLabel: Record<string, string> = { food: 'Essen', drink: 'Trinken', daily: 'Alltag', tool: 'Werkzeug', weapon: 'Waffen', document: 'Dokumente' };

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
  const count = lines.reduce((s, l) => s + l.amount, 0);

  const add = (item: string, d: number) => setCart((c) => { const n = Math.max(0, Math.min(100, (c[item] ?? 0) + d)); const next = { ...c, [item]: n }; if (n === 0) delete next[item]; return next; });
  const buy = (method: 'cash' | 'card') => { if (lines.length === 0 || tooHeavy) return; nui('action', { view: 'shop', action: 'buy', data: { method, cart: lines.map((l) => ({ item: l.def.item, amount: l.amount })) } }); setCart({}); };
  const close = () => nui('action', { view: 'shop', action: 'close' });

  return (
    <div className="center-wrap">
      <Panel style={{ width: 1200 }}>
        <PanelHead icon="bag" title={data.type} info={`${data.name} · Lege Artikel in den Warenkorb und bezahle bar oder mit Karte.`} onClose={close} />
        <div className="pbody" style={{ flexDirection: 'row', gap: 20, alignItems: 'flex-start' }}>
          <div style={{ width: 800, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end', gap: 12 }}>
              <div className="sect"><b>Sortiment</b><span className="sub">{data.items.length} Artikel</span></div>
              <div className="seg">
                <button className={cat === 'all' ? 'on' : ''} onClick={() => setCat('all')}>Alle</button>
                {cats.map((c) => <button key={c} className={cat === c ? 'on' : ''} onClick={() => setCat(c)}>{catLabel[c] ?? c}</button>)}
              </div>
              <div className="search" style={{ width: 240, height: 36 }}><Icon name="search" size={14} /><input placeholder="Artikel suchen…" value={q} onChange={(e) => setQ(e.target.value)} /></div>
            </div>
            <div className="shop-grid">
              {shown.map((i) => (
                <div key={i.item} className={'card shop-item' + (cart[i.item] ? ' on' : '')} onClick={() => add(i.item, 1)}>
                  {cart[i.item] ? <span className="tag qty">{cart[i.item]}×</span> : null}
                  <span className="ico"><ItemIcon item={i.item} category={i.category} size={44} /></span>
                  <b style={{ fontSize: 13 }}>{i.label}</b>
                  <div className="foot"><span className="price num">{money(i.price)}</span><button className="plus" onClick={(e) => { e.stopPropagation(); add(i.item, 1); }}>+</button></div>
                </div>
              ))}
            </div>
          </div>
          <aside className="shop-cart">
            <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-end' }}>
              <div className="sect"><b>Warenkorb</b><span className="sub">Bar oder mit Karte bezahlen</span></div>
              {count > 0 && <span className="tag num">{count}</span>}
            </div>
            <div className="card shop-lines">
              {lines.length === 0 && <span className="sub">Klicke Produkte an.</span>}
              {lines.map((l) => (
                <div key={l.def.item} className="row" style={{ minHeight: 46 }}>
                  <span className="ic"><ItemIcon item={l.def.item} category={l.def.category} size={18} /></span>
                  <span style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}><span>{l.def.label}</span><span className="sub">je {money(l.def.price)}</span></span>
                  <span className="qty-ctl"><button onClick={() => add(l.def.item, -1)}>−</button><span className="num">{l.amount}</span><button onClick={() => add(l.def.item, 1)}>+</button></span>
                  <b className="num" style={{ width: 64, textAlign: 'right' }}>{money(l.def.price * l.amount)}</b>
                </div>
              ))}
            </div>
            <div className="hl" style={{ padding: 16, display: 'flex', flexDirection: 'column', gap: 4 }}>
              <span className="label">GESAMTPREIS{data.taxPercent ? ` · INKL. ${data.taxPercent} % UST` : ''}</span>
              <b className="num" style={{ fontSize: 36, fontWeight: 900 }}>{money(total)}</b>
              <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 12, fontWeight: 700 }}><span>Bargeld {money(data.cash)}</span><span>Konto {money(data.bank)}</span></div>
            </div>
            {tooHeavy && <span style={{ fontSize: 12, color: 'var(--danger)' }}>Zu schwer für deine Taschen.</span>}
            <div style={{ display: 'flex', gap: 10 }}>
              <button className="btn primary" style={{ flex: 1, height: 44 }} disabled={lines.length === 0 || tooHeavy || data.cash < total} onClick={() => buy('cash')}><Icon name="cash" size={14} /> Bar zahlen</button>
              <button className="btn" style={{ flex: 1, height: 44 }} disabled={lines.length === 0 || tooHeavy || data.bank < total} onClick={() => buy('card')}><Icon name="card" size={14} /> Mit Karte</button>
            </div>
          </aside>
        </div>
      </Panel>
    </div>
  );
}
