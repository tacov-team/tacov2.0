// Hinweise oben links: farbiger Streifen je Art, Titel, Text.
import { useStore } from '../store';

export function Announce() {
  const { state } = useStore();
  const a = state.announce;
  if (!a) return null;
  return (
    <div className={'announce ' + a.kind}>
      <div className="head"><span className="dot" />{a.title}</div>
      <div className="text">{a.text}</div>
    </div>
  );
}

export function Crosshair() {
  const { state } = useStore();
  if (!state.crosshair) return null;
  return <div className="crosshair"><span /><span /><span /><span /><i /></div>;
}

export function DevOverlay() {
  const { state } = useStore();
  if (!state.dev) return null;
  return <pre className="dev">{state.dev}</pre>;
}

export function Toasts() {
  const { state } = useStore();
  if (state.toasts.length === 0) return null;
  const shift = state.view?.name === 'console' ? '38rem' : state.view?.name === 'menu' ? '26.5rem' : undefined;
  return (
    <div className="toasts" style={shift ? { left: shift } : undefined}>
      {state.toasts.map((t) => (
        <div key={t.id} className={'toast ' + t.kind}><b>{t.title}</b>{t.text && <span>{t.text}</span>}</div>
      ))}
    </div>
  );
}
