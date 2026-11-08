-- Kleiderladen und Outfits (6.2), Friseur und Chirurg (6.3), Client: E am Laden, Editor mit passenden Reitern und Preisanzeige,
-- Bezahlung Karte/Bar, Outfits speichern/anziehen/umbenennen/löschen (auch über das Fraktionsmenü → Zivilistenaktionen).
TacoV = TacoV or {}
TacoV.Clothing = TacoV.Clothing or {}

local Cfg = TacoV.Config.Clothing
local function fmt(n)
  local out = tostring(math.floor(n or 0)):reverse():gsub('(%d%d%d)', '%1.'):reverse()
  if out:sub(1, 1) == '.' then out = out:sub(2) end
  return out .. ' $'
end

local function currentAppearance()
  local c = TacoV.Client.character
  local a = c and c.appearance
  if type(a) ~= 'table' or not a.model then a = TacoV.Appearance.default(GetEntityModel(PlayerPedId()) == GetHashKey('mp_f_freemode_01') and 'mp_f_freemode_01' or 'mp_m_freemode_01') end
  -- aktuelle Kleidung vom Ped übernehmen (falls Aussehen ohne Kleidung gespeichert ist)
  local comps, props = TacoV.Appearance.readClothes(PlayerPedId())
  a.components = next(a.components or {}) and a.components or comps
  a.props = next(a.props or {}) and a.props or props
  return a
end

RegisterNetEvent('tacov:clothing:applied', function(appearance)
  if TacoV.Client.character then TacoV.Client.character.appearance = appearance end
  TacoV.Appearance.apply(appearance)
end)

local function payMenu(price, onPick)
  if price <= 0 then onPick('card') return end
  TacoV.Menu.open({ id = 'cl_pay', title = 'Bezahlen', icon = 'cash', info = fmt(price),
    items = { { id = 'card', label = 'Mit Karte zahlen', icon = 'card' }, { id = 'cash', label = 'Bar zahlen', icon = 'cash' } } },
    function(method) TacoV.Menu.close() onPick(method) end)
end

--- Editor für Laden/Friseur/Chirurg öffnen
local function openFor(kind)
  local base = currentAppearance()
  local tabs, title, priceFn
  if kind == 'clothing' then
    tabs, title = { 'clothes', 'accessories' }, 'Kleiderladen'
    priceFn = function(a) return TacoV.Clothing.price(base, a) end
  elseif kind == 'barber' then
    tabs, title = { 'hair', 'details' }, 'Friseur'
    priceFn = function(a) return TacoV.Clothing.barberPrice(base, a) end
  else
    tabs, title = { 'parents', 'face' }, 'Schönheitschirurg'
    priceFn = function() return Cfg.surgeonPrice end
  end
  local copy = json.decode(json.encode(base))
  TacoV.Appearance.openEditor({
    appearance = copy, tabs = tabs, title = title, doneLabel = 'Kaufen', price = fmt(priceFn(copy)), camera = kind == 'clothing' and 'body' or 'face',
    onUpdate = function(a) TacoV.UI.send('editorPrice', fmt(priceFn(a))) end,
  }, function(result)
    if not result then TacoV.Appearance.apply(base) return end
    local price = priceFn(result)
    payMenu(price, function(method)
      TriggerServerEvent('tacov:clothing:apply', kind, result, method)
    end)
  end)
end

-- ---------------------------------------------------------------- Outfits

