std = "lua54"
max_line_length = 140
codes = true

-- FiveM-Globale
globals = {
  "Citizen", "CreateThread", "Wait", "SetTimeout",
  "RegisterNetEvent", "AddEventHandler", "TriggerEvent",
  "TriggerClientEvent", "TriggerServerEvent", "RegisterCommand",
  "GetPlayerName", "GetPlayerIdentifiers", "GetNumPlayerIndices",
  "GetConvar", "GetConvarInt", "GetCurrentResourceName",
  "exports", "source", "vector3", "vector4", "vec3", "vec4", "json",
  "SendNUIMessage", "RegisterNUICallback", "SetNuiFocus",
  "PlayerPedId", "GetEntityCoords", "GetPlayerServerId", "PlayerId",
  "NetworkGetNetworkIdFromEntity", "NetworkGetEntityFromNetworkId",
  "MySQL",
}

ignore = { "212/_.*" }
