// Panel mit Kopf nach Canvas „V4 · Grundlagen“: Icon-Kachel, Marke, Titel (+ Schriftzug), „i“-Zeile, Schließen-Knopf.
import type { CSSProperties, ReactNode } from 'react';
import { Icon } from './Icon';

export function PanelHead({ icon, title, script, info, brand, onClose, right }: {
  icon: string; title: string; script?: string; info?: ReactNode; brand?: string; onClose?: () => void; right?: ReactNode;
}) {
  return (
    <div className="head">
      <div className="lead">
        <span className="badge"><Icon name={icon} size={22} /></span>
        <div className="title">
          {brand && <span className="brand">{brand}</span>}
          <h1>{title}{script && <span className="script">{script}</span>}</h1>
          {info && <div className="info"><i className="info-i">i</i><span>{info}</span></div>}
        </div>
      </div>
      {right}
      {onClose && <button className="btn danger sm" onClick={onClose}>Schliessen <Icon name="x" size={14} /></button>}
    </div>
  );
}

export function Panel({ className = '', soft, style, children }: { className?: string; soft?: boolean; style?: CSSProperties; children: ReactNode }) {
  return <section className={'panel' + (soft ? ' soft' : '') + (className ? ' ' + className : '')} style={style}>{children}</section>;
}

export function Kbd({ children }: { children: ReactNode }) {
  return <kbd className="kbd">{children}</kbd>;
}

export function Keys({ back = true }: { back?: boolean }) {
  return (
    <div className="keys">
      <Kbd>↑</Kbd><Kbd>↓</Kbd> Wählen <Kbd>Enter</Kbd> Bestätigen {back && <><Kbd>⌫</Kbd> Zurück</>}
    </div>
  );
}
