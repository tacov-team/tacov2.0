// Brücke zwischen NUI und Lua-Client. Außerhalb von FiveM (Browser-Vorschau) laufen Aufrufe ins Leere.
import { useEffect } from 'react';

declare global {
  interface Window { GetParentResourceName?: () => string; invokeNative?: unknown }
}

export const inGame = typeof window.GetParentResourceName === 'function';

export async function nui<T = unknown>(name: string, data: unknown = {}): Promise<T | null> {
  if (!inGame) { console.log('[nui]', name, data); return null; }
  const res = await fetch(`https://${window.GetParentResourceName!()}/${name}`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json; charset=UTF-8' },
    body: JSON.stringify(data),
  });
  try { return (await res.json()) as T; } catch { return null; }
}

export type NuiMessage = { action: string; data?: unknown };

export function useNuiEvent<T = unknown>(action: string, handler: (data: T) => void) {
  useEffect(() => {
    const listener = (e: MessageEvent<NuiMessage>) => {
      if (e.data && e.data.action === action) handler(e.data.data as T);
    };
    window.addEventListener('message', listener);
    return () => window.removeEventListener('message', listener);
  }, [action, handler]);
}
