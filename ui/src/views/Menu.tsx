// Listenmenü (links): ↑↓ wählen, Enter bestätigen, ⌫ zurück, Esc schließen. Lua schickt die Ebenen.
import { useEffect, useRef, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { Panel, Kbd } from '../components/Panel';

export type MenuItem = { id: string; label: string; icon?: string; price?: string; sub?: string; dim?: boolean; section?: string; badge?: string };
export type MenuData = { id: string; title: string; info?: string; icon?: string; items: MenuItem[]; note?: string; depth: number };

export function Menu({ data }: { data: MenuData }) {
  const [idx, setIdx] = useState(0);
  const listRef = useRef<HTMLDivElement>(null);
  useEffect(() => { setIdx(0); }, [data.id]);

  const select = (it: MenuItem) => { if (!it.dim) nui('action', { view: 'menu', action: 'select', data: { menu: data.id, id: it.id } }); };
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      const n = Math.max(1, data.items.length);
      if (e.key === 'ArrowDown') { e.preventDefault(); setIdx((i) => (i + 1) % n); }
      else if (e.key === 'ArrowUp') { e.preventDefault(); setIdx((i) => (i - 1 + n) % n); }
      else if (e.key === 'Enter') { e.preventDefault(); const it = data.items[idx]; if (it) select(it); }
      else if (e.key === 'Backspace') { e.preventDefault(); nui('action', { view: 'menu', action: 'back', data: { menu: data.id } }); }
      else if (e.key === 'Escape') { e.preventDefault(); nui('action', { view: 'menu', action: 'close', data: {} }); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [data, idx]);
  useEffect(() => { (listRef.current?.querySelector('.row.on') as HTMLElement | null)?.scrollIntoView({ block: 'nearest' }); }, [idx]);
  // Markierung melden (Vorschau in der Werkstatt u. a.)
  useEffect(() => { const it = data.items[idx]; if (it) nui('action', { view: 'menu', action: 'focus', data: { menu: data.id, id: it.id } }); }, [data.id, idx]);

  let lastSection: string | undefined;
  return (
    <Panel className="menu" icon={data.icon ?? 'list'} title={data.title} sub={data.info}
      headRight={<span className="tag num">{Math.min(idx + 1, data.items.length)}/{data.items.length}</span>}
      foot={<span className="keys"><Kbd>↑</Kbd><Kbd>↓</Kbd> wählen <Kbd>Enter</Kbd> bestätigen {data.depth > 0 && <><Kbd>⌫</Kbd> zurück</>} <Kbd>Esc</Kbd> schließen</span>}>
      <div className="list" ref={listRef}>
        {data.items.map((it, i) => {
          const sec = it.section && it.section !== lastSection ? it.section : null;
          lastSection = it.section ?? lastSection;
          return (
            <div key={it.id} style={{ display: 'contents' }}>
              {sec && <div className="section"><i />{sec}<i /></div>}
              <div className={'row' + (i === idx ? ' on' : '') + (it.dim ? ' dim' : '')} onMouseEnter={() => setIdx(i)} onClick={() => select(it)}>
                <span className="ic"><Icon name={it.icon ?? 'next'} size={14} /></span>
                <span className="col grow" style={{ gap: 0 }}><span className="ellipsis">{it.label}</span>{it.sub && <span className="sub">{it.sub}</span>}</span>
                {it.price && <span className="price num">{it.price}</span>}
                {it.badge && <span className="tag">{it.badge}</span>}
                <span className="chev">›</span>
              </div>
            </div>
          );
        })}
      </div>
      {data.note && <div className="card note">{data.note}</div>}
    </Panel>
  );
}
