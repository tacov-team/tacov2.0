// Charakter: eine Karte (ein Charakter je Spieler) – vorhandenen spielen oder neuen anlegen.
import { useState } from 'react';
import { nui, useNuiEvent } from '../nui';
import { Icon } from '../components/Icon';
import { Panel } from '../components/Panel';
import { money } from './Hud';
import type { CharactersData } from '../store';

export function Characters({ data }: { data: CharactersData; key?: string }) {
  const c = data.characters[0];
  const [creating, setCreating] = useState(!c);
  const [error, setError] = useState('');
  const [busy, setBusy] = useState(false);
  const [form, setForm] = useState({ firstName: '', lastName: '', birthDate: '', origin: '', gender: '0' });
  useNuiEvent<{ kind: string; text: string }>('notify', (d) => { if (d.kind === 'error') { setError(d.text); setBusy(false); } });

  const create = () => {
    if (!form.firstName || !form.lastName || !form.birthDate) { setError('Vorname, Nachname und Geburtsdatum sind Pflicht.'); return; }
    setBusy(true); setError(''); nui('createCharacter', { ...form, gender: Number(form.gender) });
  };

  return (
    <div className="chars">
      <img src="assets/logo.png" alt="TacoV" style={{ width: '12rem', filter: 'drop-shadow(0 0.25rem 0.75rem rgba(0,0,0,0.6))' }} />
      {c && !creating ? (
        <Panel icon="user" title={`${c.first_name} ${c.last_name}`} sub={`Level ${c.level_cache} · ${c.faction ? c.faction.toUpperCase() : 'Zivilist'} · ${Math.floor(c.playtime_seconds / 3600)} h gespielt`}
          foot={<button className="btn primary block" disabled={busy} onClick={() => { setBusy(true); nui('selectCharacter', { id: c.id }); }}><Icon name="play" size={14} /> Spielen</button>}>
          <div className="figure"><Icon name="user" size={56} stroke={1.4} /></div>
          <span className="muted" style={{ fontSize: '0.75rem', textAlign: 'center' }}>{c.immigrated_at ? 'Eingereist' : 'Noch nicht eingereist – ein Teammitglied führt die Einreise durch'}</span>
        </Panel>
      ) : (
        <Panel icon="id" title="Neuer Charakter" sub="Name, Geburtsdatum und Herkunft deiner Figur"
          foot={<>{c && <button className="btn" onClick={() => setCreating(false)}>Zurück</button>}<button className="btn primary grow" disabled={busy} onClick={create}>Anlegen</button></>}>
          <div className="row-flex">
            <input className="input" placeholder="Vorname" value={form.firstName} onChange={(e) => setForm({ ...form, firstName: e.target.value })} />
            <input className="input" placeholder="Nachname" value={form.lastName} onChange={(e) => setForm({ ...form, lastName: e.target.value })} />
          </div>
          <label className="field">Geburtsdatum<input className="input" type="date" value={form.birthDate} onChange={(e) => setForm({ ...form, birthDate: e.target.value })} /></label>
          <label className="field">Herkunft<input className="input" placeholder="z. B. Liberty City" value={form.origin} onChange={(e) => setForm({ ...form, origin: e.target.value })} /></label>
          <label className="field">Geschlecht<select className="input" value={form.gender} onChange={(e) => setForm({ ...form, gender: e.target.value })}><option value="0">Männlich</option><option value="1">Weiblich</option></select></label>
          {error && <span style={{ fontSize: '0.75rem', color: 'var(--danger)' }}>{error}</span>}
          <span className="muted" style={{ fontSize: '0.75rem' }}>Startgeld {money(5000)} auf dem Konto · Team online: {data.staffOnline ?? 0}</span>
        </Panel>
      )}
    </div>
  );
}
