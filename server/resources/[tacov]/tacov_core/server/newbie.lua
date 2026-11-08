-- Neulingspfad (6.5): zehn Schritte mit kleinem Bonus; Schritte melden sich per Ereignis `tacov:newbie:step` (src, id).
TacoV = TacoV or {}
TacoV.Newbie = {}

local N = TacoV.Config.Newbie
local done = {} -- [characterId] = { step = true }

local function stepDef(id) for _, s in ipairs(N.steps) do if s.id == id then return s end end end
local function load(cid)
  if done[cid] then return done[cid] end
  local t = {}
  for _, r in ipairs(TacoV.DB.query('SELECT step FROM newbie_steps WHERE character_id = ?', { cid }) or {}) do t[r.step] = true end
  done[cid] = t
  return t
end

function TacoV.Newbie.complete(src, id)
  local c = TacoV.Characters.get(src)
  local def = stepDef(id)
  if not c or not def then return end
  local pub = TacoV.Characters.publicData(src)
  if (pub.level or 1) >= N.hideFromLevel and id ~= 'level3' then return end
  local t = load(c.id)
  if t[id] then return end
  t[id] = true
  TacoV.DB.insert('INSERT IGNORE INTO newbie_steps (character_id, step) VALUES (?, ?)', { c.id, id })
  TacoV.Journal.move('bank', nil, { type = 'character', id = c.id }, def.bonus, 'neulingspfad', { note = id })
  TacoV.Accounts.push(src)
  TacoV.Log.write('character', ('Neulingspfad: %s (+%d $)'):format(def.label, def.bonus), { characterId = c.id })
  TriggerClientEvent('tacov:core:notify', src, 'success', ('Neulingspfad: %s – %d $ Bonus.'):format(def.label, def.bonus))
end
AddEventHandler('tacov:newbie:step', function(src, id) TacoV.Newbie.complete(src, id) end)

RegisterNetEvent('tacov:newbie:list', function()
  local src = source
  local c = TacoV.Characters.get(src)
  if not c then return end
  local t = load(c.id)
  local out = {}
  for _, s in ipairs(N.steps) do out[#out + 1] = { id = s.id, label = s.label, bonus = s.bonus, done = t[s.id] == true } end
  TriggerClientEvent('tacov:newbie:list', src, out, TacoV.Characters.publicData(src).level or 1)
end)

-- Level 3 prüfen (alle 5 Minuten)
AddEventHandler('tacov:core:ready', function()
  CreateThread(function()
    while true do
      Wait(300000)
      for src in pairs(TacoV.Players.all()) do
        local pub = TacoV.Characters.get(src) and TacoV.Characters.publicData(src)
        if pub and (pub.level or 1) >= 3 then TacoV.Newbie.complete(src, 'level3') end
      end
    end
  end)
end)
AddEventHandler('tacov:core:characterUnloaded', function(_, cid) done[cid] = nil end)
