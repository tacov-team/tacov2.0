#!/usr/bin/env python3
"""Erzeugt die SVG-Linien-Icons je Item (24er Raster, Gold auf transparent) nach ui/public/items/<item>.svg.
Ein PNG mit gleichem Namen (ui/public/items/<item>.png) hat beim Build Vorrang. Aufruf: python3 ui/tools/make-item-icons.py"""
import os

HERE = os.path.dirname(os.path.abspath(__file__))
OUT = os.path.join(HERE, '..', 'public', 'items')

GOLD = '#FFD54A'
ORANGE = '#FF9A1F'

# Jedes Icon: Liste von Elementen. 'p' = Pfad (Hauptfarbe), 'a' = Akzentpfad (Orange), 'c' = Kreis (cx,cy,r), 'f' = gefüllter Pfad
ICONS = {
    # Geld
    'cash':        [('p', 'M3 7h18v10H3z'), ('c', (12, 12, 2.6)), ('a', 'M6 12h.01M18 12h.01')],
    'black_cash':  [('p', 'M3 7h18v10H3z'), ('c', (12, 12, 2.6)), ('a', 'M5 5l14 14')],
    'cashbox':     [('p', 'M4 8h16v11H4zM4 8l2-3h12l2 3'), ('a', 'M10 13h4')],
    'gold_bar':    [('p', 'M4 16l2-7h12l2 7zM4 16h16'), ('a', 'M9 12h6')],
    'gold_crate':  [('p', 'M3 9h18v10H3zM3 9l3-4h12l3 4'), ('a', 'M8 13h8M8 16h8')],
    'jewel_bag':   [('p', 'M8 8h8l3 10a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2zM9 8l1-4h4l1 4'), ('a', 'M12 12l2 2-2 2-2-2z')],
    'luxury_watch':[('c', (12, 12, 5)), ('p', 'M9 7l1-4h4l1 4M9 17l1 4h4l1-4'), ('a', 'M12 10v2l1.5 1')],
    # Dokumente
    'id_card':     [('p', 'M3 6h18v12H3z'), ('c', (8, 11, 2)), ('a', 'M13 10h5M13 14h5M5 16h6')],
    'passport':    [('p', 'M6 3h12v18H6z'), ('c', (12, 10, 3)), ('a', 'M9 17h6')],
    'license_a':   [('p', 'M3 6h18v12H3z'), ('a', 'M8 15l2-6h1l2 6M8.8 13h3.4')],
    'license_b':   [('p', 'M3 6h18v12H3z'), ('a', 'M9 9h3a1.5 1.5 0 0 1 0 3H9zM9 12h3.5a1.5 1.5 0 0 1 0 3H9z')],
    'license_c':   [('p', 'M3 6h18v12H3z'), ('a', 'M14 10a3 3 0 1 0 0 4')],
    'license_boat':[('p', 'M3 6h18v12H3z'), ('a', 'M7 14h10l-2 2H9zM12 8v6M12 8l4 4')],
    'license_air': [('p', 'M3 6h18v12H3z'), ('a', 'M6 13l12-3-3-3M14 10l-2 5-3 1')],
    'license_gun': [('p', 'M3 6h18v12H3z'), ('a', 'M7 10h9v2h-3l-1 3h-2l1-3H7z')],
    'bus_ticket':  [('p', 'M4 7h16v4a2 2 0 0 0 0 4v2H4v-2a2 2 0 0 0 0-4z'), ('a', 'M10 7v10')],
    'city_map':    [('p', 'M3 6l6-2 6 2 6-2v14l-6 2-6-2-6 2zM9 4v14M15 6v14'), ('a', 'M12 10l1.5 2.5L12 15l-1.5-2.5z')],
    # Alltag
    'phone':       [('p', 'M7 3h10v18H7z'), ('a', 'M10 18h4')],
    'first_aid':   [('p', 'M3 8h18v11H3zM9 8V5h6v3'), ('a', 'M12 11v5M9.5 13.5h5')],
    'water':       [('p', 'M9 3h6v3l1 2v12a1 1 0 0 1-1 1H9a1 1 0 0 1-1-1V8l1-2z'), ('a', 'M10 12h4')],
    'burger':      [('p', 'M4 10h16a8 8 0 0 0-16 0zM5 17h14a2 2 0 0 1-2 3H7a2 2 0 0 1-2-3z'), ('a', 'M4 14h16')],
    'sandwich':    [('p', 'M3 9l9-5 9 5-9 5zM3 9v5l9 5 9-5V9'), ('a', 'M12 14v5')],
    'energy_drink':[('p', 'M8 5h8v16H8zM9 5V3h6v2'), ('a', 'M13 8l-3 5h4l-3 5')],
    'beer':        [('p', 'M6 7h10v13H6zM16 10h3v6h-3'), ('a', 'M9 10v7M12 10v7')],
    'spirits':     [('p', 'M10 3h4v4l3 3v10a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1V10l3-3z'), ('a', 'M9 13h6')],
    'cigarettes':  [('p', 'M3 12h16v5H3zM19 12h2v5h-2'), ('a', 'M5 14h2M3 9c1-1 0-2 1-3')],
    'vehicle_key': [('c', (8, 12, 4)), ('p', 'M12 12h9M18 12v3M15 12v2')],
    'house_key':   [('c', (8, 12, 4)), ('p', 'M12 12h9'), ('a', 'M17 12v3M20 12v2')],
    'toolbox':     [('p', 'M3 9h18v10H3zM9 9V6h6v3'), ('a', 'M3 13h18M11 12h2v3h-2z')],
    'jerrycan':    [('p', 'M6 7h11l2 2v11H5V9zM8 4h5v3'), ('a', 'M8 11h6')],
    'backpack':    [('p', 'M7 8h10a2 2 0 0 1 2 2v10H5V10a2 2 0 0 1 2-2zM9 8V5a3 3 0 0 1 6 0v3'), ('a', 'M8 14h8')],
    'radio':       [('p', 'M7 7h10v15H7zM10 7V2'), ('a', 'M10 12h4M10 16h4')],
    # Werkzeug
    'lockpick':    [('p', 'M4 18L18 4M14 4l4 4'), ('a', 'M6 20l-2-2M9 13l2 2')],
    'crowbar':     [('p', 'M5 19L17 7a2 2 0 0 1 3 3l-1 1'), ('a', 'M3 17l4 4')],
    'hammer':      [('p', 'M14 4l6 6-2 2-6-6zM12 6L4 14l2 2 8-8'), ('a', 'M4 14l6 6')],
    'rope':        [('c', (12, 12, 7)), ('a', 'M12 5c3 3 3 11 0 14M12 5c-3 3-3 11 0 14')],
    'net':         [('p', 'M4 4l16 16M4 20L20 4M12 3v18M3 12h18'), ('c', (12, 12, 8))],
    'axe':         [('p', 'M5 19L15 9M13 7l4-4 4 4-4 4a5 5 0 0 1-6 2'), ('a', 'M3 21l2-2')],
    'pickaxe':     [('p', 'M5 19L15 9M9 5c4-1 8 1 10 5M12 3c3 0 6 2 7 6')],
    'welder':      [('p', 'M4 14h8l4-4h4v6h-4l-4-4M4 14v4h4'), ('a', 'M14 6l1 2M18 4l-1 3M11 5l1 2')],
    'drill':       [('p', 'M3 9h10v6H3zM13 11h8v2h-8M6 15v5h3'), ('a', 'M4 12h8')],
    'hacking_tool':[('p', 'M3 6h18v11H3zM8 21h8'), ('a', 'M7 10l2 2-2 2M11 14h4')],
    'dynamite':    [('p', 'M4 10h12v8H4zM4 14h12'), ('a', 'M16 12c2-1 3-4 5-6M20 5l1 1')],
    # Rohstoffe
    'wood':        [('p', 'M3 9h18v6H3z'), ('c', (6, 12, 2)), ('a', 'M10 11h8M10 13h6')],
    'ore':         [('p', 'M4 16l4-9 5 3 3-4 4 10z'), ('a', 'M9 12h2M13 13h2')],
    'metal':       [('p', 'M4 15l3-6h10l3 6zM4 15h16'), ('a', 'M8 12h8')],
    'kevlar':      [('p', 'M12 3l7 3v5c0 5-3 8.5-7 10-4-1.5-7-5-7-10V6z'), ('a', 'M9 9h6M9 13h6')],
    'weapon_parts':[('p', 'M3 10h8v3H3zM13 8h8v4h-8M11 14l-2 4h4z'), ('a', 'M16 12v3')],
    'chemicals':   [('p', 'M9 3h6M10 3v6l-5 9a2 2 0 0 0 2 3h10a2 2 0 0 0 2-3l-5-9V3'), ('a', 'M8 15h8')],
    'pseudo':      [('p', 'M8 3h8v4H8zM7 7h10v13a1 1 0 0 1-1 1H8a1 1 0 0 1-1-1z'), ('a', 'M10 13h4M12 11v4')],
    'coca_leaves': [('p', 'M12 21C8 14 10 6 20 4c0 9-3 14-8 17z'), ('a', 'M12 21c1-6 3-10 7-14')],
    'mushrooms':   [('p', 'M4 11a8 6 0 0 1 16 0zM9 11v7a3 3 0 0 0 6 0v-7'), ('a', 'M8 8h.01M14 7h.01')],
    'frog':        [('p', 'M5 12a7 5 0 0 1 14 0v4H5z'), ('c', (9, 9, 1.5)), ('c', (15, 9, 1.5)), ('a', 'M6 16l-2 3M18 16l2 3')],
    'cannabis_harvest': [('p', 'M12 21V9M12 9c-4-1-6-4-6-7 3 0 6 2 6 7zM12 9c4-1 6-4 6-7-3 0-6 2-6 7zM12 15c-3 0-6-1-7-4 3 0 6 1 7 4zM12 15c3 0 6-1 7-4-3 0-6 1-7 4z')],
    # Drogen
    'cannabis':    [('p', 'M12 21V10M12 10c-3-1-5-4-5-7 3 0 5 3 5 7zM12 10c3-1 5-4 5-7-3 0-5 3-5 7zM12 15c-3 0-5-2-6-5 3 0 5 2 6 5zM12 15c3 0 5-2 6-5-3 0-5 2-6 5z')],
    'meth':        [('p', 'M9 20l-5-5 4-7 3 3zM11 11l3-8 4 5-3 7zM9 20l6-5 5 2-3 3z'), ('a', 'M8 13l2 2')],
    'cocaine':     [('p', 'M6 6h12v3l-2 11H8L6 9zM6 9h12'), ('a', 'M10 13c1-1 3-1 4 0M11 16h2')],
    'lsd':         [('p', 'M5 5h14v14H5z'), ('a', 'M5 12h14M12 5v14M8 8l2 2M14 14l2 2')],
    'frog_secret': [('p', 'M9 4h6v3l3 4v8a2 2 0 0 1-2 2H8a2 2 0 0 1-2-2v-8l3-4z'), ('a', 'M9 15c1-2 5-2 6 0')],
    # Waffen
    'weapon_pistol':    [('p', 'M3 8h17v4h-6l-2 6H8l2-6H3zM17 12v3'), ('a', 'M5 10h2')],
    'weapon_revolver':  [('p', 'M3 8h17v4h-5l-2 6H9l2-6H3z'), ('c', (9, 10, 1.6)), ('a', 'M16 12v3')],
    'weapon_rifle':     [('p', 'M2 11h16l3-2v3h-3l-1 2h-3l-1 3h-2l1-3H2z'), ('a', 'M9 8h5M13 7v2')],
    'weapon_smg':       [('p', 'M3 9h15v4h-4l-1 5h-3l1-5H3zM18 9l3-1v3'), ('a', 'M7 13v4h2')],
    'weapon_assault':   [('p', 'M2 10h17l3-2v3h-3l-1 2h-5l-1 4h-3l1-4H2zM7 8h4v2'), ('a', 'M14 13v4')],
    'weapon_pistol_il': [('p', 'M3 8h17v4h-6l-2 6H8l2-6H3zM17 12v3'), ('a', 'M4 4l16 16')],
    'weapon_knife':     [('p', 'M4 20l9-9M13 11l7-7-1 6-4 4z'), ('a', 'M4 20l2-5')],
    'ammo_pistol':      [('p', 'M9 3h6v5l-2 3v10h-2V11L9 8z'), ('a', 'M9 14h6')],
    'ammo_rifle':       [('p', 'M10 2h4v6l-1 2v12h-2V10l-1-2z'), ('a', 'M10 15h4M10 18h4')],
    'armor':            [('p', 'M12 3l7 3v5c0 5-3 8.5-7 10-4-1.5-7-5-7-10V6z'), ('a', 'M12 7v10M8 11h8')],
    # Firma, Freizeit, Schmuck
    'ingredient_meat':  [('p', 'M4 12c0-4 3-7 8-7s8 3 8 7c0 3-2 5-4 5-3 0-4-2-7-2-3 0-5-1-5-3z'), ('a', 'M9 11c1-1 3-1 4 0')],
    'ingredient_bun':   [('p', 'M4 13c0-5 4-8 8-8s8 3 8 8c0 2-1 3-3 3H7c-2 0-3-1-3-3z'), ('a', 'M9 10h.01M12 8h.01M15 10h.01')],
    'ingredient_salad': [('p', 'M4 14c0-3 2-4 4-3 0-3 3-5 5-3 2-2 6-1 6 2 2 0 3 2 2 4H4z'), ('a', 'M6 17h12')],
    'fishing_rod':      [('p', 'M4 20L18 4M18 4c2 4 1 8-2 11'), ('c', (7, 17, 2)), ('a', 'M16 15v4')],
    'bait':             [('p', 'M5 13c2-5 6-6 9-4 3-2 5 0 5 2s-2 4-5 2c-3 2-7 1-9 0z'), ('a', 'M8 11h.01')],
    'fish':             [('p', 'M3 12c3-4 7-6 12-6l6 6-6 6c-5 0-9-2-12-6z'), ('c', (15, 11, 1)), ('a', 'M9 9c1 2 1 4 0 6')],
    'shell':            [('p', 'M4 15a8 8 0 0 1 16 0zM4 15h16'), ('a', 'M8 15c0-3 1-5 4-7M16 15c0-3-1-5-4-7M12 8v7')],
    'pearl':            [('c', (12, 13, 5)), ('p', 'M4 16a8 5 0 0 0 16 0')],
    'ring':             [('c', (12, 14, 5.5)), ('p', 'M9 7l3-3 3 3-3 2z')],
    'prison_clothes':   [('p', 'M7 5l5 2 5-2 3 4-3 2v10H7V11L4 9z'), ('a', 'M7 14h10M7 17h10')],
}


def svg(elements):
    out = ['<svg xmlns="http://www.w3.org/2000/svg" viewBox="0 0 24 24" fill="none" stroke-width="1.8" stroke-linecap="round" stroke-linejoin="round">']
    for kind, v in elements:
        if kind == 'p':
            out.append(f'<path d="{v}" stroke="{GOLD}"/>')
        elif kind == 'a':
            out.append(f'<path d="{v}" stroke="{ORANGE}"/>')
        elif kind == 'c':
            cx, cy, r = v
            out.append(f'<circle cx="{cx}" cy="{cy}" r="{r}" stroke="{GOLD}"/>')
        elif kind == 'f':
            out.append(f'<path d="{v}" fill="{GOLD}" stroke="none"/>')
    out.append('</svg>')
    return ''.join(out)


def main():
    os.makedirs(OUT, exist_ok=True)
    for name, elements in ICONS.items():
        with open(os.path.join(OUT, f'{name}.svg'), 'w', encoding='utf-8') as f:
            f.write(svg(elements))
    print(f'{len(ICONS)} Icons nach {os.path.relpath(OUT)} geschrieben')


if __name__ == '__main__':
    main()
