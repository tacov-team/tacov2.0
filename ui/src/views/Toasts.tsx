// Hinweise oben links: farbiger Streifen je Art, Titel, Text.
import { useStore } from '../store';

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
