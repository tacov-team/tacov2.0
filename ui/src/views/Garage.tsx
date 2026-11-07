// Garage und Verwahrhof nach Referenzbild: Kopfzeile mit Schriftzug, Suche, Filter, Raster aus Fahrzeugkarten (leere Plätze gestrichelt).
import { useMemo, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { Panel, PanelHead } from '../components/Panel';

export type GarageVehicle = {
  id: number; label: string; plate: string; classLabel: string; moto: boolean;
  fuel: number; tank: number; km: number; own: boolean; fee: number;
  state: 'here' | 'elsewhere' | 'out' | 'impound'; garage?: string;
};
export type GarageData = { name: string; label: string; kind: 'garage' | 'impound'; items: GarageVehicle[] };

const MIN_CELLS = 15;
const money = (n: number) => `${Math.round(n).toLocaleString('de-DE')} $`;
const stateLabel: Record<GarageVehicle['state'], string> = { here: 'Hier', elsewhere: 'Andere Garage', out: 'Unterwegs', impound: 'Verwahrt' };

export function Garage({ data }: { data: GarageData }) {
  const [q, setQ] = useState('');
  const [filter, setFilter] = useState<'all' | GarageVehicle['state']>('all');
  const impound = data.kind === 'impound';
  const list = useMemo(() => data.items.filter((v) =>
    (filter === 'all' || v.state === filter) &&
    (!q || v.label.toLowerCase().includes(q.toLowerCase()) || v.plate.toLowerCase().includes(q.toLowerCase()))), [data.items, q, filter]);
  const cells = Math.max(MIN_CELLS, Math.ceil(list.length / 5) * 5);
  const close = () => nui('action', { view: 'garage', action: 'close', data: {} });
  const take = (v: GarageVehicle) => nui('action', { view: 'garage', action: 'take', data: { id: v.id } });
  const canTake = (v: GarageVehicle) => (impound ? v.state === 'impound' : v.state === 'here');

  return (
    <div className="center-wrap">
      <Panel soft style={{ width: 1080 }}>
        <PanelHead icon={impound ? 'lock' : 'key'} title={impound ? 'Verwahrhof' : 'Garage'} script={impound ? 'Impound' : 'Parking'}
          info={impound ? `${data.label} · Deine verwahrten Fahrzeuge` : `${data.label} · Deine Fahrzeuge`} onClose={close} />
        <div className="pbody" style={{ gap: 14 }}>
          <div style={{ display: 'flex', gap: 10 }}>
            <div className="search" style={{ flex: 1 }}><Icon name="search" size={15} /><input placeholder="Suche nach Name oder Kennzeichen…" value={q} onChange={(e) => setQ(e.target.value)} autoFocus /></div>
            <select className="input" style={{ width: 150, height: 42 }} value={filter} onChange={(e) => setFilter(e.target.value as typeof filter)}>
              <option value="all">Alle</option>
              {!impound && <option value="here">Hier</option>}
              {!impound && <option value="elsewhere">Andere Garage</option>}
              <option value="out">Unterwegs</option>
              <option value="impound">Verwahrt</option>
            </select>
          </div>
          <div className="garage-grid">
            {Array.from({ length: cells }, (_, i) => list[i]).map((v, i) => v ? (
              <div key={v.id} className={'card garage-card' + (canTake(v) ? '' : ' dim')}>
                <div style={{ display: 'flex', justifyContent: 'space-between', alignItems: 'flex-start' }}>
                  <span className="badge sm"><Icon name={v.moto ? 'speed' : 'car'} size={14} /></span>
                  <span className={'tag' + (canTake(v) ? ' ok' : ' dark')}>{stateLabel[v.state]}</span>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
                  <b style={{ fontSize: 15, whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{v.label}</b>
                  <span className="num" style={{ fontSize: 12, fontWeight: 800, letterSpacing: '0.08em' }}>{v.plate}</span>
                  <span className="sub">{v.classLabel}{v.own ? '' : ' · Schlüssel'}{v.state === 'elsewhere' && v.garage ? ` · ${v.garage}` : ''}</span>
                </div>
                <div style={{ display: 'flex', flexDirection: 'column', gap: 4 }}>
                  <div style={{ display: 'flex', justifyContent: 'space-between', fontSize: 11, color: 'var(--muted)', fontWeight: 700 }}>
                    <span><Icon name="fuel" size={11} /> {Math.round(v.fuel)}/{v.tank} L</span><span className="num">{Math.round(v.km).toLocaleString('de-DE')} km</span>
                  </div>
                  <span className="meter"><i style={{ width: `${Math.min(100, (v.fuel / v.tank) * 100)}%` }} /></span>
                </div>
                <button className={'btn sm' + (canTake(v) ? ' primary' : '')} disabled={!canTake(v)} onClick={() => take(v)}>
                  {canTake(v) ? (v.fee > 0 ? `${impound ? 'Auslösen' : 'Ausparken'} · ${money(v.fee)}` : impound ? 'Auslösen' : 'Ausparken') : stateLabel[v.state]}
                </button>
              </div>
            ) : <div key={'e' + i} className="slot garage-card" />)}
          </div>
          <span className="sub" style={{ textAlign: 'center' }}>
            {impound ? 'Fahrzeuge, die 24 Stunden nicht geparkt wurden, landen hier. Nach einem Neustart ist die Auslösung kostenlos, wenn du kürzlich gefahren bist.'
              : 'Öffentliche Garage: Gebühr je angefangenen Tag ab 24 Stunden Standzeit. Einparken: mit dem Fahrzeug zur Garage fahren und E drücken.'}
          </span>
        </div>
      </Panel>
    </div>
  );
}
