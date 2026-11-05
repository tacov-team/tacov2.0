std = "lua54"
max_line_length = 160
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
  "promise", "TacoV",
  "DropPlayer", "GetPlayerPed", "GetEntityHeading", "LoadResourceFile", "GetResourceState",
  "NetworkIsSessionStarted", "SetEntityVisible", "FreezeEntityPosition", "SetEntityInvincible",
  "RequestCollisionAtCoord", "SetEntityCoordsNoOffset", "SetEntityHeading", "HasCollisionLoadedAroundEntity",
  "GetGameTimer", "DoScreenFadeOut", "DoScreenFadeIn", "IsControlPressed",
  "RegisterKeyMapping", "ExecuteCommand", "GetEntityHealth", "GetEntityMaxHealth", "GetPedArmour",
  "GetStreetNameAtCoord", "GetStreetNameFromHashKey", "GetLabelText", "GetNameOfZone", "SetEntityHealth",
  "ClearPedTasks", "IsPedInAnyVehicle", "RequestAnimDict", "HasAnimDictLoaded", "TaskPlayAnim",
}

ignore = { "212/_.*" }

-- fxmanifest.lua nutzt die Manifest-Funktionen von FiveM als Globale
files["**/fxmanifest.lua"] = { ignore = { "113" } }
