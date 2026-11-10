-- Tastenbelegung aus config/core.lua (Konzept 5). Jede Taste ruft ein Menü oder eine Aktion; Spieler können sie in den
-- FiveM-Einstellungen umlegen.
TacoV = TacoV or {}

local function bind(command, label, key, handler, release)
  RegisterCommand('+' .. command, function()
    if not TacoV.Client.character then return end
    -- Bei offenem Listenmenü (Spieler kann laufen) nur die Menü-Tasten selbst durchlassen
    if TacoV.UI.current() == 'menu' and command ~= 'tacov_faction' and command ~= 'tacov_admin' and command ~= 'tacov_actions' then return end
    if TacoV.UI.current() == 'phone' and command ~= 'tacov_phone' then return end
    -- gefesselt oder in Haft: nur Befehlszeile
    if (LocalPlayer.state.cuffed or LocalPlayer.state.jailed) and command ~= 'tacov_console' then return end
    handler()
  end, false)
  RegisterCommand('-' .. command, function()
    if release and TacoV.Client.character then release() end
  end, false)
  RegisterKeyMapping('+' .. command, label, 'keyboard', key)
end

local K = TacoV.Config.Keys
bind('tacov_console',   'TacoV: Befehlszeile',    K.console,    function() TacoV.UI.openConsole() end)
bind('tacov_inventory', 'TacoV: Inventar',        K.inventory,  function()
  if TacoV.UI.current() == 'inventory' then TacoV.Inventory.close() else TacoV.Inventory.open() end
end)
bind('tacov_phone',     'TacoV: Handy',           K.phone,      function() TacoV.Phone.toggle() end)
bind('tacov_anims',     'TacoV: Animationen',     K.animations, function() TacoV.Anims.openMenu() end)
bind('tacov_actions',   'TacoV: Aktionen',        K.actions,    function() TacoV.Client.openActionsMenu() end)
bind('tacov_faction',   'TacoV: Fraktionsmenü',   K.faction,    function() TacoV.Client.openFactionMenu() end)
bind('tacov_interact',  'TacoV: Interaktion',     K.interact,   function() TacoV.Interact.open() end, function() TacoV.Interact.release() end)
bind('tacov_use',       'TacoV: Benutzen (E)',    K.use,        function() TacoV.Prompt.use() end)
bind('tacov_handsup',   'TacoV: Hände hoch',      K.handsUp,    function() TacoV.Client.toggleHandsUp() end)

--- Aktionsmenü (F4): Ausweis, Hände hoch, Neulingspfad, Fahrzeug – für alle Spieler. Outfits nur im Laden und am Kleiderschrank.
function TacoV.Client.openActionsMenu()
  if TacoV.Menu.isOpen() then TacoV.Menu.close() return end
  TacoV.Menu.open({
    id = 'actions', title = 'Aktionen', icon = 'user', info = 'Alltag',
    note = 'Mit ↑ ↓ wählen, Enter bestätigen, Esc schließen',
    items = {
      { id = 'handsup', label = 'Hände hoch', icon = 'hands', sub = 'Taste ' .. K.handsUp, section = 'Ich' },
      { id = 'show_id', label = 'Ausweis vorzeigen', icon = 'id', sub = 'Zeigt deinen Ausweis den Spielern in der Nähe' },
      { id = 'newbie', label = 'Neulingspfad', icon = 'star', sub = 'Zehn Schritte mit Bonus' },
      { id = 'vehicle', label = 'Fahrzeug', icon = 'car', sub = 'Motor, Schloss, Kofferraum', section = 'Fahrzeug' },
      { id = 'taxi_call', label = 'Taxi rufen', icon = 'phone', sub = 'Taxifahrer im Dienst bekommen deinen Standort', section = 'Unterwegs' },
      (TacoV.Jobs.state and TacoV.Jobs.state.job == 'taxi') and { id = 'taxi_fare', label = 'Fahrgast suchen', icon = 'user', sub = 'NPC-Fahrgast mit Ziel' } or nil,
    },
  }, function(id)
    if id == 'vehicle' then TacoV.Menu.close() TacoV.Vehicles.openMenu() return end
    if id == 'taxi_call' then TacoV.Menu.close() TacoV.Jobs.callTaxi() return end
    if id == 'taxi_fare' then TacoV.Menu.close() TacoV.Jobs.findFare() return end
    if id == 'handsup' then TacoV.Menu.close() TacoV.Client.toggleHandsUp() end
    if id == 'show_id' then TacoV.Menu.close() TriggerServerEvent('tacov:inventory:useItem', 'id_card') end
    if id == 'newbie' then TacoV.Menu.close() TacoV.Housing.openNewbie() end
  end)
end

--- Fraktionsmenü (F6, Konzept 2): Dienst, Mitglieder, Lager/Kasse und Fraktionsaktionen (z. B. Festnehmen) kommen mit
--- dem Fraktionsmodul (Phase 8). Zivilisten sehen nur den Hinweis.
function TacoV.Client.openFactionMenu()
  if TacoV.Menu.isOpen() then TacoV.Menu.close() return end
  local c = TacoV.Client.character
  if not c or not c.faction then
    TacoV.UI.send('notify', { kind = 'info', text = 'Du bist in keiner Fraktion. Alltagsaktionen findest du auf ' .. K.actions .. '.' })
    return
  end
  TacoV.Factions.openMenu()
end

-- F9: außerhalb des Dienstes Admin-Dienst beginnen; im Dienst öffnet sich das Team-Menü (Punkt 5.1, Dienstende dort)
bind('tacov_admin', 'TacoV: Admin-Dienst / Team-Menü', K.admin, function()
  if TacoV.Client.role == 'player' then return end
  if TacoV.Client.aduty then TacoV.Admin.openMenu() else TriggerServerEvent('tacov:core:aduty:toggle') end
end)
