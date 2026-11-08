-- Config im Spiel (Punkt 5.13), gemeinsam: welche Tabellen bearbeitbar sind, Pfad-Zugriff, Anwenden von Überschreibungen.
TacoV = TacoV or {}
TacoV.ConfigEdit = {}

-- Bearbeitbare Bereiche (Zahlen, Wahrheitswerte, Texte auf Blattebene). Listen/Items/Orte bleiben Code- bzw. Creator-Sache.
TacoV.ConfigEdit.roots = {
  { key = 'Economy',     label = 'Wirtschaft' },
  { key = 'Salaries',    label = 'Gehälter' },
  { key = 'Needs',       label = 'Hunger und Durst' },
  { key = 'Level',       label = 'Level' },
  { key = 'Traffic',     label = 'Blitzer und Kfz-Steuer' },
  { key = 'DMV',         label = 'DMV / Fahrschule' },
  { key = 'Workshop',    label = 'Werkstatt' },
  { key = 'Vehicles',    label = 'Fahrzeuge (Klassen)' },
  { key = 'Inventory',   label = 'Inventar' },
  { key = 'World',       label = 'Welt (Zeit, Wetter)' },
  { key = 'Restart',     label = 'Neustart' },
  { key = 'Permissions', label = 'Team-Grenzen (Sperren, Erstattungen)' },
  { key = 'Voice',       label = 'Stimme' },
  { key = 'Onboarding',  label = 'Einstieg' },
  { key = 'Status',      label = 'Status' },
  { key = 'AntiCheat',   label = 'Anti-Cheat (Schwellen)' },
}

local function split(path)
  local parts = {}
  for p in tostring(path):gmatch('[^%.]+') do parts[#parts + 1] = tonumber(p) or p end
  return parts
end

function TacoV.ConfigEdit.get(path)
  local node = TacoV.Config
  for _, k in ipairs(split(path)) do
    if type(node) ~= 'table' then return nil end
    node = node[k]
  end
  return node
end

--- Setzt einen Blattwert (nur wenn der Pfad existiert und der Typ passt). Gibt true/false, Fehler.
function TacoV.ConfigEdit.set(path, value)
  local parts = split(path)
  if #parts < 2 then return false, 'path' end
  local allowed = false
  for _, r in ipairs(TacoV.ConfigEdit.roots) do if r.key == parts[1] then allowed = true end end
  if not allowed then return false, 'root' end
  local node = TacoV.Config
  for i = 1, #parts - 1 do
    node = node[parts[i]]
    if type(node) ~= 'table' then return false, 'path' end
  end
  local last = parts[#parts]
  local cur = node[last]
  if cur == nil or type(cur) == 'table' or type(cur) == 'function' then return false, 'leaf' end
  if type(cur) ~= type(value) then return false, 'type' end
  node[last] = value
  return true
end

TacoV.ConfigEdit.defaults = {}
function TacoV.ConfigEdit.remember(path)
  if TacoV.ConfigEdit.defaults[path] == nil then TacoV.ConfigEdit.defaults[path] = TacoV.ConfigEdit.get(path) end
end

function TacoV.ConfigEdit.apply(overrides)
  for path, v in pairs(overrides or {}) do
    TacoV.ConfigEdit.remember(path)
    TacoV.ConfigEdit.set(path, v)
  end
end
