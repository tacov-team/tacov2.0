// Handy (Phase 7, F1): Gerät unten rechts in iPhone-Optik (eigenes Farbsystem, Dynamic Island, Dock, Home-Indikator). Startseite mit App-Raster; jede App bekommt ihre Daten per
// NUI-Nachricht 'phone' ({ app, data }) und schickt Aktionen als nui('action', { view: 'phone', action: '<app>:<aktion>' }).
import { useEffect, useState } from 'react';
import { nui, useNuiEvent } from '../nui';
import { Icon } from '../components/Icon';
import { money } from './Hud';

export type PhoneApp = { id: string; label: string; icon: string; enabled: boolean; badge?: number };
export type PhoneData = { number: string; time?: string; apps: PhoneApp[]; open?: string; cursor?: boolean };
export type Contact = { id: number; name: string; number: string; favorite: boolean };
export type CallState = { with: string; name?: string; state: 'incoming' | 'outgoing' | 'active'; since?: number } | null;
export type Thread = { number: string; name?: string; last: string; at: string; unread: number };
export type Msg = { id: number; from: string; text: string; at: string; mine: boolean; location?: { x: number; y: number } };
export type PhoneVehicle = { id: number; label: string; plate: string; state: string; garage?: string; fuel: number; tank: number; km: number; shared: number };
export type BankData = { balance: number; rows: { at: string; amount: number; reason: string; note?: string; dir: 'in' | 'out' }[]; invoices: { id: number; from: string; amount: number; reason: string }[] };
export type RadioData = { hasRadio: boolean; channel: number | null; members: string[]; talking: string[] };
export type Settings = { ringtone: number; airplane: boolean; needsNumbers: boolean; hudScale: number };

const act = (action: string, data: Record<string, unknown> = {}) => nui('action', { view: 'phone', action, data });

const DEFAULT_SETTINGS: Settings = { ringtone: 1, airplane: false, needsNumbers: true, hudScale: 100 };
export function loadPhoneSettings(): Settings {
  try { return { ...DEFAULT_SETTINGS, ...JSON.parse(localStorage.getItem('tacov_phone') || '{}') }; } catch { return { ...DEFAULT_SETTINGS }; }
}
/** HUD-Größe und Bedürfnis-Zahlen wirken sofort auf das ganze UI (CSS-Variable + body-Attribut). */
export function applyPhoneSettings(s: Settings) {
  document.documentElement.style.setProperty('--hud-scale', String((s.hudScale || 100) / 100));
  document.body.dataset.needsNumbers = s.needsNumbers ? '1' : '0';
}

function Header({ title, onBack, right }: { title: string; onBack?: () => void; right?: React.ReactNode }) {
  return (
    <div className="ph-head">
      {onBack ? <button className="ph-back" onClick={onBack}><Icon name="back" size={18} /></button> : <span className="ph-right" />}
      <span className="ph-title">{title}</span>
      <span className="ph-right">{right}</span>
    </div>
  );
}

