-- E-Aufforderungen: Orte und Objekte in Reichweite (Bank, Automat, Ablage, Läden, Türen ...).
-- Module melden sich mit TacoV.Prompt.register an; der nächste passende Eintrag wird unten in der Mitte angezeigt,
-- E führt ihn aus. Interaktionen mit Spielern und Fahrzeugen laufen über das X-Rad (client/interact.lua).
TacoV = TacoV or {}
TacoV.Prompt = { entries = {}, current = nil }

--- entry = { id, label, order, when = function() -> bool | ctx, run = function(ctx) }
function TacoV.Prompt.register(entry)
  TacoV.Prompt.entries[entry.id] = entry
end

exports('promptRegister', TacoV.Prompt.register)

local function pick()
  local best, bestCtx = nil, nil
  for _, e in pairs(TacoV.Prompt.entries) do
    local ok = e.when and e.when() or false
    if ok and (not best or (e.order or 50) < (best.order or 50)) then
      best, bestCtx = e, ok
    end
  end
  return best, bestCtx
end

function TacoV.Prompt.use()
  local cur = TacoV.Prompt.current
  if not cur or TacoV.UI.current() then return end
  local ok = cur.entry.when and cur.entry.when()
  if ok then cur.entry.run(ok) end
end

CreateThread(function()
  local shownId = nil
  while true do
    Wait(250)
    local entry, ctx = nil, nil
    if TacoV.Client.character and not TacoV.UI.current() then entry, ctx = pick() end
    TacoV.Prompt.current = entry and { entry = entry, ctx = ctx } or nil
    local id = entry and entry.id or nil
    if id ~= shownId then
      shownId = id
      TacoV.UI.send('hint', entry and { key = 'E', text = entry.label } or nil)
    end
  end
end)
