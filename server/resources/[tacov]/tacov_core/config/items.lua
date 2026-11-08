-- Item-Config aus docs/konzept/items.md. Gewicht in kg je Stück, stack = max. je Platz (0 = unbegrenzt).
-- use: { hunger=+x, thirst=+y, fitness=+z, alcohol=+p } verbraucht das Item; use = 'event' löst tacov:item:<name> aus.
-- Entscheidungen vom 06.11.2026: Bargeld hat kein Gewicht; Startitems Ausweis + Stadtplan (kein Handy).
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.ItemCategories = {
  money = 'Geld', document = 'Dokument', daily = 'Alltag', tool = 'Werkzeug', material = 'Rohstoff',
  drug = 'Droge', weapon = 'Waffe', ammo = 'Munition', armor = 'Schutz', food = 'Essen', drink = 'Getränk',
  leisure = 'Freizeit', jewelry = 'Schmuck', loot = 'Beute',
}

local I = {}
local function item(name, def) def.name = name; I[name] = def end

-- Geld
item('cash',        { label = 'Bargeld',       category = 'money', weight = 0.0,    stack = 0, money = true })
item('black_cash',  { label = 'Schwarzgeld',   category = 'money', weight = 0.0001, stack = 0, money = true })
item('cashbox',     { label = 'Geldkassette',  category = 'loot', weight = 2.0, stack = 10 })
item('gold_bar',    { label = 'Goldbarren',    category = 'loot', weight = 3.0, stack = 10 })
item('gold_crate',  { label = 'Goldkiste',     category = 'loot', weight = 8.0, stack = 2 })
item('jewel_bag',   { label = 'Schmuckbeutel', category = 'loot', weight = 0.5, stack = 20 })
item('luxury_watch',{ label = 'Uhr',           category = 'loot', weight = 0.2, stack = 5 })

-- Dokumente (unique: je Platz ein Stück mit eigenen Daten)
item('id_card',     { label = 'Ausweis',       category = 'document', weight = 0.0, stack = 1, unique = true, use = 'event' })
item('housing_key', { label = 'Wohnungsschlüssel', category = 'document', weight = 0.0, stack = 1, unique = true })
item('passport',    { label = 'Reisepass',     category = 'document', weight = 0.0, stack = 1, unique = true })
item('license_a',   { label = 'Führerschein A', category = 'document', weight = 0.0, stack = 1, unique = true })
item('license_b',   { label = 'Führerschein B', category = 'document', weight = 0.0, stack = 1, unique = true })
item('license_c',   { label = 'Führerschein C', category = 'document', weight = 0.0, stack = 1, unique = true })
item('license_boat',{ label = 'Bootsschein',   category = 'document', weight = 0.0, stack = 1, unique = true })
item('license_air', { label = 'Flugschein',    category = 'document', weight = 0.0, stack = 1, unique = true })
item('license_gun', { label = 'Waffenschein',  category = 'document', weight = 0.0, stack = 1, unique = true })
item('bus_ticket',  { label = 'Busticket',     category = 'document', weight = 0.0, stack = 20 })
item('city_map',    { label = 'Stadtplan',     category = 'document', weight = 0.1, stack = 1, use = 'event' })

-- Alltag
item('phone',       { label = 'Handy',         category = 'daily', weight = 0.2, stack = 1, unique = true })
item('first_aid',   { label = 'Erste-Hilfe-Kit', category = 'daily', weight = 0.5, stack = 10, use = 'event' })
item('water',       { label = 'Wasser',        category = 'drink', weight = 0.5, stack = 20, use = { thirst = 35 } })
item('burger',      { label = 'Burger',        category = 'food', weight = 0.3, stack = 20, use = { hunger = 35 } })
item('sandwich',    { label = 'Sandwich',      category = 'food', weight = 0.3, stack = 20, use = { hunger = 25 } })
item('energy_drink',{ label = 'Energydrink',   category = 'drink', weight = 0.3, stack = 20, use = { thirst = 20, fitness = 2 } })
item('beer',        { label = 'Bier',          category = 'drink', weight = 0.5, stack = 20, use = { thirst = 10, alcohol = 0.2 } })
item('spirits',     { label = 'Schnaps',       category = 'drink', weight = 0.5, stack = 20, use = { alcohol = 0.5 } })
item('cigarettes',  { label = 'Zigaretten',    category = 'daily', weight = 0.1, stack = 20, use = 'event' })
item('vehicle_key', { label = 'Fahrzeugschlüssel', category = 'daily', weight = 0.1, stack = 1, unique = true })
item('house_key',   { label = 'Immobilienschlüssel', category = 'daily', weight = 0.1, stack = 1, unique = true })
item('toolbox',     { label = 'Werkzeugkasten', category = 'daily', weight = 3.0, stack = 2, use = 'event' })
item('jerrycan',    { label = 'Kanister',      category = 'daily', weight = 2.0, stack = 2, use = 'event' })
item('backpack',    { label = 'Rucksack',      category = 'daily', weight = 0.5, stack = 1, backpack = true })
item('radio',       { label = 'Funkgerät',     category = 'daily', weight = 0.4, stack = 1, use = 'event' })

