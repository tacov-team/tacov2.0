-- Tattoos (Punkt 6.3): Auswahl aus den Grundspiel-Sammlungen. overlayF = Variante für weibliche Figuren (sonst unisex).
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

local T = {}
local function tat(id, label, zone, collection, overlay, overlayF, price)
  T[#T + 1] = { id = id, label = label, zone = zone, collection = collection, overlay = overlay, overlayF = overlayF, price = price or 200 }
end
-- Beach / Business (mit M/F-Varianten)
tat('bea_head',  'Beach · Kopf',          'Kopf',        'mpbeach_overlays',    'MP_Bea_M_Head_000',  'MP_Bea_F_Head_000', 250)
tat('bea_neck',  'Beach · Hals',          'Hals',        'mpbeach_overlays',    'MP_Bea_M_Neck_000',  'MP_Bea_F_Neck_000', 180)
tat('bea_chest', 'Beach · Brust',         'Brust',       'mpbeach_overlays',    'MP_Bea_M_Chest_000', 'MP_Bea_F_Chest_000', 220)
tat('bea_stom',  'Beach · Bauch',         'Bauch',       'mpbeach_overlays',    'MP_Bea_M_Stom_000',  'MP_Bea_F_Stom_000', 200)
tat('bea_back',  'Beach · Rücken',        'Rücken',      'mpbeach_overlays',    'MP_Bea_M_Back_000',  'MP_Bea_F_Back_000', 300)
tat('bea_larm',  'Beach · Linker Arm',    'Linker Arm',  'mpbeach_overlays',    'MP_Bea_M_LArm_000',  'MP_Bea_F_LArm_000', 180)
tat('bea_rarm',  'Beach · Rechter Arm',   'Rechter Arm', 'mpbeach_overlays',    'MP_Bea_M_RArm_000',  'MP_Bea_F_RArm_000', 180)
tat('bea_lleg',  'Beach · Linkes Bein',   'Linkes Bein', 'mpbeach_overlays',    'MP_Bea_M_LLeg_000',  'MP_Bea_F_LLeg_000', 180)
tat('bea_rleg',  'Beach · Rechtes Bein',  'Rechtes Bein', 'mpbeach_overlays',   'MP_Bea_M_RLeg_000',  'MP_Bea_F_RLeg_000', 180)
tat('bus_chest1', 'Business · Brust 1',   'Brust',       'mpbusiness_overlays', 'MP_Buis_M_Chest_000', 'MP_Buis_F_Chest_000', 220)
tat('bus_chest2', 'Business · Brust 2',   'Brust',       'mpbusiness_overlays', 'MP_Buis_M_Chest_001', 'MP_Buis_F_Chest_001', 220)
tat('bus_neck',  'Business · Hals',       'Hals',        'mpbusiness_overlays', 'MP_Buis_M_Neck_000', 'MP_Buis_F_Neck_000', 180)
tat('bus_back',  'Business · Rücken',     'Rücken',      'mpbusiness_overlays', 'MP_Buis_M_Back_000', 'MP_Buis_F_Back_000', 300)
tat('bus_larm',  'Business · Linker Arm', 'Linker Arm',  'mpbusiness_overlays', 'MP_Buis_M_LeftArm_000', 'MP_Buis_F_LeftArm_000', 180)
tat('bus_rarm',  'Business · Rechter Arm', 'Rechter Arm', 'mpbusiness_overlays', 'MP_Buis_M_RightArm_000', 'MP_Buis_F_RightArm_000', 180)
tat('bus_stom',  'Business · Bauch',      'Bauch',       'mpbusiness_overlays', 'MP_Buis_M_Stomach_000', 'MP_Buis_F_Stomach_000', 200)
-- Lowrider (unisex)
for i = 0, 11 do tat(('lr_%02d'):format(i), ('Lowrider %d'):format(i + 1), 'verschieden', 'mplowrider_overlays', ('MP_LR_Tat_%03d'):format(i), nil, 200) end
-- Biker (unisex)
for i = 0, 11 do tat(('bk_%02d'):format(i), ('Biker %d'):format(i + 1), 'verschieden', 'mpbiker_overlays', ('MP_MP_Biker_Tat_%03d'):format(i), nil, 220) end
-- Hipster (M/F)
for i = 0, 7 do tat(('hip_%02d'):format(i), ('Hipster %d'):format(i + 1), 'verschieden', 'mphipster_overlays', ('FM_Hip_M_Tat_%03d'):format(i), ('FM_Hip_F_Tat_%03d'):format(i), 180) end

TacoV.Config.Tattoos = T
