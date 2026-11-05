-- Bedürfnisse: Hunger und Durst sinken mit der Zeit (Konzept 5), Fitness kommt aus Sport und Energydrinks.
TacoV = TacoV or {}
TacoV.Needs = {}

local TICK = 60 -- Sekunden

local function clamp(v) return math.max(0, math.min(100, v)) end

--- Verändert einen Wert (hunger, thirst, fitness, alcohol) und schickt den Stand an den Client.
function TacoV.Needs.add(source, key, delta)
  local c = TacoV.Characters.get(source)
  if not c then return false end
  c.needs[key] = clamp((c.needs[key] or 0) + delta)
  TacoV.Needs.push(source)
  return true
end

function TacoV.Needs.push(source)
  local c = TacoV.Characters.get(source)
  if not c then return end
  TriggerClientEvent('tacov:core:needs', source, {
    hunger = c.needs.hunger or 100, thirst = c.needs.thirst or 100,
    fitness = c.needs.fitness or 0, alcohol = c.needs.alcohol or 0,
  })
end

CreateThread(function()
  while true do
    Wait(TICK * 1000)
    local cfg = TacoV.Config.Needs
    local dHunger = 100 / cfg.hungerMinutesToEmpty * (TICK / 60)
    local dThirst = 100 / cfg.thirstMinutesToEmpty * (TICK / 60)
    local dAlcohol = cfg.alcohol.decayPer10Min * (TICK / 600)
    for src in pairs(TacoV.Players.all()) do
      local c = TacoV.Characters.get(src)
      if c then
        c.needs.hunger = clamp((c.needs.hunger or 100) - dHunger)
        c.needs.thirst = clamp((c.needs.thirst or 100) - dThirst)
        if (c.needs.alcohol or 0) > 0 then c.needs.alcohol = math.max(0, c.needs.alcohol - dAlcohol) end
        TacoV.Needs.push(src)
      end
    end
  end
end)

exports('needsAdd', TacoV.Needs.add)
