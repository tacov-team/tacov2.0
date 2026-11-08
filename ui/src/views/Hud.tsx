// HUD nach GLRP-Vorbild (Punkt 3.2, abgenommen): Logo und Geld oben rechts, Hunger/Durst-Kacheln darunter, Funkliste rechts,
// Infozeilen rechts neben der Spiel-Minimap, Tacho unten rechts mit Tankstellenkarte. Größen in rem (V6-Maßstab).
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
    <div className="stat shadow">
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
    <div className="hud-veh shadow">
      {h.station && (
        <div className="hud-station">
          <span className="ic"><Icon name="fuel" size={16} /></span>
          <div className="col" style={{ gap: 0 }}><b style={{ fontSize: '0.9375rem' }}>{h.station.name}</b><span className="muted" style={{ fontSize: '0.75rem' }}>{h.station.sub}</span></div>
          {h.station.price != null && <b className="num right" style={{ fontSize: '1.25rem', fontWeight: 900 }}>{h.station.price.toLocaleString('de-DE', { minimumFractionDigits: 2 })} <span style={{ fontSize: '0.75rem', color: 'var(--muted)' }}>$/L</span></b>}
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
  const fullView = state.view && ['inventory', 'characters', 'bank', 'shop', 'garage', 'dealer', 'editor'].includes(state.view.name);
  if (!h.visible || fullView) return null;
  const time = now.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  const date = now.toLocaleDateString('de-DE');
  // Infozeilen rechts neben der Minimap des Spiels (Lage meldet Lua), sonst unten links
  const m = h.minimap;
  const rem = vp.h / 67.5;
  const infoLeft = m ? m.x * vp.w + m.w * vp.w + 1.875 * rem : 20.5 * rem;
  const infoBottom = m ? vp.h - (m.y * vp.h + m.h * vp.h) + 0.25 * rem : 2.5 * rem;

  return (
    <div className="hud">
      <div className="hud-top shadow">
        <div className="hud-logo"><img src="assets/logo.png" alt="TacoV" /><span className="ts">ROLEPLAY</span></div>
        <div className="hud-money">
          <span className="num">{money(h.cash)}</span><span className="coin"><Icon name="cash" size={14} /></span>
          <span className="num">{money(h.bank)}</span><span className="coin"><Icon name="card" size={14} /></span>
          {h.black > 0 && <><span className="num" style={{ color: 'var(--black-money)' }}>{money(h.black)}</span><span className="coin black">S</span></>}
        </div>
        <div className="hud-stats">
          <div className={'stat voice ' + (h.megaphone ? 'shout' : (h.voice ?? 'normal'))} title={h.megaphone ? 'Megafon' : 'Sprechweite'}><span className="c"><Icon name={h.megaphone ? 'radio' : 'mic'} size={15} /></span><span className="num">{h.megaphone ? 'MEGA' : `${h.voiceMeters ?? 10} m`}</span></div>
          <Stat icon="food" value={h.hunger} />
          <Stat icon="drop" value={h.thirst} />
          {h.radioOn && <div className="stat"><span className="c" title="Funk an"><Icon name="radio" size={16} /></span></div>}
        </div>
        {h.radio && h.radio.length > 0 && (
          <div className="hud-radio">
            <span className="title">Funk · Frequenz {h.radioFrequency ?? '–'}</span>
            {h.radio.map((r) => <span key={r.id}><span className="id num">[{r.id}]</span> {r.name}<i className={r.talking ? 'on' : ''} /></span>)}
          </div>
        )}
      </div>

      <div className="hud-info shadow" style={{ left: infoLeft, bottom: infoBottom }}>
        <div><span className="b"><Icon name="user" size={16} /></span><span className="num">{h.serverId}</span></div>
        <div><span className="b"><Icon name="fitness" size={16} /></span><span className="num">{h.fitness.toLocaleString('de-DE', { minimumFractionDigits: 1, maximumFractionDigits: 1 })} %</span></div>
        <div><span className="b"><Icon name="briefcase" size={16} /></span><span>{h.faction || 'Zivilist'}{h.factionRank && <small>{h.factionRank}</small>}</span></div>
        <div><span className="b"><Icon name="clock" size={16} /></span><span className="num">{date}<small>{time} Uhr</small></span></div>
        {h.aduty && <div className="aduty"><span className="b"><Icon name="shield" size={16} /></span><span>Admin-Dienst<small>{h.aduty}</small></span></div>}
        {h.injury && <div className="aduty notice"><span className="b"><Icon name="heart" size={16} /></span><span>Verletzt<small>{h.injury === 'medium' ? 'mittel – Erste Hilfe oder LSMD' : 'leicht'}</small></span></div>}
        {typeof h.downed === 'number' && <div className="aduty"><span className="b"><Icon name="heart" size={16} /></span><span>Bewusstlos<small>Koma in {Math.floor(h.downed / 60)}:{String(h.downed % 60).padStart(2, '0')} · Hilfe rufen</small></span></div>}
        {h.notice && <div className="aduty notice"><span className="b"><Icon name="id" size={16} /></span><span>Hinweis<small>{h.notice}</small></span></div>}
      </div>

      {h.vehicle && <Vehicle h={h} />}
    </div>
  );
}
