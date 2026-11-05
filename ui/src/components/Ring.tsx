import { Icon } from './Icon';

const R = 24;
const CIRC = 2 * Math.PI * R; // 150.8

export function Ring({ label, value, icon }: { label: string; value: number; icon: string }) {
  const v = Math.max(0, Math.min(100, Math.round(value)));
  const active = v > 0;
  return (
    <div className="ring" role="img" aria-label={`${label} ${v} %`}>
      <div className="ring-disc" style={{ boxShadow: active ? 'var(--accent-glow)' : '0 0 24px rgba(255,154,31,0.12)' }}>
        <svg width="58" height="58" viewBox="0 0 58 58" aria-hidden="true">
          <circle cx="29" cy="29" r={R} fill="none" stroke="rgba(255,255,255,0.1)" strokeWidth="5" />
          {active && (
            <circle cx="29" cy="29" r={R} fill="none" stroke="url(#tg)" strokeWidth="5" strokeLinecap="round"
              strokeDasharray={`${(CIRC * v) / 100} ${CIRC}`} />
          )}
        </svg>
        <span className="icon" style={{ color: active ? 'var(--accent)' : 'var(--dim)' }}><Icon name={icon} /></span>
      </div>
      <span className="ring-label" style={{ color: active ? 'var(--text)' : 'var(--muted)' }}>{v} %</span>
    </div>
  );
}

export function GradientDefs() {
  return (
    <svg width="0" height="0" style={{ position: 'absolute' }}>
      <defs>
        <linearGradient id="tg" x1="0" y1="0" x2="1" y2="1">
          <stop offset="0" stopColor="#FFD54A" />
          <stop offset="1" stopColor="#F07A12" />
        </linearGradient>
      </defs>
    </svg>
  );
}
