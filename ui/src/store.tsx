// Zentraler Zustand der Oberfläche. Der Lua-Client schickt Nachrichten (open/close/hud/...), die hier landen.
import { createContext, useCallback, useContext, useMemo, useReducer, type ReactNode } from 'react';
import { useNuiEvent } from './nui';

export type Toast = { id: number; kind: 'success' | 'info' | 'warn' | 'error'; title: string; text?: string };

export type HudData = {
  health: number; armor: number; hunger: number; thirst: number; fitness: number;
  cash: number; black: number; bank: number; serverId: number;
  street: string; area: string; weight: number; maxWeight: number;
  name: string; level: number; levelProgress: number; status: string; faction: string;
  visible: boolean;
  minimap?: { x: number; y: number; w: number; h: number }; // Bruchteile des Bildschirms, von Lua
};

export type CharacterRow = {
  id: number; slot: number; first_name: string; last_name: string; birth_date: string;
  playtime_seconds: number; level_cache: number; faction: string | null; immigrated_at: string | null;
};
export type CharactersData = { characters: CharacterRow[]; maxSlots: number; secondSlotLevel: number; maxLevel?: number; staffOnline?: number };

export type CommandInfo = { name: string; usage: string; help: string; staff?: boolean };

type View = null | { name: 'characters'; data: CharactersData } | { name: 'console'; data: { commands: CommandInfo[]; history: string[] } };

type State = { view: View; hud: HudData; toasts: Toast[]; role: string };

type Action =
  | { type: 'open'; view: View }
  | { type: 'close' }
  | { type: 'hud'; data: Partial<HudData> }
  | { type: 'toast'; toast: Toast }
  | { type: 'toastRemove'; id: number }
  | { type: 'role'; role: string };

const initialHud: HudData = {
  health: 100, armor: 0, hunger: 100, thirst: 100, fitness: 0,
  cash: 0, black: 0, bank: 0, serverId: 0, street: '', area: '', weight: 0, maxWeight: 30,
  name: '', level: 1, levelProgress: 0, status: '', faction: '', visible: false,
};

function reducer(state: State, a: Action): State {
  switch (a.type) {
    case 'open': return { ...state, view: a.view };
    case 'close': return { ...state, view: null };
    case 'hud': return { ...state, hud: { ...state.hud, ...a.data } };
    case 'toast': return { ...state, toasts: [...state.toasts.slice(-5), a.toast] };
    case 'toastRemove': return { ...state, toasts: state.toasts.filter((t) => t.id !== a.id) };
    case 'role': return { ...state, role: a.role };
  }
}

const Ctx = createContext<{ state: State; dispatch: (a: Action) => void } | null>(null);

let toastId = 0;

export function StoreProvider({ children }: { children: ReactNode }) {
  const [state, dispatch] = useReducer(reducer, { view: null, hud: initialHud, toasts: [], role: 'player' });

  useNuiEvent<{ view: string; data: unknown }>('open', useCallback((d) => {
    dispatch({ type: 'open', view: { name: d.view, data: d.data } as View });
  }, []));
  useNuiEvent('close', useCallback(() => dispatch({ type: 'close' }), []));
  useNuiEvent<Partial<HudData>>('hud', useCallback((d) => dispatch({ type: 'hud', data: d }), []));
  useNuiEvent<number>('bank', useCallback((bank) => dispatch({ type: 'hud', data: { bank } }), []));
  useNuiEvent<string>('role', useCallback((role) => dispatch({ type: 'role', role }), []));
  useNuiEvent<{ kind: Toast['kind']; text: string; title?: string }>('notify', useCallback((d) => {
    const id = ++toastId;
    const titles = { success: 'Erledigt', info: 'Hinweis', warn: 'Achtung', error: 'Fehler' };
    dispatch({ type: 'toast', toast: { id, kind: d.kind, title: d.title ?? titles[d.kind] ?? 'Hinweis', text: d.text } });
    setTimeout(() => dispatch({ type: 'toastRemove', id }), 6000);
  }, []));

  const value = useMemo(() => ({ state, dispatch }), [state]);
  return <Ctx.Provider value={value}>{children}</Ctx.Provider>;
}

export function useStore() {
  const ctx = useContext(Ctx);
  if (!ctx) throw new Error('StoreProvider fehlt');
  return ctx;
}
