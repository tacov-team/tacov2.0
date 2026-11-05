-- Verbindungsaufbau: Whitelist per Discord-ID, Sperren, Slots (Konzept 1, Abschnitt 3).
TacoV = TacoV or {}

local function activeBan(discordId)
  return TacoV.DB.single(
    'SELECT reason, until_at FROM bans WHERE discord_id = ? AND lifted_at IS NULL AND (until_at IS NULL OR until_at > NOW()) ORDER BY id DESC LIMIT 1',
    { discordId }
  )
end

AddEventHandler('playerConnecting', function(name, setKickReason, deferrals)
  local src = source
  deferrals.defer()
  Wait(0)
  deferrals.update('TacoV: Prüfe Zugang ...')

  if not TacoV.DB.isReady() then
    deferrals.done('Der Server startet noch. Bitte in einer Minute erneut versuchen.')
    return
  end

  local ids = TacoV.Players.identifiers(src)
  local discordId = ids.discord
  local license = ids.license2 or ids.license

  if not discordId then
    deferrals.done('Discord muss laufen und mit FiveM verbunden sein, damit du beitreten kannst.')
    return
  end

  local ban = activeBan(discordId)
  if ban then
    TacoV.Log.write('connect', ('Abgewiesen (gesperrt): %s'):format(name), { discordId = discordId })
    deferrals.done(TacoV.Config.Whitelist.bannedMessage:format(ban.reason))
    return
  end

  if TacoV.Config.Whitelist.enabled then
    local wl = TacoV.DB.single('SELECT discord_id FROM whitelist WHERE discord_id = ?', { discordId })
    if not wl then
      TacoV.Log.write('connect', ('Abgewiesen (keine Whitelist): %s'):format(name), { discordId = discordId })
      deferrals.done(TacoV.Config.Whitelist.rejectMessage:format(TacoV.Config.Whitelist.discordInvite))
      return
    end
  end

  if TacoV.Players.count() >= TacoV.Config.Server.slots then
    deferrals.done('Der Server ist voll.')
    return
  end

  -- Doppelte Verbindung derselben Discord-ID verhindern
  for _, p in pairs(TacoV.Players.all()) do
    if p.discordId == discordId then
      deferrals.done('Dieses Discord-Konto ist bereits verbunden.')
      return
    end
  end

  TacoV.Players.load(src, discordId, license)
  TacoV.Log.write('connect', ('Verbunden: %s'):format(name), { discordId = discordId })
  deferrals.done()
end)

-- Nach dem Laden des Clients: Charakterauswahl öffnen
RegisterNetEvent('tacov:core:clientReady', function()
  local src = source
  local p = TacoV.Players.get(src)
  if not p then
    -- Quelle wurde beim Verbinden mit einer anderen temporären ID angelegt; neu zuordnen
    local ids = TacoV.Players.identifiers(src)
    if not ids.discord then DropPlayer(src, 'Discord-ID fehlt.') return end
    for oldSrc, op in pairs(TacoV.Players.all()) do
      if op.discordId == ids.discord and oldSrc ~= src then
        TacoV.Players.all()[src] = op
        op.source = src
        TacoV.Players.all()[oldSrc] = nil
        p = op
        break
      end
    end
    if not p then p = TacoV.Players.load(src, ids.discord, ids.license2 or ids.license) end
  end
  TriggerClientEvent('tacov:core:role', src, p.role)
  TriggerClientEvent('tacov:core:characters', src, {
    characters = TacoV.Characters.list(p.id),
    maxSlots = TacoV.Config.Server.charactersPerPlayer,
    secondSlotLevel = TacoV.Config.Server.secondCharacterLevel,
  })
end)
