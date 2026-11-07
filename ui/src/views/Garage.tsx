// Garage und Verwahrhof: Suche, Filter, Fahrzeugkarten.
import { useMemo, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { Panel } from '../components/Panel';

export type GarageVehicle = { id: number; label: string; plate: string; classLabel: string; moto: boolean; fuel: number; tank: number; km: number; own: boolean; fee: number; state: 'here' | 'elsewhere' | 'out' | 'impound'; garage?: string };
export type GarageData = { name: string; label: string; kind: 'garage' | 'impound'; items: GarageVehicle[] };
const money = (n: number) => `${Math.round(n).toLocaleString('de-DE')} $`;
const stateLabel: Record<GarageVehicle['state'], string> = { here: 'Hier', elsewhere: 'Andere Garage', out: 'Unterwegs', impound: 'Verwahrt' };

export function Garage({ data }: { data: GarageData }) {
  const [q, setQ] = useState('');
  const [filter, setFilter] = useState<'all' | GarageVehicle['state']>('all');
  const impound = data.kind === 'impound';
  const list = useMemo(() => data.items.filter((v) => (filter === 'all' || v.state === filter) && (!q || v.label.toLowerCase().includes(q.toLowerCase()) || v.plate.toLowerCase().includes(q.toLowerCase()))), [data.items, q, filter]);
  const close = () => nui('action', { view: 'garage', action: 'close', data: {} });
  const take = (v: GarageVehicle) => nui('action', { view: 'garage', action: 'take', data: { id: v.id } });
  const canTake = (v: GarageVehicle) => (impound ? v.state === 'impound' : v.state === 'here');
  return (
    <div className="center garage">
      <Panel icon={impound ? 'lock' : 'key'} title={impound ? 'Verwahrhof' : 'Garage'} sub={data.label} onClose={close}
        foot={<span className="muted" style={{ fontSize: '0.75rem' }}>{impound ? 'Nicht geparkte Fahrzeuge landen nach 24 Stunden hier.' : 'Einparken: mit dem Fahrzeug zur Garage fahren und E drücken. Gebühr je angefangenen Tag ab 24 Stunden Standzeit.'}</span>}>
        <div className="row-flex">
          <input className="input grow" placeholder="Name oder Kennzeichen…" value={q} onChange={(e) => setQ(e.target.value)} autoFocus />
          <select className="input" style={{ width: '11rem' }} value={filter} onChange={(e) => setFilter(e.target.value as typeof filter)}>
            <option value="all">Alle</option>{!impound && <option value="here">Hier</option>}{!impound && <option value="elsewhere">Andere Garage</option>}<option value="out">Unterwegs</option><option value="impound">Verwahrt</option>
          </select>
        </div>
        <div className="grid">
          {list.length === 0 && <span className="muted">Keine Fahrzeuge.</span>}
          {list.map((v) => (
            <div key={v.id} className={'card veh' + (canTake(v) ? '' : ' dim')}>
              <div className="row-flex"><Icon name={v.moto ? 'speed' : 'car'} size={16} /><b className="ellipsis grow">{v.label}</b><span className={'tag' + (canTake(v) ? ' ok' : '')}>{stateLabel[v.state]}</span></div>
              <span className="plate num">{v.plate}</span>
              <span className="muted" style={{ fontSize: '0.6875rem' }}>{v.classLabel}{v.own ? '' : ' · Schlüssel'}{v.state === 'elsewhere' && v.garage ? ` · ${v.garage}` : ''}</span>
              <div className="stats"><span>Tank {Math.round(v.fuel)}/{v.tank} L</span><span className="num">{Math.round(v.km).toLocaleString('de-DE')} km</span></div>
              <span className="meter"><i style={{ width: `${Math.min(100, (v.fuel / v.tank) * 100)}%` }} /></span>
              <button className={'btn sm' + (canTake(v) ? ' primary' : '')} disabled={!canTake(v)} onClick={() => take(v)}>{canTake(v) ? `${impound ? 'Auslösen' : 'Ausparken'}${v.fee > 0 ? ` · ${money(v.fee)}` : ''}` : stateLabel[v.state]}</button>
            </div>
          ))}
        </div>
      </Panel>
    </div>
  );
}
