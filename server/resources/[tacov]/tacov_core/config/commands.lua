-- Befehle für die Befehlszeile (Taste T): Name, Schreibweise, Hilfe, Teamrecht. Die Rechte prüft der Server.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Commands = {
  { name = 'support', usage = 'support <Text>',                         help = 'Anliegen an das Team' },
  { name = 'befehle', usage = 'befehle',                                help = 'Alle Befehle anzeigen' },
  { name = 'ort',     usage = 'ort setzen <Name> <Art> [Beschriftung]', help = 'Ort an deine Position setzen', right = 'admin.locations' },
  { name = 'ort',     usage = 'ort liste',                              help = 'Alle Orte anzeigen', right = 'admin.locations' },
  { name = 'neustart', usage = 'neustart <Minuten>',                        help = 'Neustart mit Ansage (Manager)', right = 'admin.config' },
  { name = 'aduty',   usage = 'aduty',                                       help = 'Admin-Dienst an/aus (Team)', right = 'aduty' },
  { name = 'geld',    usage = 'geld <ID> <Betrag> [bank|bar]',                help = 'Geld geben (Test, Team)', right = 'admin.give' },
  { name = 'rolle',   usage = 'rolle <ID> <Rolle>',                     help = 'Teamrolle setzen', right = 'admin.roles' },
  { name = 'sperre',  usage = 'sperre <ID> <Stunden|0> <Grund>',        help = 'Spieler sperren', right = 'admin.ban' },
  { name = 'tp',      usage = 'tp <ID> | tp wp | tp <x> <y> [z]',  help = 'Teleport zu Spieler, Wegpunkt, Koordinaten', right = 'support.teleport' },
  { name = 'bring',   usage = 'bring <ID>',                                  help = 'Spieler zu dir holen', right = 'support.teleport' },
  { name = 'noclip',  usage = 'noclip',                                      help = 'Noclip an/aus', right = 'admin.noclip' },
  { name = 'unsichtbar', usage = 'unsichtbar',                               help = 'Unsichtbar an/aus', right = 'support.invisible' },
  { name = 'kick',    usage = 'kick <ID> <Grund>',                      help = 'Spieler vom Server entfernen', right = 'admin.warn' },
}