function Contacts({ onCall, onMessage }: { onCall: (n: string) => void; onMessage: (n: string, name?: string) => void }) {
  const [list, setList] = useState<Contact[]>([]);
  const [adding, setAdding] = useState(false);
  const [form, setForm] = useState({ name: '', number: '' });
  const [sel, setSel] = useState<Contact | null>(null);
  const [rename, setRename] = useState<string | null>(null);
  useNuiEvent<{ app: string; data: Contact[] }>('phone', (d) => { if (d.app === 'contacts') setList(d.data); });
  useEffect(() => { act('contacts:list'); }, []);
  const sorted = [...list].sort((a, b) => Number(b.favorite) - Number(a.favorite) || a.name.localeCompare(b.name));
  if (sel) {
    return (<>
      <Header title={sel.name} onBack={() => setSel(null)} right={<button className="ph-icon" onClick={() => { act('contacts:favorite', { id: sel.id, favorite: !sel.favorite }); setSel({ ...sel, favorite: !sel.favorite }); }}><Icon name="star" size={16} /></button>} />
      <div className="ph-body">
        <div className="ph-card ph-center"><div className="ph-avatar">{sel.name.slice(0, 1).toUpperCase()}</div><b>{sel.name}</b><span className="muted num">{sel.number}</span></div>
        <div className="ph-grid2">
          <button className="btn primary" onClick={() => onCall(sel.number)}><Icon name="phone" size={14} /> Anrufen</button>
          <button className="btn" onClick={() => onMessage(sel.number, sel.name)}><Icon name="doc" size={14} /> Nachricht</button>
          <button className="btn" onClick={() => setRename(rename === null ? sel.name : null)}>Umbenennen</button>
          <button className="btn danger" onClick={() => { act('contacts:delete', { id: sel.id }); setSel(null); }}>Löschen</button>
        </div>
        {rename !== null && (
          <div className="ph-card">
            <input className="input" value={rename} maxLength={32} onChange={(e) => setRename(e.target.value)} />
            <button className="btn primary" disabled={!rename.trim()} onClick={() => { act('contacts:rename', { id: sel.id, name: rename.trim() }); setSel({ ...sel, name: rename.trim() }); setRename(null); }}>Speichern</button>
          </div>
        )}
      </div>
    </>);
  }
  return (<>
    <Header title="Kontakte" right={<button className="ph-icon" onClick={() => setAdding((a) => !a)}><Icon name="plus" size={16} /></button>} />
    <div className="ph-body">
      {adding && (
        <div className="ph-card">
          <input className="input" placeholder="Name" value={form.name} onChange={(e) => setForm({ ...form, name: e.target.value })} />
          <input className="input num" placeholder="Nummer (4-stellig)" maxLength={4} value={form.number} onChange={(e) => setForm({ ...form, number: e.target.value.replace(/\D/g, '') })} />
          <button className="btn primary" disabled={!form.name || form.number.length !== 4} onClick={() => { act('contacts:add', form); setForm({ name: '', number: '' }); setAdding(false); }}>Speichern</button>
        </div>
      )}
      {sorted.length === 0 && !adding && <div className="ph-empty"><Icon name="group" size={28} /><span>Noch keine Kontakte. Nummern tauschst du über das X-Rad mit deinem Gegenüber.</span></div>}
      {sorted.map((c) => (
        <button key={c.id} className="ph-row" onClick={() => setSel(c)}>
          <span className="ph-avatar sm">{c.name.slice(0, 1).toUpperCase()}</span>
          <span className="grow"><b>{c.name}</b><small className="num">{c.number}</small></span>
          {c.favorite && <Icon name="star" size={14} />}
        </button>
      ))}
    </div>
  </>);
}

function Dialer({ onCall }: { onCall: (n: string) => void }) {
  const [n, setN] = useState('');
  const keys: [string, string][] = [['1', ''], ['2', 'ABC'], ['3', 'DEF'], ['4', 'GHI'], ['5', 'JKL'], ['6', 'MNO'], ['7', 'PQRS'], ['8', 'TUV'], ['9', 'WXYZ'], ['', ''], ['0', '+'], ['⌫', '']];
  return (<>
    <Header title="Telefon" />
    <div className="ph-body" style={{ justifyContent: 'flex-end', gap: '1rem' }}>
      <div className="ph-dial num">{n || <span className="muted" style={{ fontSize: '1rem', letterSpacing: 0 }}>Nummer eingeben</span>}</div>
      <div className="ph-keys">
        {keys.map(([k, sub], i) => <button key={i} className={'ph-key' + (k === '' ? ' blank' : '')} disabled={k === ''} onClick={() => setN((v) => (k === '⌫' ? v.slice(0, -1) : (v + k).slice(0, 4)))}>{k}{sub && <small>{sub}</small>}</button>)}
      </div>
      <button className="ph-callbtn" disabled={n.length !== 4} onClick={() => onCall(n)} title="Anrufen"><Icon name="phone" size={26} /></button>
    </div>
  </>);
}

