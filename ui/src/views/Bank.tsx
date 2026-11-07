// Bank und Geldautomat: Kontokarte, Reiter Einzahlen/Abheben/Überweisen, Schnellbeträge, Kontoauszug rechts.
import { useEffect, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { Panel } from '../components/Panel';
import { money } from './Hud';

export type BankEntry = { at: string; amount: number; reason: string; note?: string | null; who: string };
export type BankData = { kind: 'bank' | 'atm'; title: string; account: string; balance: number; cash: number; transferLeft: number; atmMax: number; feePercent: number; feeFrom: number; statement: BankEntry[]; noLimits?: boolean };
type Tab = 'deposit' | 'withdraw' | 'transfer';

function when(at: string) {
  const d = new Date(at.replace(' ', 'T'));
  if (Number.isNaN(d.getTime())) return at;
  return d.toLocaleString('de-DE', { day: '2-digit', month: '2-digit', hour: '2-digit', minute: '2-digit' });
}

export function Bank({ data }: { data: BankData }) {
  const atm = data.kind === 'atm';
  const [tab, setTab] = useState<Tab>(atm ? 'withdraw' : 'deposit');
  const [amount, setAmount] = useState('');
  const [target, setTarget] = useState('');
  const [note, setNote] = useState('');
  useEffect(() => { if (atm && tab === 'transfer') setTab('withdraw'); }, [atm, tab]);

  const n = Math.max(0, Math.floor(Number(amount.replace(/[^\d]/g, '')) || 0));
  const max = tab === 'deposit' ? data.cash : tab === 'withdraw' ? (atm && data.atmMax > 0 ? Math.min(data.balance, data.atmMax) : data.balance) : (data.transferLeft > 0 ? Math.min(data.balance, data.transferLeft) : data.balance);
  const fee = tab === 'transfer' && n >= data.feeFrom ? Math.floor((n * data.feePercent) / 100) : 0;
  const ok = n > 0 && n <= max && (tab !== 'transfer' || (target.trim().length >= 3 && n + fee <= data.balance));
  const submit = () => { if (!ok) return; nui('action', { view: 'bank', action: 'action', data: { action: tab, amount: n, target: target.trim(), note: note.trim() } }); setAmount(''); };
  const close = () => nui('action', { view: 'bank', action: 'close' });
  const labels: Record<Tab, string> = { deposit: 'Einzahlen', withdraw: 'Abheben', transfer: 'Überweisen' };

  return (
    <div className="center bank">
      <Panel icon="card" title={data.title} sub={`Konto ${data.account}`} onClose={close}>
        <div className="cols">
          <div className="col">
            <div className="account">
              <span className="lbl">Kontostand</span>
              <span className="money-big num">{money(data.balance)}</span>
              <span style={{ fontSize: '0.75rem', opacity: 0.9 }}>Bargeld {money(data.cash)}</span>
            </div>
            <div className="tabs">
              {(['deposit', 'withdraw', 'transfer'] as Tab[]).filter((t) => !(atm && t === 'transfer')).map((t) => <button key={t} className={tab === t ? 'on' : ''} onClick={() => { setTab(t); setAmount(''); }}>{labels[t]}</button>)}
            </div>
            {tab === 'transfer' && <label className="field">Empfänger<input className="input" placeholder="Vorname Nachname oder Kontonummer" value={target} onChange={(e) => setTarget(e.target.value)} /></label>}
            <label className="field">Betrag<input className="input num" style={{ fontSize: '1.125rem', fontWeight: 700 }} inputMode="numeric" placeholder="0" value={amount} onChange={(e) => setAmount(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') submit(); }} /></label>
            {tab === 'transfer' && <label className="field">Verwendungszweck<input className="input" placeholder="optional" maxLength={64} value={note} onChange={(e) => setNote(e.target.value)} /></label>}
            <div className="quick">
              {[100, 500, 1000, 5000].map((q) => <button key={q} className="btn sm" onClick={() => setAmount(String(Math.min(q, max)))}>{q.toLocaleString('de-DE')}</button>)}
              <button className="btn sm" onClick={() => setAmount(String(max))}>Alles</button>
            </div>
            <button className="btn primary" disabled={!ok} onClick={submit}>{labels[tab]}{n > 0 ? ` · ${money(n)}` : ''}{fee > 0 ? ` (+ ${money(fee)} Gebühr)` : ''}</button>
            {n > max && <span style={{ fontSize: '0.75rem', color: 'var(--danger)' }}>Höchstens {money(max)} möglich.</span>}
          </div>
          <div className="col">
            <b style={{ fontSize: '0.8125rem' }}>Letzte Buchungen</b>
            <div className="statement">
              {data.statement.length === 0 && <span className="muted">Noch keine Buchungen.</span>}
              {data.statement.map((e, i) => (
                <div key={i} className="row">
                  <Icon name={e.amount >= 0 ? 'plus' : 'cash'} size={14} />
                  <div className="col grow" style={{ gap: 0 }}><span className="ellipsis">{e.who}</span><span className="sub">{e.reason}{e.note ? ` · ${e.note}` : ''} · {when(e.at)}</span></div>
                  <b className="num" style={{ color: e.amount >= 0 ? 'var(--ok)' : 'var(--text)', whiteSpace: 'nowrap' }}>{e.amount >= 0 ? '+' : '−'}{money(Math.abs(e.amount))}</b>
                </div>
              ))}
            </div>
          </div>
        </div>
      </Panel>
    </div>
  );
}
