-- Führt die SQL-Dateien in sql/ in Reihenfolge aus. Dateiname = NNN_name.sql; NNN ist die Version.
TacoV = TacoV or {}
TacoV.Migrations = {}

local resource = GetCurrentResourceName()

local function listMigrations()
  -- FiveM bietet kein Verzeichnislisting; die Liste wird hier gepflegt.
  return {
    { version = 1, file = 'sql/001_init.sql' },
    { version = 2, file = 'sql/002_inventory.sql' },
    { version = 3, file = 'sql/003_vehicles.sql' },
    { version = 4, file = 'sql/004_roles.sql' },
    { version = 5, file = 'sql/005_status.sql' },
    { version = 6, file = 'sql/006_dmv.sql' },
    { version = 7, file = 'sql/007_traffic.sql' },
    { version = 8, file = 'sql/008_warnings.sql' },
    { version = 9, file = 'sql/009_locations_extra.sql' },
    { version = 10, file = 'sql/010_doors.sql' },
    { version = 11, file = 'sql/011_teleports.sql' },
    { version = 12, file = 'sql/012_peds.sql' },
    { version = 13, file = 'sql/013_props_zones.sql' },
    { version = 14, file = 'sql/014_refunds.sql' },
    { version = 15, file = 'sql/015_config.sql' },
  }
end

local function splitStatements(sql)
  local out = {}
  -- Kommentarzeilen entfernen, dann an ';' am Zeilenende trennen
  sql = sql:gsub('%-%-[^\n]*', '')
  for stmt in sql:gmatch('[^;]+') do
    stmt = stmt:gsub('^%s+', ''):gsub('%s+$', '')
    if #stmt > 0 then out[#out + 1] = stmt end
  end
  return out
end

function TacoV.Migrations.run()
  TacoV.DB.waitReady()
  -- Tabelle migrations existiert evtl. noch nicht; die erste Datei legt sie an.
  local applied = {}
  local ok, rows = pcall(function()
    return TacoV.DB.query('SELECT version FROM migrations')
  end)
  if ok and rows then
    for _, r in ipairs(rows) do applied[r.version] = true end
  end

  for _, m in ipairs(listMigrations()) do
    if not applied[m.version] then
      local sql = LoadResourceFile(resource, m.file)
      if not sql then
        print(('^1[tacov_core]^7 Migration %s fehlt'):format(m.file))
        return false
      end
      for _, stmt in ipairs(splitStatements(sql)) do
        TacoV.DB.query(stmt)
      end
      TacoV.DB.insert('INSERT IGNORE INTO migrations (version) VALUES (?)', { m.version })
      print(('^2[tacov_core]^7 Migration %d (%s) ausgeführt'):format(m.version, m.file))
    end
  end
  return true
end