function Messages({ initial }: { initial?: { number: string; name?: string } }) {
  const [threads, setThreads] = useState<Thread[]>([]);
  const [open, setOpen] = useState<{ number: string; name?: string } | null>(initial ?? null);
  const [msgs, setMsgs] = useState<Msg[]>([]);
  const [text, setText] = useState('');
  const [newNo, setNewNo] = useState<string | null>(null);
  useNuiEvent<{ app: string; data: unknown; thread?: string }>('phone', (d) => {
    if (d.app === 'messages') setThreads(d.data as Thread[]);
    if (d.app === 'thread' && open && d.thread === open.number) setMsgs(d.data as Msg[]);
    if (d.app === 'sms') { // neue Nachricht: Liste bzw. offene Unterhaltung nachladen
      const from = (d.data as { from: string }).from;
      if (open && open.number === from) act('messages:thread', { number: from }); else act('messages:list');
    }
  });
  useEffect(() => { act('messages:list'); }, []);
  useEffect(() => { if (open) act('messages:thread', { number: open.number }); }, [open?.number]);
  if (open) {
    return (<>
      <Header title={open.name ?? open.number} onBack={() => { setOpen(null); act('messages:list'); }} right={<button className="ph-icon" title="Standort senden" onClick={() => act('messages:location', { number: open.number })}><Icon name="pin" size={16} /></button>} />
      <div className="ph-body ph-chat">
        {msgs.map((m) => (
          <div key={m.id} className={'ph-msg' + (m.mine ? ' mine' : '')}>
            {m.location ? <button className="ph-loc" onClick={() => act('messages:waypoint', { x: m.location!.x, y: m.location!.y })}><Icon name="pin" size={14} /> Standort – als Ziel setzen</button> : <span>{m.text}</span>}
            <small>{m.at}</small>
          </div>
        ))}
      </div>
      <div className="ph-compose">
        <input className="input" placeholder="Nachricht…" value={text} maxLength={300} onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter' && text.trim()) { act('messages:send', { number: open.number, text: text.trim() }); setText(''); } }} />
        <button className="btn primary" disabled={!text.trim()} onClick={() => { act('messages:send', { number: open.number, text: text.trim() }); setText(''); }}><Icon name="next" size={14} /></button>
      </div>
    </>);
  }
  return (<>
    <Header title="Nachrichten" right={<button className="ph-icon" onClick={() => setNewNo(newNo === null ? '' : null)}><Icon name="plus" size={16} /></button>} />
    <div className="ph-body">
      {newNo !== null && (
        <div className="ph-card">
          <input className="input num" placeholder="Nummer (4-stellig)" maxLength={4} value={newNo} onChange={(e) => setNewNo(e.target.value.replace(/\D/g, ''))} />
          <button className="btn primary" disabled={newNo.length !== 4} onClick={() => { setOpen({ number: newNo }); setNewNo(null); }}>Schreiben</button>
        </div>
      )}
      {threads.length === 0 && <div className="ph-empty"><Icon name="doc" size={28} /><span>Keine Nachrichten.</span></div>}
      {threads.map((t) => (
        <button key={t.number} className="ph-row" onClick={() => setOpen({ number: t.number, name: t.name })}>
          <span className="ph-avatar sm">{(t.name ?? t.number).slice(0, 1).toUpperCase()}</span>
          <span className="grow"><b>{t.name ?? t.number}</b><small className="ellipsis">{t.last}</small></span>
          {t.unread > 0 && <span className="ph-badge">{t.unread}</span>}
        </button>
      ))}
    </div>
  </>);
}

