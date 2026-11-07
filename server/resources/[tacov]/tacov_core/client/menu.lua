-- Listenmenüs (V4): Tastatur-Menü mit Untermenüs. Module öffnen ein Menü, bekommen Auswahl per Callback.
-- TacoV.Menu.open({ id, title, info, icon, note, items = { { id, label, icon, price, sub, dim, section, badge } } }, onSelect)
-- onSelect(itemId, menu) darf TacoV.Menu.open für ein Untermenü aufrufen; Backspace geht eine Ebene zurück.
TacoV = TacoV or {}
TacoV.Menu = {}

local stack = {} -- { def = ..., onSelect = fn }

local function show()
  local top = stack[#stack]
  if not top then
    TacoV.UI.close()
    return
  end
  local def = top.def
  TacoV.UI.open('menu', {
    id = def.id, title = def.title, info = def.info, icon = def.icon, note = def.note,
    items = def.items, depth = #stack - 1,
  }, false)
end

--- Öffnet ein Menü. Ist bereits eines offen, wird es als Untermenü darauf gestapelt.
function TacoV.Menu.open(def, onSelect)
  if TacoV.UI.current() and TacoV.UI.current() ~= 'menu' then return false end
  stack[#stack + 1] = { def = def, onSelect = onSelect }
  show()
  return true
end

--- Ersetzt die Einträge des offenen Menüs (z. B. nach einer Aktion), ohne die Ebene zu wechseln.
function TacoV.Menu.update(items, note)
  local top = stack[#stack]
  if not top then return end
  top.def.items = items
  if note ~= nil then top.def.note = note end
  show()
end

--- def.onClose() wird gerufen, wenn das Menü (per Zurück oder Schließen) verschwindet – z. B. um eine Vorschau zu löschen.
function TacoV.Menu.back()
  if #stack == 0 then return end
  local top = table.remove(stack)
  if top.def.onClose then top.def.onClose() end
  show()
end

function TacoV.Menu.close()
  local old = stack
  stack = {}
  for i = #old, 1, -1 do
    if old[i].def.onClose then old[i].def.onClose() end
  end
  TacoV.UI.close()
end

function TacoV.Menu.isOpen()
  return #stack > 0
end

AddEventHandler('tacov:ui:menu:select', function(data)
  local top = stack[#stack]
  if not top or type(data) ~= 'table' or data.menu ~= top.def.id then return end
  local id = tostring(data.id or '')
  local item
  for _, it in ipairs(top.def.items or {}) do
    if it.id == id then item = it break end
  end
  if not item or item.dim then return end
  if top.onSelect then top.onSelect(id, top.def, item) end
end)

AddEventHandler('tacov:ui:menu:back', function()
  TacoV.Menu.back()
end)

AddEventHandler('tacov:ui:menu:close', function()
  TacoV.Menu.close()
end)
