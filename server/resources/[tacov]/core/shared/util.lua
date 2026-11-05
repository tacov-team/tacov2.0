-- Gemeinsame Hilfsfunktionen für Server und Client. Keine Spielwerte hier; die stehen in config/.
TacoV = TacoV or {}
TacoV.Util = {}

--- Rundet einen Geldbetrag auf ganze Dollar.
function TacoV.Util.money(n)
  return math.floor((tonumber(n) or 0) + 0.5)
end

--- Prüft, ob ein Wert eine ganze Zahl im Bereich [min, max] ist.
function TacoV.Util.intInRange(n, min, max)
  n = tonumber(n)
  if not n or n ~= math.floor(n) then return false end
  if min and n < min then return false end
  if max and n > max then return false end
  return true
end

--- Kürzt und bereinigt Freitext (Namen, Begründungen) auf eine Höchstlänge.
function TacoV.Util.cleanText(s, maxLen)
  s = tostring(s or ''):gsub('[%c]', ''):gsub('^%s+', ''):gsub('%s+$', '')
  if maxLen and #s > maxLen then s = s:sub(1, maxLen) end
  return s
end

--- Liest einen Server-Convar mit Standardwert.
function TacoV.Util.convar(name, default)
  local v = GetConvar(name, '')
  if v == '' then return default end
  return v
end