local function outfitsMenu(list, max)
  local items = { { id = 'save', label = 'Aktuelles Outfit speichern', icon = 'plus', sub = ('%d / %d belegt'):format(#list, max), dim = #list >= max, section = 'Outfits' } }
  for i, o in ipairs(list) do
    items[#items + 1] = { id = tostring(o.id), label = o.name, icon = 'bag', section = i == 1 and 'Gespeichert' or nil }
  end
  TacoV.Menu.open({ id = 'outfits', title = 'Outfits', icon = 'bag', info = 'Enter: anziehen · Optionen im Untermenü', items = items }, function(id)
    if id == 'save' then
      TacoV.UI.ask({ title = 'Name des Outfits', placeholder = 'z. B. Arbeit', maxLength = 32, icon = 'bag' }, function(v)
        if not v or #v == 0 then return end
        local comps, props = TacoV.Appearance.readClothes(PlayerPedId())
        TriggerServerEvent('tacov:outfits:save', v, comps, props)
        TacoV.Menu.close()
      end)
      return
    end
    local o
    for _, e in ipairs(list) do if tostring(e.id) == id then o = e end end
    if not o then return end
    TacoV.Menu.open({ id = 'outfit', title = o.name, icon = 'bag', items = {
      { id = 'wear', label = 'Anziehen', icon = 'check' },
      { id = 'rename', label = 'Umbenennen', icon = 'doc' },
      { id = 'delete', label = 'Löschen', icon = 'x', section = 'Gefahr' },
    } }, function(a)
      if a == 'wear' then TacoV.Menu.close() TriggerServerEvent('tacov:outfits:wear', o.id)
      elseif a == 'rename' then
        TacoV.UI.ask({ title = 'Neuer Name', value = o.name, maxLength = 32, icon = 'bag' }, function(v)
          if v and #v > 0 then TriggerServerEvent('tacov:outfits:rename', o.id, v) TacoV.Menu.close() end
        end)
      elseif a == 'delete' then TacoV.Menu.close() TriggerServerEvent('tacov:outfits:delete', o.id) end
    end)
  end)
end

RegisterNetEvent('tacov:outfits:list', function(list, max) outfitsMenu(list, max) end)
function TacoV.Clothing.openOutfits() TriggerServerEvent('tacov:outfits:list') end

-- ---------------------------------------------------------------- Aufforderungen

TacoV.Prompt.register({ id = 'clothing', label = 'Kleiderladen', order = 10,
  when = function() return TacoV.Client.nearestLocation('clothing', 3.0) ~= nil end,
  run = function()
    TacoV.Menu.open({ id = 'cl_shop', title = 'Kleiderladen', icon = 'bag', info = 'Alles anprobieren, nur Geändertes wird berechnet', items = {
      { id = 'try', label = 'Kleidung anprobieren', icon = 'bag', sub = 'Oberteile, Hosen, Schuhe, Masken, Zubehör …' },
      { id = 'outfits', label = 'Outfits', icon = 'list', sub = ('bis zu %d speichern'):format(Cfg.maxOutfits) },
    } }, function(id)
      TacoV.Menu.close()
      if id == 'try' then openFor('clothing') else TacoV.Clothing.openOutfits() end
    end)
  end })
TacoV.Prompt.register({ id = 'barber', label = 'Friseur', order = 10,
  when = function() return TacoV.Client.nearestLocation('barber', 3.0) ~= nil end,
  run = function() openFor('barber') end })
TacoV.Prompt.register({ id = 'surgeon', label = 'Schönheitschirurg', order = 10,
  when = function() return TacoV.Client.nearestLocation('surgeon', 3.0) ~= nil end,
  run = function()
    TacoV.Menu.open({ id = 'cl_surgeon', title = 'Schönheitschirurg', icon = 'heart', info = ('%s · einmal je %d Tage'):format(fmt(Cfg.surgeonPrice), Cfg.surgeonDays), items = {
      { id = 'go', label = 'Gesicht und Herkunft ändern', icon = 'user', sub = 'Geschlecht bleibt' },
    } }, function() TacoV.Menu.close() openFor('surgeon') end)
  end })

-- Statebag „maskiert“ beim Laden setzen
AddEventHandler('tacov:client:characterLoaded', function()
  Wait(500)
  LocalPlayer.state:set('masked', GetPedDrawableVariation(PlayerPedId(), 1) > 0, true)
end)