function BankApp() {
  const [d, setD] = useState<BankData | null>(null);
  const [to, setTo] = useState(''); const [amount, setAmount] = useState(''); const [reason, setReason] = useState('');
  const [tab, setTab] = useState<'overview' | 'transfer' | 'invoice'>('overview');
  useNuiEvent<{ app: string; data: BankData }>('phone', (e) => { if (e.app === 'bank') setD(e.data); });
  useEffect(() => { act('bank:load'); }, []);
  return (<>
    <Header title="Bank" />
    <div className="ph-body">
      <div className="ph-card ph-center"><span className="muted">Girokonto</span><b className="ph-big num">{money(d?.balance ?? 0)}</b></div>
      <div className="ph-tabs">
        {(['overview', 'transfer', 'invoice'] as const).map((t) => <button key={t} className={'ph-tab' + (tab === t ? ' on' : '')} onClick={() => setTab(t)}>{{ overview: 'Umsätze', transfer: 'Überweisen', invoice: 'Rechnung' }[t]}</button>)}
      </div>
      {tab === 'overview' && (d?.rows ?? []).map((r, i) => (
        <div key={i} className="ph-row static"><span className="grow"><b>{r.reason}</b><small>{r.note ?? ''} · {r.at}</small></span><span className={'num ' + (r.dir === 'in' ? 'ok' : 'bad')}>{r.dir === 'in' ? '+' : '−'}{money(r.amount)}</span></div>
      ))}
      {tab !== 'overview' && (
        <div className="ph-card">
          <input className="input num" placeholder="Nummer des Empfängers" maxLength={4} value={to} onChange={(e) => setTo(e.target.value.replace(/\D/g, ''))} />
          <input className="input num" placeholder="Betrag in $" value={amount} onChange={(e) => setAmount(e.target.value.replace(/\D/g, ''))} />
          <input className="input" placeholder="Verwendungszweck" maxLength={64} value={reason} onChange={(e) => setReason(e.target.value)} />
          <button className="btn primary" disabled={to.length !== 4 || !amount} onClick={() => { act(tab === 'transfer' ? 'bank:transfer' : 'bank:invoice', { number: to, amount: Number(amount), reason }); setAmount(''); setReason(''); }}>{tab === 'transfer' ? 'Überweisen' : 'Rechnung stellen'}</button>
        </div>
      )}
      {tab === 'overview' && (d?.invoices ?? []).length > 0 && <div className="ph-section">Offene Rechnungen</div>}
      {tab === 'overview' && (d?.invoices ?? []).map((inv) => (
        <div key={inv.id} className="ph-row static"><span className="grow"><b>{inv.from}</b><small>{inv.reason}</small></span><span className="num">{money(inv.amount)}</span><button className="btn sm primary" onClick={() => act('bank:pay', { id: inv.id })}>Zahlen</button></div>
      ))}
    </div>
  </>);
}

function Vehicles() {
  const [list, setList] = useState<PhoneVehicle[]>([]);
  useNuiEvent<{ app: string; data: PhoneVehicle[] }>('phone', (e) => { if (e.app === 'vehicles') setList(e.data); });
  useEffect(() => { act('vehicles:list'); }, []);
  const st: Record<string, string> = { garage: 'In der Garage', out: 'Unterwegs', impound: 'Verwahrhof' };
  return (<>
    <Header title="Fahrzeuge" />
    <div className="ph-body">
      {list.length === 0 && <div className="ph-empty"><Icon name="car" size={28} /><span>Keine Fahrzeuge.</span></div>}
      {list.map((v) => (
        <div key={v.id} className="ph-card">
          <div className="row-flex"><b className="grow">{v.label}</b><span className="tag num">{v.plate}</span></div>
          <small className="muted">{st[v.state] ?? v.state}{v.garage ? ` · ${v.garage}` : ''} · Tank {Math.round((v.fuel / v.tank) * 100)} % · {Math.round(v.km)} km{v.shared > 0 ? ` · ${v.shared} Schlüssel vergeben` : ''}</small>
          <div className="ph-grid2">
            <button className="btn sm" disabled={v.state !== 'out'} onClick={() => act('vehicles:locate', { id: v.id })}><Icon name="pin" size={12} /> Orten</button>
            <button className="btn sm" onClick={() => act('vehicles:share', { id: v.id })}><Icon name="key" size={12} /> Schlüssel teilen</button>
          </div>
        </div>
      ))}
    </div>
  </>);
}

