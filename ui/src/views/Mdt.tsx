// MDT der Polizei (Punkt 9.4): Personen (Suche, Akte, Einträge, Haftbefehl), Fahrzeuge (Kennzeichen), Fahndung, Berichte.
import { useEffect, useState } from 'react';
import { nui, useNuiEvent } from '../nui';
import { Icon } from '../components/Icon';
import { Panel } from '../components/Panel';
import { money } from './Hud';

type Warrant = { id: number; kind: 'person' | 'vehicle'; characterId?: number; plate?: string; reason: string; officer: string; at: string; name?: string };
type Report = { id: number; officer: string; title: string; text: string; at: string };
type PersonHit = { id: number; name: string; birth: string; phone?: string };
type PersonFile = {
  id: number; name: string; birth: string; phone?: string; inJail?: boolean;
  licenses: { type: string; points: number; revoked: boolean }[];
  vehicles: { plate: string; model: string; state: string; registered: boolean }[];
  records: { officer: string; offense: string; fine: number; jail: number; at: string }[];
  warrants: Warrant[];
};
type VehicleInfo = { plate: string; unknown?: boolean; model?: string; state?: string; registered?: boolean; owner?: string; ownerId?: number; wanted?: string };
export type MdtData = { officer: string; rank: string; rankNo: number; warrants: Warrant[]; reports: Report[]; warrantMinRank: number; plate?: string };
type Tab = 'persons' | 'vehicles' | 'warrants' | 'reports';

