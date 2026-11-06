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
    post('hint', { key: 'E', text: 'Geldautomat' });
  }, 300);
  window.addEventListener('keydown', (e) => {
    if (e.key === 't' || e.key === 'T') post('open', { view: 'console', data: { history: ['support Hilfe bitte'], commands: [
      { name: 'support', usage: 'support <Text>', help: 'Ticket an das Team' },
      { name: 'ort', usage: 'ort setzen <Name> <Art>', help: 'Ort an deine Position setzen', staff: true },
    ] } });
    if (e.key === 'i') post('open', { view: 'inventory', data: { target: 12, self: { kind: 'character', id: 1, title: 'Taschen', name: 'Diego Alvarez', cash: 2340, black: 850, weight: 4.6, maxWeight: 30, items: [
      { slot: 1, item: 'cash', amount: 2340, label: 'Bargeld', category: 'money', weight: 0, usable: false, money: true },
      { slot: 2, item: 'black_cash', amount: 850, label: 'Schwarzgeld', category: 'money', weight: 0.0001, usable: false, money: true },
      { slot: 3, item: 'water', amount: 3, label: 'Wasser', category: 'drink', weight: 0.5, usable: true, money: false },
      { slot: 4, item: 'sandwich', amount: 2, label: 'Sandwich', category: 'food', weight: 0.3, usable: true, money: false },
      { slot: 6, item: 'id_card', amount: 1, label: 'Ausweis', category: 'document', weight: 0, usable: true, money: false },
      { slot: 7, item: 'city_map', amount: 1, label: 'Stadtplan', category: 'document', weight: 0.1, usable: true, money: false },
      { slot: 9, item: 'first_aid', amount: 4, label: 'Erste-Hilfe-Kit', category: 'daily', weight: 0.5, usable: true, money: false },
    ] }, other: { kind: 'drop', id: 1, title: 'Boden', subtitle: 'Ablage verfällt in 14 Minuten', weight: 1.1, maxWeight: 100, items: [
      { slot: 1, item: 'rope', amount: 2, label: 'Seil', category: 'tool', weight: 0.5, usable: false, money: false },
    ] } } });
    if (e.key === 'x') post('open', { view: 'wheel', data: { center: { kind: 'Fahrzeug', title: 'Sultan RS', sub: 'LS 4721' }, entries: [
      { id: 'pickup', label: 'Aufheben', icon: 'bag', order: 5 }, { id: 'inventory', label: 'Inventar', icon: 'bag', order: 10 },
      { id: 'give', label: 'Geben', icon: 'gift', order: 20 }, { id: 'show_id', label: 'Ausweis', icon: 'id', order: 30 },
      { id: 'handsup', label: 'Hände hoch', icon: 'hands', order: 90 },
    ] } });
    if (e.key === 'b') post('open', { view: 'bank', data: { kind: 'bank', title: 'Fleeca Bank', account: 'LS-004277', balance: 61300, cash: 4820, transferLeft: 50000, atmMax: 5000, feePercent: 1, feeFrom: 10000, statement: [
      { at: '2026-11-06 21:00:00', amount: 13400, reason: 'Lohn', who: 'Payday' },
      { at: '2026-11-06 20:12:00', amount: -22000, reason: 'Überweisung', note: 'Blista', who: 'Mara Kowalski' },
      { at: '2026-11-05 18:40:00', amount: -80, reason: 'Einkauf', who: 'Tankstelle Grove' },
      { at: '2026-11-05 12:00:00', amount: 5000, reason: 'Startgeld', who: '—' },
    ] } });
    if (e.key === 's') post('open', { view: 'shop', data: { shop: 'supermarket', type: '24/7', name: '24/7 Strawberry', cash: 4820, bank: 61300, taxPercent: 5, weight: 4.6, maxWeight: 30, items: [
      { item: 'water', label: 'Wasser', category: 'drink', price: 3, weight: 0.5 }, { item: 'sandwich', label: 'Sandwich', category: 'food', price: 8, weight: 0.3 },
      { item: 'burger', label: 'Burger', category: 'food', price: 15, weight: 0.3 }, { item: 'energy_drink', label: 'Energydrink', category: 'drink', price: 6, weight: 0.3 },
      { item: 'beer', label: 'Bier', category: 'drink', price: 5, weight: 0.5 }, { item: 'spirits', label: 'Schnaps', category: 'drink', price: 12, weight: 0.5 },
      { item: 'cigarettes', label: 'Zigaretten', category: 'daily', price: 10, weight: 0.1 }, { item: 'radio', label: 'Funkgerät', category: 'daily', price: 250, weight: 0.4 },
      { item: 'weapon_knife', label: 'Messer', category: 'weapon', price: 80, weight: 0.5 },
    ] } });
    if (e.key === 'c') post('open', { view: 'characters', data: { maxSlots: 2, secondSlotLevel: 15, maxLevel: 12, staffOnline: 3, characters: [
      { id: 1, slot: 1, first_name: 'Jonas', last_name: 'Brenner', birth_date: '1990-01-01', playtime_seconds: 43000, level_cache: 12, faction: 'lspd', immigrated_at: '2026-11-01' },
    ] } });
  });
}
