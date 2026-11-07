// HUD nach Canvas „V4 · HUD“ und „V4 · HUD Fahrzeug“. Die Minimap bleibt die des Spiels; die Infozeilen stehen rechts daneben.
import { useEffect, useState } from 'react';
import { useStore, type HudData } from '../store';
import { Icon } from '../components/Icon';

export const money = (n: number) => `${Math.round(n).toLocaleString('de-DE')} $`;

function useClock() {
  const [now, setNow] = useState(new Date());
  useEffect(() => { const t = setInterval(() => setNow(new Date()), 1000); return () => clearInterval(t); }, []);
  return now;
}

function useViewport() {
  const [v, setV] = useState({ w: window.innerWidth, h: window.innerHeight });
  useEffect(() => {
    const on = () => setV({ w: window.innerWidth, h: window.innerHeight });
    window.addEventListener('resize', on);
    return () => window.removeEventListener('resize', on);
  }, []);
  return v;
}

function Stat({ icon, value }: { icon: string; value: number }) {
  const v = Math.max(0, Math.min(100, Math.round(value)));
  return (
    <div className="stat">
      <span className="c"><i style={{ height: `${100 - v}%` }} /><Icon name={icon} size={18} /></span>
      <span className="num">{v} %</span>
    </div>
  );
}

function Vehicle({ h }: { h: HudData }) {
  const v = h.vehicle!;
  const ticks = 14;
  const on = Math.round(Math.min(1, v.speed / 240) * ticks);
  return (
    <div className="hud-veh">
      {h.station && (
        <div className="panel hud-station">
          <span className="badge sm"><Icon name="fuel" size={16} /></span>
          <div style={{ display: 'flex', flexDirection: 'column' }}><b style={{ fontSize: 15 }}>{h.station.name}</b><span className="sub">{h.station.sub}</span></div>
          {h.station.price != null && <b className="num" style={{ marginLeft: 'auto', fontSize: 20, fontWeight: 900 }}>{h.station.price.toLocaleString('de-DE', { minimumFractionDigits: 2 })} <span style={{ fontSize: 12, color: 'var(--muted)' }}>$/L</span></b>}
        </div>
      )}
      <span className="speed"><b className="num">{Math.round(v.speed)}</b><span>km/h</span></span>
      <span className="ticks">{Array.from({ length: ticks }, (_, i) => <i key={i} className={i < on ? 'on' : ''} />)}</span>
      <span className="meta">
        <Icon name="fuel" size={18} /> <span className="num">{Math.round(v.fuel)} L</span>
        <span className="meter"><i style={{ width: `${Math.max(0, Math.min(100, (v.fuel / Math.max(1, v.tank)) * 100))}%` }} /></span>
        <span className="dot"><Icon name="engine" size={18} /><i style={{ background: v.engine ? 'var(--ok)' : 'var(--danger)' }} /></span>
        <span className="dot"><Icon name="lock" size={18} /><i style={{ background: v.locked ? 'var(--danger)' : 'var(--ok)' }} /></span>
      </span>
    </div>
  );
}

export function Hud() {
  const { state } = useStore();
  const h = state.hud;
  const now = useClock();
  const vp = useViewport();
  const fullView = state.view && ['inventory', 'characters', 'bank', 'shop', 'garage'].includes(state.view.name);
  if (!h.visible || fullView) return null;
  const time = now.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  const date = now.toLocaleDateString('de-DE');
  // Infozeilen rechts neben der Minimap des Spiels (Bereich meldet Lua)
  const m = h.minimap;
  const infoLeft = m ? m.x * vp.w + m.w * vp.w + 30 : 330;
  const infoBottom = m ? vp.h - (m.y * vp.h + m.h * vp.h) + 4 : 40;

  return (
    <>
      <div className="hud-top">
        <div style={{ display: 'flex', alignItems: 'center', gap: 14 }}>
          <span style={{ color: h.radioOn ? 'var(--accent)' : 'var(--muted)' }}><Icon name="radio" size={18} /></span>
          <div className="hud-logo">
            <img src="assets/logo.png" alt="TacoV" width={150} style={{ display: 'block', filter: 'drop-shadow(0 4px 12px rgba(0,0,0,0.6))' }} />
            <span className="ts" style={{ fontSize: 12, fontWeight: 900, letterSpacing: '0.26em' }}>ROLEPLAY</span>
          </div>
        </div>
        <div className="hud-money">
          <span className="num">{money(h.cash)}</span><span className="badge coin"><Icon name="cash" size={14} /></span>
          <span className="num">{money(h.bank)}</span><span className="badge coin"><Icon name="card" size={14} /></span>
          {h.black > 0 && <>
            <span className="num" style={{ color: 'var(--black-money)' }}>{money(h.black)}</span>
            <span className="coin" style={{ background: 'linear-gradient(135deg,#C9A0FF,#7A3FE0)', color: '#1A0A33', fontSize: 12, fontWeight: 900 }}>S</span>
          </>}
        </div>
      </div>

      <div className="hud-stats">
        <Stat icon="food" value={h.hunger} />
        <Stat icon="drop" value={h.thirst} />
      </div>

      {h.radio && h.radio.length > 0 && (
        <div className="hud-radio">
          <span className="sub" style={{ letterSpacing: '0.14em', textTransform: 'uppercase', fontSize: 11 }}>Funk · Frequenz {h.radioFrequency ?? '–'}</span>
          {h.radio.map((r) => <span key={r.id}><span className="id">[{r.id}]</span> {r.name}<i className={r.talking ? 'on' : ''} /></span>)}
        </div>
      )}

      <div className="hud-info" style={{ left: infoLeft, bottom: infoBottom }}>
        <div><span className="b"><Icon name="user" size={16} /></span><span className="num">{h.serverId}</span></div>
        <div><span className="b"><Icon name="fitness" size={16} /></span><span className="num">{h.fitness.toLocaleString('de-DE', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} %</span></div>
        <div><span className="b"><Icon name="briefcase" size={16} /></span><span>{h.faction || 'Zivilist'}{h.factionRank && <small>{h.factionRank}</small>}</span></div>
        <div><span className="b"><Icon name="clock" size={16} /></span><span className="num">{date}<small>{time} Uhr</small></span></div>
        {h.aduty && <div className="aduty"><span className="b"><Icon name="shield" size={16} /></span><span>Admin-Dienst<small>{h.aduty}</small></span></div>}
      </div>

      {h.vehicle && <Vehicle h={h} />}
    </>
  );
}
