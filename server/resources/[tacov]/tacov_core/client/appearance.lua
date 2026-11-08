-- Aussehen (Punkt 6.1): Modell, Eltern-Mix, Gesichtszüge, Haare, Overlays, Kleidung auf den Ped anwenden; Editor mit Kamera.
-- Datenform siehe ui/src/views/Editor.tsx (Appearance). Friseur/Chirurg/Kleiderladen nutzen denselben Editor mit Reiter-Filter.
TacoV = TacoV or {}
TacoV.Appearance = {}

local OVERLAY_IDS = { blemishes = 0, beard = 1, eyebrows = 2, ageing = 3, makeup = 4, blush = 5, complexion = 6, sundamage = 7,
  lipstick = 8, freckles = 9, chesthair = 10, bodyblemish = 11 }
local HAIR_COLORED = { beard = true, eyebrows = true, chesthair = true }
local MAKEUP_COLORED = { makeup = true, blush = true, lipstick = true }

function TacoV.Appearance.default(model)
  return {
    model = model or 'mp_m_freemode_01',
    parents = { father = 0, mother = 21, shapeMix = 0.5, skinMix = 0.5 },
    face = { 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0, 0 },
    hair = { style = 0, color = 0, highlight = 0 },
    eyeColor = 0,
    overlays = {},
    components = {},
    props = {},
  }
end

local function loadModel(name)
  local hash = GetHashKey(name)
  if not IsModelValid(hash) then return nil end
  RequestModel(hash)
  local t = GetGameTimer()
  while not HasModelLoaded(hash) and GetGameTimer() - t < 5000 do Wait(20) end
  return HasModelLoaded(hash) and hash or nil
end

--- Modell setzen (wechselt den Spieler-Ped). Gibt den neuen Ped zurück.
function TacoV.Appearance.setModel(model)
  local hash = loadModel(model)
  if not hash then return PlayerPedId() end
  if GetEntityModel(PlayerPedId()) ~= hash then
    SetPlayerModel(PlayerId(), hash)
    Wait(50)
    SetPedDefaultComponentVariation(PlayerPedId())
  end
  SetModelAsNoLongerNeeded(hash)
  return PlayerPedId()
end

--- Alles außer dem Modell auf einen Ped anwenden
function TacoV.Appearance.applyTo(ped, a)
  if type(a) ~= 'table' then return end
  local p = a.parents or {}
  SetPedHeadBlendData(ped, p.father or 0, p.mother or 21, 0, p.father or 0, p.mother or 21, 0, p.shapeMix or 0.5, p.skinMix or 0.5, 0.0, false)
  for i = 0, 19 do SetPedFaceFeature(ped, i, (a.face and a.face[i + 1]) or 0.0) end
  local h = a.hair or {}
  SetPedComponentVariation(ped, 2, h.style or 0, 0, 0)
  SetPedHairColor(ped, h.color or 0, h.highlight or 0)
  SetPedEyeColor(ped, a.eyeColor or 0)
  for id, idx in pairs(OVERLAY_IDS) do
    local o = a.overlays and a.overlays[id]
    if o and (o.style or -1) >= 0 then
      SetPedHeadOverlay(ped, idx, o.style, o.opacity or 1.0)
      if HAIR_COLORED[id] then SetPedHeadOverlayColor(ped, idx, 1, o.color or 0, o.color or 0)
      elseif MAKEUP_COLORED[id] then SetPedHeadOverlayColor(ped, idx, 2, o.color or 0, o.color or 0) end
    else
      SetPedHeadOverlay(ped, idx, 255, 0.0)
    end
  end
  for k, v in pairs(a.components or {}) do
    local comp = tonumber(k)
    if comp and comp ~= 2 then SetPedComponentVariation(ped, comp, v[1] or 0, v[2] or 0, 0) end
  end
  for k, v in pairs(a.props or {}) do
    local prop = tonumber(k)
    if prop then
      if (v[1] or -1) >= 0 then SetPedPropIndex(ped, prop, v[1], v[2] or 0, true) else ClearPedProp(ped, prop) end
    end
  end
end

local function updateMasked(ped)
  local masked = GetPedDrawableVariation(ped, 1) > 0
  LocalPlayer.state:set('masked', masked, true)
end

--- Komplett anwenden (Modell + Rest) auf den Spieler
function TacoV.Appearance.apply(a)
  if type(a) ~= 'table' or not a.model then return end
  local ped = TacoV.Appearance.setModel(a.model)
  TacoV.Appearance.applyTo(ped, a)
  updateMasked(ped)
end

--- Aktuelle Kleidung des Peds auslesen (für Kleiderladen/Outfits)
function TacoV.Appearance.readClothes(ped)
  local comps, props = {}, {}
  for _, c in ipairs({ 0, 1, 3, 4, 5, 6, 7, 8, 9, 10, 11 }) do comps[tostring(c)] = { GetPedDrawableVariation(ped, c), GetPedTextureVariation(ped, c) } end
  for _, pr in ipairs({ 0, 1, 2, 6, 7 }) do props[tostring(pr)] = { GetPedPropIndex(ped, pr), GetPedPropTextureIndex(ped, pr) } end
  return comps, props
end

