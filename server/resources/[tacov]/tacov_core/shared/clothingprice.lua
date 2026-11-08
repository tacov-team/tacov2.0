-- Preise für Kleidung und Friseur (Punkt 6.2/6.3), gemeinsam für Server (Abrechnung) und Client (Anzeige im Editor).
TacoV = TacoV or {}
TacoV.Clothing = TacoV.Clothing or {}
local Cfg = TacoV.Config.Clothing

local function same(a, b) return (a and a[1] or -1) == (b and b[1] or -1) and (a and a[2] or 0) == (b and b[2] or 0) end

--- Preis der Kleidungsänderung zwischen alt und neu
function TacoV.Clothing.price(old, new)
  local sum = 0
  for k, p in pairs(Cfg.prices) do
    if k:sub(1, 1) == 'p' then
      if not same((old.props or {})[k:sub(2)], (new.props or {})[k:sub(2)]) then sum = sum + p end
    else
      if not same((old.components or {})[k], (new.components or {})[k]) then sum = sum + p end
    end
  end
  return sum
end

--- Preis der Friseur-Änderung (Frisur/Farbe, Bart, Brauen, Make-up …)
function TacoV.Clothing.barberPrice(old, new)
  local sum = 0
  local oh, nh = old.hair or {}, new.hair or {}
  if (oh.style or 0) ~= (nh.style or 0) or (oh.color or 0) ~= (nh.color or 0) or (oh.highlight or 0) ~= (nh.highlight or 0) then sum = sum + Cfg.barber.hair end
  for id, p in pairs(Cfg.barber) do
    if id ~= 'hair' then
      local a, b = (old.overlays or {})[id] or {}, (new.overlays or {})[id] or {}
      if (a.style or -1) ~= (b.style or -1) or (a.color or 0) ~= (b.color or 0) or math.abs((a.opacity or 1) - (b.opacity or 1)) > 0.01 then sum = sum + p end
    end
  end
  return sum
end


--- Preis neuer Tattoos (nur hinzugekommene zählen; Entfernen ist kostenlos)
function TacoV.Clothing.tattooPrice(old, new)
  local had = {}
  for _, t in ipairs(old.tattoos or {}) do had[t.collection .. '|' .. t.overlay] = true end
  local sum = 0
  for _, t in ipairs(new.tattoos or {}) do
    if not had[t.collection .. '|' .. t.overlay] then
      local price = 200
      for _, def in ipairs(TacoV.Config.Tattoos) do
        if def.collection == t.collection and (def.overlay == t.overlay or def.overlayF == t.overlay) then price = def.price end
      end
      sum = sum + price
    end
  end
  return sum
end
