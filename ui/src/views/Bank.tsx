// Bank und Geldautomat nach Board „Bank“: Kontokarte, Reiter Einzahlen/Abheben/Überweisen, Kontoauszug rechts.
import { useEffect, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { money } from './Hud';

export type BankEntry = { at: string; amount: number; reason: string; note?: string | null; who: string };
export type BankData = {
  kind: 'bank' | 'atm'; title: string; account: string; balance: number; cash: number;
  transferLeft: number; atmMax: number; feePercent: number; feeFrom: number; statement: BankEntry[];
};

type Tab = 'deposit' | 'withdraw' | 'transfer';

function when(at: string) {
  const d = new Date(at.replace(' ', 'T'));
  if (Number.isNaN(d.getTime())) return at;
  const today = new Date();
  const sameDay = d.toDateString() === today.toDateString();
  const time = d.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  if (sameDay) return `heute ${time}`;
  const yesterday = new Date(today); yesterday.setDate(today.getDate() - 1);
  if (d.toDateString() === yesterday.toDateString()) return `gestern ${time}`;
  return `${d.toLocaleDateString('de-DE', { weekday: 'short' })} ${d.toLocaleDateString('de-DE')}`;
}

export function Bank({ data }: { data: BankData }) {
  const atm = data.kind === 'atm';
  const [tab, setTab] = useState<Tab>(atm ? 'withdraw' : 'deposit');
  const [amount, setAmount] = useState('');
  const [target, setTarget] = useState('');
  const [note, setNote] = useState('');

  useEffect(() => { if (atm && tab === 'transfer') setTab('withdraw'); }, [atm, tab]);

  const n = Math.max(0, Math.floor(Number(amount.replace(/[^\d]/g, '')) || 0));
  const max = tab === 'deposit' ? data.cash : tab === 'withdraw' ? (atm ? Math.min(data.balance, data.atmMax) : data.balance) : Math.min(data.balance, data.transferLeft);
  const fee = tab === 'transfer' && n >= data.feeFrom ? Math.floor((n * data.feePercent) / 100) : 0;
  const ok = n > 0 && n <= max && (tab !== 'transfer' || target.trim().length >= 3) && (tab !== 'transfer' || n + fee <= data.balance);

  const submit = () => {
    if (!ok) return;
    nui('action', { view: 'bank', action: 'action', data: { action: tab, amount: n, target: target.trim(), note: note.trim() } });
    setAmount('');
  };
  const close = () => nui('action', { view: 'bank', action: 'close' });

  const labels: Record<Tab, string> = { deposit: 'Einzahlen', withdraw: 'Abheben', transfer: 'Überweisen' };

  return (
    <div className="bank-wrap">
      <section className="bank-panel" style={{ width: 560 }}>
        <span className="top" />
        <div className="inv-head">
          <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
            <span className="eyebrow">{atm ? 'Geldautomat' : 'Bank'}</span>
            <h2>{data.title}</h2>
            <span className="sub">Konto {data.account}</span>
          </div>
          <button className="bank-x" onClick={close} aria-label="Schließen"><Icon name="x" size={16} /></button>
        </div>
        <div className="bank-card">
          <span>KONTOSTAND</span>
          <strong className="num">{money(data.balance)}</strong>
          <span>Bargeld {money(data.cash)}{atm ? ` · Automat max. ${money(data.atmMax)} je Abhebung` : ` · Überweisung heute noch ${money(data.transferLeft)}`}</span>
        </div>
        <div className="bank-tabs">
          {(['deposit', 'withdraw', 'transfer'] as Tab[]).filter((t) => !(atm && t === 'transfer')).map((t) => (
            <button key={t} className={tab === t ? 'active' : ''} onClick={() => { setTab(t); setAmount(''); }}>{labels[t]}</button>
          ))}
          {!atm && <button disabled title="Rechnungen kommen mit dem Handy">Rechnungen</button>}
        </div>
        {tab === 'transfer' && (
          <label className="bank-field"><span>Empfänger · Name oder Kontonummer</span>
            <input className="input" placeholder="Vorname Nachname oder LS-000000" value={target} onChange={(e) => setTarget(e.target.value)} /></label>
        )}
        <label className="bank-field"><span>Betrag</span>
          <input className="input num" inputMode="numeric" placeholder="0" value={amount} onChange={(e) => setAmount(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') submit(); }} /></label>
        {tab === 'transfer' && (
          <label className="bank-field"><span>Verwendungszweck</span>
            <input className="input" placeholder="optional" maxLength={64} value={note} onChange={(e) => setNote(e.target.value)} /></label>
        )}
        <div style={{ display: 'flex', gap: 8 }}>
          {[100, 500, 1000].map((q) => <button key={q} className="btn" style={{ height: 36, flex: 1 }} onClick={() => setAmount(String(Math.min(q, max)))}>{q.toLocaleString('de-DE')}</button>)}
          <button className="btn" style={{ height: 36, flex: 1 }} onClick={() => setAmount(String(max))}>Alles</button>
        </div>
        <button className="btn primary" style={{ height: 48 }} disabled={!ok} onClick={submit}>
          {labels[tab]}{n > 0 ? ` · ${money(n)}` : ''}{fee > 0 ? ` (+ ${money(fee)} Gebühr)` : ''}
        </button>
        {n > max && <span style={{ fontSize: 12, color: 'var(--danger)' }}>Höchstens {money(max)} möglich.</span>}
      </section>

      <section className="bank-panel" style={{ width: 480 }}>
        <span className="top" />
        <div style={{ display: 'flex', flexDirection: 'column', gap: 6 }}>
          <span className="eyebrow">Kontoauszug</span>
          <h2 style={{ margin: 0, fontSize: 30, fontWeight: 900, fontStyle: 'italic', textTransform: 'uppercase', lineHeight: 1 }}>Letzte Buchungen</h2>
        </div>
        <div className="bank-list">
          {data.statement.length === 0 && <span style={{ fontSize: 13, color: 'var(--dim)' }}>Noch keine Buchungen.</span>}
          {data.statement.map((e, i) => (
            <div key={i} className="bank-row">
              <span className="ico"><Icon name={e.amount >= 0 ? 'cash' : 'briefcase'} size={16} /></span>
              <span style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}>
                <strong style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.who}</strong>
                <span style={{ fontSize: 12, color: 'var(--muted)' }}>{e.reason}{e.note ? ` · ${e.note}` : ''} · {when(e.at)}</span>
              </span>
              <strong className="num" style={{ color: e.amount >= 0 ? 'var(--ok)' : 'var(--text)', whiteSpace: 'nowrap' }}>{e.amount >= 0 ? '+' : '−'}{money(Math.abs(e.amount))}</strong>
            </div>
          ))}
        </div>
      </section>
    </div>
  );
}
