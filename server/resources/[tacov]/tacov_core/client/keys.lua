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
bind('tacov_faction',   'TacoV: Fraktionsmenü',   K.faction,    function() TacoV.Client.openFactionMenu() end)
bind('tacov_interact',  'TacoV: Interaktion',     K.interact,   function() TacoV.Interact.open() end, function() TacoV.Interact.release() end)
bind('tacov_use',       'TacoV: Benutzen (E)',    K.use,        function() TacoV.Prompt.use() end)
bind('tacov_handsup',   'TacoV: Hände hoch',      K.handsUp,    function() TacoV.Client.toggleHandsUp() end)

--- Fraktionsmenü (F6, Konzept 2): Fraktionspunkte kommen mit dem Fraktionsmodul; Zivilistenaktionen und Fahrzeug sind
--- für alle da (bei Fraktionen als Unterpunkt, wie im Referenzbild des LSPD-Menüs).
function TacoV.Client.openFactionMenu()
  if TacoV.Menu.isOpen() then TacoV.Menu.close() return end
  local c = TacoV.Client.character
  local faction = c and c.faction
  local items = {}
  if faction then
    items[#items + 1] = { id = 'duty', label = 'Dienst', icon = 'shield', dim = true, badge = 'bald', section = faction:upper() }
    items[#items + 1] = { id = 'members', label = 'Mitglieder', icon = 'group', dim = true, badge = 'bald' }
    items[#items + 1] = { id = 'stash', label = 'Lager und Kasse', icon = 'box', dim = true, badge = 'bald' }
  end
  items[#items + 1] = { id = 'civil', label = 'Zivilistenaktionen', icon = 'user', sub = 'Hände hoch, Ausweis', section = faction and 'Allgemein' or nil }
  items[#items + 1] = { id = 'vehicle', label = 'Fahrzeug', icon = 'car', sub = 'Motor, Schloss, Kofferraum' }
  TacoV.Menu.open({
    id = 'faction', title = 'Fraktionsmenü', icon = 'shield',
    info = faction and (faction:upper() .. ' · Rang ' .. tostring(c.factionRank or 0)) or 'Zivilist · keine Fraktion',
    note = faction and 'Fraktionsfunktionen kommen mit dem Fraktionsmodul.' or 'Mit ↑ ↓ wählen, Enter bestätigen, Esc schließen',
    items = items,
  }, function(id)
    if id == 'vehicle' then TacoV.Menu.close() TacoV.Vehicles.openMenu() return end
    if id == 'civil' then
      TacoV.Menu.open({
        id = 'civil', title = 'Zivilistenaktionen', info = 'Fraktionsmenü · Allgemein', icon = 'user',
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

-- F9: außerhalb des Dienstes Admin-Dienst beginnen; im Dienst öffnet sich das Team-Menü (Punkt 5.1, Dienstende dort)
bind('tacov_admin', 'TacoV: Admin-Dienst / Team-Menü', K.admin, function()
  if TacoV.Client.role == 'player' then return end
  if TacoV.Client.aduty then TacoV.Admin.openMenu() else TriggerServerEvent('tacov:core:aduty:toggle') end
end)
