// Charakterauswahl in V4: Karten je Platz mit Panelkopf, leere Karte für neuen Charakter, Anlage-Formular.
import { useState } from 'react';
import { nui, useNuiEvent } from '../nui';
import { Icon } from '../components/Icon';
import { Panel, PanelHead } from '../components/Panel';
import { money } from './Hud';
import type { CharacterRow, CharactersData } from '../store';

export function Characters({ data }: { data: CharactersData; key?: string }) {
  const [selected, setSelected] = useState<number | null>(data.characters[0]?.id ?? null);
  const [creating, setCreating] = useState(data.characters.length === 0);
  const [error, setError] = useState('');
  const [form, setForm] = useState({ firstName: '', lastName: '', birthDate: '', origin: '', gender: '0' });
  const [busy, setBusy] = useState(false);
  useNuiEvent<{ kind: string; text: string }>('notify', (d) => { if (d.kind === 'error') { setError(d.text); setBusy(false); } });

  const free = data.maxSlots - data.characters.length;
  const locked = data.characters.length >= 1 && (data.maxLevel ?? 0) < data.secondSlotLevel;
  const play = (id: number) => { setBusy(true); nui('selectCharacter', { id }); };
  const create = () => {
    if (!form.firstName || !form.lastName || !form.birthDate) { setError('Vorname, Nachname und Geburtsdatum sind Pflicht.'); return; }
    setBusy(true); setError(''); nui('createCharacter', { ...form, gender: Number(form.gender) });
  };
  const sub = (c: CharacterRow) => `${c.faction ? c.faction.toUpperCase() : 'Zivil'} · ${Math.floor(c.playtime_seconds / 3600)} h · ${c.immigrated_at ? 'eingereist' : 'noch nicht eingereist'}`;

  return (
    <div className="chars">
      <img src="assets/logo.png" alt="TacoV" width={220} style={{ display: 'block', filter: 'drop-shadow(0 4px 12px rgba(0,0,0,0.6))' }} />
      <div className="cards">
        {data.characters.map((c) => {
          const active = c.id === selected;
          return (
            <Panel key={c.id} className={'ccard' + (active ? ' on' : '')} style={active ? { borderColor: 'var(--accent-2)', boxShadow: '0 0 0 1px rgba(139,92,246,0.45), 0 30px 60px rgba(0,0,0,0.55)' } : undefined}>
              <PanelHead icon="user" brand={`Level ${c.level_cache}`} title={`${c.first_name} ${c.last_name}`} info={sub(c)} />
              <div className="body" onClick={() => setSelected(c.id)}>
                <div className="figure"><Icon name="user" size={64} stroke={1.4} /></div>
                <button className={'btn' + (active ? ' primary' : '')} disabled={busy} onClick={(e) => { e.stopPropagation(); if (active) play(c.id); else setSelected(c.id); }}>{active ? 'Spielen' : 'Wählen'}</button>
              </div>
            </Panel>
          );
        })}
        {free > 0 && !creating && (
          <Panel className={'ccard empty' + (locked ? ' locked' : '')} soft>
            <div className="body" style={{ alignItems: 'center', justifyContent: 'center', gap: 10 }} onClick={() => { if (!locked) setCreating(true); }}>
              <span className="badge" style={{ width: 64, height: 64, borderRadius: '50%' }}><Icon name="plus" size={26} stroke={2.6} /></span>
              <b style={{ fontSize: 16 }}>{locked ? 'Gesperrt' : 'Neuer Charakter'}</b>
              <span className="sub">{data.characters.length >= 1 ? `Weiterer Charakter ab Level ${data.secondSlotLevel}` : 'Dein Charakter'}</span>
            </div>
          </Panel>
        )}
        {creating && (
          <Panel className="ccard" style={{ borderColor: 'var(--accent-2)' }}>
            <PanelHead icon="id" brand="Neu" title="Neuer Charakter" info="Name, Geburtsdatum, Herkunft" />
            <div className="body" style={{ gap: 8 }}>
              <div style={{ display: 'flex', gap: 8 }}><input className="input" placeholder="Vorname" value={form.firstName} onChange={(e) => setForm({ ...form, firstName: e.target.value })} /><input className="input" placeholder="Nachname" value={form.lastName} onChange={(e) => setForm({ ...form, lastName: e.target.value })} /></div>
              <label className="field"><span>Geburtsdatum</span><input className="input" type="date" value={form.birthDate} onChange={(e) => setForm({ ...form, birthDate: e.target.value })} /></label>
              <label className="field"><span>Herkunft</span><input className="input" placeholder="z. B. Liberty City" value={form.origin} onChange={(e) => setForm({ ...form, origin: e.target.value })} /></label>
              <label className="field"><span>Geschlecht</span><select className="input" value={form.gender} onChange={(e) => setForm({ ...form, gender: e.target.value })}><option value="0">Männlich</option><option value="1">Weiblich</option></select></label>
              <span style={{ fontSize: 12, color: 'var(--danger)', minHeight: 14 }}>{error}</span>
              <div style={{ display: 'flex', gap: 8, marginTop: 'auto' }}>
                {data.characters.length > 0 && <button className="btn ghost" onClick={() => setCreating(false)}>Zurück</button>}
                <button className="btn primary" disabled={busy} onClick={create} style={{ flex: 1 }}>Anlegen</button>
              </div>
            </div>
          </Panel>
        )}
      </div>
      <span className="sub">Startgeld {money(5000)} auf dem Konto · Team online: {data.staffOnline ?? 0}</span>
    </div>
  );
}
