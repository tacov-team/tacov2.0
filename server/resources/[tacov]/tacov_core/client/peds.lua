-- NPCs (Client, 5.7): lokale Peds in Reichweite spawnen (unverwundbar, eingefroren, Szenario), E spricht sie an und löst
-- die Aufgabe (Laden, Bank, Kaufhaus ...) aus; Creator-Menü mit Vorschau am Zeiger.
TacoV = TacoV or {}
TacoV.Peds = { list = {} }

local spawned = {} -- [id] = { ped, model }

local function loadModel(name)
  local hash = GetHashKey(name)
  if not IsModelValid(hash) then return nil end
  RequestModel(hash)
  local t = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(20) end
  return HasModelLoaded(hash) and hash or nil
end

local function despawn(id)
  local s = spawned[id]
  if s and DoesEntityExist(s.ped) then DeleteEntity(s.ped) end
  spawned[id] = nil
end

local function spawn(d)
  local hash = loadModel(d.model)
  if not hash then return end
  local ped = CreatePed(4, hash, d.x, d.y, d.z - 1.0, d.h, false, false)
  SetModelAsNoLongerNeeded(hash)
  SetEntityInvincible(ped, true)
  FreezeEntityPosition(ped, true)
  SetBlockingOfNonTemporaryEvents(ped, true)
  SetPedCanRagdollFromPlayerImpact(ped, false)
  SetPedDiesWhenInjured(ped, false)
  SetPedFleeAttributes(ped, 0, false)
  if d.scenario and d.scenario ~= '' then TaskStartScenarioInPlace(ped, d.scenario, 0, true) end
  spawned[d.id] = { ped = ped, sig = d.model .. d.x .. d.y .. d.z .. d.h .. tostring(d.scenario) }
end

RegisterNetEvent('tacov:peds:list', function(list)
  TacoV.Peds.list = {}
  for _, d in ipairs(list or {}) do TacoV.Peds.list[d.id] = d end
  for id, s in pairs(spawned) do
    local d = TacoV.Peds.list[id]
    if not d or s.sig ~= (d.model .. d.x .. d.y .. d.z .. d.h .. tostring(d.scenario)) then despawn(id) end
  end
end)

CreateThread(function()
  while true do
    Wait(1000)
    if TacoV.Client.character then
      local pos = GetEntityCoords(PlayerPedId())
      for id, d in pairs(TacoV.Peds.list) do
        local dist = #(pos - vector3(d.x, d.y, d.z))
        if dist < 120.0 and not spawned[id] then spawn(d)
        elseif dist > 140.0 and spawned[id] then despawn(id) end
      end
    end
  end
end)

AddEventHandler('onResourceStop', function(res)
  if res == GetCurrentResourceName() then for id in pairs(spawned) do despawn(id) end end
end)

local function nearestPed(maxDist)
  local pos = GetEntityCoords(PlayerPedId())
  local best, bestD = nil, maxDist or 2.0
  for _, d in pairs(TacoV.Peds.list) do
    local dist = #(pos - vector3(d.x, d.y, d.z))
    if dist < bestD then best, bestD = d, dist end
  end
  return best
end

local function taskLabel(id)
  for _, t in ipairs(TacoV.Config.PedTasks) do if t.id == id then return t.label end end
  return id or ''
end

TacoV.Prompt.register({ id = 'npc', label = 'Ansprechen', order = 4,
  when = function()
    local d = nearestPed(2.0)
    if not d or not d.task or d.task == '' then return false end
    local entry = TacoV.Prompt.entries[d.task]
    return entry and { d = d, entry = entry } or false
  end,
  run = function(ctx)
    local ok = ctx.entry.when and ctx.entry.when()
    if ok then
      local ped = spawned[ctx.d.id]
      if ped and DoesEntityExist(ped.ped) then PlayPedAmbientSpeechNative(ped.ped, 'GENERIC_HI', 'SPEECH_PARAMS_FORCE') end
      ctx.entry.run(ok)
    else
      local who = ctx.d.label ~= '' and ctx.d.label or 'Der NPC'
      TacoV.UI.send('notify', { kind = 'error', text = ('%s steht nicht an einem %s-Punkt – im Creator an den Ort verschieben.'):format(who, taskLabel(ctx.d.task)) })
    end
  end })

-- ---------------------------------------------------------------- Creator

local function save(d) TriggerServerEvent('tacov:peds:save', d) end

local function modelLabel(m)
  for _, e in ipairs(TacoV.Config.PedModels) do if e.model == m then return e.label end end
  return m
end
local function scenarioLabel(s)
  for _, e in ipairs(TacoV.Config.PedScenarios) do if e.id == (s or '') then return e.label end end
  return s or ''
end

