-- Team-Rollen und Rechte (Konzept 1, Phase 0). Stufen sind aufsteigend; eine höhere Stufe hat alle Rechte der niedrigeren.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Roles = {
  player     = { level = 0, label = 'Spieler' },
  supporter  = { level = 1, label = 'Supporter' },
  admin      = { level = 2, label = 'Admin' },
  management = { level = 3, label = 'Management' },
}

-- Mindeststufe je Recht
TacoV.Config.Rights = {
  ['support.view']      = 1,
  ['support.teleport']  = 1,
  ['immigration']       = 1,  -- Einreise durchführen (Konzept 1: nur mit Teammitglied)
  ['admin.warn']        = 2,
  ['admin.ban']         = 2,
  ['admin.give']        = 2,
  ['admin.locations']   = 2,  -- /ort setzen (Konzept 5)
  ['admin.refund']      = 3,  -- Erstattung im Vier-Augen-Prinzip
  ['admin.roles']       = 3,
  ['admin.config']      = 3,
}
