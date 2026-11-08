-- NUI-Brücke zur React-Oberfläche (ui/, Build in ui/ dieser Resource).
TacoV = TacoV or {}
TacoV.UI = {}

local openView = nil
local history = {}

function TacoV.UI.send(action, data)
  SendNUIMessage({ action = action, data = data })
end

--- Öffnet eine Ansicht. cursor=false für reine Tastatur-Ansichten (Befehlszeile).
--- keepInput=true: das Spiel behält die Tastatur (für Halten-Menüs wie das X-Rad); Bewegung/Kamera werden solange gesperrt.
--- keepInput='walk': Spieler kann weiterlaufen; nur die Menü-Tasten (Pfeile, Enter, Backspace, Esc) gehen nicht ans Spiel.
local WALK_BLOCK = { 27, 172, 173, 174, 175, 177, 191, 194, 199, 200, 201, 202, 243, 322, 37, 24, 25, 257, 140, 141, 142 }
function TacoV.UI.open(view, data, cursor, keepInput)
  openView = view
  SetNuiFocus(true, cursor ~= false)
  SetNuiFocusKeepInput(keepInput == true or keepInput == 'walk')
  if keepInput == 'walk' then
    CreateThread(function()
      while openView == view do
        for _, c in ipairs(WALK_BLOCK) do DisableControlAction(0, c, true) end
        Wait(0)
      end
    end)
  elseif keepInput then
    CreateThread(function()
      while openView == view do
        DisableAllControlActions(0)
        EnableControlAction(0, 73, true) -- X (Loslassen erkennen)
        EnableControlAction(0, 200, true) -- Esc
        Wait(0)
      end
    end)
  end
  TacoV.UI.send('open', { view = view, data = data })
end

function TacoV.UI.close()
  openView = nil
  SetNuiFocusKeepInput(false)
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

--- Texteingabe: TacoV.UI.ask({ title, label, placeholder, value, maxLength, numeric }, function(text) end) – nil bei Abbruch.
local askCb = nil
function TacoV.UI.ask(opts, cb)
  if openView and openView ~= 'menu' then return false end
  local wasMenu = openView == 'menu'
  askCb = function(v)
    askCb = nil
    openView = nil
    SetNuiFocusKeepInput(false)
    SetNuiFocus(false, false)
    if wasMenu and TacoV.Menu.isOpen() then TacoV.Menu.refresh() else TacoV.UI.send('close') end
    cb(v)
  end
  openView = 'ask'
  SetNuiFocus(true, true)
  SetNuiFocusKeepInput(false)
  TacoV.UI.send('open', { view = 'ask', data = opts })
  return true
end
AddEventHandler('tacov:ui:ask:submit', function(d) if askCb then askCb(tostring(d.value or '')) end end)
AddEventHandler('tacov:ui:ask:cancel', function() if askCb then askCb(nil) end end)

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

-- Allgemeine Aktion einer Ansicht: { view, action, data } -> Event tacov:ui:<view>:<action> (Module hören darauf)
RegisterNUICallback('action', function(data, cb)
  if type(data) == 'table' and type(data.view) == 'string' and type(data.action) == 'string' then
    TriggerEvent('tacov:ui:' .. data.view .. ':' .. data.action, data.data or {})
  end
  cb({})
end)

RegisterNUICallback('selectCharacter', function(data, cb)
  TriggerServerEvent('tacov:core:selectCharacter', tonumber(data.id))
  cb({})
end)

RegisterNUICallback('createCharacter', function(data, cb)
  cb({})
  -- Erst das Aussehen (Charaktereditor, Punkt 6.1), dann legt der Server den Charakter an
  local form = { firstName = data.firstName, lastName = data.lastName, birthDate = data.birthDate, origin = data.origin, gender = tonumber(data.gender) or 0 }
  local model = form.gender == 1 and 'mp_f_freemode_01' or 'mp_m_freemode_01'
  openView = nil
  SetNuiFocus(false, false)
  TacoV.UI.send('close')
  local spot = TacoV.Config.Onboarding.editorSpot or TacoV.Config.Onboarding.spawn
  local opts = { appearance = TacoV.Appearance.default(model), spot = spot, title = 'Dein Aussehen', doneLabel = 'Charakter anlegen' }
  TacoV.Appearance.openEditor(opts, function(appearance)
    if appearance then
      form.appearance = appearance
      TriggerServerEvent('tacov:core:createCharacter', form)
    else
      local ped = PlayerPedId()
      SetEntityVisible(ped, false, false)
      FreezeEntityPosition(ped, true)
      if TacoV.Client.lastCharacters then TacoV.UI.open('characters', TacoV.Client.lastCharacters) end
    end
  end)
end)
