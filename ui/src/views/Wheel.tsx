// X-Rad: Segmente mit Icons, Mitte zeigt Ziel oder gewählten Eintrag. Halten → Maus auf Segment → loslassen wählt.
import { useEffect, useMemo, useRef, useState } from 'react';
import { nui, useNuiEvent } from '../nui';
import { Icon } from '../components/Icon';

export type WheelEntry = { id: string; label: string; icon: string; order: number };
export type WheelData = { entries: WheelEntry[]; center: { kind: string; title: string; sub: string; icon?: string }; key?: string };

const SIZE = 420;
const INNER = 92;
const RING_R = 160;

export function Wheel({ data }: { data: WheelData }) {
  const [hover, setHover] = useState<string | null>(null);
  const hoverRef = useRef<string | null>(null);
  hoverRef.current = hover;
  const entries = useMemo(() => [{ id: '__close', label: 'Schließen', icon: 'x', order: -1 }, ...data.entries], [data.entries]);
  const n = entries.length;
  const pick = (id: string | null) => {
    if (!id || id === '__close') nui('action', { view: 'wheel', action: 'close', data: {} });
    else nui('action', { view: 'wheel', action: 'pick', data: { id } });
  };
  useNuiEvent('wheelRelease', () => pick(hoverRef.current));
  useEffect(() => {
    const key = (data.key ?? 'x').toLowerCase();
    const onUp = (e: KeyboardEvent) => { if (e.key.toLowerCase() === key) pick(hoverRef.current); };
    window.addEventListener('keyup', onUp);
    return () => window.removeEventListener('keyup', onUp);
  }, [data.key]);
  // Skalierung: das Rad wird in rem gezeichnet; die Maus-Geometrie rechnet mit der echten Pixelgröße
  const rem = parseFloat(getComputedStyle(document.documentElement).fontSize) / 16;
  useEffect(() => {
    const onMove = (e: MouseEvent) => {
      const cx = window.innerWidth / 2, cy = window.innerHeight / 2;
      const dx = e.clientX - cx, dy = e.clientY - cy;
      const dist = Math.hypot(dx, dy) / rem;
      if (dist < INNER || dist > SIZE / 2 + 40) { setHover(null); return; }
      const ang = (Math.atan2(dy, dx) + Math.PI / 2 + Math.PI * 2 + Math.PI / n) % (Math.PI * 2);
      setHover(entries[Math.floor(ang / (Math.PI * 2 / n)) % n]?.id ?? null);
    };
    window.addEventListener('mousemove', onMove);
    return () => window.removeEventListener('mousemove', onMove);
  }, [entries, n, rem]);

  const segs = entries.map((e, i) => {
    const a0 = (-90 + (i * 360) / n - 180 / n) * (Math.PI / 180);
    const a1 = a0 + (2 * Math.PI) / n;
    const R = SIZE / 2 - 4;
    const p = (r: number, a: number) => `${SIZE / 2 + Math.cos(a) * r} ${SIZE / 2 + Math.sin(a) * r}`;
    const d = `M${p(R, a0)} A${R} ${R} 0 0 1 ${p(R, a1)} L${p(INNER, a1)} A${INNER} ${INNER} 0 0 0 ${p(INNER, a0)} Z`;
    const on = hover === e.id;
    const close = e.id === '__close';
    return <path key={e.id} d={d} fill={on ? (close ? 'rgba(248,113,113,0.9)' : 'rgba(139,92,246,0.92)') : 'rgba(14,12,22,0.9)'} stroke="rgba(255,255,255,0.12)" onMouseEnter={() => setHover(e.id)} onClick={() => pick(e.id)} />;
  });
  const label = hover && hover !== '__close' ? entries.find((e) => e.id === hover)?.label : hover === '__close' ? 'Schließen' : data.center.title;

  return (
    <div className="wheel-wrap">
      <div className="wheel" style={{ width: `${SIZE / 16}rem`, height: `${SIZE / 16}rem` }}>
        <svg width="100%" height="100%" viewBox={`0 0 ${SIZE} ${SIZE}`}>{segs}</svg>
        {entries.map((e, i) => {
          const a = (-90 + (i * 360) / n) * (Math.PI / 180);
          const x = SIZE / 2 + Math.cos(a) * RING_R - 14, y = SIZE / 2 + Math.sin(a) * RING_R - 14;
          return <span key={e.id} className={'wicon' + (hover === e.id ? ' on' : '')} style={{ left: `${x / 16}rem`, top: `${y / 16}rem` }}><Icon name={e.icon} size={22} /></span>;
        })}
        <div className="wheel-center" style={{ width: `${(INNER * 2 - 12) / 16}rem`, height: `${(INNER * 2 - 12) / 16}rem` }}>
          <Icon name={data.center.icon ?? 'user'} size={18} />
          <b className="ellipsis" style={{ maxWidth: '100%' }}>{label}</b>
          <span className="sub ellipsis" style={{ maxWidth: '100%' }}>{data.center.sub}</span>
        </div>
      </div>
    </div>
  );
}
