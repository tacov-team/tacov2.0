// Kaufhaus (Punkt 4.2): Klassen als Reiter, Fahrzeugkarten wie in der Garage, rechts Details mit Vorschau im Showroom und Kauf.
import { useEffect, useMemo, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { Panel } from '../components/Panel';
import { money } from './Hud';

export type DealerVehicle = { model: string; label: string; price: number };
export type DealerClass = { id: string; label: string; level: number; license: string; trunk: number; tank: number; locked: boolean; vehicles: DealerVehicle[] };
export type DealerData = { name: string; label: string; dealer: string; title: string; level: number; fee: number; cash: number; bank: number; classes: DealerClass[] };

export function Dealer({ data }: { data: DealerData }) {
  const [cls, setCls] = useState(data.classes[0]?.id ?? '');
  const [q, setQ] = useState('');
  const current = useMemo(() => data.classes.find((c) => c.id === cls) ?? data.classes[0], [data.classes, cls]);
  const [model, setModel] = useState(current?.vehicles[0]?.model ?? '');
  const sel = current?.vehicles.find((v) => v.model === model) ?? current?.vehicles[0];
  useEffect(() => { if (current && !current.vehicles.some((v) => v.model === model)) setModel(current.vehicles[0]?.model ?? ''); }, [current]);
  useEffect(() => { if (sel) nui('action', { view: 'dealer', action: 'preview', data: { model: sel.model } }); }, [sel?.model]);

  const list = (current?.vehicles ?? []).filter((v) => !q || v.label.toLowerCase().includes(q.toLowerCase()));
  const total = sel ? sel.price + data.fee : 0;
  const close = () => nui('action', { view: 'dealer', action: 'close', data: {} });
  const buy = (method: 'cash' | 'card') => { if (sel) nui('action', { view: 'dealer', action: 'buy', data: { model: sel.model, method } }); };

  return (
    <div className="dealer">
      <Panel icon="car" title={data.title} sub={data.label} onClose={close}
        foot={<span className="muted" style={{ fontSize: '0.75rem' }}>Das gewählte Modell steht im Showroom. Nach dem Kauf findest du das Fahrzeug an der Ausfahrt – Zulassung ist im Preis enthalten.</span>}>
        <div className="cols">
          <div className="catalog">
            <div className="row-flex">
              <div className="tabs grow">{data.classes.map((c) => <button key={c.id} className={c.id === current?.id ? 'on' : ''} onClick={() => setCls(c.id)}>{c.label}</button>)}</div>
              <input className="input" style={{ width: '12rem' }} placeholder="Suchen…" value={q} onChange={(e) => setQ(e.target.value)} />
            </div>
            <div className="grid">
              {list.map((v) => (
                <div key={v.model} className={'card veh' + (sel?.model === v.model ? ' on' : '')} onClick={() => setModel(v.model)}>
                  <div className="row-flex"><Icon name={current?.id === 'moto' ? 'speed' : 'car'} size={16} /><b className="ellipsis grow">{v.label}</b></div>
                  <span className="muted" style={{ fontSize: '0.6875rem' }}>{current?.label} · Tank {current?.tank} L · Kofferraum {current?.trunk} kg</span>
                  <span className="price num">{money(v.price)}</span>
                </div>
              ))}
            </div>
          </div>
          <aside className="detail">
            {sel && current ? (
              <>
                <div className="hero"><Icon name={current.id === 'moto' ? 'speed' : 'car'} size={40} stroke={1.4} /></div>
                <b style={{ fontSize: '1.25rem' }}>{sel.label}</b>
                <span className="muted" style={{ fontSize: '0.75rem' }}>{current.label} · Führerschein {current.license}</span>
                <div className="specs">
                  <span><Icon name="fuel" size={13} /> {current.tank} L Tank</span>
                  <span><Icon name="trunk" size={13} /> {current.trunk} kg Kofferraum</span>
                </div>
                <div className="total">
                  <span className="lbl">Preis inkl. Zulassung {money(data.fee)}</span>
                  <span className="money-big num">{money(total)}</span>
                  <span style={{ fontSize: '0.75rem', opacity: 0.9 }}>Bargeld {money(data.cash)} · Konto {money(data.bank)}</span>
                </div>
                <div className="row-flex">
                  <button className="btn primary grow" disabled={data.cash < total} onClick={() => buy('cash')}><Icon name="cash" size={14} /> Bar</button>
                  <button className="btn grow" disabled={data.bank < total} onClick={() => buy('card')}><Icon name="card" size={14} /> Karte</button>
                </div>
              </>
            ) : <span className="muted">Kein Fahrzeug gewählt.</span>}
          </aside>
        </div>
      </Panel>
    </div>
  );
}