const act = (action: string, data: unknown = {}) => nui('action', { view: 'mdt', action, data });
const when = (at: string) => {
  const d = new Date(at.replace(' ', 'T'));
  return Number.isNaN(d.getTime()) ? at : d.toLocaleString('de-DE', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
};

export function Mdt({ data }: { data: MdtData }) {
  const [tab, setTab] = useState<Tab>(data.plate ? 'vehicles' : 'persons');
  const [q, setQ] = useState('');
  const [hits, setHits] = useState<PersonHit[] | null>(null);
  const [file, setFile] = useState<PersonFile | null>(null);
  const [plate, setPlate] = useState(data.plate ?? '');
  const [veh, setVeh] = useState<VehicleInfo | null>(null);
  const [warrants, setWarrants] = useState<Warrant[]>(data.warrants);
  const [reports, setReports] = useState<Report[]>(data.reports);
  const [text, setText] = useState('');
  const [title, setTitle] = useState('');
  const [openReport, setOpenReport] = useState<number | null>(null);
  const canWarrant = data.rankNo >= data.warrantMinRank;

  useNuiEvent<{ kind: string; data: unknown }>('mdt', (m) => {
    if (m.kind === 'persons') { setHits(m.data as PersonHit[]); setFile(null); }
    if (m.kind === 'file') { setFile((m.data as PersonFile) || null); setTab('persons'); setText(''); }
    if (m.kind === 'vehicle') setVeh(m.data as VehicleInfo);
    if (m.kind === 'warrants') setWarrants(m.data as Warrant[]);
    if (m.kind === 'reports') { setReports(m.data as Report[]); setTitle(''); setText(''); }
  });
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => { if (e.key === 'Escape') act('close'); };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const labels: Record<Tab, string> = { persons: 'Personen', vehicles: 'Fahrzeuge', warrants: `Fahndung (${warrants.length})`, reports: 'Berichte' };

  return (
    <div className="center mdt">
      <Panel icon="shield" title="MDT · Los Santos Police Department" sub={`${data.officer} · ${data.rank} · jede Abfrage wird protokolliert`} onClose={() => act('close')}>
        <div className="tabs">{(Object.keys(labels) as Tab[]).map((t) => <button key={t} className={tab === t ? 'on' : ''} onClick={() => setTab(t)}>{labels[t]}</button>)}</div>

        {tab === 'persons' && !file && (<>
          <div className="mdt-search">
            <input className="input" autoFocus placeholder="Name oder Handynummer" value={q} onChange={(e) => setQ(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter' && q.trim().length >= 2) act('person', { value: q.trim() }); }} />
            <button className="btn primary" disabled={q.trim().length < 2} onClick={() => act('person', { value: q.trim() })}><Icon name="search" size={15} /> Suchen</button>
          </div>
          <div className="mdt-list">
            {hits === null && <span className="muted">Mindestens zwei Zeichen eingeben.</span>}
            {hits && hits.length === 0 && <span className="muted">Keine Person gefunden.</span>}
            {hits?.map((h) => (
              <button key={h.id} className="mdt-row" onClick={() => act('file', { value: h.id })}>
                <Icon name="user" size={16} /><span className="grow"><b>{h.name}</b><small>geboren {h.birth}{h.phone ? ` · Tel. ${h.phone}` : ''}</small></span><Icon name="next" size={14} />
              </button>
            ))}
          </div>
        </>)}

        {tab === 'persons' && file && (
          <div className="mdt-file">
            <div className="col">
              <button className="btn sm" style={{ alignSelf: 'flex-start' }} onClick={() => setFile(null)}><Icon name="back" size={14} /> Zurück zur Suche</button>
              <div className="mdt-card">
                <b style={{ fontSize: '1.25rem' }}>{file.name}</b>
                <span className="muted">geboren {file.birth}{file.phone ? ` · Tel. ${file.phone}` : ''}</span>
                {file.inJail && <span className="tag bad">in Haft</span>}
                {file.warrants.map((w) => <span key={w.id} className="tag bad">Haftbefehl: {w.reason}</span>)}
              </div>
              <div className="mdt-card">
                <b>Führerscheine</b>
                {file.licenses.length === 0 && <span className="muted">keine</span>}
                {file.licenses.map((l) => <span key={l.type}>Klasse {l.type}{l.revoked ? ' · entzogen' : ''} · {l.points} Punkte</span>)}
              </div>
              <div className="mdt-card">
                <b>Fahrzeuge</b>
                {file.vehicles.length === 0 && <span className="muted">keine</span>}
                {file.vehicles.map((v) => <span key={v.plate} className="num">{v.plate} · {v.model}{v.registered ? '' : ' · nicht zugelassen'}{v.state === 'impound' ? ' · Verwahrhof' : ''}</span>)}
              </div>
            </div>
            <div className="col">
              <b style={{ fontSize: '0.8125rem' }}>Einträge</b>
              <div className="mdt-list tall">
                {file.records.length === 0 && <span className="muted">Keine Einträge.</span>}
                {file.records.map((r, i) => (
                  <div key={i} className="mdt-row static">
                    <Icon name="doc" size={15} />
                    <span className="grow"><b>{r.offense}</b><small>{r.officer} · {when(r.at)}{r.fine > 0 ? ` · ${money(r.fine)}` : ''}{r.jail > 0 ? ` · ${r.jail} min Haft` : ''}</small></span>
                  </div>
                ))}
              </div>
              <textarea className="input" rows={2} maxLength={200} placeholder="Delikt / Vermerk bzw. Grund für den Haftbefehl" value={text} onChange={(e) => setText(e.target.value)} />
              <div className="row-flex" style={{ gap: '0.5rem' }}>
                <button className="btn primary grow" disabled={!text.trim()} onClick={() => act('record', { characterId: file.id, offense: text.trim() })}>Eintrag anlegen</button>
                <button className="btn grow" disabled={!text.trim() || !canWarrant} title={canWarrant ? '' : 'Rang reicht nicht'} onClick={() => act('warrant', { kind: 'person', characterId: file.id, reason: text.trim() })}>Haftbefehl</button>
              </div>
            </div>
          </div>
        )}

        {tab === 'vehicles' && (<>
          <div className="mdt-search">
            <input className="input num" autoFocus placeholder="Kennzeichen" value={plate} maxLength={8} onChange={(e) => setPlate(e.target.value.toUpperCase())} onKeyDown={(e) => { if (e.key === 'Enter' && plate.trim().length >= 2) act('vehicle', { value: plate.trim() }); }} />
            <button className="btn primary" disabled={plate.trim().length < 2} onClick={() => act('vehicle', { value: plate.trim() })}><Icon name="search" size={15} /> Abfragen</button>
          </div>
          {veh && (
            <div className="mdt-card">
              <b className="num" style={{ fontSize: '1.25rem' }}>{veh.plate}</b>
              {veh.unknown ? <span className="muted">Kein zugelassenes Fahrzeug mit diesem Kennzeichen (Leih-, Job- oder Fraktionsfahrzeug).</span> : (<>
                <span>{veh.model} · Halter: {veh.ownerId ? <button className="mdt-link" onClick={() => act('file', { value: veh.ownerId })}>{veh.owner}</button> : veh.owner}</span>
                <span className={veh.registered ? 'muted' : 'bad'}>{veh.registered ? 'zugelassen' : 'nicht zugelassen'}{veh.state === 'impound' ? ' · im Verwahrhof' : ''}</span>
              </>)}
              {veh.wanted && <span className="tag bad">Fahndung: {veh.wanted}</span>}
              <div className="row-flex" style={{ gap: '0.5rem', marginTop: '0.25rem' }}>
                <input className="input grow" placeholder="Grund für die Fahndung" maxLength={200} value={text} onChange={(e) => setText(e.target.value)} />
                <button className="btn" disabled={!text.trim() || !canWarrant} onClick={() => { act('warrant', { kind: 'vehicle', plate: veh.plate, reason: text.trim() }); setText(''); }}>Fahndung setzen</button>
              </div>
            </div>
          )}
        </>)}

        {tab === 'warrants' && (
          <div className="mdt-list tall">
            {warrants.length === 0 && <span className="muted">Keine offenen Fahndungen.</span>}
            {warrants.map((w) => (
              <div key={w.id} className="mdt-row static">
                <Icon name={w.kind === 'person' ? 'user' : 'car'} size={16} />
                <span className="grow"><b>{w.kind === 'person' ? w.name ?? `#${w.characterId}` : w.plate}</b><small>{w.reason} · {w.officer} · {when(w.at)}</small></span>
                {w.kind === 'person' && w.characterId && <button className="btn sm" onClick={() => act('file', { value: w.characterId })}>Akte</button>}
                <button className="btn sm" disabled={!canWarrant} onClick={() => act('warrantClose', { value: w.id })}>Aufheben</button>
              </div>
            ))}
          </div>
        )}

        {tab === 'reports' && (
          <div className="mdt-file">
            <div className="col">
              <b style={{ fontSize: '0.8125rem' }}>Neuer Bericht</b>
              <input className="input" placeholder="Titel" maxLength={96} value={title} onChange={(e) => setTitle(e.target.value)} />
              <textarea className="input" rows={8} maxLength={2000} placeholder="Was ist passiert?" value={text} onChange={(e) => setText(e.target.value)} />
              <button className="btn primary" disabled={!title.trim() || !text.trim()} onClick={() => act('report', { title: title.trim(), text: text.trim() })}>Bericht speichern</button>
            </div>
            <div className="col">
              <b style={{ fontSize: '0.8125rem' }}>Letzte Berichte</b>
              <div className="mdt-list tall">
                {reports.length === 0 && <span className="muted">Noch keine Berichte.</span>}
                {reports.map((r) => (
                  <button key={r.id} className="mdt-row" onClick={() => setOpenReport(openReport === r.id ? null : r.id)}>
                    <Icon name="doc" size={15} />
                    <span className="grow"><b>{r.title}</b><small>{r.officer} · {when(r.at)}</small>{openReport === r.id && <span className="mdt-text">{r.text}</span>}</span>
                  </button>
                ))}
              </div>
            </div>
          </div>
        )}
      </Panel>
    </div>
  );
}
