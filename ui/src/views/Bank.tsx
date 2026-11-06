// Bank und Geldautomat nach Canvas „V4 · Bank“: Kontokarte, Reiter, Empfänger, Schnellbeträge, Kontoauszug.
import { useEffect, useState } from 'react';
import { nui } from '../nui';
import { Icon } from '../components/Icon';
import { Panel, PanelHead } from '../components/Panel';
import { money } from './Hud';

export type BankEntry = { at: string; amount: number; reason: string; note?: string | null; who: string };
export type BankData = { kind: 'bank' | 'atm'; title: string; account: string; balance: number; cash: number; transferLeft: number; atmMax: number; feePercent: number; feeFrom: number; statement: BankEntry[] };
type Tab = 'deposit' | 'withdraw' | 'transfer';

function when(at: string) {
  const d = new Date(at.replace(' ', 'T'));
  if (Number.isNaN(d.getTime())) return at;
  const today = new Date();
  const time = d.toLocaleTimeString('de-DE', { hour: '2-digit', minute: '2-digit' });
  if (d.toDateString() === today.toDateString()) return `heute ${time}`;
  const y = new Date(today); y.setDate(today.getDate() - 1);
  if (d.toDateString() === y.toDateString()) return `gestern ${time}`;
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
  const ok = n > 0 && n <= max && (tab !== 'transfer' || (target.trim().length >= 3 && n + fee <= data.balance));
  const submit = () => { if (!ok) return; nui('action', { view: 'bank', action: 'action', data: { action: tab, amount: n, target: target.trim(), note: note.trim() } }); setAmount(''); };
  const close = () => nui('action', { view: 'bank', action: 'close' });
  const labels: Record<Tab, string> = { deposit: 'Einzahlen', withdraw: 'Abheben', transfer: 'Überweisen' };

  return (
    <div className="center-wrap">
      <Panel style={{ width: 1120 }}>
        <PanelHead icon="card" title={data.title} info={`Konto ${data.account} · ${atm ? 'Einzahlen, Abheben' : 'Einzahlen, Abheben, Überweisen'}`} onClose={close} />
        <div className="pbody" style={{ flexDirection: 'row', gap: 30, alignItems: 'flex-start' }}>
          <div style={{ width: 520, display: 'flex', flexDirection: 'column', gap: 12 }}>
            <div className="hl" style={{ padding: 18, display: 'flex', flexDirection: 'column', gap: 4 }}>
              <span className="label">KONTOSTAND</span>
              <b className="num" style={{ fontSize: 40, fontWeight: 900, fontStyle: 'italic' }}>{money(data.balance)}</b>
              <span style={{ fontSize: 12, fontWeight: 700 }}>Bargeld {money(data.cash)}{atm ? ` · Automat max. ${money(data.atmMax)} je Abhebung` : ` · Überweisung heute noch ${money(data.transferLeft)}`}</span>
            </div>
            <div className="seg" style={{ width: '100%' }}>
              {(['deposit', 'withdraw', 'transfer'] as Tab[]).filter((t) => !(atm && t === 'transfer')).map((t) => <button key={t} className={tab === t ? 'on' : ''} style={{ flex: 1, justifyContent: 'center' }} onClick={() => { setTab(t); setAmount(''); }}>{labels[t]}</button>)}
              {!atm && <button disabled style={{ flex: 1, justifyContent: 'center' }}>Rechnungen</button>}
            </div>
            {tab === 'transfer' && <label className="field"><span>Empfänger · Name oder Kontonummer</span><input className="input" placeholder="Vorname Nachname oder LS-000000" value={target} onChange={(e) => setTarget(e.target.value)} /></label>}
            <label className="field"><span>Betrag</span><input className="input num" style={{ fontSize: 18, fontWeight: 800 }} inputMode="numeric" placeholder="0" value={amount} onChange={(e) => setAmount(e.target.value)} onKeyDown={(e) => { if (e.key === 'Enter') submit(); }} /></label>
            {tab === 'transfer' && <label className="field"><span>Verwendungszweck</span><input className="input" placeholder="optional" maxLength={64} value={note} onChange={(e) => setNote(e.target.value)} /></label>}
            <div style={{ display: 'flex', gap: 8 }}>
              {[100, 500, 1000].map((q) => <button key={q} className="btn sm" style={{ flex: 1 }} onClick={() => setAmount(String(Math.min(q, max)))}>{q.toLocaleString('de-DE')}</button>)}
              <button className="btn sm" style={{ flex: 1 }} onClick={() => setAmount(String(max))}>Alles</button>
            </div>
            <button className="btn primary" style={{ height: 48 }} disabled={!ok} onClick={submit}>{labels[tab]}{n > 0 ? ` · ${money(n)}` : ''}{fee > 0 ? ` (+ ${money(fee)} Gebühr)` : ''}</button>
            {n > max && <span style={{ fontSize: 12, color: 'var(--danger)' }}>Höchstens {money(max)} möglich.</span>}
          </div>
          <div style={{ width: 530, display: 'flex', flexDirection: 'column', gap: 10 }}>
            <div className="sect"><b>Letzte Buchungen</b><span className="sub">Kontoauszug</span></div>
            <div className="bank-list">
              {data.statement.length === 0 && <span className="sub">Noch keine Buchungen.</span>}
              {data.statement.map((e, i) => (
                <div key={i} className="row" style={{ minHeight: 52 }}>
                  <span className="ic"><Icon name={e.amount >= 0 ? 'cash' : 'briefcase'} size={14} /></span>
                  <span style={{ display: 'flex', flexDirection: 'column', minWidth: 0 }}><span style={{ whiteSpace: 'nowrap', overflow: 'hidden', textOverflow: 'ellipsis' }}>{e.who}</span><span className="sub">{e.reason}{e.note ? ` · ${e.note}` : ''} · {when(e.at)}</span></span>
                  <b className="num" style={{ marginLeft: 'auto', color: e.amount >= 0 ? 'var(--ok)' : 'var(--text)', whiteSpace: 'nowrap' }}>{e.amount >= 0 ? '+' : '−'}{money(Math.abs(e.amount))}</b>
                </div>
              ))}
            </div>
          </div>
        </div>
      </Panel>
    </div>
  );
}