function TacoV.Appearance.limits(ped)
  local overlays = {}
  for id, idx in pairs(OVERLAY_IDS) do overlays[id] = GetPedHeadOverlayNum(idx) end
  local comps, props, textures = {}, {}, {}
  for c = 0, 11 do
    comps[tostring(c)] = GetNumberOfPedDrawableVariations(ped, c)
    textures['c' .. c] = GetNumberOfPedTextureVariations(ped, c, GetPedDrawableVariation(ped, c))
  end
  for _, pr in ipairs({ 0, 1, 2, 6, 7 }) do
    props[tostring(pr)] = GetNumberOfPedPropDrawableVariations(ped, pr)
    local cur = GetPedPropIndex(ped, pr)
    textures['p' .. pr] = cur >= 0 and GetNumberOfPedPropTextureVariations(ped, pr, cur) or 1
  end
  return { hair = GetNumberOfPedDrawableVariations(ped, 2), hairColors = GetNumHairColors(), makeupColors = GetNumMakeupColors(),
    overlays = overlays, components = comps, props = props, textures = textures }
end



-- ---------------------------------------------------------------- Editor

local editing = nil -- { cb, cam, heading, base }

local function camFor(mode)
  local ped = PlayerPedId()
  local pos = GetEntityCoords(ped)
  local h = math.rad(GetEntityHeading(ped))
  local fwd = vector3(-math.sin(h), math.cos(h), 0.0)
  if mode == 'body' then
    return pos + fwd * 2.6 + vector3(0.0, 0.0, 0.2), pos + vector3(0.0, 0.0, 0.1)
  end
  return pos + fwd * 0.9 + vector3(0.0, 0.0, 0.62), pos + vector3(0.0, 0.0, 0.62)
end

local function setCam(mode)
  if not editing then return end
  local from, at = camFor(mode)
  if not editing.cam then
    editing.cam = CreateCam('DEFAULT_SCRIPTED_CAMERA', true)
    SetCamActive(editing.cam, true)
    RenderScriptCams(true, true, 400, true, true)
  end
  SetCamCoord(editing.cam, from.x, from.y, from.z)
  PointCamAtCoord(editing.cam, at.x, at.y, at.z)
  SetCamFov(editing.cam, mode == 'body' and 45.0 or 32.0)
  editing.mode = mode
end

--- Editor öffnen. opts = { appearance, tabs, title, price, doneLabel, spot = vector4 (optional) }; cb(appearance|nil)
function TacoV.Appearance.openEditor(opts, cb)
  if editing then return false end
  local a = opts.appearance or TacoV.Appearance.default('mp_m_freemode_01')
  editing = { cb = cb, base = a, mode = 'face', tabs = opts.tabs, title = opts.title, onUpdate = opts.onUpdate }
  TacoV.Appearance.apply(a)
  local ped = PlayerPedId()
  if opts.spot then
    SetEntityCoordsNoOffset(ped, opts.spot.x, opts.spot.y, opts.spot.z, false, false, false)
    SetEntityHeading(ped, opts.spot.w)
  end
  SetEntityVisible(ped, true, false)
  FreezeEntityPosition(ped, true)
  SetEntityInvincible(ped, true)
  TaskStandStill(ped, -1)
  TacoV.UI.open('editor', { appearance = a, limits = TacoV.Appearance.limits(ped), tabs = opts.tabs, title = opts.title, price = opts.price, doneLabel = opts.doneLabel }, true)
  setCam(opts.camera or 'face')
  DisplayRadar(false)
  return true
end

local function closeEditor()
  if not editing then return end
  if editing.cam then
    RenderScriptCams(false, true, 400, true, true)
    DestroyCam(editing.cam, false)
  end
  DisplayRadar(true)
  local ped = PlayerPedId()
  ClearPedTasks(ped)
  FreezeEntityPosition(ped, false)
  SetEntityInvincible(ped, false)
  updateMasked(ped)
  TacoV.UI.close()
  editing = nil
end

AddEventHandler('tacov:ui:editor:update', function(d)
  if not editing or type(d.appearance) ~= 'table' then return end
  local a = d.appearance
  local ped = PlayerPedId()
  if a.model and GetEntityModel(ped) ~= GetHashKey(a.model) then
    -- Modellwechsel: Ped neu, Kamera nachführen, Grenzen neu senden
    TacoV.Appearance.apply(a)
    ped = PlayerPedId()
    FreezeEntityPosition(ped, true)
    SetEntityInvincible(ped, true)
    TaskStandStill(ped, -1)
    TacoV.UI.send('open', { view = 'editor', data = { appearance = a, limits = TacoV.Appearance.limits(ped), tabs = editing.tabs, title = editing.title } })
    setCam(editing.mode)
  else
    TacoV.Appearance.applyTo(ped, a)
    TacoV.UI.send('editorLimits', TacoV.Appearance.limits(ped))
  end
  editing.current = a
  if editing.onUpdate then editing.onUpdate(a) end
end)

AddEventHandler('tacov:ui:editor:camera', function(d) if editing then setCam(d.mode == 'body' and 'body' or 'face') end end)
AddEventHandler('tacov:ui:editor:rotate', function(d)
  if not editing then return end
  local ped = PlayerPedId()
  SetEntityHeading(ped, (GetEntityHeading(ped) + (tonumber(d.delta) or 0)) % 360)
  setCam(editing.mode)
end)
AddEventHandler('tacov:ui:editor:done', function(d)
  if not editing then return end
  local a = type(d.appearance) == 'table' and d.appearance or editing.current or editing.base
  local cb = editing.cb
  closeEditor()
  cb(a)
end)
AddEventHandler('tacov:ui:editor:cancel', function()
  if not editing then return end
  local cb, base = editing.cb, editing.base
  closeEditor()
  TacoV.Appearance.apply(base)
  cb(nil)
end)
