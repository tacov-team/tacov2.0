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
  "SetPedSuffersCriticalHits", "GetPlayers", "GetSoundId", "StopSound", "ReleaseSoundId", "SetNewWaypoint", "StopAnimTask", "AddPedDecorationFromHashes", "ClearPedDecorations", "SetVehicleSteerBias", "StopGameplayCamShaking", "ShakeGameplayCam", "AnimpostfxStop", "SetPedIsDrunk", "RestorePlayerStamina", "SetRunSprintMultiplierForPlayer", "IsEntityDead", "ResetPedMovementClipset", "SetPedMovementClipset", "HasAnimSetLoaded", "RequestAnimSet", "IsPedActiveInScenario", "IsPedUsingAnyScenario", "IsEntityPlayingAnim", "IsPedJumping", "IsPedSprinting", "IsPedRunning", "IsPedWalking", "SetResourceKvp", "GetResourceKvpString", "SetPlayerRoutingBucket", "TaskLeaveVehicle", "LocalPlayer", "GetNumberOfPedPropTextureVariations", "GetNumberOfPedPropDrawableVariations", "GetNumberOfPedTextureVariations", "DisplayRadar", "TaskStandStill", "PointCamAtCoord", "SetPedDefaultComponentVariation", "SetPlayerModel", "GetNumMakeupColors", "GetNumHairColors", "GetNumberOfPedDrawableVariations", "GetPedHeadOverlayNum", "SetPedHeadOverlayColor", "SetPedHeadOverlay", "SetPedEyeColor", "SetPedHairColor", "SetPedFaceFeature", "SetPedHeadBlendData", "SetEntityDrawOutlineShader", "SetEntityDrawOutlineColor", "SetEntityDrawOutline", "GetEntityPopulationType", "UseSnowWheelVfxWhenUnsheltered", "UseSnowFootVfxWhenUnsheltered", "SetForcePedFootstepsTracks", "SetForceVehicleTrails", "ForceSnowPass", "GetVehicleNumberPlateTextIndex", "SetVehicleNumberPlateTextIndex", "GetVehicleClass", "GetModTextLabel", "vector2", "CancelEvent", "EndTextCommandDisplayText", "AddTextComponentSubstringPlayerName", "BeginTextCommandDisplayText", "SetTextOutline", "SetTextCentre", "SetTextScale", "SetTextFont", "ClearDrawOrigin", "SetDrawOrigin", "NetworkGetEntityIsNetworked", "GetEntityType", "NetworkGetEntityOwner", "SetWeatherTypeNowPersist", "SetWeatherTypeOvertimePersist", "NetworkOverrideClockTime", "GetVehicleNumberOfPassengers", "IsVehicleSeatFree", "GetNumVehicleMods", "SetVehiclePetrolTankHealth", "SetVehicleUndriveable", "SetVehicleDeformationFixed", "IsModelAVehicle", "PlaceObjectOnGroundProperly", "SetEntityRotation", "SetEntityAlpha", "PlayPedAmbientSpeechNative", "TaskStartScenarioInPlace", "SetPedFleeAttributes", "SetPedDiesWhenInjured", "SetPedCanRagdollFromPlayerImpact", "SetBlockingOfNonTemporaryEvents", "CreatePed", "IsModelValid", "PlaySoundFromCoord", "RemoveDoorFromSystem", "DoorSystemSetOpenRatio", "DoorSystemSetDoorState", "AddDoorToSystem", "IsDisabledControlJustPressed", "DrawLine", "GetShapeTestResult", "StartShapeTestLosProbe", "GetGameplayCamCoord", "ClearPedBloodDamage", "SetPedArmour", "ClearPedProp", "SetPedPropIndex", "SetPedComponentVariation", "GetPedPropTextureIndex", "GetPedPropIndex", "GetPedPaletteVariation", "GetPedTextureVariation", "GetPedDrawableVariation", "GetEntityArchetypeName", "GetWaterHeightNoWaves", "Player", "DisableControlAction", "GetGameplayCamRot", "GetBlipInfoIdCoord", "GetFirstBlipInfoId", "GetGroundZFor_3dCoord", "PlaySoundFrontend", "AnimpostfxPlay", "GetEntityVelocity", "SetVehicleDirtLevel", "SetVehicleFixed", "SetVehicleWindowTint", "GetVehicleWindowTint", "SetVehicleWheelType", "GetVehicleWheelType", "IsToggleModOn", "ToggleVehicleMod", "SetVehicleModKit", "SetVehicleMod", "GetVehicleMod", "TaskWarpPedIntoVehicle", "DrawMarker", "SetBlipRouteColour", "SetBlipRoute", "GetGamePool", "GetVehiclePedIsIn", "SetVehicleDoorOpen", "SetVehicleDoorShut", "GetVehicleDoorLockStatus", "CreateCam", "SetCamCoord", "SetCamFov", "PointCamAtEntity", "SetCamActive", "RenderScriptCams", "DestroyCam",
}

ignore = { "212/_.*" }

-- fxmanifest.lua nutzt die Manifest-Funktionen von FiveM als Globale
files["**/fxmanifest.lua"] = { ignore = { "113" } }
files["**/vehicles.lua"] = { max_line_length = 200 }
files["**/dmv.lua"] = { max_line_length = 200 }
files["**/workshop.lua"] = { max_line_length = 200 }
files["**/traffic.lua"] = { max_line_length = 200 }
files["**/admin.lua"] = { max_line_length = 200 }
files["**/creator.lua"] = { max_line_length = 200 }
files["**/doors.lua"] = { max_line_length = 200 }
files["**/teleports.lua"] = { max_line_length = 200 }
files["**/access.lua"] = { max_line_length = 200 }
files["**/peds.lua"] = { max_line_length = 200 }
files["**/world.lua"] = { max_line_length = 200 }
files["**/refunds.lua"] = { max_line_length = 200 }
files["**/weather.lua"] = { max_line_length = 200 }
files["**/configedit.lua"] = { max_line_length = 200 }
files["**/devtools.lua"] = { max_line_length = 200 }
files["**/tickets.lua"] = { max_line_length = 200 }
files["**/anticheat.lua"] = { max_line_length = 200 }
files["**/appearance.lua"] = { max_line_length = 200 }
files["**/characters.lua"] = { max_line_length = 200 }
files["**/clothing.lua"] = { max_line_length = 200 }
files["**/clothingprice.lua"] = { max_line_length = 200 }
files["**/immigration.lua"] = { max_line_length = 200 }
files["**/housing.lua"] = { max_line_length = 200 }
files["**/newbie.lua"] = { max_line_length = 200 }
files["**/animations.lua"] = { max_line_length = 200 }
files["**/health.lua"] = { max_line_length = 200 }
files["**/fitness.lua"] = { max_line_length = 200 }
files["**/tattoos.lua"] = { max_line_length = 200 }
files["**/keys.lua"] = { max_line_length = 200 }
files["**/phone.lua"] = { max_line_length = 200 }
