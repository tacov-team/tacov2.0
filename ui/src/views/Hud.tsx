import { useEffect, useState } from 'react';
import { useStore } from '../store';
import { Ring } from '../components/Ring';
import { Icon } from '../components/Icon';

export const money = (n: number) => `${Math.round(n).toLocaleString('de-DE')} $`;

function useClock() {
  const [now, setNow] = useState(new Date());
  useEffect(() => { const t = setInterval(() => setNow(new Date()), 1000); return () => clearInterval(t); }, []);
  return now;
}

export function Hud() {
  const { state } = useStore();
  const h = state.hud;
  const now = useClock();
  if (!h.visible) return null;
  const time = now.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  const date = now.toLocaleDateString('de-DE');

  return (
    <>
      <div className="hud-top">
        <div style={{ display: 'flex', alignItems: 'center', gap: 16 }}>
          <span style={{ display: 'inline-flex', gap: 8 }}>
            <span style={{ width: 34, height: 34, borderRadius: '50%', background: 'rgba(255,255,255,0.10)', display: 'inline-grid', placeItems: 'center' }}><Icon name="mic" size={16} /></span>
          </span>
          <div style={{ display: 'flex', flexDirection: 'column', alignItems: 'center' }}>
            <img src="assets/logo.png" alt="TacoV" width={170} style={{ display: 'block', filter: 'drop-shadow(0 4px 12px rgba(0,0,0,0.6))' }} />
            <span className="ts" style={{ fontSize: 13, fontWeight: 900, letterSpacing: '0.26em', marginTop: 2 }}>ROLEPLAY</span>
          </div>
        </div>
        <span className="ts num" style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 24, fontWeight: 900 }}>
          {money(h.cash)}
          <span style={{ width: 28, height: 28, borderRadius: '50%', background: 'var(--accent-grad)', color: 'var(--on-accent)', display: 'grid', placeItems: 'center', fontSize: 15, fontWeight: 900, boxShadow: 'var(--accent-glow)' }}>$</span>
        </span>
        {h.black > 0 && (
          <span className="ts num" style={{ display: 'flex', alignItems: 'center', gap: 10, fontSize: 17, fontWeight: 900, color: 'var(--black-money)' }}>
            {money(h.black)}
            <span style={{ width: 24, height: 24, borderRadius: '50%', background: 'linear-gradient(135deg, #C9A0FF, #7A3FE0)', color: '#1A0A33', display: 'grid', placeItems: 'center', fontSize: 12, fontWeight: 900 }}>S</span>
          </span>
        )}
        <span className="ts" style={{ fontSize: 12, color: 'var(--muted)' }}>ID {h.serverId} · Bank {money(h.bank)} · {time}</span>
      </div>

      <div className="hud-rings">
        <Ring label="Leben" value={h.health} icon="heart" />
        <Ring label="Weste" value={h.armor} icon="shield" />
        <Ring label="Hunger" value={h.hunger} icon="food" />
        <Ring label="Durst" value={h.thirst} icon="drop" />
        <Ring label="Fitness" value={h.fitness} icon="fitness" />
      </div>

      <div className="hud-bottom">
        <div className="hud-card">
          <div className="frame" />
          <div className="inner"><div className="grid" /><span className="dot" /></div>
          <span style={{ position: 'absolute', right: 14, top: 10 }}><Icon name="home" size={20} /></span>
          <div className="who">
            <strong>{h.name}</strong>
            <span>Level {h.level}{h.status ? ` · ${h.status}` : ''}</span>
          </div>
          <div className="bar"><span style={{ width: `${Math.round(h.levelProgress * 100)}%` }} /></div>
        </div>
        <div className="hud-info">
          <div className="row"><span><Icon name="clock" /></span><strong>{date} | {time} Uhr</strong></div>
          <div className="row"><span><Icon name="pin" /></span><span style={{ display: 'flex', flexDirection: 'column' }}><strong>{h.street || '–'}</strong>{h.area && <small>{h.area}</small>}</span></div>
          <div className="row"><span><Icon name="briefcase" /></span><strong>{h.faction || 'Zivilist'}</strong></div>
          <div className="row"><span><Icon name="fitness" /></span><strong className="num">{h.weight.toLocaleString('de-DE', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} / {h.maxWeight} kg</strong></div>
        </div>
      </div>
    </>
  );
}
