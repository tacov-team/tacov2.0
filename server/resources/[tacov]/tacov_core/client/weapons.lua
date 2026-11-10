-- Waffen (Grundlage, Client): ziehen/wegstecken über das Item, Munitionsstand an den Server, Weste.
TacoV = TacoV or {}
TacoV.Weapons = { current = nil }

local lastAmmo = nil

RegisterNetEvent('tacov:weapons:draw', function(item, weapon, ammo, usesAmmo)
  local ped = PlayerPedId()
  local hash = GetHashKey(weapon)
  RemoveAllPedWeapons(ped, true)
  GiveWeaponToPed(ped, hash, usesAmmo and ammo or 1, false, true)
  if usesAmmo then SetPedAmmo(ped, hash, ammo) end
  TacoV.Weapons.current = { item = item, hash = hash, usesAmmo = usesAmmo }
  lastAmmo = usesAmmo and ammo or nil
  if usesAmmo and ammo <= 0 then TacoV.UI.send('notify', { kind = 'warn', text = 'Keine Munition dabei.' }) end
end)

RegisterNetEvent('tacov:weapons:holster', function()
  RemoveAllPedWeapons(PlayerPedId(), true)
  TacoV.Weapons.current = nil
  lastAmmo = nil
end)

RegisterNetEvent('tacov:weapons:setAmmo', function(ammo)
  local cur = TacoV.Weapons.current
  if not cur then return end
  SetPedAmmo(PlayerPedId(), cur.hash, ammo)
  lastAmmo = ammo
end)

RegisterNetEvent('tacov:weapons:armor', function(amount) SetPedArmour(PlayerPedId(), amount) end)

CreateThread(function()
  while true do
    Wait(1000)
    local cur = TacoV.Weapons.current
    if cur and cur.usesAmmo then
      local ammo = GetAmmoInPedWeapon(PlayerPedId(), cur.hash)
      if lastAmmo and ammo < lastAmmo then
        lastAmmo = ammo
        TriggerServerEvent('tacov:weapons:ammo', ammo)
      end
    end
  end
end)