local function pickModel(cb)
  local items = {}
  for _, e in ipairs(TacoV.Config.PedModels) do items[#items + 1] = { id = e.model, label = e.label, icon = 'user', sub = e.model } end
  items[#items + 1] = { id = '__custom', label = 'Modell eingeben', icon = 'plus', section = 'Sonstiges' }
  TacoV.Menu.open({ id = 'ped_model', title = 'Modell wählen', icon = 'user', items = items }, function(id)
    if id == '__custom' then
      TacoV.UI.ask({ title = 'Ped-Modell (z. B. a_m_y_skater_01)', maxLength = 48, icon = 'user' }, function(v)
        if v and #v > 0 then cb(v:lower()) end
      end)
    else cb(id) end
  end)
end

local function placePed(d, cb)
  TacoV.Menu.close()
  TacoV.Creator.place({ start = d.x and vector3(d.x, d.y, d.z) or nil, heading = d.h, label = d.label ~= '' and d.label or 'NPC', previewPed = d.model }, function(pos, h)
    if pos then d.x, d.y, d.z, d.h = pos.x, pos.y, pos.z + 1.0, h end
    cb(pos ~= nil)
  end)
end

local function pedMenu(d)
  TacoV.Menu.open({ id = 'ped_edit', title = d.label ~= '' and d.label or ('NPC #' .. d.id), icon = 'user', info = 'NPC-Creator', items = {
    { id = 'info', label = modelLabel(d.model), icon = 'user', dim = true, sub = ('%s · %s'):format(scenarioLabel(d.scenario), taskLabel(d.task or '')) },
    { id = 'label', label = 'Bezeichnung', icon = 'doc', sub = d.label, section = 'Einstellungen' },
    { id = 'model', label = 'Modell', icon = 'user', sub = d.model },
    { id = 'move', label = 'Neu platzieren', icon = 'pin' },
    { id = 'scenario', label = 'Animation / Szenario', icon = 'play', sub = scenarioLabel(d.scenario) },
    { id = 'task', label = 'Aufgabe', icon = 'briefcase', sub = taskLabel(d.task or '') },
    { id = 'tp', label = 'Zum NPC teleportieren', icon = 'next', section = 'Sonstiges' },
    { id = 'delete', label = 'NPC löschen', icon = 'x', section = 'Gefahr' },
  } }, function(id)
    if id == 'label' then
      TacoV.UI.ask({ title = 'Bezeichnung', value = d.label, maxLength = 64, icon = 'user' }, function(v) if v and #v > 0 then d.label = v save(d) end end)
    elseif id == 'model' then pickModel(function(m) d.model = m save(d) TacoV.Menu.back() end)
    elseif id == 'move' then placePed(d, function(ok) if ok then save(d) end end)
    elseif id == 'scenario' then
      local items = {}
      for _, e in ipairs(TacoV.Config.PedScenarios) do items[#items + 1] = { id = e.id == '' and '__none' or e.id, label = e.label, icon = 'play', sub = e.id } end
      items[#items + 1] = { id = '__custom', label = 'Szenario eingeben', icon = 'plus', section = 'Sonstiges' }
      TacoV.Menu.open({ id = 'ped_scenario', title = 'Szenario', icon = 'play', items = items }, function(s)
        if s == '__custom' then
          TacoV.UI.ask({ title = 'Szenario (WORLD_HUMAN_…)', maxLength = 64, icon = 'play' }, function(v) if v and #v > 0 then d.scenario = v:upper() save(d) end end)
        else d.scenario = s ~= '__none' and s or nil save(d) TacoV.Menu.back() end
      end)
    elseif id == 'task' then
      local items = {}
      for _, t in ipairs(TacoV.Config.PedTasks) do items[#items + 1] = { id = t.id == '' and '__none' or t.id, label = t.label, icon = 'briefcase' } end
      TacoV.Menu.open({ id = 'ped_task', title = 'Aufgabe', icon = 'briefcase', info = 'NPC muss am passenden Ort stehen', items = items }, function(t)
        d.task = t ~= '__none' and t or nil save(d) TacoV.Menu.back()
      end)
    elseif id == 'tp' then TacoV.Menu.close() TacoV.Creator.fadeTeleport(d.x, d.y, d.z, d.h)
    elseif id == 'delete' then
      TacoV.Menu.open({ id = 'ped_del', title = 'NPC wirklich löschen?', icon = 'warn', items = {
        { id = 'yes', label = 'Ja, löschen', icon = 'x' }, { id = 'no', label = 'Abbrechen', icon = 'back' } } }, function(a)
        if a == 'yes' then TriggerServerEvent('tacov:peds:delete', d.id) TacoV.Menu.close() else TacoV.Menu.back() end
      end)
    end
  end)
end

local function newPed()
  pickModel(function(model)
    local d = { model = model, label = '', scenario = nil, task = nil }
    placePed(d, function(ok)
      if not ok then return end
      TacoV.UI.ask({ title = 'Bezeichnung des NPCs', placeholder = 'z. B. Verkäufer 24/7', maxLength = 64, icon = 'user' }, function(v)
        d.label = (v and #v > 0) and v or modelLabel(model)
        save(d)
      end)
    end)
  end)
end

function TacoV.Peds.openCreator()
  local pos = GetEntityCoords(PlayerPedId())
  local near = {}
  for _, d in pairs(TacoV.Peds.list) do near[#near + 1] = { d = d, dist = #(pos - vector3(d.x, d.y, d.z)) } end
  table.sort(near, function(a, b) return a.dist < b.dist end)
  local items = { { id = 'new', label = 'Neuer NPC', icon = 'plus', sub = 'Modell wählen, am Zeiger platzieren', section = 'NPCs' } }
  for i, e in ipairs(near) do
    if i > 12 then break end
    items[#items + 1] = { id = tostring(e.d.id), label = e.d.label ~= '' and e.d.label or ('NPC #' .. e.d.id), icon = 'user',
      sub = ('%s · %.0f m'):format(taskLabel(e.d.task or ''), e.dist), section = i == 1 and 'Vorhanden (nach Entfernung)' or nil }
  end
  TacoV.Menu.open({ id = 'peds', title = 'NPC-Creator', icon = 'user', info = ('%d NPCs'):format(#near), items = items }, function(id)
    if id == 'new' then newPed() else local d = TacoV.Peds.list[tonumber(id)] if d then pedMenu(d) end end
  end)
end
