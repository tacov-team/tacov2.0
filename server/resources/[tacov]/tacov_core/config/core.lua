-- Kern-Config. Jeder Wert stammt aus dem Serverkonzept (docs/konzept); nichts davon steht im Code.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Server = {
  name = 'TacoV',
  slots = 10,                      -- Konzept 1: Start mit 10 Slots
  autosaveSeconds = 300,           -- Konzept 1: Autosave alle 5 Minuten
  charactersPerPlayer = 1,         -- Punkt 2.3 (07.11.): ein Charakter je Spieler
  secondCharacterLevel = 15,       -- nur relevant, falls charactersPerPlayer > 1
}

-- Betrieb (Punkt 0.13): Neustart alle 6 Stunden mit Ansagen; Status-Zeile für das Discord-Embed
TacoV.Config.Restart = {
  hours = { 0, 6, 12, 18 },        -- Serverzeit (Europe/Berlin auf dem VPS)
  warnMinutes = { 15, 5, 1 },      -- Ansagen im Spiel und in Discord
  kickMessage = 'TacoV startet neu – in zwei Minuten geht es weiter.',
}
TacoV.Config.Status = { intervalSeconds = 30 }

TacoV.Config.Whitelist = {
  enabled = true,
  minAccountAgeDays = 0,           -- Konzept 1: keine Kontoalter-Prüfung
  rejectMessage = 'Du stehst noch nicht auf der Whitelist. Tritt dem Discord bei und reagiere auf die Willkommensnachricht: %s',
  bannedMessage = 'Dein Zugang ist gesperrt. Grund: %s',
  discordInvite = 'https://discord.gg/tacov',
}

TacoV.Config.Onboarding = {
  startCash = 5000,                -- Konzept 1: Startgeld aufs Konto
  socialHousingDays = 14,          -- Konzept 1: Sozialwohnung 14 Tage kostenlos
  retryHours = 24,                 -- Konzept 1: erneuter Einreiseversuch nach 24 h
  requiresStaff = true,            -- Konzept 1: Einreise nur mit Teammitglied
  spawn = vector4(-1037.6, -2737.7, 20.2, 330.0), -- Ankunftshalle LSIA
}

TacoV.Config.Level = {
  hoursPerLevel = 1,               -- Konzept 1: 1 Stunde aktive Spielzeit = 1 Levelpunkt
  noobProtectionUntil = 3,
  probationUntil = 8,
  afkMinutes = 20,                 -- Punkt 2.9 (07.11.): ab 20 Minuten ohne Bewegung zählt die Zeit nicht
}

TacoV.Config.Needs = {
  hungerMinutesToEmpty = 180,      -- Konzept 5
  thirstMinutesToEmpty = 180,
  starveDamagePercentPer30s = 1,
  fitness = { gainEquipment = 1, gainEnergyDrink = 2, decayPerDay = 1, maxSpeedBonusPercent = 8 },
  alcohol = { beer = 0.2, spirits = 0.5, decayPer10Min = 0.1, duiThreshold = 0.5 },
}

TacoV.Config.Inventory = {
  baseWeight = 30.0,               -- Konzept 5: 30 kg
  backpackWeight = 45.0,           -- mit Rucksack
  fullBlocksPickup = true,
  fullBlocksSprint = false,
  dropLifetimeMinutes = 15,
  dropMaxPerPlayer = 10,
  stackMax = 50,
  stackMaxAmmo = 500,
}

TacoV.Config.Keys = {
  phone = 'F1', inventory = 'F2', animations = 'F3', faction = 'F6',
  admin = 'F9', interact = 'X',
  use = 'E', handsUp = 'H', console = 'T',
}

TacoV.Config.Voice = { whisper = 3.0, normal = 10.0, shout = 25.0 }
