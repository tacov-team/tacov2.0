import { createRoot } from 'react-dom/client';
import { App } from './App';
import './theme.css';
import { inGame } from './nui';

createRoot(document.getElementById('root')!).render(<App />);

// Vorschau im Browser: Beispieldaten, damit man das HUD ohne Spiel sieht
if (!inGame) {
  const post = (action: string, data?: unknown) => window.postMessage({ action, data }, '*');
  setTimeout(() => {
    post('hud', { visible: true, health: 86, armor: 0, hunger: 64, thirst: 75, fitness: 48, cash: 2340, black: 850, bank: 14820, serverId: 47,
      street: 'Vespucci Boulevard', area: 'Little Seoul', weight: 24.6, maxWeight: 30, name: 'Diego Alvarez', level: 7, levelProgress: 0.62, status: 'Probezeit', faction: 'LSPD · Officer · Rang 4' });
    post('notify', { kind: 'success', title: 'Auftrag abgeschlossen', text: '+2.000 $ und 20 XP aufs Konto' });
    post('notify', { kind: 'warn', title: 'Tank fast leer', text: 'Nächste Tankstelle: Grove Street' });
  }, 300);
  window.addEventListener('keydown', (e) => {
    if (e.key === 't' || e.key === 'T') post('open', { view: 'console', data: { history: ['support Hilfe bitte'], commands: [
      { name: 'support', usage: 'support <Text>', help: 'Ticket an das Team' },
      { name: 'ort', usage: 'ort setzen <Name> <Art>', help: 'Ort an deine Position setzen', staff: true },
    ] } });
    if (e.key === 'c') post('open', { view: 'characters', data: { maxSlots: 2, secondSlotLevel: 15, maxLevel: 12, staffOnline: 3, characters: [
      { id: 1, slot: 1, first_name: 'Jonas', last_name: 'Brenner', birth_date: '1990-01-01', playtime_seconds: 43000, level_cache: 12, faction: 'lspd', immigrated_at: '2026-11-01' },
    ] } });
  });
}
