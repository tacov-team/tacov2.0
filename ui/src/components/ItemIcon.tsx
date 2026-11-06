// Item-Bild: assets/items/<item>.png (Vorrang) oder .svg, sonst Kategorie-Symbol. Der Build trägt ein, welche Datei es je Item gibt.
import { Icon } from './Icon';

declare const __ITEM_ICONS__: Record<string, 'png' | 'svg'>;
const index: Record<string, 'png' | 'svg'> = typeof __ITEM_ICONS__ === 'object' ? __ITEM_ICONS__ : {};

export const catIcon: Record<string, string> = {
  money: 'cash', document: 'doc', daily: 'bag', tool: 'tool', material: 'box', drug: 'leaf', weapon: 'gun', ammo: 'ammo',
  armor: 'shield', food: 'food', drink: 'drop', leisure: 'fish', jewelry: 'ring', loot: 'box',
};

export function ItemIcon({ item, category, size = 34 }: { item: string; category: string; size?: number }) {
  const ext = index[item];
  if (ext) return <img src={`assets/items/${item}.${ext}`} width={size} height={size} alt="" draggable={false} style={{ display: 'block', objectFit: 'contain' }} />;
  return <Icon name={catIcon[category] ?? 'box'} size={size} stroke={1.8} />;
}
