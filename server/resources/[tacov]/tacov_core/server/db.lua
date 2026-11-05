-- Datenbankzugriff über die eigene Resource tacov_db (JS, Rückruf-Exports). Alle Module nutzen nur TacoV.DB.
TacoV = TacoV or {}
TacoV.DB = {}

local NULL = '\0NULL' -- Platzhalter für nil in Parameterlisten (tacov_db macht daraus SQL NULL)
local db = exports.tacov_db
local ready = false

--- Baut aus einer Lua-Liste mit Lücken eine lückenlose Liste; nil wird zum Platzhalter.
local function pack(params)
  if type(params) ~= 'table' then return {} end
  local n = 0
  for k in pairs(params) do
    if type(k) == 'number' and k > n then n = k end
  end
  local out = {}
  for i = 1, n do
    local v = params[i]
    if v == nil then out[i] = NULL else out[i] = v end
  end
  return out
end

--- Ruft einen Export mit Rückruf auf und wartet auf das Ergebnis. Fehler werden als Lua-Fehler geworfen.
local function await(name, a, b)
  local p = promise.new()
  db[name](nil, a, b, function(result, err)
    if err then p:reject(err) else p:resolve(result) end
  end)
  return Citizen.Await(p)
end

function TacoV.DB.isReady()
  return ready
end

--- Wartet, bis die Datenbank erreichbar ist (beim Resource-Start).
function TacoV.DB.waitReady()
  while not ready do Wait(50) end
end

function TacoV.DB.query(sql, params)
  return await('query', sql, pack(params))
end

function TacoV.DB.single(sql, params)
  return await('single', sql, pack(params))
end

function TacoV.DB.scalar(sql, params)
  return await('scalar', sql, pack(params))
end

function TacoV.DB.insert(sql, params)
  return await('insert', sql, pack(params))
end

function TacoV.DB.update(sql, params)
  return await('update', sql, pack(params))
end

--- Führt mehrere Anweisungen in einer Transaktion aus. queries = { {sql, params}, ... }. Gibt true oder false zurück.
function TacoV.DB.transaction(queries)
  local list = {}
  for i, q in ipairs(queries) do list[i] = { q[1], pack(q[2]) } end
  local ok, res = pcall(await, 'transaction', list)
  return ok and res == true
end

CreateThread(function()
  local tries = 0
  while not ready do
    local ok = pcall(function()
      if not db:ready() then error('db') end
      await('scalar', 'SELECT 1', {})
    end)
    if ok then
      ready = true
      print('^2[tacov_core]^7 Datenbank verbunden')
    else
      tries = tries + 1
      if tries % 10 == 1 then print('^3[tacov_core]^7 Warte auf Datenbank ...') end
      Wait(1000)
    end
  end
end)
