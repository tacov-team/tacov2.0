-- Datenbankzugriff über oxmysql (MIT). Alle Module nutzen diese Hülle, nie MySQL direkt.
TacoV = TacoV or {}
TacoV.DB = {}

local ready = false

function TacoV.DB.isReady()
  return ready
end

--- Wartet, bis die Datenbank erreichbar ist (beim Resource-Start).
function TacoV.DB.waitReady()
  while not ready do Wait(50) end
end

function TacoV.DB.query(sql, params)
  return MySQL.query.await(sql, params or {})
end

function TacoV.DB.single(sql, params)
  return MySQL.single.await(sql, params or {})
end

function TacoV.DB.scalar(sql, params)
  return MySQL.scalar.await(sql, params or {})
end

function TacoV.DB.insert(sql, params)
  return MySQL.insert.await(sql, params or {})
end

function TacoV.DB.update(sql, params)
  return MySQL.update.await(sql, params or {})
end

--- Führt mehrere Anweisungen in einer Transaktion aus. queries = { {sql, params}, ... }
function TacoV.DB.transaction(queries)
  return MySQL.transaction.await(queries)
end

CreateThread(function()
  local tries = 0
  while not ready do
    local ok = pcall(function()
      MySQL.scalar.await('SELECT 1')
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
