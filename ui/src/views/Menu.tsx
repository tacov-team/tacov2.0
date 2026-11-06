// Listenmenü nach Canvas „V4 · Listenmenü“: Tastatur ↑↓ Enter ⌫, Zähler, Abschnitte, Infokasten. Lua schickt die Ebenen.
import { useEffect, useRef, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { Panel, PanelHead, Keys } from '../components/Panel';

export type MenuItem = { id: string; label: string; icon?: string; price?: string; sub?: string; dim?: boolean; section?: string; badge?: string };
export type MenuData = { id: string; title: string; info?: string; icon?: string; items: MenuItem[]; note?: string; depth: number };

export function Menu({ data }: { data: MenuData }) {
  const [idx, setIdx] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);

  useEffect(() => { setIdx(0); }, [data.id]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const n = data.items.length;
      if (e.key === 'ArrowDown') { e.preventDefault(); setIdx((i) => (i + 1) % Math.max(1, n)); }
      else if (e.key === 'ArrowUp') { e.preventDefault(); setIdx((i) => (i - 1 + n) % Math.max(1, n)); }
      else if (e.key === 'Enter') { e.preventDefault(); const it = data.items[idx]; if (it && !it.dim) nui('action', { view: 'menu', action: 'select', data: { menu: data.id, id: it.id } }); }
      else if (e.key === 'Backspace') { e.preventDefault(); nui('action', { view: 'menu', action: 'back', data: { menu: data.id } }); }
      else if (e.key === 'Escape') { e.preventDefault(); nui('action', { view: 'menu', action: 'close', data: {} }); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [data, idx]);

  useEffect(() => {
    const el = listRef.current?.children[idx] as HTMLElement | undefined;
    el?.scrollIntoView({ block: 'nearest' });
  }, [idx]);

  let lastSection: string | undefined;
  return (
    <Panel className="menu" soft>
      <PanelHead icon={data.icon ?? 'list'} brand="TacoV Roleplay" title={data.title} info={data.info} />
      <div className="body">
        <div className="counter"><b style={{ fontSize: 14 }}>Auswahl</b><span className="tag dark num">{Math.min(idx + 1, data.items.length)}/{data.items.length}</span></div>
        <div className="list" ref={listRef}>
          {data.items.map((it, i) => {
            const sec = it.section && it.section !== lastSection ? it.section : null;
            lastSection = it.section ?? lastSection;
            return (
              <div key={it.id} style={{ display: 'contents' }}>
                {sec && <div className="section"><i />{sec}<i /></div>}
                <div className={'row' + (i === idx ? ' on' : '') + (it.dim ? ' dim' : '')} onMouseEnter={() => setIdx(i)}
                  onClick={() => { if (!it.dim) nui('action', { view: 'menu', action: 'select', data: { menu: data.id, id: it.id } }); }}>
                  <span className="ic">{it.icon ? <Icon name={it.icon} size={14} /> : '•'}</span>
                  <span style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                    <span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{it.label}</span>
                    {it.sub && <span className="sub">{it.sub}</span>}
                  </span>
                  {it.price && <span className="price-ok num">{it.price}</span>}
                  {it.badge && <span className="tag dark" style={{ marginLeft: 'auto' }}>{it.badge}</span>}
                  <span className="chev">›</span>
                </div>
              </div>
            );
          })}
        </div>
        {data.note && <div className="card note"><i className="info-i on">i</i>{data.note}</div>}
        <Keys back={data.depth > 0} />
      </div>
    </Panel>
  );
}
