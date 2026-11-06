// Linien-Icons aus den Design-Boards (24er Raster, Strich 2.2)
import type { ReactElement } from 'react';
const paths: Record<string, string> = {
  heart: 'M12 20s-8-5-8-11a4.5 4.5 0 0 1 8-2.8A4.5 4.5 0 0 1 20 9c0 6-8 11-8 11z',
  shield: 'M12 3l7 3v5c0 5-3 8.5-7 10-4-1.5-7-5-7-10V6z',
  food: 'M4 10h16a8 8 0 0 0-16 0zM4 14h16M5 17h14a2 2 0 0 1-2 3H7a2 2 0 0 1-2-3z',
  drop: 'M12 3c3.5 4.5 6 7.7 6 11a6 6 0 0 1-12 0c0-3.3 2.5-6.5 6-11z',
  fitness: 'M3 10v4M6 7v10M18 7v10M21 10v4M6 12h12',
  clock: 'M12 7v5l3 2',
  pin: 'M12 21s-6-5.5-6-10.5a6 6 0 0 1 12 0C18 15.5 12 21 12 21z',
  briefcase: 'M9 8V5h6v3M3 13h18',
  check: 'M5 12.5l4.5 4.5L19 7.5',
  info: 'M12 11v5M12 8h.01',
  warn: 'M12 3l10 18H2zM12 10v4M12 17h.01',
  x: 'M6 6l12 12M18 6L6 18',
  plus: 'M12 5v14M5 12h14',
  home: 'M3 11l9-7 9 7v9H3zM10 20v-6h4v6',
  mic: 'M5 11a7 7 0 0 0 14 0M12 18v3',
  radio: 'M10 7V2M10 12h4M10 16h4',
  user: 'M4 21a8 8 0 0 1 16 0',
  bag: 'M6 8h12l1 13H5zM9 8V6a3 3 0 0 1 6 0v2',
  cash: 'M3 7h18v10H3zM12 9.5a2.5 2.5 0 1 0 0 5a2.5 2.5 0 1 0 0-5M6 12h.01M18 12h.01',
  doc: 'M7 3h7l5 5v13H7zM14 3v5h5M10 13h6M10 17h6',
  tool: 'M14 4l6 6-9 9H5v-6zM12 6l6 6',
  box: 'M3 8l9-5 9 5v8l-9 5-9-5zM3 8l9 5 9-5M12 13v8',
  leaf: 'M4 20C8 8 14 4 20 4c0 8-4 14-12 15-1 0-3 0-4 1',
  gun: 'M3 8h17v4h-6l-2 6H8l2-6H3zM17 12v3',
  ammo: 'M8 3h8v5l-2 3v10H10V11L8 8z',
  fish: 'M3 12c3-4 7-6 12-6l6 6-6 6c-5 0-9-2-12-6zM15 12h.01',
  ring: 'M12 9a6 6 0 1 0 0 12a6 6 0 1 0 0-12zM9 6l3-3 3 3',
  gift: 'M3 11h18v3H3zM5 14v7h14v-7M12 11v10M12 11c-3 0-5-1-5-3s3-3 5 0c2-3 5-3 5 0s-2 3-5 3',
  id: 'M3 6h18v12H3zM7 10a2 2 0 1 0 0 4a2 2 0 1 0 0-4M13 10h5M13 14h5',
  hands: 'M8 21V9M8 9a2 2 0 1 1 4 0v3a2 2 0 1 1 4 0v1M16 21V13M12 12v9',
  // V4-Ergänzungen
  fuel: 'M5 21V5a2 2 0 0 1 2-2h6a2 2 0 0 1 2 2v16M5 21h10M7 7h6v4H7zM15 10h2a2 2 0 0 1 2 2v5a1.5 1.5 0 0 0 3 0V9l-3-3',
  engine: 'M4 10h3V8h4V6h4v2h3v9h-3v2H7v-2H4zM2 12v4M22 11v6',
  lock: 'M5 11h14v10H5zM8 11V8a4 4 0 0 1 8 0v3M12 15v2',
  card: 'M3 6h18v12H3zM3 10h18M7 15h4',
  list: 'M9 6h12M9 12h12M9 18h12M4 6h.01M4 12h.01M4 18h.01',
  key: 'M14 4a5 5 0 1 0 0 10a5 5 0 1 0 0-10zM10 13l-7 7M6 17l2 2M3 20l2 2',
  door: 'M5 3h14v18H5zM15 12h.01M9 21V3',
  trunk: 'M3 10l3-5h12l3 5v9H3zM3 10h18M7 19v2M17 19v2M9 14h6',
  speed: 'M4 16a8 8 0 1 1 16 0M12 16l4-6M12 16h.01',
  group: 'M9 7a3 3 0 1 0 0 6a3 3 0 1 0 0-6zM3 21a6 6 0 0 1 12 0M16 4a3 3 0 0 1 0 6M21 21a6 6 0 0 0-4-5.6',
  search: 'M10 4a6 6 0 1 0 0 12a6 6 0 1 0 0-12zM20 20l-5.5-5.5',
  play: 'M7 4l13 8-13 8z',
  back: 'M15 5l-7 7 7 7',
  next: 'M9 5l7 7-7 7',
  book: 'M4 4h7a3 3 0 0 1 3 3v13a2 2 0 0 0-2-2H4zM20 4h-7a3 3 0 0 0-3 3v13a2 2 0 0 1 2-2h8z',
  phone: 'M7 2h10a1 1 0 0 1 1 1v18a1 1 0 0 1-1 1H7a1 1 0 0 1-1-1V3a1 1 0 0 1 1-1zM11 18h2',
  car: 'M5 11l2-5h10l2 5M3 11h18v6H3zM6 17v2M18 17v2M7 14h.01M17 14h.01',
  star: 'M12 3l2.7 5.8 6.3.8-4.6 4.4 1.2 6.3L12 17.3 6.4 20.3l1.2-6.3L3 9.6l6.3-.8z',
  wrench: 'M14 4a5 5 0 0 0 6 6L9 21a2 2 0 0 1-3-3L17 7a5 5 0 0 0-3-3z',
  settings: 'M12 8a4 4 0 1 0 0 8a4 4 0 1 0 0-8zM12 2v3M12 19v3M2 12h3M19 12h3M4.9 4.9l2.1 2.1M17 17l2.1 2.1M4.9 19.1L7 17M17 7l2.1-2.1',
};

const extra: Record<string, ReactElement> = {
  clock: <circle cx="12" cy="12" r="9" />,
  pin: <circle cx="12" cy="10.5" r="2" />,
  briefcase: <rect x="3" y="8" width="18" height="12" rx="2" />,
  info: <circle cx="12" cy="12" r="9" />,
  mic: <rect x="9" y="3" width="6" height="11" rx="3" />,
  radio: <rect x="7" y="7" width="10" height="15" rx="2" />,
  user: <circle cx="12" cy="8" r="4" />,
};

export function Icon({ name, size = 22, stroke = 2.2 }: { name: string; size?: number; stroke?: number }) {
  return (
    <svg width={size} height={size} viewBox="0 0 24 24" fill="none" stroke="currentColor" strokeWidth={stroke}
      strokeLinecap="round" strokeLinejoin="round" aria-hidden="true">
      {extra[name]}
      <path d={paths[name] ?? ''} />
    </svg>
  );
}
