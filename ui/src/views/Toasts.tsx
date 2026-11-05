import { useStore, type Toast } from '../store';
import { Icon } from '../components/Icon';

const look: Record<Toast['kind'], { color: string; icon: string }> = {
  success: { color: 'var(--ok)', icon: 'check' },
  info: { color: 'var(--accent)', icon: 'info' },
  warn: { color: 'var(--warn)', icon: 'warn' },
  error: { color: 'var(--danger)', icon: 'x' },
};

export function Toasts() {
  const { state } = useStore();
  if (state.toasts.length === 0) return null;
  const consoleOpen = state.view?.name === 'console';
  return (
    <div className="toasts" style={consoleOpen ? { left: 620 } : undefined}>
      {state.toasts.map((t) => (
        <div key={t.id} className="toast">
          <span className="bar" style={{ background: look[t.kind].color }} />
          <span className="ico" style={{ color: look[t.kind].color }}><Icon name={look[t.kind].icon} size={17} /></span>
          <span style={{ display: 'flex', flexDirection: 'column', gap: 2 }}>
            <strong>{t.title}</strong>
            {t.text && <span className="txt">{t.text}</span>}
          </span>
        </div>
      ))}
    </div>
  );
}
