// Panel: Kopf (Icon, Titel, Untertitel, Schließen), Körper, Fuß.
import type { CSSProperties, ReactNode } from 'react';
import { Icon } from './Icon';

export function Panel({ className = '', style, icon, title, sub, onClose, headRight, children, foot }: {
  className?: string; style?: CSSProperties; icon?: string; title?: string; sub?: ReactNode; onClose?: () => void;
  headRight?: ReactNode; children: ReactNode; foot?: ReactNode;
}) {
  return (
    <section className={'panel' + (className ? ' ' + className : '')} style={style}>
      {title && (
        <div className="head">
          {icon && <span className="ic"><Icon name={icon} size={18} /></span>}
          <div className="grow"><h1>{title}</h1>{sub && <div className="sub">{sub}</div>}</div>
          {headRight}
          {onClose && <button className="btn icon" onClick={onClose} title="Schließen (Esc)"><Icon name="x" size={16} /></button>}
        </div>
      )}
      <div className="body">{children}</div>
      {foot && <div className="foot">{foot}</div>}
    </section>
  );
}

export function Kbd({ children }: { children: ReactNode }) {
  return <kbd className="kbd">{children}</kbd>;
}