-- Werkzeug
item('lockpick',    { label = 'Dietrich',      category = 'tool', weight = 0.2, stack = 5, uses = 3 })
item('crowbar',     { label = 'Brecheisen',    category = 'tool', weight = 2.0, stack = 1 })
item('hammer',      { label = 'Hammer',        category = 'tool', weight = 1.5, stack = 1 })
item('rope',        { label = 'Seil',          category = 'tool', weight = 0.5, stack = 10 })
item('net',         { label = 'Netz',          category = 'tool', weight = 0.8, stack = 1 })
item('axe',         { label = 'Axt',           category = 'tool', weight = 2.5, stack = 1 })
item('pickaxe',     { label = 'Spitzhacke',    category = 'tool', weight = 2.5, stack = 1 })
item('welder',      { label = 'Schweißgerät',  category = 'tool', weight = 6.0, stack = 1 })
item('drill',       { label = 'Bohrer',        category = 'tool', weight = 4.0, stack = 1 })
item('hacking_tool',{ label = 'Hacking-Tool',  category = 'tool', weight = 0.5, stack = 1 })
item('dynamite',    { label = 'Dynamit',       category = 'tool', weight = 1.0, stack = 5 })

-- Rohstoffe
item('wood',        { label = 'Holz',          category = 'material', weight = 2.0, stack = 50 })
item('ore',         { label = 'Erz',           category = 'material', weight = 2.5, stack = 50 })
item('metal',       { label = 'Metall',        category = 'material', weight = 1.5, stack = 50 })
item('kevlar',      { label = 'Kevlar',        category = 'material', weight = 0.8, stack = 50 })
item('weapon_parts',{ label = 'Waffenteile',   category = 'material', weight = 1.0, stack = 50 })
item('chemicals',   { label = 'Chemikalien',   category = 'material', weight = 1.0, stack = 50 })
item('pseudo',      { label = 'Pseudo',        category = 'material', weight = 0.3, stack = 50 })
item('coca_leaves', { label = 'Kokablätter',   category = 'material', weight = 0.5, stack = 50 })
item('mushrooms',   { label = 'Pilze',         category = 'material', weight = 0.2, stack = 50 })
item('frog',        { label = 'Frosch',        category = 'material', weight = 0.3, stack = 50 })
item('cannabis_harvest', { label = 'Cannabis (Ernte)', category = 'material', weight = 0.5, stack = 50 })

-- Drogen (Qualität in meta.quality 1–3)
item('cannabis',    { label = 'Cannabis',      category = 'drug', weight = 0.1,  stack = 50, use = 'event' })
item('meth',        { label = 'Meth',          category = 'drug', weight = 0.1,  stack = 50, use = 'event' })
item('cocaine',     { label = 'Kokain',        category = 'drug', weight = 0.1,  stack = 50, use = 'event' })
item('lsd',         { label = 'LSD-Blotter',   category = 'drug', weight = 0.05, stack = 50, use = 'event' })
item('frog_secret', { label = 'Froschsekret',  category = 'drug', weight = 0.05, stack = 50, use = 'event' })

-- Waffen (Munition als eigene Items)
item('weapon_pistol',   { label = 'Pistole',     category = 'weapon', weight = 1.0, stack = 1, unique = true, weapon = 'WEAPON_PISTOL', license = true })
item('weapon_revolver', { label = 'Revolver',    category = 'weapon', weight = 1.2, stack = 1, unique = true, weapon = 'WEAPON_REVOLVER', license = true })
item('weapon_rifle',    { label = 'Jagdgewehr',  category = 'weapon', weight = 3.5, stack = 1, unique = true, weapon = 'WEAPON_SNIPERRIFLE', license = true })
item('weapon_smg',      { label = 'SMG',         category = 'weapon', weight = 2.5, stack = 1, unique = true, weapon = 'WEAPON_SMG', illegal = true })
item('weapon_assault',  { label = 'Sturmgewehr', category = 'weapon', weight = 3.5, stack = 1, unique = true, weapon = 'WEAPON_ASSAULTRIFLE', illegal = true })
item('weapon_pistol_il',{ label = 'Pistole (unlizenziert)', category = 'weapon', weight = 1.0, stack = 1, unique = true,
  weapon = 'WEAPON_PISTOL', illegal = true })
item('weapon_knife',    { label = 'Messer',      category = 'weapon', weight = 0.5, stack = 1, unique = true, weapon = 'WEAPON_KNIFE' })
item('ammo_pistol',     { label = 'Pistolenmunition', category = 'ammo', weight = 0.01, stack = 500 })
item('ammo_rifle',      { label = 'Gewehrmunition',   category = 'ammo', weight = 0.017, stack = 500 })
item('armor',           { label = 'Weste',       category = 'armor', weight = 2.0, stack = 1, use = 'event' })

-- Firma, Freizeit, Schmuck
item('ingredient_meat', { label = 'Fleisch',     category = 'material', weight = 0.2, stack = 50 })
item('ingredient_bun',  { label = 'Brötchen',    category = 'material', weight = 0.2, stack = 50 })
item('ingredient_salad',{ label = 'Salat',       category = 'material', weight = 0.2, stack = 50 })
item('fishing_rod',     { label = 'Angel',       category = 'leisure', weight = 1.5, stack = 1 })
item('bait',            { label = 'Köder',       category = 'leisure', weight = 0.02, stack = 100 })
item('fish',            { label = 'Fisch',       category = 'leisure', weight = 1.0, stack = 20 })
item('shell',           { label = 'Muschel',     category = 'leisure', weight = 0.2, stack = 50, use = 'event' })
item('pearl',           { label = 'Perle',       category = 'jewelry', weight = 0.05, stack = 50 })
item('ring',            { label = 'Ring',        category = 'jewelry', weight = 0.05, stack = 1, unique = true })
item('prison_clothes',  { label = 'Gefängniskleidung', category = 'daily', weight = 0.0, stack = 1 })

TacoV.Config.Items = I

-- Bei der Charakteranlage: nur der Reisepass (Konzept 1.4). Den Rest gibt es mit der Einreise (config/core.lua, Onboarding).
TacoV.Config.StartItems = {
  { item = 'passport', amount = 1 },
}
