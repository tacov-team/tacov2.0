// Hinweise oben links nach Canvas „V4“: Balken links in der Farbe, Überschrift in Großbuchstaben, Text darunter.
import { useStore } from '../store';

export function Toasts() {
  const { state } = useStore();
  if (state.toasts.length === 0) return null;
  const consoleOpen = state.view?.name === 'console';
  const menuOpen = state.view?.name === 'menu';
  return (
    <div className="toasts" style={consoleOpen ? { left: 620 } : menuOpen ? { left: 440 } : undefined}>
      {state.toasts.map((t) => (
        <div key={t.id} className={'toast ' + t.kind}>
          <b>{t.title}</b>
          {t.text && <span>{t.text}</span>}
        </div>
      ))}
    </div>
  );
}
