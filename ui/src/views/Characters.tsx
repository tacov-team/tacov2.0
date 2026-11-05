// Charakterauswahl nach Board „Charakterauswahl“: Karten je Platz, leere Karte für neuen Charakter.
import { useState } from 'react';
import { nui } from '../nui';
import { useNuiEvent } from '../nui';
import { Icon } from '../components/Icon';
import { money } from './Hud';
import type { CharacterRow, CharactersData } from '../store';

function lastSeen(c: CharacterRow) {
  return c.immigrated_at ? 'eingereist' : 'noch nicht eingereist';
}

export function Characters({ data }: { data: CharactersData; key?: string }) {
  const [selected, setSelected] = useState<number | null>(data.characters[0]?.id ?? null);
  const [creating, setCreating] = useState(data.characters.length === 0);
  const [error, setError] = useState('');
  const [form, setForm] = useState({ firstName: '', lastName: '', birthDate: '', origin: '', gender: '0' });
  const [busy, setBusy] = useState(false);

  useNuiEvent<{ kind: string; text: string }>('notify', (d) => { if (d.kind === 'error') { setError(d.text); setBusy(false); } });

  const free = data.maxSlots - data.characters.length;
  const locked = data.characters.length >= 1 && (data.maxLevel ?? 0) < data.secondSlotLevel;

  function play(id: number) { setBusy(true); nui('selectCharacter', { id }); }
  function create() {
    if (!form.firstName || !form.lastName || !form.birthDate) { setError('Vorname, Nachname und Geburtsdatum sind Pflicht.'); return; }
    setBusy(true); setError('');
    nui('createCharacter', { ...form, gender: Number(form.gender) });
  }

  return (
    <div className="chars">
      <img src="assets/logo.png" alt="TacoV" width={220} style={{ display: 'block', filter: 'drop-shadow(0 4px 12px rgba(0,0,0,0.6))' }} />
      <div className="cards">
        {data.characters.map((c) => {
          const active = c.id === selected;
          return (
            <div key={c.id} className={'card' + (active ? ' active' : '')} onClick={() => setSelected(c.id)}>
              <span className="top" />
              <div className="figure">Figur</div>
              <span className="lvl">Level {c.level_cache}</span>
              <strong className="name">{c.first_name} {c.last_name}</strong>
              <span className="meta">{c.faction ? c.faction.toUpperCase() : 'Zivil'} · {Math.floor(c.playtime_seconds / 3600)} h · {lastSeen(c)}</span>
              <button className={'btn' + (active ? ' primary' : '')} disabled={busy} onClick={(e) => { e.stopPropagation(); if (active) play(c.id); else setSelected(c.id); }}>
                {active ? 'Spielen' : 'Wählen'}
              </button>
            </div>
          );
        })}
        {free > 0 && !creating && (
          <div className={'card empty' + (locked ? ' locked' : '')} onClick={() => { if (!locked) setCreating(true); }}>
            <span className="plus"><Icon name="plus" size={24} stroke={2.6} /></span>
            <strong style={{ fontSize: 16 }}>{locked ? 'Gesperrt' : 'Neuer Charakter'}</strong>
            <span style={{ fontSize: 12 }}>{data.characters.length >= 1 ? `Zweiter Charakter ab Level ${data.secondSlotLevel}` : 'Dein erster Charakter'}</span>
          </div>
        )}
        {creating && (
          <div className="card form active">
            <span className="top" />
            <span className="lvl">Neuer Charakter</span>
            <label>Name</label>
            <div className="two">
              <input className="input" placeholder="Vorname" value={form.firstName} onChange={(e) => setForm({ ...form, firstName: e.target.value })} />
              <input className="input" placeholder="Nachname" value={form.lastName} onChange={(e) => setForm({ ...form, lastName: e.target.value })} />
            </div>
            <label>Geburtsdatum</label>
            <input className="input" type="date" value={form.birthDate} onChange={(e) => setForm({ ...form, birthDate: e.target.value })} />
            <label>Herkunft</label>
            <input className="input" placeholder="z. B. Liberty City" value={form.origin} onChange={(e) => setForm({ ...form, origin: e.target.value })} />
            <label>Geschlecht</label>
            <select className="input" value={form.gender} onChange={(e) => setForm({ ...form, gender: e.target.value })}>
              <option value="0">Männlich</option>
              <option value="1">Weiblich</option>
            </select>
            <span className="err">{error}</span>
            <div className="two">
              {data.characters.length > 0 && <button className="btn" onClick={() => setCreating(false)}>Zurück</button>}
              <button className="btn primary" disabled={busy} onClick={create} style={{ flex: 1 }}>Anlegen</button>
            </div>
          </div>
        )}
      </div>
      <span className="foot">Startgeld {money(5000)} auf dem Konto · Team online: {data.staffOnline ?? 0}</span>
    </div>
  );
}
