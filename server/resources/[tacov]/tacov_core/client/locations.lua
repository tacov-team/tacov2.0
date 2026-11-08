-- Orte vom Server: Liste merken, Blips setzen, Nähe-Abfrage für andere Client-Module.
TacoV = TacoV or {}
TacoV.Client = TacoV.Client or {}
TacoV.Client.locations = {}

local blips = {}

local function clearBlips()
  for _, b in ipairs(blips) do if DoesBlipExist(b) then RemoveBlip(b) end end
  blips = {}
end

local function makeBlips()
  clearBlips()
  for _, l in ipairs(TacoV.Client.locations) do
    local def = TacoV.Config.Blips[l.kind]
    if l.kind == 'shop' and TacoV.Config.Shops[l.shop] then
      def = TacoV.Config.Shops[l.shop].blip
      def.label = TacoV.Config.Shops[l.shop].label
    end
    if def and not def.hidden and not (l.extra and l.extra.noblip) then
      local b = AddBlipForCoord(l.x, l.y, l.z)
      SetBlipSprite(b, def.sprite)
      SetBlipColour(b, def.color)
      SetBlipScale(b, def.scale or 0.8)
      SetBlipAsShortRange(b, true)
      BeginTextCommandSetBlipName('STRING')
      AddTextComponentString(l.label or def.label)
      EndTextCommandSetBlipName(b)
      blips[#blips + 1] = b
    end
  end
end

RegisterNetEvent('tacov:core:locations', function(list)
  TacoV.Client.locations = list or {}
  makeBlips()
end)

--- Nächster Ort einer Art in Reichweite, oder nil.
function TacoV.Client.nearestLocation(kind, maxDist)
  local pos = GetEntityCoords(PlayerPedId())
  local best, bestD = nil, maxDist or 5.0
  for _, l in ipairs(TacoV.Client.locations) do
    if l.kind == kind then
      local d = #(pos - vector3(l.x, l.y, l.z))
      if d < bestD then best, bestD = l, d end
    end
  end
  return best, bestD
end

AddEventHandler('onResourceStop', function(res)
  if res == GetCurrentResourceName() then clearBlips() end
end)
