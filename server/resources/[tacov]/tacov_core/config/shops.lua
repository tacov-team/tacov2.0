-- Läden (Konzept 3/5): Sortiment und Preise je Ladentyp. Preise aus docs/konzept/items.md, Umsatzsteuer aus economy.lua.
-- Orte der Läden stehen in config/locations.lua (kind = 'shop', shop = <Typ>).
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Shops = {
  supermarket = {
    label = '24/7',
    blip = { sprite = 52, color = 2, scale = 0.7 },
    items = {
      { item = 'water',        price = 3 },
      { item = 'sandwich',     price = 8 },
      { item = 'burger',       price = 15 },
      { item = 'energy_drink', price = 6 },
      { item = 'beer',         price = 5 },
      { item = 'spirits',      price = 12 },
      { item = 'cigarettes',   price = 10 },
      { item = 'radio',        price = 250 },
    },
  },
  hardware = {
    label = 'Baumarkt',
    blip = { sprite = 402, color = 5, scale = 0.7 },
    items = {
      { item = 'phone',    price = 300 },
      { item = 'radio',    price = 250 },
      { item = 'toolbox',  price = 400 },
      { item = 'axe',      price = 150 },
      { item = 'pickaxe',  price = 150 },
      { item = 'lockpick', price = 250 },
      { item = 'crowbar',  price = 180 },
      { item = 'hammer',   price = 60 },
      { item = 'rope',     price = 40 },
      { item = 'axe',      price = 200 },
      { item = 'pickaxe',  price = 200 },
    },
  },
  -- Waffenladen (Konzept 4.2): legale Schusswaffen nur mit Waffenschein (Prüfung kommt mit dem Waffenschein, Phase 11);
  -- bis dahin verkauft er, was ohne Schein erlaubt ist.
  gunshop = {
    label = 'Waffenladen',
    blip = { sprite = 110, color = 1, scale = 0.7 },
    items = {
      { item = 'weapon_knife',    price = 80 },
      { item = 'armor',           price = 600 },
      { item = 'weapon_pistol',   price = 1200, license = 'weapon' },
      { item = 'weapon_revolver', price = 1800, license = 'weapon' },
      { item = 'weapon_rifle',    price = 3500, license = 'weapon' },
      { item = 'ammo_pistol',     price = 2,    license = 'weapon' },
      { item = 'ammo_rifle',      price = 3,    license = 'weapon' },
    },
  },
}

-- Reihenfolge der Kategorie-Reiter im Laden
TacoV.Config.ShopCategories = { 'food', 'drink', 'daily', 'tool', 'weapon', 'ammo', 'armor' }