function Radio() {
  const [d, setD] = useState<RadioData>({ hasRadio: false, channel: null, members: [], talking: [] });
  const [freq, setFreq] = useState('');
  useNuiEvent<{ app: string; data: RadioData }>('phone', (e) => { if (e.app === 'radio') setD(e.data); });
  useEffect(() => { act('radio:load'); }, []);
  return (<>
    <Header title="Funk" />
    <div className="ph-body">
      {!d.hasRadio ? <div className="ph-empty"><Icon name="radio" size={28} /><span>Kein Funkgerät in der Tasche. Gibt es im Baumarkt (250 $).</span></div> : (<>
        <div className="ph-card ph-center"><span className="muted">Frequenz</span><b className="ph-big num">{d.channel ?? '—'}</b>
          {d.channel && <button className="btn sm danger" onClick={() => act('radio:leave')}>Verlassen</button>}</div>
        <div className="ph-card">
          <input className="input num" placeholder="Frequenz 1–999" value={freq} maxLength={3} onChange={(e) => setFreq(e.target.value.replace(/\D/g, ''))} />
          <button className="btn primary" disabled={!freq} onClick={() => { act('radio:join', { channel: Number(freq) }); setFreq(''); }}>Einstellen</button>
          <small className="muted">1–10 sind Fraktionsfrequenzen. Sprechen mit der Funktaste von SaltyChat.</small>
        </div>
        {d.members.length > 0 && <div className="ph-section">Auf der Frequenz</div>}
        {d.members.map((m) => <div key={m} className="ph-row static"><span className="grow">{m}</span>{d.talking.includes(m) && <Icon name="mic" size={14} />}</div>)}
      </>)}
    </div>
  </>);
}

function SettingsApp({ number, s, onChange }: { number: string; s: Settings; onChange: (s: Settings) => void }) {
  return (<>
    <Header title="Einstellungen" />
    <div className="ph-body">
      <div className="ph-card ph-center"><span className="muted">Deine Nummer</span><b className="ph-big num">{number}</b></div>
      <div className="ph-row static"><span className="grow"><b>Klingelton</b></span><div className="ph-step">{[1, 2, 3].map((n) => <button key={n} className={'btn sm' + (s.ringtone === n ? ' primary' : '')} onClick={() => { onChange({ ...s, ringtone: n }); act('settings:ringtone', { n }); }}>{n}</button>)}</div></div>
      <div className="ph-row static"><span className="grow"><b>Flugmodus</b><small>keine Anrufe, keine Nachrichten</small></span><button className={'ph-switch' + (s.airplane ? ' on' : '')} onClick={() => onChange({ ...s, airplane: !s.airplane })} aria-label="Flugmodus" /></div>
      <div className="ph-row static"><span className="grow"><b>Bedürfnisse als Zahl</b><small>Hunger und Durst im HUD mit Prozent</small></span><button className={'ph-switch' + (s.needsNumbers ? ' on' : '')} onClick={() => onChange({ ...s, needsNumbers: !s.needsNumbers })} aria-label="Bedürfnisse als Zahl" /></div>
      <div className="ph-row static"><span className="grow"><b>HUD-Größe</b></span><div className="ph-step">{[90, 100, 110].map((n) => <button key={n} className={'btn sm' + (s.hudScale === n ? ' primary' : '')} onClick={() => onChange({ ...s, hudScale: n })}>{n} %</button>)}</div></div>
    </div>
  </>);
}

