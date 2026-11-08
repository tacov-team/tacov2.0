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
  "GetClosestObjectOfType", "DoesBlipExist", "RemoveBlip", "AddBlipForCoord", "SetBlipSprite", "SetBlipColour",
  "SetBlipScale", "SetBlipAsShortRange", "BeginTextCommandSetBlipName", "AddTextComponentString", "EndTextCommandSetBlipName",
  "GetHashKey", "CreateObjectNoOffset", "DoesEntityExist", "DeleteEntity", "GetActivePlayers", "GetPlayerPed",
  "GetVehiclePedIsIn", "GetClosestVehicle", "GetDisplayNameFromVehicleModel", "GetEntityModel", "GetVehicleNumberPlateText",
  "GetSafeZoneSize", "GetAspectRatio", "GetActiveScreenResolution", "HideHudComponentThisFrame",
  "ClearPedTasks", "ClearPedTasksImmediately", "NetworkResurrectLocalPlayer", "ShutdownLoadingScreen", "ShutdownLoadingScreenNui", "IsPedInAnyVehicle", "RequestAnimDict", "HasAnimDictLoaded", "TaskPlayAnim",
  "GetEntitySpeed", "GetVehicleFuelLevel", "GetIsVehicleEngineRunning", "GetVehicleDoorLockStatus",
  "GetAllVehicles", "RequestModel", "HasModelLoaded", "IsModelInCdimage", "CreateVehicle", "SetVehicleNumberPlateText",
  "SetEntityAsMissionEntity", "SetVehicleOnGroundProperly", "SetVehicleEngineHealth", "SetVehicleBodyHealth",
  "GetVehicleEngineHealth", "GetVehicleBodyHealth", "SetVehicleColours", "GetVehicleColours", "SetVehicleExtraColours",
  "GetVehicleExtraColours", "SetVehicleFuelLevel", "GetVehicleCurrentRpm", "SetVehicleEngineOn", "GetPedInVehicleSeat",
  "SetVehicleDoorsLocked", "NetworkRequestControlOfEntity", "NetworkHasControlOfEntity", "Entity", "SetModelAsNoLongerNeeded",
  "SetVehicleLights", "IsDisabledControlPressed", "SetEntityCollision", "SetNuiFocusKeepInput", "DisableAllControlActions", "EnableControlAction",
  "SetPedSuffersCriticalHits", "GetPlayers", "ClearPedBloodDamage", "SetPedArmour", "ClearPedProp", "SetPedPropIndex", "SetPedComponentVariation", "GetPedPropTextureIndex", "GetPedPropIndex", "GetPedPaletteVariation", "GetPedTextureVariation", "GetPedDrawableVariation", "GetEntityArchetypeName", "GetWaterHeightNoWaves", "Player", "DisableControlAction", "GetGameplayCamRot", "GetBlipInfoIdCoord", "GetFirstBlipInfoId", "GetGroundZFor_3dCoord", "PlaySoundFrontend", "AnimpostfxPlay", "GetEntityVelocity", "SetVehicleDirtLevel", "SetVehicleFixed", "SetVehicleWindowTint", "GetVehicleWindowTint", "SetVehicleWheelType", "GetVehicleWheelType", "IsToggleModOn", "ToggleVehicleMod", "SetVehicleModKit", "SetVehicleMod", "GetVehicleMod", "TaskWarpPedIntoVehicle", "DrawMarker", "SetBlipRouteColour", "SetBlipRoute", "GetGamePool", "GetVehiclePedIsIn", "SetVehicleDoorOpen", "SetVehicleDoorShut", "GetVehicleDoorLockStatus", "CreateCam", "SetCamCoord", "SetCamFov", "PointCamAtEntity", "SetCamActive", "RenderScriptCams", "DestroyCam",
}

ignore = { "212/_.*" }

-- fxmanifest.lua nutzt die Manifest-Funktionen von FiveM als Globale
files["**/fxmanifest.lua"] = { ignore = { "113" } }
files["**/vehicles.lua"] = { max_line_length = 200 }
files["**/dmv.lua"] = { max_line_length = 200 }
files["**/workshop.lua"] = { max_line_length = 200 }
files["**/traffic.lua"] = { max_line_length = 200 }
files["**/admin.lua"] = { max_line_length = 200 }
