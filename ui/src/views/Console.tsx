// Befehlszeile (Taste T, oben links). Nur Befehle, kein Roleplay-Chat (Konzept 5).
import { useEffect, useMemo, useRef, useState } from 'react';
import { nui } from '../nui';
import { useStore, type CommandInfo } from '../store';

export function Console({ commands, history }: { commands: CommandInfo[]; history: string[] }) {
  const { state, dispatch } = useStore();
  const [text, setText] = useState('');
  const [active, setActive] = useState(0);
  const input = useRef<HTMLInputElement>(null);

  useEffect(() => { input.current?.focus(); }, []);

  const staff = state.role !== 'player';
  const word = text.trim().split(/\s+/)[0] ?? '';
  const suggestions = useMemo(() => {
    const list = commands.filter((c) => staff || !c.staff);
    if (!word) return list.slice(0, 8);
    return list.filter((c) => c.name.startsWith(word.toLowerCase())).slice(0, 8);
  }, [commands, word, staff]);

  function close() { dispatch({ type: 'close' }); nui('close'); }

  function submit() {
    const cmd = text.trim();
    if (cmd) nui('command', { command: cmd });
    close();
  }

  function onKey(e: React.KeyboardEvent<HTMLInputElement>) {
    if (e.key === 'Escape') { e.preventDefault(); close(); }
    else if (e.key === 'Enter') { e.preventDefault(); submit(); }
    else if (e.key === 'ArrowDown') { e.preventDefault(); setActive((a) => Math.min(a + 1, suggestions.length - 1)); }
    else if (e.key === 'ArrowUp') { e.preventDefault(); setActive((a) => Math.max(a - 1, 0)); }
    else if (e.key === 'Tab') {
      e.preventDefault();
      const s = suggestions[active];
      if (s) setText(s.name + ' ');
    }
  }

  return (
    <div className="console">
      {history.length > 0 && (
        <div className="history">
          {history.slice(-3).map((h, i) => <span key={i}><strong>/{h.split(' ')[0]}</strong> {h.includes(' ') ? h.slice(h.indexOf(' ')) : ''}</span>)}
        </div>
      )}
      <div className="line">
        <kbd className="kbd">T</kbd>
        <span className="slash">/</span>
        <input ref={input} value={text} onChange={(e) => { setText(e.target.value); setActive(0); }} onKeyDown={onKey}
          placeholder="Befehl eingeben" spellCheck={false} autoComplete="off" />
        <span className="hint">Enter ausführen · ESC schließen</span>
      </div>
      {suggestions.length > 0 && (
        <div className="suggest">
          {suggestions.map((s, i) => (
            <div key={s.name} className={'item' + (i === active ? ' active' : '')} onMouseDown={() => setText(s.name + ' ')}>
              <span><strong>/{s.usage}</strong></span>
              <span>{s.help}{s.staff ? ' · Team' : ''}</span>
            </div>
          ))}
        </div>
      )}
    </div>
  );
}
