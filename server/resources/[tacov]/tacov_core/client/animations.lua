-- Animationsmenü (Punkt 6.6, F3): Kategorien, Favoriten (lokal gespeichert), Abbruch mit F3 oder /stopanim.
TacoV = TacoV or {}
TacoV.Anims = { current = nil }

local A = TacoV.Config.Animations
local favs = {}
do
  local raw = GetResourceKvpString('tacov_anim_favs')
  if raw then local ok, t = pcall(json.decode, raw) if ok and type(t) == 'table' then favs = t end end
end
local function saveFavs() SetResourceKvp('tacov_anim_favs', json.encode(favs)) end
local function byId(id) for _, a in ipairs(A.list) do if a.id == id then return a end end end

function TacoV.Anims.stop()
  local ped = PlayerPedId()
  if TacoV.Anims.current then
    ClearPedTasks(ped)
    TacoV.Anims.current = nil
  end
end

function TacoV.Anims.play(id)
  local a = byId(id)
  if not a then return end
  local ped = PlayerPedId()
  if IsPedInAnyVehicle(ped, false) then TacoV.UI.send('notify', { kind = 'error', text = 'Nicht im Fahrzeug.' }) return end
  if TacoV.Anims.current then ClearPedTasks(ped) end
  if a.kind == 'scenario' then
    TaskStartScenarioInPlace(ped, a.name, 0, true)
  else
    RequestAnimDict(a.dict)
    local t = GetGameTimer()
    while not HasAnimDictLoaded(a.dict) and GetGameTimer() - t < 3000 do Wait(10) end
    if not HasAnimDictLoaded(a.dict) then TacoV.UI.send('notify', { kind = 'error', text = 'Animation nicht verfügbar.' }) return end
    TaskPlayAnim(ped, a.dict, a.name, 8.0, -8.0, a.loop and -1 or 3000, a.flag or 0, 0.0, false, false, false)
  end
  TacoV.Anims.current = a.id
  TacoV.UI.send('hint', { key = 'F3', text = a.label .. ' · F3 oder Bewegung beendet' })
  CreateThread(function()
    Wait(500)
    while TacoV.Anims.current == a.id do
      Wait(200)
      local p = PlayerPedId()
      local moving = IsPedWalking(p) or IsPedRunning(p) or IsPedSprinting(p) or IsPedJumping(p) or IsPedInAnyVehicle(p, false)
      local ended = a.kind == 'anim' and not a.loop and not IsEntityPlayingAnim(p, a.dict, a.name, 3)
      if (a.flag ~= 49 and moving) or ended or (a.kind == 'scenario' and not IsPedUsingAnyScenario(p) and not IsPedActiveInScenario(p)) then
        if TacoV.Anims.current == a.id then TacoV.Anims.current = nil end
      end
    end
    TacoV.UI.send('hint', nil)
  end)
end

local function animItems(filter)
  local items = {}
  for _, a in ipairs(A.list) do
    if filter(a) then items[#items + 1] = { id = a.id, label = a.label, icon = favs[a.id] and 'star' or 'play', badge = favs[a.id] and '★' or nil } end
  end
  return items
end

local function openList(title, items)
  TacoV.Menu.open({ id = 'anims_' .. title, title = title, icon = 'play', info = 'Enter: abspielen · Backspace: zurück', items = items,
    note = 'Favorit setzen: Animation auswählen und im Untermenü markieren' }, function(id)
    TacoV.Menu.open({ id = 'anim_one', title = byId(id).label, icon = 'play', items = {
      { id = 'play', label = 'Abspielen', icon = 'play' },
      { id = 'fav', label = favs[id] and 'Aus Favoriten entfernen' or 'Zu Favoriten', icon = 'star' },
    } }, function(a)
      if a == 'play' then TacoV.Menu.close() TacoV.Anims.play(id)
      else favs[id] = (not favs[id]) and true or nil saveFavs() TacoV.Menu.back() end
    end)
  end)
end

function TacoV.Anims.openMenu()
  if TacoV.Menu.isOpen() then TacoV.Menu.close() return end
  if TacoV.Anims.current and not TacoV.Menu.isOpen() then
    -- F3 während einer Animation beendet sie
    TacoV.Anims.stop()
    return
  end
  local items = {}
  local favItems = animItems(function(a) return favs[a.id] end)
  for _, it in ipairs(favItems) do it.section = 'Favoriten' items[#items + 1] = it end
  for i, c in ipairs(A.categories) do
    local n = 0
    for _, a in ipairs(A.list) do if a.cat == c.id then n = n + 1 end end
    items[#items + 1] = { id = 'cat:' .. c.id, label = c.label, icon = c.icon, badge = tostring(n), section = i == 1 and 'Kategorien' or nil }
  end
  TacoV.Menu.open({ id = 'anims', title = 'Animationen', icon = 'play', info = ('%d Animationen · F3 beendet'):format(#A.list), items = items }, function(id)
    if id:sub(1, 4) == 'cat:' then
      local cid = id:sub(5)
      local c
      for _, cc in ipairs(A.categories) do if cc.id == cid then c = cc end end
      openList(c and c.label or cid, animItems(function(a) return a.cat == cid end))
    else
      TacoV.Menu.close()
      TacoV.Anims.play(id)
    end
  end)
end

RegisterCommand('stopanim', function() TacoV.Anims.stop() end, false)
