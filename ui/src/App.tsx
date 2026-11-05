import { useEffect } from 'react';
import { StoreProvider, useStore } from './store';
import { GradientDefs } from './components/Ring';
import { Hud } from './views/Hud';
import { Toasts } from './views/Toasts';
import { Console } from './views/Console';
import { Characters } from './views/Characters';
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
      if (e.key === 'Escape' && v && v.name !== 'console') { dispatch({ type: 'close' }); nui('close'); }
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
