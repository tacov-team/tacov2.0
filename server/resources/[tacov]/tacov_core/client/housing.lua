-- Sozialwohnung (Client, 6.5): E an der Haustür, drinnen Ausgang, Lager und Kleiderschrank; Neulingspfad-Ansicht.
TacoV = TacoV or {}
TacoV.Housing = { inside = false }

local H = TacoV.Config.Housing.social

RegisterNetEvent('tacov:housing:go', function(where)
  TacoV.Housing.inside = where == 'inside'
  if TacoV.Housing.inside then TacoV.Creator.fadeTeleport(H.inside.x, H.inside.y, H.inside.z, H.inside.w)
  else TacoV.Creator.fadeTeleport(H.entry.x, H.entry.y, H.entry.z, H.entry.w) end
end)

local function near(v, d) return #(GetEntityCoords(PlayerPedId()) - v) < d end

TacoV.Prompt.register({ id = 'home_enter', label = 'Wohnung betreten', order = 9,
  when = function() return not TacoV.Housing.inside and near(vector3(H.entry.x, H.entry.y, H.entry.z), 2.0) end,
  run = function() TriggerServerEvent('tacov:housing:enter') end })
TacoV.Prompt.register({ id = 'home_leave', label = 'Wohnung verlassen', order = 9,
  when = function() return TacoV.Housing.inside and near(H.exit, 2.0) end,
  run = function() TriggerServerEvent('tacov:housing:leave') end })
TacoV.Prompt.register({ id = 'home_storage', label = 'Lager', order = 9,
  when = function() return TacoV.Housing.inside and near(H.storage, 1.8) end,
  run = function() TriggerServerEvent('tacov:housing:storage') end })
TacoV.Prompt.register({ id = 'home_wardrobe', label = 'Kleiderschrank', order = 9,
  when = function() return TacoV.Housing.inside and near(H.wardrobe, 1.8) end,
  run = function() TacoV.Clothing.openOutfits() end })

-- Marker drinnen
CreateThread(function()
  while true do
    if TacoV.Housing.inside then
      Wait(0)
      for _, v in ipairs({ H.exit, H.storage, H.wardrobe }) do
        DrawMarker(27, v.x, v.y, v.z - 0.95, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.7, 0.7, 0.5, 167, 139, 250, 110, false, false, 2, false, nil, nil, false)
      end
    else
      Wait(500)
    end
  end
end)

-- Neulingspfad
RegisterNetEvent('tacov:newbie:list', function(steps, level)
  local items, doneN = {}, 0
  for _, s in ipairs(steps) do
    if s.done then doneN = doneN + 1 end
    items[#items + 1] = { id = s.id, label = s.label, icon = s.done and 'check' or 'next', dim = s.done, badge = s.done and 'erledigt' or (s.bonus .. ' $') }
  end
  TacoV.Menu.open({ id = 'newbie', title = 'Neulingspfad', icon = 'star', info = ('%d / %d erledigt · Level %d'):format(doneN, #steps, level),
    note = 'Freiwillig – jeder Schritt bringt einen kleinen Bonus. Ab Level 4 ausgeblendet.', items = items }, function() end)
end)
function TacoV.Housing.openNewbie() TriggerServerEvent('tacov:newbie:list') end
