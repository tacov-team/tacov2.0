-- Tastenbelegung aus config/core.lua (Konzept 5). Jede Taste ruft ein Menü oder eine Aktion; Spieler können sie in den
-- FiveM-Einstellungen umlegen.
TacoV = TacoV or {}

local function bind(command, label, key, handler, release)
  RegisterCommand('+' .. command, function()
    if not TacoV.Client.character then return end
    handler()
  end, false)
  RegisterCommand('-' .. command, function()
    if release and TacoV.Client.character then release() end
  end, false)
  RegisterKeyMapping('+' .. command, label, 'keyboard', key)
end

local function soon(name)
  TacoV.UI.send('notify', { kind = 'info', text = name .. ' kommt in einer späteren Phase.' })
end

local K = TacoV.Config.Keys
bind('tacov_console',   'TacoV: Befehlszeile',    K.console,    function() TacoV.UI.openConsole() end)
bind('tacov_inventory', 'TacoV: Inventar',        K.inventory,  function()
  if TacoV.UI.current() == 'inventory' then TacoV.Inventory.close() else TacoV.Inventory.open() end
end)
bind('tacov_phone',     'TacoV: Handy',           K.phone,      function() soon('Das Handy') end)
bind('tacov_anims',     'TacoV: Animationen',     K.animations, function() soon('Das Animationsmenü') end)
bind('tacov_faction',   'TacoV: Aktionsmenü',     K.faction,    function() TacoV.Client.openActionMenu() end)
bind('tacov_interact',  'TacoV: Interaktion',     K.interact,   function() TacoV.Interact.open() end, function() TacoV.Interact.release() end)
bind('tacov_use',       'TacoV: Benutzen (E)',    K.use,        function() TacoV.Prompt.use() end)
bind('tacov_handsup',   'TacoV: Hände hoch',      K.handsUp,    function() TacoV.Client.toggleHandsUp() end)

--- Aktionsmenü (F6): Zivilistenaktionen als Unterpunkt, Fraktion/Fahrzeug folgen mit ihren Modulen.
function TacoV.Client.openActionMenu()
  if TacoV.Menu.isOpen() then TacoV.Menu.close() return end
  TacoV.Menu.open({
    id = 'actions', title = 'Aktionsmenü', info = 'Taste ' .. K.faction, icon = 'list',
    note = 'Mit ↑ ↓ wählen, Enter bestätigen, Esc schließen',
    items = {
      { id = 'civil', label = 'Zivilistenaktionen', icon = 'user', sub = 'Hände hoch, Ausweis' },
      { id = 'vehicle', label = 'Fahrzeug', icon = 'car', sub = 'Motor, Schloss, Kofferraum' },
      { id = 'faction', label = 'Fraktion', icon = 'shield', dim = true, badge = 'bald', section = 'Dienst' },
    },
  }, function(id)
    if id == 'vehicle' then TacoV.Menu.close() TacoV.Vehicles.openMenu() return end
    if id == 'civil' then
      TacoV.Menu.open({
        id = 'civil', title = 'Zivilistenaktionen', info = 'Aktionsmenü · Bürger', icon = 'user',
        items = {
          { id = 'handsup', label = 'Hände hoch', icon = 'hands', sub = 'Taste ' .. K.handsUp },
          { id = 'show_id', label = 'Ausweis vorzeigen', icon = 'id', sub = 'Zeigt deinen Ausweis den Spielern in der Nähe' },
        },
      }, function(sub)
        if sub == 'handsup' then TacoV.Menu.close() TacoV.Client.toggleHandsUp() end
        if sub == 'show_id' then TacoV.Menu.close() TriggerServerEvent('tacov:inventory:useItem', 'id_card') end
      end)
    end
  end)
end

-- Team-Menü nur anzeigen, wenn der Spieler Teammitglied ist (prüft der Server beim Öffnen erneut)
bind('tacov_admin', 'TacoV: Team-Menü', K.admin, function()
  if TacoV.Client.role == 'player' then return end
  soon('Das Team-Menü')
end)
