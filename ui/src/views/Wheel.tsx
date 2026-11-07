// X-Rad nach Canvas „V4 · X-Rad“: Ring mit Icon-Segmenten, Mitte mit Kachel/Titel/Hinweis, Schließen-Segment oben. Loslassen wählt.
import { useEffect, useMemo, useRef, useState } from 'react';
import { nui, useNuiEvent } from '../nui';
import { Icon } from '../components/Icon';

export type WheelEntry = { id: string; label: string; icon: string; order: number };
export type WheelData = { entries: WheelEntry[]; center: { kind: string; title: string; sub: string; icon?: string }; key?: string };

const SIZE = 500;
const INNER = 118;
const RING_R = 180;

export function Wheel({ data }: { data: WheelData }) {
  const [hover, setHover] = useState<string | null>(null);
  const hoverRef = useRef<string | null>(null);
  hoverRef.current = hover;

  // Eintrag 0 ist immer „Schließen“ oben
  const entries = useMemo(() => [{ id: '__close', label: 'Schließen', icon: 'x', order: -1 }, ...data.entries], [data.entries]);
  const n = entries.length;

  const release = () => {
    const id = hoverRef.current;
    if (!id || id === '__close') nui('action', { view: 'wheel', action: 'close', data: {} });
    else nui('action', { view: 'wheel', action: 'pick', data: { id } });
  };
  useNuiEvent('wheelRelease', release);
  // Die NUI hat den Fokus, solange das Rad offen ist: das Loslassen der Taste kommt hier an
  useEffect(() => {
    const key = (data.key ?? 'x').toLowerCase();
    const onUp = (e: KeyboardEvent) => { if (e.key.toLowerCase() === key) release(); };
    window.addEventListener('keyup', onUp);
    return () => window.removeEventListener('keyup', onUp);
  }, [data.key]);

  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      const cx = window.innerWidth / 2, cy = window.innerHeight / 2;
      const dx = e.clientX - cx, dy = e.clientY - cy;
      const dist = Math.hypot(dx, dy);
      if (dist < INNER || dist > SIZE / 2 + 40) { setHover(null); return; }
      const ang = (Math.atan2(dy, dx) + Math.PI / 2 + Math.PI * 2 + Math.PI / n) % (Math.PI * 2);
      const idx = Math.floor(ang / (Math.PI * 2 / n)) % n;
      setHover(entries[idx]?.id ?? null);
    };
    window.addEventListener('mousemove', onMove);
    return () => window.removeEventListener('mousemove', onMove);
  }, [entries, n]);

  const segs = entries.map((e, i) => {
    const a0 = (-90 + (i * 360) / n - 180 / n) * (Math.PI / 180);
    const a1 = a0 + (2 * Math.PI) / n;
    const R = SIZE / 2 - 4;
    const p = (r: number, a: number) => `${SIZE / 2 + Math.cos(a) * r} ${SIZE / 2 + Math.sin(a) * r}`;
    const d = `M${p(R, a0)} A${R} ${R} 0 0 1 ${p(R, a1)} L${p(INNER, a1)} A${INNER} ${INNER} 0 0 0 ${p(INNER, a0)} Z`;
    const on = hover === e.id;
    return <path key={e.id} d={d} fill={on ? 'rgba(139,92,246,0.92)' : 'rgba(255,255,255,0.04)'} stroke="rgba(255,255,255,0.1)" onMouseEnter={() => setHover(e.id)} onClick={() => { if (e.id === '__close') nui('action', { view: 'wheel', action: 'close', data: {} }); else nui('action', { view: 'wheel', action: 'pick', data: { id: e.id } }); }} />;
  });

  return (
    <div className="wheel-wrap">
      <div className="wheel" style={{ width: SIZE, height: SIZE }}>
        <svg width={SIZE} height={SIZE} viewBox={`0 0 ${SIZE} ${SIZE}`}>{segs}</svg>
        {entries.map((e, i) => {
          const a = (-90 + (i * 360) / n) * (Math.PI / 180);
          const x = SIZE / 2 + Math.cos(a) * RING_R - 13, y = SIZE / 2 + Math.sin(a) * RING_R - 13;
          return <span key={e.id} className={'wicon' + (hover === e.id ? ' on' : '')} style={{ left: x, top: y }} title={e.label}><Icon name={e.icon} size={26} /></span>;
        })}
        <div className="wheel-center" style={{ width: INNER * 2 - 10, height: INNER * 2 - 10 }}>
          <span className="badge sm"><Icon name={data.center.icon ?? 'user'} size={16} /></span>
          <b>{hover && hover !== '__close' ? entries.find((e) => e.id === hover)?.label : data.center.title}</b>
          <span className="sub" style={{ fontSize: 12 }}>{data.center.sub}</span>
        </div>
      </div>
    </div>
  );
}