export function Phone({ data }: { data: PhoneData }) {
  const [app, setApp] = useState<string | null>(data.open ?? null);
  const [apps, setApps] = useState<PhoneApp[]>(data.apps);
  const [call, setCall] = useState<CallState>(null);
  const [msgTarget, setMsgTarget] = useState<{ number: string; name?: string } | undefined>(undefined);
  const [settings, setSettings] = useState<Settings>(loadPhoneSettings);
  const [cursor, setCursor] = useState<boolean>(data.cursor ?? true);
  useNuiEvent<{ app: string; data: unknown }>('phone', (d) => {
    if (d.app === 'apps') setApps(d.data as PhoneApp[]);
    if (d.app === 'call') setCall(d.data as CallState);
    if (d.app === 'cursor') setCursor(d.data === true);
  });
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape') { e.preventDefault(); act('close'); }
      if (e.key === 'Backspace' && !(e.target instanceof HTMLInputElement)) { e.preventDefault(); setApp(null); }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);
  const changeSettings = (s: Settings) => {
    setSettings(s);
    try { localStorage.setItem('tacov_phone', JSON.stringify(s)); } catch { /* ignorieren */ }
    applyPhoneSettings(s);
    act('settings:set', s as unknown as Record<string, unknown>);
  };
  const startCall = (n: string) => act('calls:start', { number: n });
  const openMessage = (n: string, name?: string) => { setMsgTarget({ number: n, name }); setApp('messages'); };

  const DOCK = ['dialer', 'messages', 'contacts', 'bank'];
  const dockApps: PhoneApp[] = [
    { id: 'dialer', label: 'Telefon', icon: 'phone', enabled: true },
    { id: 'messages', label: 'Nachrichten', icon: 'doc', enabled: true, badge: apps.find((a) => a.id === 'messages')?.badge },
    { id: 'contacts', label: 'Kontakte', icon: 'group', enabled: true },
    ...apps.filter((a) => a.id === 'bank'),
  ];
  const gridApps = apps.filter((a) => !DOCK.includes(a.id));
  const AppIcon = ({ a }: { a: PhoneApp }) => (
    <button className={'ph-app' + (a.enabled ? '' : ' off')} disabled={!a.enabled} onClick={() => setApp(a.id)} title={a.label}>
      <span className={'ph-app-ico c-' + a.id}><Icon name={a.icon} size={24} />{a.badge ? <i className="ph-badge">{a.badge}</i> : null}</span>
      <span>{a.label}</span>
    </button>
  );
  const time = data.time ?? '';
  const isHome = !call && !app;

  return (
    <div className={'phone' + (cursor ? '' : ' nocursor')}>
      {!cursor && <div className="ph-hint"><b>Alt</b> Handy bedienen · <b>F1</b> weglegen</div>}
      <div className={'ph-screen' + (isHome ? ' home' : '')}>
        <div className="ph-island" />
        <div className="ph-status">
          <span className="num">{time}</span>
          <span className="right"><span className="ph-sig"><i /><i /><i /><i /></span><Icon name="radio" size={12} /><span className="ph-bat" /></span>
        </div>
        {call && (
          <div className={'ph-call ' + call.state}>
            <div className="who">
              <div className="ph-avatar">{(call.name ?? call.with).slice(0, 1).toUpperCase()}</div>
              <b>{call.name ?? call.with}</b>
              <span>{call.state === 'incoming' ? 'Eingehender Anruf · ' + call.with : call.state === 'outgoing' ? 'Wählt …' : 'Verbunden'}</span>
            </div>
            <div className="actions">
              <div><button className="ph-callbtn red" onClick={() => act('calls:end')} title="Auflegen"><Icon name="x" size={26} /></button>{call.state === 'incoming' ? 'Ablehnen' : 'Auflegen'}</div>
              {call.state === 'incoming' && <div><button className="ph-callbtn" onClick={() => act('calls:accept')} title="Annehmen"><Icon name="phone" size={26} /></button>Annehmen</div>}
            </div>
          </div>
        )}
        {isHome && (
          <div className="ph-home">
            <div className="ph-clock"><b className="num">{time}</b><span>{data.number}</span></div>
            <div className="ph-apps">{gridApps.map((a) => <AppIcon key={a.id} a={a} />)}</div>
            <div className="ph-dock">{dockApps.map((a) => <AppIcon key={a.id} a={a} />)}</div>
          </div>
        )}
        {!call && app === 'contacts' && <Contacts onCall={startCall} onMessage={openMessage} />}
        {!call && app === 'dialer' && <Dialer onCall={startCall} />}
        {!call && app === 'messages' && <Messages initial={msgTarget} />}
        {!call && app === 'bank' && <BankApp />}
        {!call && app === 'vehicles' && <Vehicles />}
        {!call && app === 'radio' && <Radio />}
        {!call && app === 'settings' && <SettingsApp number={data.number} s={settings} onChange={changeSettings} />}
        {!call && app && !['contacts', 'dialer', 'messages', 'bank', 'vehicles', 'radio', 'settings'].includes(app) && (<>
          <Header title={apps.find((a) => a.id === app)?.label ?? app} onBack={() => setApp(null)} />
          <div className="ph-body"><div className="ph-empty"><Icon name="clock" size={28} /><span>Kommt mit einer späteren Phase.</span></div></div>
        </>)}
        <button className="ph-indicator" onClick={() => (app ? setApp(null) : act('close'))} title={app ? 'Startseite' : 'Handy weglegen'} />
      </div>
    </div>
  );
}
