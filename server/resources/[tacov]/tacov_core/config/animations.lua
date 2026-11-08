-- Animationsmenü (Punkt 6.6, Konzept 5.5): eigene Liste aus Grundspiel-Animationen und Szenarien, nach Kategorien.
-- kind 'anim': dict/name/flag (49 = Oberkörper, Bewegung möglich; 1 = Schleife; 0 = einmal), kind 'scenario': Szenario-Name.
TacoV = TacoV or {}
TacoV.Config = TacoV.Config or {}

TacoV.Config.Animations = {
  categories = {
    { id = 'greet', label = 'Begrüßung und Gesten', icon = 'hands' },
    { id = 'pose', label = 'Haltung', icon = 'user' },
    { id = 'sit', label = 'Sitzen und Liegen', icon = 'home' },
    { id = 'dance', label = 'Tanzen', icon = 'star' },
    { id = 'work', label = 'Arbeit', icon = 'tool' },
    { id = 'misc', label = 'Alltag', icon = 'leaf' },
  },
  list = {
    -- Begrüßung / Gesten
    { id = 'wave',      cat = 'greet', label = 'Winken',          kind = 'anim', dict = 'friends@frj@ig_1', name = 'wave_a', flag = 49 },
    { id = 'thumbsup',  cat = 'greet', label = 'Daumen hoch',     kind = 'anim', dict = 'anim@mp_player_intupperthumbs_up', name = 'idle_a', flag = 49, loop = true },
    { id = 'peace',     cat = 'greet', label = 'Peace',           kind = 'anim', dict = 'anim@mp_player_intupperpeace', name = 'idle_a', flag = 49, loop = true },
    { id = 'bird',      cat = 'greet', label = 'Mittelfinger',    kind = 'anim', dict = 'anim@mp_player_intselfiethe_bird', name = 'idle_a', flag = 49, loop = true },
    { id = 'clap',      cat = 'greet', label = 'Klatschen',       kind = 'anim', dict = 'anim@mp_player_intcelebrationmale@slow_clap', name = 'slow_clap', flag = 49, loop = true },
    { id = 'facepalm',  cat = 'greet', label = 'Facepalm',        kind = 'anim', dict = 'anim@mp_player_intcelebrationmale@face_palm', name = 'face_palm', flag = 49, loop = true },
    { id = 'salute',    cat = 'greet', label = 'Salutieren',      kind = 'anim', dict = 'mp_player_int_uppersalute', name = 'mp_player_int_salute', flag = 49, loop = true },
    { id = 'point',     cat = 'greet', label = 'Zeigen',          kind = 'anim', dict = 'gestures@m@standing@casual', name = 'gesture_point', flag = 49 },
    { id = 'shrug',     cat = 'greet', label = 'Schulterzucken',  kind = 'anim', dict = 'gestures@m@standing@casual', name = 'gesture_shrug_hard', flag = 49 },
    { id = 'nod',       cat = 'greet', label = 'Nicken',          kind = 'anim', dict = 'gestures@m@standing@casual', name = 'gesture_nod_yes_hard', flag = 49 },
    -- Haltung
    { id = 'armscross', cat = 'pose', label = 'Arme verschränken', kind = 'anim', dict = 'amb@world_human_hang_out_street@male_c@idle_a', name = 'idle_a', flag = 1, loop = true },
    { id = 'hips',      cat = 'pose', label = 'Hände in die Hüften', kind = 'anim', dict = 'anim@heists@heist_corona@single_team', name = 'single_team_loop_boss', flag = 1, loop = true },
    { id = 'impatient', cat = 'pose', label = 'Ungeduldig',       kind = 'scenario', name = 'WORLD_HUMAN_STAND_IMPATIENT' },
    { id = 'lean',      cat = 'pose', label = 'Anlehnen',         kind = 'scenario', name = 'WORLD_HUMAN_LEANING' },
    { id = 'guard',     cat = 'pose', label = 'Wache stehen',     kind = 'scenario', name = 'WORLD_HUMAN_GUARD_STAND' },
    { id = 'arrested',  cat = 'pose', label = 'Hände hinter dem Rücken', kind = 'anim', dict = 'mp_arresting', name = 'idle', flag = 49, loop = true },
    { id = 'kneel',     cat = 'pose', label = 'Knien',            kind = 'anim', dict = 'amb@medic@standing@kneel@idle_a', name = 'idle_a', flag = 1, loop = true },
    -- Sitzen / Liegen
    { id = 'sitground', cat = 'sit', label = 'Auf den Boden setzen', kind = 'anim', dict = 'amb@world_human_picnic@male@idle_a', name = 'idle_a', flag = 1, loop = true },
    { id = 'sitwall',   cat = 'sit', label = 'An die Wand setzen', kind = 'anim', dict = 'amb@world_human_bum_slumped@male@laying_on_left_side@idle_a', name = 'idle_a', flag = 1, loop = true },
    { id = 'lieback',   cat = 'sit', label = 'Auf den Rücken legen', kind = 'anim', dict = 'amb@world_human_sunbathe@male@back@idle_a', name = 'idle_a', flag = 1, loop = true },
    { id = 'liefront',  cat = 'sit', label = 'Auf den Bauch legen', kind = 'anim', dict = 'amb@world_human_sunbathe@male@front@idle_a', name = 'idle_a', flag = 1, loop = true },
    { id = 'sitchair',  cat = 'sit', label = 'Hinsetzen (Stuhl)', kind = 'scenario', name = 'PROP_HUMAN_SEAT_CHAIR_MP_PLAYER' },
    -- Tanzen
    { id = 'dance1',    cat = 'dance', label = 'Tanz 1',          kind = 'anim', dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_a@', name = 'high_center', flag = 1, loop = true },
    { id = 'dance2',    cat = 'dance', label = 'Tanz 2',          kind = 'anim', dict = 'anim@amb@nightclub@mini@dance@dance_solo@female@var_a@', name = 'high_center', flag = 1, loop = true },
    { id = 'dance3',    cat = 'dance', label = 'Tanz 3',          kind = 'anim', dict = 'anim@amb@nightclub@dancers@crowddance_facedj@hi_intensity',
      name = 'hi_dance_facedj_09_v1_male^1', flag = 1, loop = true },
    { id = 'dance4',    cat = 'dance', label = 'Tanz 4',          kind = 'anim', dict = 'missfbi3_sniping', name = 'dance_m_default', flag = 1, loop = true },
    { id = 'dance5',    cat = 'dance', label = 'Tanz 5 (langsam)', kind = 'anim', dict = 'anim@amb@nightclub@mini@dance@dance_solo@male@var_b@', name = 'low_center', flag = 1, loop = true },
    -- Arbeit
    { id = 'clipboard', cat = 'work', label = 'Klemmbrett',       kind = 'scenario', name = 'WORLD_HUMAN_CLIPBOARD' },
    { id = 'welding',   cat = 'work', label = 'Schweißen',        kind = 'scenario', name = 'WORLD_HUMAN_WELDING' },
    { id = 'hammer',    cat = 'work', label = 'Hämmern',          kind = 'scenario', name = 'WORLD_HUMAN_HAMMERING' },
    { id = 'repair',    cat = 'work', label = 'Reparieren',       kind = 'anim', dict = 'mini@repair', name = 'fixing_a_ped', flag = 1, loop = true },
    { id = 'clean',     cat = 'work', label = 'Putzen',           kind = 'scenario', name = 'WORLD_HUMAN_MAID_CLEAN' },
    { id = 'garden',    cat = 'work', label = 'Gärtnern',         kind = 'scenario', name = 'WORLD_HUMAN_GARDENER_PLANT' },
    { id = 'photo',     cat = 'work', label = 'Fotografieren',    kind = 'scenario', name = 'WORLD_HUMAN_PAPARAZZI' },
    { id = 'binoculars', cat = 'work', label = 'Fernglas',        kind = 'scenario', name = 'WORLD_HUMAN_BINOCULARS' },
    -- Alltag
    { id = 'smoke',     cat = 'misc', label = 'Rauchen',          kind = 'scenario', name = 'WORLD_HUMAN_SMOKING' },
    { id = 'coffee',    cat = 'misc', label = 'Kaffee',           kind = 'scenario', name = 'WORLD_HUMAN_AA_COFFEE' },
    { id = 'drink',     cat = 'misc', label = 'Trinken',          kind = 'scenario', name = 'WORLD_HUMAN_DRINKING' },
    { id = 'phone',     cat = 'misc', label = 'Handy',            kind = 'scenario', name = 'WORLD_HUMAN_STAND_MOBILE' },
    { id = 'party',     cat = 'misc', label = 'Feiern (Bier)',    kind = 'scenario', name = 'WORLD_HUMAN_PARTYING' },
    { id = 'pushups',   cat = 'misc', label = 'Liegestütze',      kind = 'scenario', name = 'WORLD_HUMAN_PUSH_UPS' },
    { id = 'situps',    cat = 'misc', label = 'Sit-ups',          kind = 'scenario', name = 'WORLD_HUMAN_SIT_UPS' },
    { id = 'yoga',      cat = 'misc', label = 'Yoga',             kind = 'scenario', name = 'WORLD_HUMAN_YOGA' },
    { id = 'jog',       cat = 'misc', label = 'Auf der Stelle laufen', kind = 'scenario', name = 'WORLD_HUMAN_JOG_STANDING' },
    { id = 'music',     cat = 'misc', label = 'Musizieren',       kind = 'scenario', name = 'WORLD_HUMAN_MUSICIAN' },
    { id = 'beg',       cat = 'misc', label = 'Betteln',          kind = 'scenario', name = 'WORLD_HUMAN_BUM_FREEWAY' },
    { id = 'cheer',     cat = 'misc', label = 'Jubeln',           kind = 'scenario', name = 'WORLD_HUMAN_CHEERING' },
  },
}
