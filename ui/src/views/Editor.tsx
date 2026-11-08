// Charaktereditor (Punkt 6.1): Panel links mit Reitern, Figur rechts in der Welt. Jede Änderung geht sofort an Lua (Vorschau).
// Wird auch von Friseur, Chirurg und Kleiderladen genutzt (eingeschränkte Reiter über data.tabs).
import { useEffect, useMemo, useRef, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { Panel, Kbd } from '../components/Panel';

export type Appearance = {
  model: string;
  parents: { father: number; mother: number; shapeMix: number; skinMix: number };
  face: number[];                      // 20 Werte −1..1
  hair: { style: number; color: number; highlight: number };
  eyeColor: number;
  overlays: Record<string, { style: number; opacity: number; color: number }>;
  components: Record<string, [number, number]>;
  props: Record<string, [number, number]>;
};
export type EditorLimits = { hair: number; hairColors: number; makeupColors: number; overlays: Record<string, number>; components: Record<string, number>; textures?: Record<string, number> };
export type EditorData = { appearance: Appearance; limits: EditorLimits; tabs?: string[]; title?: string; price?: string; doneLabel?: string };

const PARENTS = ['Benjamin', 'Daniel', 'Joshua', 'Noah', 'Andrew', 'Juan', 'Alex', 'Isaac', 'Evan', 'Ethan', 'Vincent', 'Angel', 'Diego', 'Adrian', 'Gabriel', 'Michael', 'Santiago', 'Kevin', 'Louis', 'Samuel', 'Anthony',
  'Hannah', 'Audrey', 'Jasmine', 'Giselle', 'Amelia', 'Isabella', 'Zoe', 'Ava', 'Camila', 'Violet', 'Sophia', 'Eveline', 'Nicole', 'Ashley', 'Grace', 'Brianna', 'Natalie', 'Olivia', 'Elizabeth', 'Charlotte', 'Emma', 'Claude', 'Niko', 'John', 'Misty'];
const FACE = ['Nasenbreite', 'Nasenhöhe', 'Nasenlänge', 'Nasenrücken', 'Nasenspitze', 'Nasenknick', 'Brauenhöhe', 'Brauentiefe', 'Wangenknochen hoch', 'Wangenknochen breit', 'Wangenbreite', 'Augen', 'Lippen', 'Kieferbreite', 'Kieferhöhe', 'Kinnlänge', 'Kinnposition', 'Kinnbreite', 'Kinnform', 'Halsbreite'];
const OVERLAYS: { id: string; label: string; colored?: 'hair' | 'makeup'; female?: boolean; male?: boolean }[] = [
  { id: 'beard', label: 'Bart', colored: 'hair' },
  { id: 'eyebrows', label: 'Augenbrauen', colored: 'hair' },
  { id: 'chesthair', label: 'Brustbehaarung', colored: 'hair', male: true },
  { id: 'ageing', label: 'Alterung' },
  { id: 'complexion', label: 'Teint' },
  { id: 'sundamage', label: 'Sonnenschäden' },
  { id: 'freckles', label: 'Sommersprossen' },
  { id: 'blemishes', label: 'Hautunreinheiten' },
  { id: 'bodyblemish', label: 'Körpermale' },
  { id: 'makeup', label: 'Make-up', colored: 'makeup' },
  { id: 'blush', label: 'Rouge', colored: 'makeup' },
  { id: 'lipstick', label: 'Lippenstift', colored: 'makeup' },
];
const TABS = [
  { id: 'parents', label: 'Herkunft', icon: 'group' },
  { id: 'face', label: 'Gesicht', icon: 'user' },
  { id: 'hair', label: 'Haare', icon: 'star' },
  { id: 'details', label: 'Details', icon: 'search' },
];

function Slider({ label, value, min, max, step, onChange, fmt }: { label: string; value: number; min: number; max: number; step: number; onChange: (v: number) => void; fmt?: (v: number) => string }) {
  return (
    <label className="ed-row">
      <span className="ed-label">{label}</span>
      <input type="range" min={min} max={max} step={step} value={value} onChange={(e) => onChange(Number(e.target.value))} />
      <span className="ed-val num">{fmt ? fmt(value) : value}</span>
    </label>
  );
}

function Stepper({ label, value, max, onChange, name }: { label: string; value: number; max: number; onChange: (v: number) => void; name?: (v: number) => string }) {
  const n = Math.max(1, max);
  const step = (d: number) => onChange(((value + d) % n + n) % n);
  return (
    <div className="ed-row">
      <span className="ed-label">{label}</span>
      <div className="ed-step">
        <button className="btn sm" onClick={() => step(-1)}>‹</button>
        <span className="num">{name ? name(value) : `${value + 1} / ${n}`}</span>
        <button className="btn sm" onClick={() => step(1)}>›</button>
      </div>
    </div>
  );
}

export function Editor({ data }: { data: EditorData }) {
  const tabs = useMemo(() => TABS.filter((t) => !data.tabs || data.tabs.includes(t.id)), [data.tabs]);
  const [tab, setTab] = useState(tabs[0]?.id ?? 'parents');
  const [app, setApp] = useState<Appearance>(data.appearance);
  const [cam, setCam] = useState<'face' | 'body'>('face');
  const female = app.model === 'mp_f_freemode_01';
  const timer = useRef<number | null>(null);

  // Vorschau: gebündelt alle 60 ms an Lua
  const push = (next: Appearance) => {
    setApp(next);
    if (timer.current) window.clearTimeout(timer.current);
    timer.current = window.setTimeout(() => nui('action', { view: 'editor', action: 'update', data: { appearance: next } }), 60);
  };
  useEffect(() => { nui('action', { view: 'editor', action: 'camera', data: { mode: cam } }); }, [cam]);
  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'ArrowLeft') nui('action', { view: 'editor', action: 'rotate', data: { delta: -10 } });
      if (e.key === 'ArrowRight') nui('action', { view: 'editor', action: 'rotate', data: { delta: 10 } });
      if (e.key === 'Escape') nui('action', { view: 'editor', action: 'cancel', data: {} });
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, []);

  const setParent = (k: keyof Appearance['parents'], v: number) => push({ ...app, parents: { ...app.parents, [k]: v } });
  const setFace = (i: number, v: number) => { const face = [...app.face]; face[i] = v; push({ ...app, face }); };
  const setHair = (k: keyof Appearance['hair'], v: number) => push({ ...app, hair: { ...app.hair, [k]: v } });
  const ov = (id: string) => app.overlays[id] ?? { style: -1, opacity: 1, color: 0 };
  const setOv = (id: string, patch: Partial<{ style: number; opacity: number; color: number }>) => push({ ...app, overlays: { ...app.overlays, [id]: { ...ov(id), ...patch } } });
  const randomize = () => {
    const r = (n: number) => Math.floor(Math.random() * n);
    const face = Array.from({ length: 20 }, () => Math.round((Math.random() * 1.2 - 0.6) * 100) / 100);
    const father = female ? r(21) : r(21), mother = 21 + r(21);
    push({ ...app, parents: { father, mother, shapeMix: Math.round(Math.random() * 100) / 100, skinMix: Math.round(Math.random() * 100) / 100 }, face,
      hair: { style: r(Math.max(1, data.limits.hair)), color: r(data.limits.hairColors), highlight: r(data.limits.hairColors) }, eyeColor: r(32) });
  };
  const done = () => nui('action', { view: 'editor', action: 'done', data: { appearance: app } });

  return (
    <div className="editor">
      <Panel icon="user" title={data.title ?? 'Aussehen'} sub={female ? 'Weiblich' : 'Männlich'}
        headRight={<span className="keys"><Kbd>←</Kbd><Kbd>→</Kbd> drehen</span>}
        foot={<>
          <button className="btn" onClick={() => nui('action', { view: 'editor', action: 'cancel', data: {} })}>Abbrechen</button>
          {!data.tabs && <button className="btn" onClick={randomize}>Zufall</button>}
          <button className="btn primary grow" onClick={done}>{data.doneLabel ?? 'Übernehmen'}{data.price ? ` · ${data.price}` : ''}</button>
        </>}>
        <div className="ed-tabs">
          {tabs.map((t) => <button key={t.id} className={'ed-tab' + (tab === t.id ? ' on' : '')} onClick={() => setTab(t.id)}><Icon name={t.icon} size={14} />{t.label}</button>)}
          <span className="grow" />
          <button className={'ed-tab' + (cam === 'face' ? ' on' : '')} onClick={() => setCam('face')}>Gesicht</button>
          <button className={'ed-tab' + (cam === 'body' ? ' on' : '')} onClick={() => setCam('body')}>Körper</button>
        </div>
        <div className="ed-body">
          {tab === 'parents' && (<>
            {!data.tabs && (
              <div className="ed-row"><span className="ed-label">Geschlecht</span>
                <div className="ed-step">
                  <button className={'btn sm' + (!female ? ' primary' : '')} onClick={() => push({ ...app, model: 'mp_m_freemode_01' })}>Männlich</button>
                  <button className={'btn sm' + (female ? ' primary' : '')} onClick={() => push({ ...app, model: 'mp_f_freemode_01' })}>Weiblich</button>
                </div>
              </div>
            )}
            <Stepper label="Vater" value={app.parents.father} max={46} onChange={(v) => setParent('father', v)} name={(v) => PARENTS[v] ?? String(v)} />
            <Stepper label="Mutter" value={app.parents.mother} max={46} onChange={(v) => setParent('mother', v)} name={(v) => PARENTS[v] ?? String(v)} />
            <Slider label="Ähnlichkeit (Vater ↔ Mutter)" value={app.parents.shapeMix} min={0} max={1} step={0.01} onChange={(v) => setParent('shapeMix', v)} fmt={(v) => `${Math.round(v * 100)} %`} />
            <Slider label="Hautton (Vater ↔ Mutter)" value={app.parents.skinMix} min={0} max={1} step={0.01} onChange={(v) => setParent('skinMix', v)} fmt={(v) => `${Math.round(v * 100)} %`} />
            <Stepper label="Augenfarbe" value={app.eyeColor} max={32} onChange={(v) => push({ ...app, eyeColor: v })} />
          </>)}
          {tab === 'face' && FACE.map((label, i) => (
            <Slider key={label} label={label} value={app.face[i] ?? 0} min={-1} max={1} step={0.02} onChange={(v) => setFace(i, v)} fmt={(v) => v.toFixed(2)} />
          ))}
          {tab === 'hair' && (<>
            <Stepper label="Frisur" value={app.hair.style} max={data.limits.hair} onChange={(v) => setHair('style', v)} />
            <Stepper label="Haarfarbe" value={app.hair.color} max={data.limits.hairColors} onChange={(v) => setHair('color', v)} />
            <Stepper label="Strähnen" value={app.hair.highlight} max={data.limits.hairColors} onChange={(v) => setHair('highlight', v)} />
            {OVERLAYS.filter((o) => o.colored === 'hair' && (!o.male || !female)).map((o) => (
              <div key={o.id} className="ed-group">
                <Stepper label={o.label} value={ov(o.id).style + 1} max={(data.limits.overlays[o.id] ?? 0) + 1} onChange={(v) => setOv(o.id, { style: v - 1 })} name={(v) => (v === 0 ? 'Keine' : `${v} / ${data.limits.overlays[o.id] ?? 0}`)} />
                {ov(o.id).style >= 0 && <>
                  <Slider label="Deckkraft" value={ov(o.id).opacity} min={0} max={1} step={0.05} onChange={(v) => setOv(o.id, { opacity: v })} fmt={(v) => `${Math.round(v * 100)} %`} />
                  <Stepper label="Farbe" value={ov(o.id).color} max={data.limits.hairColors} onChange={(v) => setOv(o.id, { color: v })} />
                </>}
              </div>
            ))}
          </>)}
          {tab === 'details' && OVERLAYS.filter((o) => o.colored !== 'hair' && (!o.female || female)).map((o) => (
            <div key={o.id} className="ed-group">
              <Stepper label={o.label} value={ov(o.id).style + 1} max={(data.limits.overlays[o.id] ?? 0) + 1} onChange={(v) => setOv(o.id, { style: v - 1 })} name={(v) => (v === 0 ? 'Keine' : `${v} / ${data.limits.overlays[o.id] ?? 0}`)} />
              {ov(o.id).style >= 0 && <>
                <Slider label="Deckkraft" value={ov(o.id).opacity} min={0} max={1} step={0.05} onChange={(v) => setOv(o.id, { opacity: v })} fmt={(v) => `${Math.round(v * 100)} %`} />
                {o.colored === 'makeup' && <Stepper label="Farbe" value={ov(o.id).color} max={data.limits.makeupColors} onChange={(v) => setOv(o.id, { color: v })} />}
              </>}
            </div>
          ))}
        </div>
      </Panel>
    </div>
  );
}
