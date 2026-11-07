// HUD: Geld oben rechts, Status-Leiste über der Minimap, Funkliste rechts, Tacho unten rechts, Admin-Dienst oben mittig.
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

function Stat({ kind, icon, value }: { kind: string; icon: string; value: number }) {
  const v = Math.max(0, Math.min(100, Math.round(value)));
  return (
    <div className={'st ' + kind + (v <= 20 ? ' low' : '')} title={`${v} %`}>
      <span className="ic"><Icon name={icon} size={15} /></span>
      <span className="bar"><i style={{ width: `${v}%` }} /></span>
    </div>
  );
}

function Vehicle({ h }: { h: HudData }) {
  const v = h.vehicle!;
  const pct = Math.max(0, Math.min(100, (v.fuel / Math.max(1, v.tank)) * 100));
  return (
    <div className="hud-veh">
      {h.station && (
        <div className="hud-station">
          <span className="ic"><Icon name="fuel" size={15} /></span>
          <div className="col" style={{ gap: 0 }}><b>{h.station.name}</b><span className="muted" style={{ fontSize: '0.6875rem' }}>{h.station.sub}</span></div>
          {h.station.price != null && <b className="price num">{h.station.price.toLocaleString('de-DE', { minimumFractionDigits: 2 })} $/L</b>}
        </div>
      )}
      <div className="speedo"><b className="num">{Math.round(v.speed)}</b><span>km/h</span></div>
      <div className="bar"><i style={{ width: `${Math.min(100, (v.speed / 240) * 100)}%` }} /></div>
      <div className="meta">
        <span className="st"><Icon name="fuel" size={14} /><span className="fuel"><i style={{ width: `${pct}%` }} /></span><span className="num">{Math.round(v.fuel)} L</span></span>
        <span className="st"><Icon name="engine" size={14} /><i className="led" style={{ background: v.engine ? 'var(--ok)' : 'var(--danger)' }} /></span>
        <span className="st"><Icon name="lock" size={14} /><i className="led" style={{ background: v.locked ? 'var(--danger)' : 'var(--ok)' }} /></span>
      </div>
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

  // Status-Leiste direkt über der Minimap des Spiels (Lage kommt vom Client), sonst unten links
  const m = h.minimap;
  const statusStyle = m
    ? { left: m.x * vp.w, bottom: vp.h - m.y * vp.h + 8 }
    : { left: '1.5rem', bottom: '15%' };
  const time = now.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  const date = now.toLocaleDateString('de-DE', { day: '2-digit', month: '2-digit', year: 'numeric' });

  return (
    <div className="hud">
      {h.aduty && <div className="hud-aduty"><Icon name="shield" size={14} /> Admin-Dienst · {h.aduty}</div>}

      <div className="hud-money">
        <div className="line"><span className="num">{money(h.cash)}</span><span className="ic"><Icon name="cash" size={14} /></span></div>
        <div className="line bank"><span className="num">{money(h.bank)}</span><span className="ic"><Icon name="card" size={14} /></span></div>
        {h.black > 0 && <div className="line black"><span className="num">{money(h.black)}</span><span className="ic"><Icon name="briefcase" size={14} /></span></div>}
        <div className="meta">
          <span className="num">ID {h.serverId}</span><span>·</span><span>{h.faction || 'Zivilist'}{h.factionRank ? ` · ${h.factionRank}` : ''}</span><span>·</span><span className="num">{date} {time}</span>
        </div>
      </div>

      <div className="hud-status" style={statusStyle}>
        <Stat kind="health" icon="heart" value={h.health} />
        <Stat kind="armor" icon="shield" value={h.armor} />
        <Stat kind="hunger" icon="food" value={h.hunger} />
        <Stat kind="thirst" icon="drop" value={h.thirst} />
      </div>

      {h.radioOn && h.radio && h.radio.length > 0 && (
        <div className="hud-radio">
          <span className="title">Funk · {h.radioFrequency ?? '–'}</span>
          {h.radio.map((r) => <span key={r.id} className="who"><span className="num muted">[{r.id}]</span> {r.name}<i className={r.talking ? 'on' : ''} /></span>)}
        </div>
      )}

      {h.vehicle && <Vehicle h={h} />}
    </div>
  );
}
