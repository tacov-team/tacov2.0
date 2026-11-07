import { useEffect } from 'react';
import { StoreProvider, useStore } from './store';
import { GradientDefs } from './components/Ring';
import { Hud } from './views/Hud';
import { Toasts } from './views/Toasts';
import { Console } from './views/Console';
import { Characters } from './views/Characters';
import { Inventory } from './views/Inventory';
import { Wheel } from './views/Wheel';
import { Bank } from './views/Bank';
import { Shop } from './views/Shop';
import { Menu } from './views/Menu';
import { Garage } from './views/Garage';
import { inGame, nui } from './nui';

function Views() {
  const { state, dispatch } = useStore();
  const v = state.view;

  // Vollbild-Ansichten dunkeln den Hintergrund ab (außerhalb des Spiels: Szene als Vorschau)
  useEffect(() => {
    document.body.classList.toggle('scene', !inGame || v?.name === 'characters');
  }, [v]);

  useEffect(() => {
    const onKey = (e: KeyboardEvent) => {
      if (e.key === 'Escape' && v && v.name !== 'console') {
        if (v.name === 'inventory') { nui('action', { view: 'inventory', action: 'close' }); return; }
        if (v.name === 'wheel') { nui('action', { view: 'wheel', action: 'close' }); return; }
        if (v.name === 'bank') { nui('action', { view: 'bank', action: 'close' }); return; }
        if (v.name === 'shop') { nui('action', { view: 'shop', action: 'close' }); return; }
        if (v.name === 'menu') { return; } // Menü behandelt Escape selbst
        if (v.name === 'garage') { nui('action', { view: 'garage', action: 'close', data: {} }); return; }
        dispatch({ type: 'close' }); nui('close');
      }
    };
    window.addEventListener('keydown', onKey);
    return () => window.removeEventListener('keydown', onKey);
  }, [v, dispatch]);

  return (
    <>
      <GradientDefs />
      <Hud />
      <Toasts />
      {v?.name === 'characters' && <Characters key={v.data.characters.map((c) => c.id).join(',')} data={v.data} />}
      {v?.name === 'console' && <Console commands={v.data.commands} history={v.data.history} />}
      {v?.name === 'inventory' && <Inventory data={v.data} />}
      {v?.name === 'wheel' && <Wheel data={v.data} />}
      {v?.name === 'bank' && <Bank data={v.data} />}
      {v?.name === 'shop' && <Shop data={v.data} />}
      {v?.name === 'menu' && <Menu data={v.data} />}
      {v?.name === 'garage' && <Garage data={v.data} />}
      {!v && state.hint && <div className="hint"><span className="ring">{state.hint.key}</span><span className="txt">{state.hint.text}</span></div>}
    </>
  );
}

export function App() {
  return (
    <StoreProvider>
      <Views />
    </StoreProvider>
  );
}
