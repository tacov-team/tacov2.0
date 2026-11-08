-- Fitness und Promille (Punkt 6.9, Konzept 5.2): Trainingsstationen am Muscle Sands (Vespucci Beach)
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Fitness = {
  sessionSeconds = 30,       -- eine Trainingseinheit
  cooldownSeconds = 120,     -- zwischen zwei Einheiten an derselben Station
  stations = {
    { name = 'gym_1', label = 'Hantelbank',   x = -1201.6, y = -1567.2, z = 4.6,  scenario = 'WORLD_HUMAN_MUSCLE_FREE_WEIGHTS' },
    { name = 'gym_2', label = 'Klimmzüge',    x = -1205.9, y = -1558.6, z = 4.6,  scenario = 'WORLD_HUMAN_MUSCLE_FLEX' },
    { name = 'gym_3', label = 'Liegestütze',  x = -1197.4, y = -1571.0, z = 4.6,  scenario = 'WORLD_HUMAN_PUSH_UPS' },
    { name = 'gym_4', label = 'Sit-ups',      x = -1192.0, y = -1565.0, z = 4.6,  scenario = 'WORLD_HUMAN_SIT_UPS' },
  },
}

local L = TacoV.Config.Locations
for _, s in ipairs(TacoV.Config.Fitness.stations) do
  L[#L + 1] = { name = s.name, kind = 'gym', label = s.label, x = s.x, y = s.y, z = s.z, scenario = s.scenario }
end
TacoV.Config.Blips.gym = { sprite = 311, color = 2, scale = 0.7, label = 'Muscle Sands' }
