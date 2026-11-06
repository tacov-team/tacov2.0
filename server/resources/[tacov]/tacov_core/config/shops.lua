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
      { item = 'weapon_knife', price = 80 },
    },
  },
  hardware = {
    label = 'Baumarkt',
    blip = { sprite = 402, color = 5, scale = 0.7 },
    items = {
      { item = 'toolbox',  price = 400 },
      { item = 'lockpick', price = 250 },
      { item = 'crowbar',  price = 180 },
      { item = 'hammer',   price = 60 },
      { item = 'rope',     price = 40 },
      { item = 'axe',      price = 200 },
      { item = 'pickaxe',  price = 200 },
    },
  },
}

-- Reihenfolge der Kategorie-Reiter im Laden
TacoV.Config.ShopCategories = { 'food', 'drink', 'daily', 'tool', 'weapon' }
