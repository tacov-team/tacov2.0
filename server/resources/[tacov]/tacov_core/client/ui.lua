-- NUI-Brücke zur React-Oberfläche (ui/, Build in ui/ dieser Resource).
TacoV = TacoV or {}
TacoV.UI = {}

local openView = nil
local history = {}

function TacoV.UI.send(action, data)
  SendNUIMessage({ action = action, data = data })
end

--- Öffnet eine Ansicht. cursor=false für reine Tastatur-Ansichten (Befehlszeile).
function TacoV.UI.open(view, data, cursor)
  openView = view
  SetNuiFocus(true, cursor ~= false)
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

--- Befehlszeile (T): Liste aus config/commands.lua, Teambefehle nur für Teammitglieder sichtbar.
function TacoV.UI.openConsole()
  if openView then return end
  local list = {}
  for _, c in ipairs(TacoV.Config.Commands) do
    list[#list + 1] = { name = c.name, usage = c.usage, help = c.help, staff = c.right ~= nil }
  end
  TacoV.UI.open('console', { commands = list, history = history }, false)
end

RegisterNUICallback('close', function(_, cb)
  TacoV.UI.close()
  cb({})
end)

RegisterNUICallback('command', function(data, cb)
  local cmd = tostring(data.command or ''):gsub('^/', '')
  if #cmd > 0 then
    history[#history + 1] = cmd
    if #history > 10 then table.remove(history, 1) end
    if cmd == 'befehle' then
      for _, c in ipairs(TacoV.Config.Commands) do
        if not c.right or TacoV.Client.role ~= 'player' then
          TacoV.UI.send('notify', { kind = 'info', title = '/' .. c.usage, text = c.help })
        end
      end
    else
      -- Unbekannte Client-Befehle leitet FiveM automatisch an den Server weiter
      ExecuteCommand(cmd)
    end
  end
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
