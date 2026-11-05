-- NUI-Brücke. Die eigentliche Oberfläche (React, nach den Boards in docs/design) kommt in Phase 3;
-- ui/index.html ist bis dahin ein Platzhalter mit der Charakterauswahl.
TacoV = TacoV or {}
TacoV.UI = {}

local openView = nil

function TacoV.UI.send(action, data)
  SendNUIMessage({ action = action, data = data })
end

function TacoV.UI.open(view, data)
  openView = view
  SetNuiFocus(true, true)
  TacoV.UI.send('open', { view = view, data = data })
end

function TacoV.UI.close()
  openView = nil
  SetNuiFocus(false, false)
  TacoV.UI.send('close')
end

function TacoV.UI.current()
  return openView
end

RegisterNUICallback('close', function(_, cb)
  TacoV.UI.close()
  cb({})
end)

RegisterNUICallback('selectCharacter', function(data, cb)
  TriggerServerEvent('tacov:core:selectCharacter', tonumber(data.id))
  cb({})
end)

RegisterNUICallback('createCharacter', function(data, cb)
  TriggerServerEvent('tacov:core:createCharacter', {
    firstName = data.firstName, lastName = data.lastName, birthDate = data.birthDate,
    origin = data.origin, gender = tonumber(data.gender) or 0, appearance = {},
  })
  cb({})
end)
