// Interaktionsrad (X halten) nach Board „Interaktionsrad“: Einträge im Kreis, Ziel in der Mitte; Loslassen wählt.
import { useEffect, useRef, useState } from 'react';
import { nui, useNuiEvent } from '../nui';
import { Icon } from '../components/Icon';

export type WheelEntry = { id: string; label: string; icon: string; order: number };
export type WheelData = { entries: WheelEntry[]; center: { kind: string; title: string; sub: string } };

const SIZE = 560;
const R = 200;

export function Wheel({ data }: { data: WheelData }) {
  const [hover, setHover] = useState<string | null>(null);
  const hoverRef = useRef<string | null>(null);
  hoverRef.current = hover;

  useNuiEvent('wheelRelease', () => {
    nui('action', { view: 'wheel', action: hoverRef.current ? 'pick' : 'close', data: { id: hoverRef.current } });
  });

  // Auswahl auch per Mausposition (Winkel), damit man nicht genau treffen muss
  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      const cx = window.innerWidth / 2, cy = window.innerHeight / 2;
      const dx = e.clientX - cx, dy = e.clientY - cy;
      const dist = Math.hypot(dx, dy);
      if (dist < 70 || data.entries.length === 0) { setHover(null); return; }
      const n = data.entries.length;
      const ang = (Math.atan2(dy, dx) + Math.PI / 2 + Math.PI * 2) % (Math.PI * 2);
      const idx = Math.round(ang / (Math.PI * 2 / n)) % n;
      setHover(data.entries[idx]?.id ?? null);
    };
    window.addEventListener('mousemove', onMove);
    return () => window.removeEventListener('mousemove', onMove);
  }, [data.entries]);

  const n = data.entries.length;
  return (
    <div className="wheel-wrap">
      <div className="wheel" style={{ width: SIZE, height: SIZE }}>
        <div className="wheel-bg" />
        <div className="wheel-center">
          <span className="eyebrow">{data.center.kind}</span>
          <strong>{data.center.title}</strong>
          <span>{data.center.sub}</span>
        </div>
        {data.entries.map((e, i) => {
          const a = (i / n) * Math.PI * 2 - Math.PI / 2;
          const x = SIZE / 2 + Math.cos(a) * R - 54;
          const y = SIZE / 2 + Math.sin(a) * R - 44;
          const active = hover === e.id;
          return (
            <div key={e.id} className={'wheel-item' + (active ? ' active' : '')} style={{ left: x, top: y }}
              onMouseEnter={() => setHover(e.id)} onClick={() => nui('action', { view: 'wheel', action: 'pick', data: { id: e.id } })}>
              <Icon name={e.icon} size={22} />
              {e.label}
            </div>
          );
        })}
        {n === 0 && <span className="wheel-empty">Nichts in der Nähe</span>}
      </div>
    </div>
  );
}
