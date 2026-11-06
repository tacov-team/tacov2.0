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
bind('tacov_faction',   'TacoV: Fraktionsmenü',   K.faction,    function() soon('Das Fraktionsmenü') end)
bind('tacov_interact',  'TacoV: Interaktion',     K.interact,   function() TacoV.Interact.open() end, function() TacoV.Interact.release() end)
bind('tacov_use',       'TacoV: Benutzen (E)',    K.use,        function() TacoV.Prompt.use() end)
bind('tacov_handsup',   'TacoV: Hände hoch',      K.handsUp,    function() TacoV.Client.toggleHandsUp() end)

-- Team-Menü nur anzeigen, wenn der Spieler Teammitglied ist (prüft der Server beim Öffnen erneut)
bind('tacov_admin', 'TacoV: Team-Menü', K.admin, function()
  if TacoV.Client.role == 'player' then return end
  soon('Das Team-Menü')
end)
