// Texteingabe (Creator, Team-Werkzeuge): kleines Panel mit einer Zeile, Enter bestätigt, Esc bricht ab.
import { useEffect, useRef, useState } from 'react';
import { nui } from '../nui';
import { Panel, Kbd } from '../components/Panel';

export type AskData = { title: string; label?: string; placeholder?: string; value?: string; maxLength?: number; icon?: string; numeric?: boolean };

export function Ask({ data }: { data: AskData }) {
  const [text, setText] = useState(data.value ?? '');
  const input = useRef<HTMLInputElement>(null);
  useEffect(() => { input.current?.focus(); input.current?.select(); }, []);
  const submit = () => nui('action', { view: 'ask', action: 'submit', data: { value: text } });
  const cancel = () => nui('action', { view: 'ask', action: 'cancel' });
  return (
    <div className="ask">
      <Panel icon={data.icon ?? 'doc'} title={data.title} sub={data.label} onClose={cancel} className="soft"
        foot={<span className="keys"><Kbd>Enter</Kbd> übernehmen · <Kbd>Esc</Kbd> abbrechen</span>}>
        <input ref={input} className="input" value={text} maxLength={data.maxLength ?? 64} placeholder={data.placeholder} spellCheck={false} autoComplete="off"
          inputMode={data.numeric ? 'decimal' : undefined}
          onChange={(e) => setText(e.target.value)}
          onKeyDown={(e) => { if (e.key === 'Enter') { e.preventDefault(); submit(); } else if (e.key === 'Escape') { e.preventDefault(); cancel(); } }} />
      </Panel>
    </div>
  );
}
