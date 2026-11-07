-- Blitzer (Client): meldet dem Server, wenn das eigene Fahrzeug im Messbereich zu schnell ist; der Server misst nach.
TacoV = TacoV or {}

local Cfg = TacoV.Config.Traffic
local lastReport = {}

CreateThread(function()
  while true do
    Wait(400)
    local ped = PlayerPedId()
    local veh = TacoV.Client.character and GetVehiclePedIsIn(ped, false) or 0
    if veh ~= 0 and GetPedInVehicleSeat(veh, -1) == ped then
      local cam = TacoV.Client.nearestLocation('speedcam', Cfg.radius)
      if cam then
        local speed = GetEntitySpeed(veh) * 3.6
        local now = GetGameTimer()
        if speed > (tonumber(cam.limit) or 70) + Cfg.tolerance and (not lastReport[cam.name] or now - lastReport[cam.name] > Cfg.cooldownSeconds * 1000) then
          lastReport[cam.name] = now
          TriggerServerEvent('tacov:traffic:flash', cam.name, NetworkGetNetworkIdFromEntity(veh))
        end
      end
    end
  end
end)

RegisterNetEvent('tacov:traffic:flashed', function()
  AnimpostfxPlay('SuccessNeutral', 300, false)
  PlaySoundFrontend(-1, 'Camera_Shoot', 'Phone_Soundset_Franklin', true)
end)
