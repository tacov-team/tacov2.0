-- Bank-Client: Blips für Filialen, Erkennung von Schalter und Geldautomat, Einträge im Interaktionsrad.
TacoV = TacoV or {}
TacoV.Bank = {}

local atmModels = {}
for _, m in ipairs(TacoV.Config.AtmModels) do atmModels[#atmModels + 1] = GetHashKey(m) end

--- Nächster Geldautomat (Grundspiel-Modell) in Reichweite, oder nil.
function TacoV.Bank.nearestAtm(maxDist)
  local pos = GetEntityCoords(PlayerPedId())
  for _, hash in ipairs(atmModels) do
    local obj = GetClosestObjectOfType(pos.x, pos.y, pos.z, maxDist or 1.5, hash, false, false, false)
    if obj ~= 0 then return obj end
  end
  return nil
end

function TacoV.Bank.nearestBranch(maxDist)
  return TacoV.Client.nearestLocation('bank', maxDist or 4.0)
end

function TacoV.Bank.open(kind)
  if TacoV.UI.current() then return end
  if kind == 'atm' then
    local atm = TacoV.Bank.nearestAtm(1.5)
    if not atm then return end
    TriggerServerEvent('tacov:bank:open', 'atm', GetEntityCoords(atm))
  else
    TriggerServerEvent('tacov:bank:open', 'bank')
  end
end

function TacoV.Bank.close()
  if TacoV.UI.current() == 'bank' then
    TacoV.UI.close()
    TriggerServerEvent('tacov:bank:close')
  end
end

RegisterNetEvent('tacov:bank:data', function(data)
  if TacoV.UI.current() == 'bank' then
    TacoV.UI.send('open', { view = 'bank', data = data })
  else
    TacoV.UI.open('bank', data)
  end
end)

AddEventHandler('tacov:ui:bank:action', function(data)
  TriggerServerEvent('tacov:bank:action', data)
end)

AddEventHandler('tacov:ui:bank:close', function()
  TacoV.Bank.close()
end)

TacoV.Interact.register({
  id = 'bank', label = 'Bank', icon = 'cash', order = 1,
  when = function() return TacoV.Bank.nearestBranch(4.0) ~= nil end,
  run = function() TacoV.Bank.open('bank') end,
})
TacoV.Interact.register({
  id = 'atm', label = 'Automat', icon = 'cash', order = 1,
  when = function() return TacoV.Bank.nearestAtm(1.5) ~= nil end,
  run = function() TacoV.Bank.open('atm') end,
})

-- Hinweis unten in der Mitte, wenn man an Schalter oder Automat steht
CreateThread(function()
  local shown = nil
  while true do
    Wait(500)
    local hint = nil
    if TacoV.Client.character and not TacoV.UI.current() then
      if TacoV.Bank.nearestBranch(4.0) then hint = 'Bank · X halten'
      elseif TacoV.Bank.nearestAtm(1.5) then hint = 'Geldautomat · X halten' end
    end
    if hint ~= shown then
      shown = hint
      TacoV.UI.send('hint', hint)
    end
  end
end)
