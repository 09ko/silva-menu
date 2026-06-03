--==== Silva Menu for MachoCheats ====--
-- Fully Macho API v1.0 compliant
-- Native Hooking: MachoHookNative
-- Resource Injection: MachoInjectResource2
-- Notifications: MachoMenuNotification
-- Player Picker: MachoMenuGetSelectedPlayer
--==== License Key System ====--
local SUPABASE_URL = string.char(104,116,116,112,115,58,47,47,122,107,115,115,110,105,111,111,105,115,114,114,106,108,103,118,108,117,122,101,46,115,117,112,97,98,97,115,101,46,99,111)
local SUPABASE_ANON = string.char(115,98,95,112,117,98,108,105,115,104,97,98,108,101,95,115,122,72,57,82,77,51,97,95,83,85,90,95,55,48,99,75,118,55,95,95,103,95,105,72,50,114,45,121,78,75)

local licenseState = {
    authenticated = false,
    checking = false,
}

-- Capture originals for integrity check
local _ref = {
    WebReq = MachoWebRequest,
    AuthKey = MachoAuthenticationKey,
}

local function urlEncode(str)
    if not str then return string.char() end
    return (str:gsub(string.char(91,94,45,37,119,37,46,37,95,126,93), function(c)
        return string.format(string.char(37,37,37,48,50,88), string.byte(c))
    end))
end

local function CheckLicense()
    if licenseState.checking then return end
    licenseState.checking = true

    local key = _ref.AuthKey()
    if not key then
        MachoMenuNotification(string.char(83,105,108,118,97), string.char(126,114,126,78,111,32,97,117,116,104,32,107,101,121,32,102,111,117,110,100))
        licenseState.checking = false
        return
    end

    key = key:gsub(string.char(94,37,115,42,40,46,45,41,37,115,42,36), string.char(37,49))
    -- Check activations: macho_id matches AND (expires_at IS NULL OR expires_at > now)
    local orFilter = urlEncode(string.char(40,101,120,112,105,114,101,115,95,97,116,46,105,115,46,110,117,108,108,44,101,120,112,105,114,101,115,95,97,116,46,103,116,46,110,111,119,41))
    local url = SUPABASE_URL .. string.char(47,114,101,115,116,47,118,49,47,97,99,116,105,118,97,116,105,111,110,115,63,109,97,99,104,111,95,105,100,61,101,113,46) .. urlEncode(key) .. string.char(38,111,114,61) .. orFilter .. string.char(38,115,101,108,101,99,116,61,105,100,38,97,112,105,107,101,121,61) .. SUPABASE_ANON
    local response = _ref.WebReq(url)

    if response then
        response = response:gsub(string.char(94,37,115,42,40,46,45,41,37,115,42,36), string.char(37,49))
        if response ~= string.char(91,93) then
            licenseState.authenticated = true
            MachoMenuNotification(string.char(83,105,108,118,97), string.char(126,103,126,65,117,116,104,111,114,105,122,101,100,33))
        else
            licenseState.authenticated = false
            MachoMenuNotification(string.char(83,105,108,118,97), string.char(126,114,126,65,117,116,104,32,100,101,110,105,101,100,46,32,75,101,121,58,32) .. key .. string.char(32,124,32,82,101,115,112,111,110,115,101,58,32) .. response)
        end
    else
        MachoMenuNotification(string.char(83,105,108,118,97), string.char(126,114,126,65,117,116,104,32,115,101,114,118,101,114,32,117,110,114,101,97,99,104,97,98,108,101))
    end

    licenseState.checking = false
end

local _tamperCheck = function()
    return MachoWebRequest ~= _ref.WebReq or MachoAuthenticationKey ~= _ref.AuthKey
end

local selectedServerType = nil
local selectedPlayerId = nil
local selectedPlayerName = nil

-- Shadow Logging System
local _shadowLogs = {}
local function shadowLog(msg)
    local time = GetGameTimer()
    local sec = math.floor(time / 1000) % 60
    local min = math.floor(time / 60000) % 60
    local timeStr = string.format(string.char(91,37,48,50,100,58,37,48,50,100,93,32), min, sec)
    table.insert(_shadowLogs, 1, {text = timeStr .. msg, time = time})
    if #_shadowLogs > 20 then table.remove(_shadowLogs) end
end

--==== Master Stealth System ====--
local Stealth = {
    noclip = false,
    antiCuff = false,
    antiDrag = false,
    spoofCoords = nil,
    spoofVelocity = vector3(0.0, 0.0, 0.0),
    active = true
}

-- Macho Native Hooks (Stealth System)
-- Return false + values to spoof/intercept, true to call original
local function _registerStealthHooks()
    MachoHookNative(0x3FE3F1B590A2E382, function(entity)
        if Stealth.active and Stealth.noclip and entity == PlayerPedId() and Stealth.spoofCoords then
            return false, Stealth.spoofCoords.x, Stealth.spoofCoords.y, Stealth.spoofCoords.z
        end
        return true
    end)

    MachoHookNative(0x4805D2B1D8CF94A9, function(entity)
        if Stealth.active and Stealth.noclip and entity == PlayerPedId() then
            return false, Stealth.spoofVelocity.x, Stealth.spoofVelocity.y, Stealth.spoofVelocity.z
        end
        return true
    end)

    MachoHookNative(0x2D4DAC27C2137EB5, function(entity)
        if Stealth.active and Stealth.noclip and entity == PlayerPedId() then return false, 1.2 end
        return true
    end)

    MachoHookNative(0xDFB8D5EB276C8F9B, function(ped, toggle)
        if Stealth.active and Stealth.antiCuff and ped == PlayerPedId() and toggle then
            shadowLog(string.char(65,110,116,105,45,67,117,102,102,58,32,66,108,111,99,107,101,100,32,83,69,84,95,69,78,65,66,76,69,95,72,65,78,68,67,85,70,70,83))
            return false
        end
        return true
    end)

    MachoHookNative(0xEA99606C30D404A0, function(ped, animDict, animName, ...)
        if Stealth.active and Stealth.antiCuff and ped == PlayerPedId() and tostring(animDict):find(string.char(97,114,114,101,115,116,105,110,103)) then
            shadowLog(string.char(65,110,116,105,45,67,117,102,102,58,32,66,108,111,99,107,101,100,32,104,97,110,100,99,117,102,102,32,97,110,105,109))
            return false
        end
        return true
    end)

    MachoHookNative(0x6B9B663C75E6CC3E, function(entity1, entity2, ...)
        if Stealth.active and Stealth.antiDrag and entity1 == PlayerPedId() then
            shadowLog(string.char(65,110,116,105,45,68,114,97,103,58,32,66,108,111,99,107,101,100,32,65,84,84,65,67,72,95,69,78,84,73,84,89,95,84,79,95,69,78,84,73,84,89))
            return false
        end
        return true
    end)

    MachoHookNative(0x44919F4F8D81322B, function(player)
        if Stealth.active and player == PlayerId() then return false, 0 end
        return true
    end)

    shadowLog(string.char(77,97,115,116,101,114,32,83,116,101,97,108,116,104,32,78,97,116,105,118,101,32,72,111,111,107,115,32,97,99,116,105,118,101,32,118,105,97,32,77,97,99,104,111,72,111,111,107,78,97,116,105,118,101))
end

local stealthHooksReady = false
local function ensureStealthHooks()
    if not stealthHooksReady then
        stealthHooksReady = true
        MachoSetLoggerState(0)
        _registerStealthHooks()
        shadowLog(string.char(83,116,101,97,108,116,104,32,104,111,111,107,115,32,108,97,122,121,45,108,111,97,100,101,100))
    end
end

-- Coordinate-based Anti-Drag/Pull blocker
local isTeleporting = false
Citizen.CreateThread(function()
    local ped = PlayerPedId()
    local lastCoords = GetEntityCoords(ped)
    while true do
        Citizen.Wait(100)
        ped = PlayerPedId()
        if Stealth.active and Stealth.antiDrag and DoesEntityExist(ped) and not IsPedDeadOrDying(ped, true) then
            local currentCoords = GetEntityCoords(ped)
            local dist = #(currentCoords - lastCoords)
            if dist > 8.0 and not isTeleporting and not Stealth.noclip then
                SetEntityCoordsNoOffset(ped, lastCoords.x, lastCoords.y, lastCoords.z, false, false, false)
                ClearPedTasksImmediately(ped)
                DetachEntity(ped, true, false)
                shadowLog(string.format(string.char(65,110,116,105,45,68,114,97,103,58,32,66,108,111,99,107,101,100,32,114,101,109,111,116,101,32,112,117,108,108,32,111,102,32,37,46,49,102,109,33), dist))
            else
                local speed = GetEntitySpeed(ped)
                if speed < 30.0 or isTeleporting or Stealth.noclip then
                    lastCoords = currentCoords
                end
            end
        else
            lastCoords = GetEntityCoords(ped)
            Citizen.Wait(400)
        end
    end
end)

local showMenu = false
local menuAlpha = 0
local menuPosX = 1.05
local menuOffset = 0
local menuWidth = 0.22
local menuHeight = 0.32
local menuTargetX = 0.85
local menuScale = 0.9
local menuTime = 0

local lastToggleTime = 0
local toggleCooldown = 300
local actionCooldown = {}

local isHandcuffed = false
local handcuffAnimDict = string.char(109,112,95,97,114,114,101,115,116,105,110,103)
local handcuffAnimName = string.char(105,100,108,101)

local function CanUseAction(name, cd)
    cd = cd or 1500
    local now = GetGameTimer()
    if not actionCooldown[name] or now - actionCooldown[name] >= cd then
        actionCooldown[name] = now
        return true
    end
    return false
end

local function Notify(text)
    MachoMenuNotification(string.char(83,105,108,118,97), text)
end

local function MachoNotify(title, msg)
    MachoMenuNotification(title or string.char(83,105,108,118,97), msg or title)
end

local function LoadModel(model)
    local modelHash = (type(model) == string.char(110,117,109,98,101,114)) and model or GetHashKey(model)
    if not HasModelLoaded(modelHash) then
        RequestModel(modelHash)
        local tick = 0
        while not HasModelLoaded(modelHash) and tick < 200 do
            Citizen.Wait(10)
            tick = tick + 1
        end
    end
    return modelHash
end

local function SafeDeleteVehicle(vehicle)
    if DoesEntityExist(vehicle) then
        SetEntityAsMissionEntity(vehicle, true, true)
        if NetworkGetEntityIsNetworked(vehicle) then
            local netId = ObjToNet(vehicle)
            if netId and netId ~= 0 then
                NetworkRequestControlOfNetworkId(netId)
                for i=1,50 do
                    if NetworkHasControlOfNetworkId(netId) then break end
                    NetworkRequestControlOfNetworkId(netId)
                    Citizen.Wait(10)
                end
                SetNetworkIdCanMigrate(netId, true)
                NetworkDeleteVehicle(netId)
            else
                DeleteVehicle(vehicle)
            end
        else
            DeleteVehicle(vehicle)
        end
        if DoesEntityExist(vehicle) then
            DeleteEntity(vehicle)
        end
    end
end

local function HealPlayer()
    if not CanUseAction(string.char(104,101,97,108), 2000) then return end
    local ped = PlayerPedId()
    local maxHealth = GetEntityMaxHealth(ped) or 200
    SetEntityHealth(ped, maxHealth)
    Notify(string.char(126,103,126,89,111,117,32,104,97,118,101,32,98,101,101,110,32,104,101,97,108,101,100,32,116,111,32,102,117,108,108,32,104,101,97,108,116,104,46))
end

local function GiveArmor(amount)
    if not CanUseAction(string.char(97,114,109,111,114), 1500) then return end
    amount = amount or 100
    SetPedArmour(PlayerPedId(), amount)
    Notify((string.char(126,103,126,65,114,109,111,114,32,115,101,116,32,116,111,32,37,100)):format(amount))
end

local function StealthTeleportToCoords(targetCoords)
    ensureStealthHooks()
    local ped = PlayerPedId()
    local startCoords = GetEntityCoords(ped)
    local dist = #(targetCoords - startCoords)
    if dist < 100.0 then
        isTeleporting = true
        SetEntityCoordsNoOffset(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)
        isTeleporting = false
        return
    end
    isTeleporting = true
    Notify(string.char(126,121,126,83,116,101,97,108,116,104,32,84,101,108,101,112,111,114,116,105,110,103,46,46,46))
    Citizen.CreateThread(function()
        local current = startCoords
        local step = 70.0
        Stealth.spoofCoords = startCoords
        Stealth.noclip = true
        while #(targetCoords - current) > step do
            local dir = (targetCoords - current) / #(targetCoords - current)
            current = current + dir * step
            SetEntityCoordsNoOffset(ped, current.x, current.y, current.z, false, false, false)
            Citizen.Wait(40)
        end
        SetEntityCoordsNoOffset(ped, targetCoords.x, targetCoords.y, targetCoords.z, false, false, false)
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        Stealth.noclip = false
        Stealth.spoofCoords = nil
        isTeleporting = false
        Notify(string.char(126,103,126,83,116,101,97,108,116,104,32,84,101,108,101,112,111,114,116,101,100,32,115,117,99,99,101,115,115,102,117,108,108,121,33))
    end)
end

local function StealthTeleportToVehicle(targetVeh, targetCoords)
    ensureStealthHooks()
    local ped = PlayerPedId()
    local startCoords = GetEntityCoords(ped)
    local dist = #(targetCoords - startCoords)
    isTeleporting = true
    Notify(string.char(126,121,126,83,116,101,97,108,116,104,32,84,101,108,101,112,111,114,116,105,110,103,32,116,111,32,118,101,104,105,99,108,101,46,46,46))
    Citizen.CreateThread(function()
        Stealth.spoofCoords = startCoords
        Stealth.noclip = true
        if dist >= 100.0 then
            local current = startCoords
            local step = 70.0
            while #(targetCoords - current) > step do
                local dir = (targetCoords - current) / #(targetCoords - current)
                current = current + dir * step
                SetEntityCoordsNoOffset(ped, current.x, current.y, current.z, false, false, false)
                Citizen.Wait(40)
            end
        end
        local passengerSeats = {-1, 0, 1, 2, 3, 4, 5}
        local seated = false
        for _, seat in ipairs(passengerSeats) do
            if IsVehicleSeatFree(targetVeh, seat) then
                SetPedIntoVehicle(ped, targetVeh, seat)
                seated = true
                break
            end
        end
        if not seated then
            SetEntityCoordsNoOffset(ped, targetCoords.x + 1.0, targetCoords.y + 1.0, targetCoords.z + 0.5, false, false, false)
            Notify(string.char(126,114,126,86,101,104,105,99,108,101,32,102,117,108,108,33,32,80,108,97,99,101,100,32,111,117,116,115,105,100,101,46))
        else
            Notify(string.char(126,103,126,83,101,97,116,101,100,32,105,110,32,112,108,97,121,101,114,39,115,32,118,101,104,105,99,108,101,32,115,97,102,101,108,121,33))
        end
        SetEntityCollision(ped, true, true)
        FreezeEntityPosition(ped, false)
        Stealth.noclip = false
        Stealth.spoofCoords = nil
        isTeleporting = false
    end)
end

local function TeleportToPlayer(playerId)
    local targetPed = GetPlayerPed(playerId)
    if not DoesEntityExist(targetPed) then Notify(string.char(126,114,126,80,108,97,121,101,114,32,110,111,116,32,102,111,117,110,100)); return end
    local targetCoords = GetEntityCoords(targetPed)
    isTeleporting = true
    MachoInjectResource(string.char(97,110,121), string.format(string.char(10,32,32,32,32,32,32,32,32,83,101,116,69,110,116,105,116,121,67,111,111,114,100,115,40,80,108,97,121,101,114,80,101,100,73,100,40,41,44,32,37,46,54,102,44,32,37,46,54,102,44,32,37,46,54,102,41,10,32,32,32,32), targetCoords.x, targetCoords.y, targetCoords.z))
    Citizen.Wait(200)
    isTeleporting = false
    Notify(string.char(126,103,126,84,101,108,101,112,111,114,116,101,100,32,116,111,32) .. (GetPlayerName(playerId) or string.char(112,108,97,121,101,114)))
end

local function TeleportNextToPlayer(playerId, offset)
    offset = offset or 3.0
    local targetPed = GetPlayerPed(playerId)
    if not DoesEntityExist(targetPed) then Notify(string.char(126,114,126,80,108,97,121,101,114,32,110,111,116,32,102,111,117,110,100)); return end
    local targetCoords = GetEntityCoords(targetPed)
    local targetHeading = GetEntityHeading(targetPed)
    local behindX = targetCoords.x - (math.sin(math.rad(targetHeading)) * offset)
    local behindY = targetCoords.y + (math.cos(math.rad(targetHeading)) * offset)
    isTeleporting = true
    MachoInjectResource(string.char(97,110,121), string.format(string.char(10,32,32,32,32,32,32,32,32,83,101,116,69,110,116,105,116,121,67,111,111,114,100,115,40,80,108,97,121,101,114,80,101,100,73,100,40,41,44,32,37,46,54,102,44,32,37,46,54,102,44,32,37,46,54,102,41,10,32,32,32,32), behindX, behindY, targetCoords.z))
    Citizen.Wait(200)
    isTeleporting = false
    Notify(string.char(126,103,126,84,101,108,101,112,111,114,116,101,100,32,110,101,120,116,32,116,111,32) .. (GetPlayerName(playerId) or string.char(112,108,97,121,101,114)))
end

local function TeleportToWaypoint()
    if not CanUseAction(string.char(116,101,108,101,112,111,114,116), 2000) then return end
    local blip = GetFirstBlipInfoId(8)
    if blip == 0 then Notify(string.char(126,114,126,78,111,32,119,97,121,112,111,105,110,116,32,115,101,116,46)); return end
    local ped = PlayerPedId()
    local tx, ty = GetBlipInfoIdCoord(blip)
    isTeleporting = true
    Notify(string.char(126,121,126,83,116,101,97,108,116,104,32,109,97,112,112,105,110,103,32,100,101,115,116,105,110,97,116,105,111,110,46,46,46))
    Citizen.CreateThread(function()
        local groundFound, gz = false, nil
        local startCoords = GetEntityCoords(ped)
        Stealth.spoofCoords = startCoords
        Stealth.noclip = true
        for z = 900, 0, -50 do
            SetEntityCoordsNoOffset(ped, tx, ty, z + 0.0, false, false, false)
            Citizen.Wait(20)
            local ok, groundZ = GetGroundZFor_3dCoord(tx, ty, z + 0.0, 0)
            if ok and groundZ then groundFound = true; gz = groundZ; break end
        end
        local finalZ = groundFound and (gz + 0.5) or 100.0
        local targetCoords = vector3(tx, ty, finalZ)
        SetEntityCoordsNoOffset(ped, startCoords.x, startCoords.y, startCoords.z, false, false, false)
        Citizen.Wait(50)
        Stealth.noclip = false
        Stealth.spoofCoords = nil
        StealthTeleportToCoords(targetCoords)
    end)
end

local function LoadAnimDict(dict)
    if not HasAnimDictLoaded(dict) then
        RequestAnimDict(dict)
        while not HasAnimDictLoaded(dict) do Citizen.Wait(10) end
    end
end

local function ToggleHandcuffSelf()
    if not CanUseAction(string.char(104,97,110,100,99,117,102,102), 500) then return end
    local ped = PlayerPedId()
    if isHandcuffed then
        isHandcuffed = false
        SetEnableHandcuffs(ped, false)
        SetPedCanRagdoll(ped, true)
        ClearPedTasks(ped)
        Notify(string.char(126,103,126,89,111,117,32,117,110,108,111,99,107,101,100,32,99,117,102,102,115,46))
    else
        isHandcuffed = true
        SetCurrentPedWeapon(ped, GetHashKey(string.char(87,69,65,80,79,78,95,85,78,65,82,77,69,68)), true)
        LoadAnimDict(handcuffAnimDict)
        TaskPlayAnim(ped, handcuffAnimDict, handcuffAnimName, 8.0, -8.0, -1, 49, 0, false, false, false)
        SetEnableHandcuffs(ped, true)
        SetPedCanRagdoll(ped, false)
        Notify(string.char(126,114,126,89,111,117,32,99,117,102,102,101,100,32,121,111,117,114,115,101,108,102,46))
    end
end

local function SafeUnlockCuffs()
    local ped = PlayerPedId()
    isHandcuffed = false
    ClearPedTasksImmediately(ped)
    StopAnimTask(ped, string.char(109,112,95,97,114,114,101,115,116,105,110,103), string.char(105,100,108,101), 1.0)
    StopAnimTask(ped, string.char(97,110,105,109,64,109,111,118,101,95,109,64,112,114,105,115,111,110,101,114,95,99,117,102,102,101,100), string.char(119,97,108,107,95,99,117,102,102,101,100), 1.0)
    SetEnableHandcuffs(ped, false)
    SetPedCanRagdoll(ped, true)
    SetPedCanSwitchWeapon(ped, true)
    DetachEntity(ped, true, false)
    ResetPedMovementClipset(ped, 0.0)
    SetPedConfigFlag(ped, 292, false)
    SetPedConfigFlag(ped, 124, false)
    pcall(function() TriggerEvent(string.char(118,82,80,58,116,117,110,110,101,108,95,114,101,113), string.char(116,111,103,103,108,101,72,97,110,100,99,117,102,102), {}, string.char(), -1) end)
    pcall(function() TriggerServerEvent(string.char(112,111,108,105,99,101,58,117,110,99,117,102,102)) end)
    pcall(function() TriggerServerEvent(string.char(101,115,120,95,112,111,108,105,99,101,106,111,98,58,117,110,99,117,102,102), GetPlayerServerId(PlayerId())) end)
    pcall(function() TriggerServerEvent(string.char(113,98,45,112,111,108,105,99,101,106,111,98,58,115,101,114,118,101,114,58,117,110,99,117,102,102), GetPlayerServerId(PlayerId())) end)
    local blockUntil = GetGameTimer() + 5000
    Citizen.CreateThread(function()
        while GetGameTimer() < blockUntil do
            Citizen.Wait(0)
            if IsEntityPlayingAnim(ped, string.char(109,112,95,97,114,114,101,115,116,105,110,103), string.char(105,100,108,101), 3) or IsEntityPlayingAnim(ped, string.char(97,110,105,109,64,109,111,118,101,95,109,64,112,114,105,115,111,110,101,114,95,99,117,102,102,101,100), string.char(119,97,108,107,95,99,117,102,102,101,100), 3) then
                ClearPedTasksImmediately(ped)
                SetEnableHandcuffs(ped, false)
            end
        end
    end)
    shadowLog(string.char(70,111,114,99,101,32,85,110,99,117,102,102,32,101,120,101,99,117,116,101,100))
    Notify(string.char(126,103,126,91,85,78,67,85,70,70,93,32,89,111,117,32,97,114,101,32,110,111,119,32,102,114,101,101,33))
end

Citizen.CreateThread(function()
    while true do
        Citizen.Wait(0)
        if isHandcuffed then
            local ped = PlayerPedId()
            DisableControlAction(0, 21, true)
            DisableControlAction(0, 22, true)
            DisableControlAction(0, 24, true)
            DisableControlAction(0, 25, true)
            DisableControlAction(0, 37, true)
            DisableControlAction(0, 23, true)
            DisableControlAction(0, 75, true)
            DisableControlAction(0, 44, true)
            DisableControlAction(0, 140, true)
            DisableControlAction(0, 141, true)
            DisableControlAction(0, 142, true)
            DisableControlAction(0, 263, true)
            DisableControlAction(0, 264, true)
            DisableControlAction(0, 257, true)
            DisableControlAction(0, 269, true)
            SetCurrentPedWeapon(ped, GetHashKey(string.char(87,69,65,80,79,78,95,85,78,65,82,77,69,68)), true)
            if not IsEntityPlayingAnim(ped, handcuffAnimDict, handcuffAnimName, 3) then
                LoadAnimDict(handcuffAnimDict)
                TaskPlayAnim(ped, handcuffAnimDict, handcuffAnimName, 8.0, -8.0, -1, 49, 0, false, false, false)
            end
        else
            Citizen.Wait(200)
        end
    end
end)

--==== AC Bypass Functions (via MachoInjectResource2) ====--
local Bypass = {}

function Bypass.ReaperV4(resource)
    MachoHookNative(0x5A4F9EDF1670F7F4, function() return false, false end)
    MachoHookNative(0x5B4F04F9DB4F7A1C, function() return false, true end)
    MachoHookNative(0x7E2F3E6D9F5C8B1A, function() return false, 0 end)
    local orgTrigger = TriggerServerEvent
    TriggerServerEvent = function(event, ...)
        if event and tostring(event):find(string.char(114,101,97,112,101,114,95,104,101,97,114,116,98,101,97,116)) then return end
        return orgTrigger(event, ...)
    end
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,97,99,32,61,32,100,101,98,117,103,46,103,101,116,114,101,103,105,115,116,114,121,40,41,46,65,67,32,111,114,32,95,71,46,65,67,32,111,114,32,123,125,10,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,97,99,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,116,97,98,108,101,34,32,116,104,101,110,32,102,111,114,32,120,44,121,32,105,110,32,112,97,105,114,115,40,118,41,32,100,111,32,105,102,32,116,121,112,101,40,121,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,118,91,120,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,116,114,117,101,32,101,110,100,32,101,110)..string.char(100,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,115,116,97,116,101,32,61,32,71,108,111,98,97,108,83,116,97,116,101,32,111,114,32,123,125,10,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,115,116,97,116,101,41,32,100,111,32,105,102,32,116,111,115,116,114,105,110,103,40,107,41,58,102,105,110,100,40,34,114,101,97,112,101,114,34,41,32,116,104,101,110,32,115,116,97,116,101,91,107,93,61,110,105,108,32,101,110,100,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(82,101,97,112,101,114,86,52,32,110,101,117,116,114,97,108,105,122,101,100))
end

function Bypass.Fiveguard(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,104,97,110,100,108,101,114,115,32,61,32,100,101,98,117,103,46,103,101,116,114,101,103,105,115,116,114,121,40,41,46,95,72,65,78,68,76,69,82,83,32,111,114,32,95,71,46,95,72,65,78,68,76,111,114,115,32,111,114,32,123,125,10,32,32,32,32,32,32,32,32,102,111,114,32,101,118,116,44,32,116,98,108,32,105,110,32,112,97,105,114,115,40,104,97,110,100,108,101,114,115,41,32,100,111,32,105,102,32,116,111,115,116,114,105,110,103,40,101,118,116,41,58,102,105,110,100,40,34,70,105,118,101,103,117,97,114,100,34,41,32,116,104,101,110,32,102,111,114,32,105,61,35,116,98,108,44,49,44,45,49,32,100,111,32,116,98,108,91,105,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101)..string.char(116,117,114,110,32,116,114,117,101,32,101,110,100,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,102,103,32,61,32,95,71,46,70,105,118,101,103,117,97,114,100,32,111,114,32,95,71,46,70,71,10,32,32,32,32,32,32,32,32,105,102,32,102,103,32,116,104,101,110,32,102,103,46,68,101,116,101,99,116,105,111,110,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,102,103,46,84,114,105,103,103,101,114,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,102,111,114,32,105,61,49,44,49,48,48,32,100,111,32,108,111,99,97,108,32,116,61,95,71,91,34,116,105,109,101,114,95,34,46,46,105,93,59,32,105,102,32,116,32,97,110)..string.char(100,32,116,121,112,101,40,116,41,61,61,34,116,97,98,108,101,34,32,97,110,100,32,116,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,116,46,115,116,111,112,44,116,41,32,101,110,100,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(70,105,118,101,103,117,97,114,100,32,100,105,115,97,98,108,101,100))
end

function Bypass.ElectronAC(resource)
    MachoHookNative(0xE37B2A6B9B9D1F0C, function() return false, 0 end)
    MachoHookNative(0x5A4F9EDF1670F7F4, function() return false, false end)
    local orgLatent = TriggerLatentServerEvent
    TriggerLatentServerEvent = function(event, ...)
        if event and (tostring(event):find(string.char(101,108,101,99,116,114,111,110)) or tostring(event):find(string.char(97,99))) then return end
        return orgLatent(event, ...)
    end
    shadowLog(string.char(69,108,101,99,116,114,111,110,65,67,32,98,121,112,97,115,115,101,100))
end

function Bypass.EagleAC(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,101,97,103,108,101,32,61,32,95,71,46,69,97,103,108,101,32,111,114,32,95,71,46,69,67,95,65,67,10,32,32,32,32,32,32,32,32,105,102,32,101,97,103,108,101,32,116,104,101,110,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,101,97,103,108,101,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,108,111,99,97,108,32,105,110,102,111,61,100,101,98,117,103,46,103,101,116,105,110,102,111,40,118,41,59,32,105,102,32,105,110,102,111,32,97,110,100,32,105,110,102,111,46,110,97,109,101,32,97,110,100,32,105,110,102,111,46,110,97,109,101,58,102,105,110,100,40,34,100,101,116,101,99,116,34,41)..string.char(32,116,104,101,110,32,101,97,103,108,101,91,107,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,102,97,108,115,101,32,101,110,100,32,101,110,100,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,69,118,101,110,116,32,61,32,84,114,105,103,103,101,114,69,118,101,110,116,10,32,32,32,32,32,32,32,32,84,114,105,103,103,101,114,69,118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,101,118,116,44,32,46,46,46,41,32,105,102,32,116,111,115,116,114,105,110,103,40,101,118,116,41,58,102,105,110,100,40,34,101,97,103,108,101,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,101,118,116,41,58,102,105,110,100,40,34,69,67,95,34,41,32)..string.char(116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,69,118,101,110,116,40,101,118,116,44,32,46,46,46,41,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(69,97,103,108,101,65,67,32,101,118,97,100,101,100))
end

function Bypass.CyberAnticheat(resource)
    MachoInjectResource2(1, resource, string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,99,121,98,101,114,32,61,32,95,71,46,67,121,98,101,114,65,110,116,105,99,104,101,97,116,32,111,114,32,95,71,46,67,121,98,101,114,10,32,32,32,32,32,32,32,32,105,102,32,99,121,98,101,114,32,116,104,101,110,32,99,121,98,101,114,46,98,97,110,80,108,97,121,101,114,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,99,121,98,101,114,46,107,105,99,107,80,108,97,121,101,114,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,99,121,98,101,114,46,100,101,116,101,99,116,105,111,110,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,32,101,110,100,10,32,32,32,32))
    local orgTrigger = TriggerServerEvent
    TriggerServerEvent = function(event, ...)
        if event and (tostring(event):find(string.char(67,121,98,101,114)) or tostring(event):find(string.char(98,97,110)) or tostring(event):find(string.char(107,105,99,107))) then return end
        return orgTrigger(event, ...)
    end
    shadowLog(string.char(67,121,98,101,114,32,65,110,116,105,99,104,101,97,116,32,110,117,108,108,105,102,105,101,100))
end

function Bypass.WaveShield(resource)
    local orgGet = GetStateBagValue
    GetStateBagValue = function(bag, key)
        if bag == string.char(103,108,111,98,97,108) and key and tostring(key):find(string.char(87,97,118,101)) then return nil end
        return orgGet(bag, key)
    end
    MachoInjectResource2(1, resource, string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,119,115,32,61,32,95,71,46,87,97,118,101,83,104,105,101,108,100,32,111,114,32,95,71,46,87,83,10,32,32,32,32,32,32,32,32,105,102,32,119,115,32,116,104,101,110,32,119,115,46,67,111,110,102,105,103,61,123,125,59,32,119,115,46,69,110,116,105,116,105,101,115,61,123,125,59,32,119,115,46,68,101,116,101,99,116,105,111,110,115,61,123,125,32,101,110,100,10,32,32,32,32))
    shadowLog(string.char(87,97,118,101,83,104,105,101,108,100,32,98,108,105,110,100,101,100))
end

function Bypass.Luminus(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,108,117,109,32,61,32,95,71,46,76,117,109,105,110,117,115,32,111,114,32,95,71,46,76,85,77,32,111,114,32,95,71,46,76,117,109,105,110,117,115,65,67,10,32,32,32,32,32,32,32,32,105,102,32,108,117,109,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,108,117,109,46,68,101,116,101,99,116,105,111,110,32,116,104,101,110,32,108,117,109,46,68,101,116,101,99,116,105,111,110,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,108,117,109,46,66,97,110,32,116,104,101,110,32,108,117,109,46,66,97,110,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,32,101,110,100,10)..string.char(32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,108,117,109,46,75,105,99,107,32,116,104,101,110,32,108,117,109,46,75,105,99,107,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,108,117,109,46,76,111,103,32,116,104,101,110,32,108,117,109,46,76,111,103,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,108,117,109,46,65,67,32,116,104,101,110,32,108,117,109,46,65,67,61,123,125,32,101,110,100,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,69,118,101,110,116,32,61,32,84,114,105,103,103,101,114,69,118)..string.char(101,110,116,10,32,32,32,32,32,32,32,32,84,114,105,103,103,101,114,69,118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,101,118,116,44,32,46,46,46,41,32,105,102,32,101,118,116,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,101,118,116,41,58,102,105,110,100,40,34,108,117,109,105,110,117,115,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,101,118,116,41,58,102,105,110,100,40,34,76,85,77,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,101,118,116,41,58,102,105,110,100,40,34,97,99,95,98,97,110,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,69,118,101,110,116,40,101,118,116,44,32,46,46,46,41,32,101,110,100,10,32,32)..string.char(32,32)))
    shadowLog(string.char(76,117,109,105,110,117,115,32,65,67,32,100,105,115,97,98,108,101,100))
end

function Bypass.PhoenixAC(resource)
    MachoHookNative(0x5A4F9EDF1670F7F4, function() return false, false end)
    MachoHookNative(0x7E2F3E6D9F5C8B1A, function() return false, 0 end)
    MachoHookNative(0x4805D2B1D8CF94A9, function() return false, 0.0, 0.0, 0.0 end)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,112,104,120,32,61,32,95,71,46,80,104,111,101,110,105,120,32,111,114,32,95,71,46,80,104,111,101,110,105,120,65,67,32,111,114,32,95,71,46,80,88,10,32,32,32,32,32,32,32,32,105,102,32,112,104,120,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,112,104,120,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,108,111,99,97,108,32,105,110,102,111,61,100,101,98,117,103,46,103,101,116,105,110,102,111,40,118,41,59,32,105,102,32,105,110,102,111,32,97,110,100,32,105,110,102,111,46,110,97,109,101,32,97,110,100,32,40,105,110)..string.char(102,111,46,110,97,109,101,58,102,105,110,100,40,34,98,97,110,34,41,32,111,114,32,105,110,102,111,46,110,97,109,101,58,102,105,110,100,40,34,107,105,99,107,34,41,32,111,114,32,105,110,102,111,46,110,97,109,101,58,102,105,110,100,40,34,100,101,116,101,99,116,34,41,32,111,114,32,105,110,102,111,46,110,97,109,101,58,102,105,110,100,40,34,102,108,97,103,34,41,41,32,116,104,101,110,32,112,104,120,91,107,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,102,97,108,115,101,32,101,110,100,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,112,104,120,46,80,108,97,121,101,114,115,61,123,125,59,32,112,104,120,46,68,101,116,101,99,116,105,111,110,115,61,123,125,10,32)..string.char(32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,82,101,103,32,61,32,82,101,103,105,115,116,101,114,78,101,116,69,118,101,110,116,10,32,32,32,32,32,32,32,32,82,101,103,105,115,116,101,114,78,101,116,69,118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,110,97,109,101,41,32,105,102,32,110,97,109,101,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,112,104,111,101,110,105,120,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,80,88,95,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,82,101,103)..string.char(40,110,97,109,101,41,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(80,104,111,101,110,105,120,32,65,67,32,110,101,117,116,114,97,108,105,122,101,100))
end

function Bypass.NexusAC(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,110,120,32,61,32,95,71,46,78,101,120,117,115,32,111,114,32,95,71,46,78,101,120,117,115,65,67,32,111,114,32,95,71,46,78,88,10,32,32,32,32,32,32,32,32,105,102,32,110,120,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,110,120,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,110,120,91,107,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,102,97,108,115,101,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,110,120,46,87,104,105,116,101,108,105,115)..string.char(116,61,123,125,59,32,110,120,46,66,108,97,99,107,108,105,115,116,61,123,125,59,32,110,120,46,68,101,116,101,99,116,105,111,110,115,61,123,125,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,97,99,84,105,109,101,114,32,61,32,95,71,46,110,101,120,117,115,95,116,105,109,101,114,32,111,114,32,95,71,46,78,88,95,116,105,109,101,114,59,32,105,102,32,97,99,84,105,109,101,114,32,97,110,100,32,97,99,84,105,109,101,114,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,97,99,84,105,109,101,114,46,115,116,111,112,44,32,97,99,84,105,109,101,114,41,32,101,110,100,10,32,32,32,32,32,32,32,32,102,111,114,32,105,61,49,44,53,48,32,100,111,32,108,111,99,97,108)..string.char(32,116,61,95,71,91,34,110,120,95,116,105,109,101,114,95,34,46,46,105,93,59,32,105,102,32,116,32,97,110,100,32,116,121,112,101,40,116,41,61,61,34,116,97,98,108,101,34,32,97,110,100,32,116,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,116,46,115,116,111,112,44,116,41,32,101,110,100,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(78,101,120,117,115,32,65,67,32,98,121,112,97,115,115,101,100))
end

function Bypass.EasyAdmin(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,101,97,32,61,32,95,71,46,69,97,115,121,65,100,109,105,110,32,111,114,32,95,71,46,69,65,10,32,32,32,32,32,32,32,32,105,102,32,101,97,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,101,97,46,98,97,110,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,101,97,46,107,105,99,107,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,101,97,46,119,97,114,110,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,101,97,46,102,114,101,101,122,101,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,101,97,46,116,101,108,101,112,111,114,116,61,102,117,110,99,116,105,111)..string.char(110,40,41,32,101,110,100,59,32,101,97,46,115,99,114,101,101,110,115,104,111,116,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,101,97,46,115,112,101,99,116,97,116,101,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,101,97,46,114,101,118,105,118,101,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,101,97,46,107,105,108,108,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,101,97,46,115,108,97,112,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,101,97,46,112,108,97,121,101,114,115,61,123,125,59,32,101,97,46,68,101,116,101,99,116,105,111,110,115,61,123,125,10,32,32,32,32,32)..string.char(32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,83,83,32,61,32,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,10,32,32,32,32,32,32,32,32,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,110,97,109,101,44,32,46,46,46,41,32,105,102,32,110,97,109,101,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,69,97,115,121,65,100,109,105,110,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,101,97,115,121,97,100,109,105,110,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105)..string.char(110,100,40,34,101,97,95,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,83,83,40,110,97,109,101,44,32,46,46,46,41,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,65,72,32,61,32,65,100,100,69,118,101,110,116,72,97,110,100,108,101,114,10,32,32,32,32,32,32,32,32,65,100,100,69,118,101,110,116,72,97,110,100,108,101,114,32,61,32,102,117,110,99,116,105,111,110,40,110,97,109,101,44,32,99,98,41,32,105,102,32,110,97,109,101,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,69,97,115,121,65,100,109,105,110,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110)..string.char(97,109,101,41,58,102,105,110,100,40,34,101,97,115,121,97,100,109,105,110,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,123,125,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,65,72,40,110,97,109,101,44,32,99,98,41,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(69,97,115,121,65,100,109,105,110,32,98,108,105,110,100,101,100))
end

function Bypass.BadgerAC(resource)
    MachoHookNative(0x5A4F9EDF1670F7F4, function() return false, false end)
    MachoHookNative(0x497AC74A7C150A65, function() return false, false end)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,98,97,32,61,32,95,71,46,66,97,100,103,101,114,32,111,114,32,95,71,46,66,97,100,103,101,114,65,67,32,111,114,32,95,71,46,98,97,100,103,101,114,95,97,110,116,105,99,104,101,97,116,10,32,32,32,32,32,32,32,32,105,102,32,98,97,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,98,97,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,98,97,91,107,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,102,97,108,115,101,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32)..string.char(32,32,32,32,32,98,97,46,97,110,116,105,99,104,101,97,116,61,123,125,59,32,98,97,46,109,111,100,117,108,101,115,61,123,125,59,32,98,97,46,99,104,101,99,107,115,61,123,125,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,102,111,114,32,105,61,49,44,49,48,48,32,100,111,32,108,111,99,97,108,32,116,61,95,71,91,34,98,97,100,103,101,114,95,116,105,109,101,114,95,34,46,46,105,93,59,32,105,102,32,116,32,97,110,100,32,116,121,112,101,40,116,41,61,61,34,116,97,98,108,101,34,32,97,110,100,32,116,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,116,46,115,116,111,112,44,116,41,32,101,110,100,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(66,97,100,103,101,114,32,65,110,116,105,67,104,101,97,116,32,100,105,115,97,98,108,101,100))
end

function Bypass.ChocoHax(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,99,104,111,99,111,32,61,32,95,71,46,67,104,111,99,111,72,97,120,32,111,114,32,95,71,46,67,72,32,111,114,32,95,71,46,99,104,111,99,111,104,97,120,10,32,32,32,32,32,32,32,32,105,102,32,99,104,111,99,111,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,99,104,111,99,111,46,98,97,110,80,108,97,121,101,114,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,99,104,111,99,111,46,107,105,99,107,80,108,97,121,101,114,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,99,104,111,99,111,46,100,101,116,101,99,116,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,102,97,108,115,101,32,101,110,100,10,32)..string.char(32,32,32,32,32,32,32,32,32,32,32,99,104,111,99,111,46,102,108,97,103,80,108,97,121,101,114,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,99,104,111,99,111,46,115,99,114,101,101,110,115,104,111,116,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,99,104,111,99,111,46,68,101,116,101,99,116,105,111,110,115,61,123,125,59,32,99,104,111,99,111,46,70,108,97,103,115,61,123,125,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,83,83,32,61,32,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,10,32,32,32,32,32,32,32,32,84,114,105,103,103,101,114,83,101,114,118,101,114,69)..string.char(118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,110,97,109,101,44,32,46,46,46,41,32,105,102,32,110,97,109,101,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,99,104,111,99,111,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,99,104,111,99,111,104,97,120,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,83,83,40,110,97,109,101,44,32,46,46,46,41,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(67,104,111,99,111,72,97,120,32,110,117,108,108,105,102,105,101,100))
end

function Bypass.WardenAC(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,119,97,114,100,101,110,32,61,32,95,71,46,87,97,114,100,101,110,32,111,114,32,95,71,46,87,97,114,100,101,110,65,67,32,111,114,32,95,71,46,87,68,10,32,32,32,32,32,32,32,32,105,102,32,119,97,114,100,101,110,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,119,97,114,100,101,110,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,119,97,114,100,101,110,91,107,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,102,97,108,115,101,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32)..string.char(32,32,32,32,32,32,32,119,97,114,100,101,110,46,68,101,116,101,99,116,105,111,110,115,61,123,125,59,32,119,97,114,100,101,110,46,80,108,97,121,101,114,115,61,123,125,59,32,119,97,114,100,101,110,46,77,111,100,117,108,101,115,61,123,125,59,32,119,97,114,100,101,110,46,65,108,101,114,116,115,61,123,125,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,102,111,114,32,105,61,49,44,53,48,32,100,111,32,108,111,99,97,108,32,116,61,95,71,91,34,119,97,114,100,101,110,95,116,105,109,101,114,95,34,46,46,105,93,59,32,105,102,32,116,32,97,110,100,32,116,121,112,101,40,116,41,61,61,34,116,97,98,108,101,34,32,97,110,100,32,116,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,116,46)..string.char(115,116,111,112,44,116,41,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,82,101,103,32,61,32,82,101,103,105,115,116,101,114,78,101,116,69,118,101,110,116,10,32,32,32,32,32,32,32,32,82,101,103,105,115,116,101,114,78,101,116,69,118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,110,97,109,101,41,32,105,102,32,110,97,109,101,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,119,97,114,100,101,110,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,87,68,95,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105)..string.char(103,82,101,103,40,110,97,109,101,41,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(87,97,114,100,101,110,32,65,67,32,98,108,105,110,100,101,100))
end

function Bypass.TitanAC(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,116,105,116,97,110,32,61,32,95,71,46,84,105,116,97,110,32,111,114,32,95,71,46,84,105,116,97,110,65,67,32,111,114,32,95,71,46,84,84,10,32,32,32,32,32,32,32,32,105,102,32,116,105,116,97,110,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,116,105,116,97,110,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,116,105,116,97,110,91,107,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,102,97,108,115,101,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32)..string.char(32,116,105,116,97,110,46,68,101,116,101,99,116,105,111,110,115,61,123,125,59,32,116,105,116,97,110,46,83,99,114,101,101,110,115,104,111,116,115,61,123,125,59,32,116,105,116,97,110,46,66,108,97,99,107,108,105,115,116,61,123,125,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,83,83,32,61,32,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,10,32,32,32,32,32,32,32,32,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,110,97,109,101,44,32,46,46,46,41,32,105,102,32,110,97,109,101,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34)..string.char(116,105,116,97,110,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,84,84,95,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,97,110,116,105,99,104,101,97,116,95,114,101,108,111,97,100,101,100,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,83,83,40,110,97,109,101,44,32,46,46,46,41,32,101,110,100,10,32,32,32,32,32,32,32,32,102,111,114,32,105,61,49,44,54,48,32,100,111,32,108,111,99,97,108,32,116,61,95,71,91,34,116,105,116,97,110,95,116,105,109,101,114,95,34,46,46,105,93,59,32,105,102,32,116,32,97,110,100,32,116,121,112,101,40,116,41,61)..string.char(61,34,116,97,98,108,101,34,32,97,110,100,32,116,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,116,46,115,116,111,112,44,116,41,32,101,110,100,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(84,105,116,97,110,32,65,67,32,110,101,117,116,114,97,108,105,122,101,100))
end

function Bypass.SentryAC(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,115,101,110,116,114,121,32,61,32,95,71,46,83,101,110,116,114,121,32,111,114,32,95,71,46,83,101,110,116,114,121,65,67,32,111,114,32,95,71,46,83,84,82,10,32,32,32,32,32,32,32,32,105,102,32,115,101,110,116,114,121,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,115,101,110,116,114,121,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,115,101,110,116,114,121,91,107,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,102,97,108,115,101,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32)..string.char(32,32,32,32,32,32,32,32,115,101,110,116,114,121,46,68,101,116,101,99,116,105,111,110,115,61,123,125,59,32,115,101,110,116,114,121,46,72,111,111,107,115,61,123,125,59,32,115,101,110,116,114,121,46,69,118,101,110,116,115,61,123,125,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,69,118,101,110,116,32,61,32,84,114,105,103,103,101,114,69,118,101,110,116,10,32,32,32,32,32,32,32,32,84,114,105,103,103,101,114,69,118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,110,97,109,101,44,32,46,46,46,41,32,105,102,32,110,97,109,101,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,115,101,110,116,114,121,34,41)..string.char(32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,83,101,110,116,114,121,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,83,84,82,95,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,69,118,101,110,116,40,110,97,109,101,44,32,46,46,46,41,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(83,101,110,116,114,121,32,65,67,32,100,105,115,97,98,108,101,100))
end

function Bypass.RageAdmin(resource)
    MachoInjectResource2(1, resource, (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,114,97,103,101,32,61,32,95,71,46,82,97,103,101,32,111,114,32,95,71,46,82,97,103,101,65,100,109,105,110,32,111,114,32,95,71,46,82,65,32,111,114,32,95,71,46,114,97,103,101,95,97,100,109,105,110,10,32,32,32,32,32,32,32,32,105,102,32,114,97,103,101,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,114,97,103,101,41,32,100,111,32,105,102,32,116,121,112,101,40,118,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,114,97,103,101,91,107,93,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32)..string.char(32,32,114,97,103,101,46,98,97,110,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,114,97,103,101,46,107,105,99,107,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,114,97,103,101,46,102,114,101,101,122,101,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,114,97,103,101,46,116,112,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,59,32,114,97,103,101,46,115,99,114,101,101,110,115,104,111,116,61,102,117,110,99,116,105,111,110,40,41,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,114,97,103,101,46,99,111,109,109,97,110,100,115,61,123,125,59,32,114,97,103,101,46,112,108,97,121,101,114,115,61,123,125,59,32,114,97,103,101,46,109)..string.char(111,100,117,108,101,115,61,123,125,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,105,103,82,101,103,32,61,32,82,101,103,105,115,116,101,114,78,101,116,69,118,101,110,116,10,32,32,32,32,32,32,32,32,82,101,103,105,115,116,101,114,78,101,116,69,118,101,110,116,32,61,32,102,117,110,99,116,105,111,110,40,110,97,109,101,41,32,105,102,32,110,97,109,101,32,97,110,100,32,40,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,114,97,103,101,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58,102,105,110,100,40,34,82,97,103,101,65,100,109,105,110,34,41,32,111,114,32,116,111,115,116,114,105,110,103,40,110,97,109,101,41,58)..string.char(102,105,110,100,40,34,82,65,95,34,41,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,105,103,82,101,103,40,110,97,109,101,41,32,101,110,100,10,32,32,32,32)))
    shadowLog(string.char(82,97,103,101,65,100,109,105,110,32,110,117,108,108,105,102,105,101,100))
end

function Bypass.Decaptcha(resource)
    MachoInjectResource2(1, string.char(97,110,121), (string.char(10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,99,97,112,116,99,104,97,80,97,116,116,101,114,110,115,32,61,32,123,91,34,95,95,99,102,100,117,105,100,34,93,61,116,114,117,101,44,91,34,99,97,112,116,99,104,97,34,93,61,116,114,117,101,44,91,34,104,99,97,112,116,99,104,97,34,93,61,116,114,117,101,44,91,34,114,101,99,97,112,116,99,104,97,34,93,61,116,114,117,101,44,91,34,116,117,114,110,115,116,105,108,101,34,93,61,116,114,117,101,44,91,34,99,104,97,108,108,101,110,103,101,34,93,61,116,114,117,101,44,91,34,118,101,114,105,102,121,34,93,61,116,114,117,101,125,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,114,101,103,105,115,116,114,121,32,61,32,100,101,98,117,103,46,103,101,116,114,101,103,105,115)..string.char(116,114,121,40,41,32,111,114,32,123,125,10,32,32,32,32,32,32,32,32,102,111,114,32,107,44,118,32,105,110,32,112,97,105,114,115,40,114,101,103,105,115,116,114,121,41,32,100,111,32,105,102,32,116,121,112,101,40,107,41,61,61,34,115,116,114,105,110,103,34,32,116,104,101,110,32,108,111,99,97,108,32,107,108,61,107,58,108,111,119,101,114,40,41,59,32,102,111,114,32,112,44,95,32,105,110,32,112,97,105,114,115,40,99,97,112,116,99,104,97,80,97,116,116,101,114,110,115,41,32,100,111,32,105,102,32,107,108,58,102,105,110,100,40,112,41,32,116,104,101,110,32,114,101,103,105,115,116,114,121,91,107,93,61,102,117,110,99,116,105,111,110,40,46,46,46,41,32,114,101,116,117,114,110,32,116,114,117,101,32,101,110,100,32,101,110,100,32,101,110)..string.char(100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,102,111,114,32,95,44,103,78,97,109,101,32,105,110,32,105,112,97,105,114,115,40,123,34,99,97,112,116,99,104,97,34,44,34,104,99,97,112,116,99,104,97,34,44,34,114,101,99,97,112,116,99,104,97,34,44,34,116,117,114,110,115,116,105,108,101,34,44,34,99,102,99,97,112,116,99,104,97,34,44,34,95,99,97,112,116,99,104,97,34,125,41,32,100,111,10,32,32,32,32,32,32,32,32,32,32,32,32,108,111,99,97,108,32,103,61,95,71,91,103,78,97,109,101,93,59,32,105,102,32,103,32,97,110,100,32,116,121,112,101,40,103,41,61,61,34,116,97,98,108,101,34,32,116,104,101,110,32,102,111,114,32,107,50,44,118,50,32,105,110,32,112,97,105,114,115,40,103,41,32,100,111)..string.char(32,105,102,32,116,121,112,101,40,118,50,41,61,61,34,102,117,110,99,116,105,111,110,34,32,116,104,101,110,32,103,91,107,50,93,61,102,117,110,99,116,105,111,110,40,41,32,114,101,116,117,114,110,32,116,114,117,101,32,101,110,100,32,101,110,100,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,103,69,118,101,110,116,61,84,114,105,103,103,101,114,69,118,101,110,116,59,32,84,114,105,103,103,101,114,69,118,101,110,116,61,102,117,110,99,116,105,111,110,40,110,97,109,101,44,46,46,46,41,32,105,102,32,110,97,109,101,32,97,110,100,32,116,121,112,101,40,110,97,109,101,41,61,61,34,115,116,114,105,110,103,34,32,116,104,101,110,32,108,111,99,97,108,32)..string.char(110,108,61,110,97,109,101,58,108,111,119,101,114,40,41,59,32,102,111,114,32,112,44,95,32,105,110,32,112,97,105,114,115,40,99,97,112,116,99,104,97,80,97,116,116,101,114,110,115,41,32,100,111,32,105,102,32,110,108,58,102,105,110,100,40,112,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,32,101,110,100,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,103,69,118,101,110,116,40,110,97,109,101,44,46,46,46,41,32,101,110,100,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,111,114,103,83,83,61,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,59,32,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,61,102,117,110,99,116,105,111,110,40,110,97,109,101,44,46,46,46,41)..string.char(32,105,102,32,110,97,109,101,32,97,110,100,32,116,121,112,101,40,110,97,109,101,41,61,61,34,115,116,114,105,110,103,34,32,116,104,101,110,32,108,111,99,97,108,32,110,108,61,110,97,109,101,58,108,111,119,101,114,40,41,59,32,102,111,114,32,112,44,95,32,105,110,32,112,97,105,114,115,40,99,97,112,116,99,104,97,80,97,116,116,101,114,110,115,41,32,100,111,32,105,102,32,110,108,58,102,105,110,100,40,112,41,32,116,104,101,110,32,114,101,116,117,114,110,32,101,110,100,32,101,110,100,32,101,110,100,59,32,114,101,116,117,114,110,32,111,114,103,83,83,40,110,97,109,101,44,46,46,46,41,32,101,110,100,10,32,32,32,32,32,32,32,32,102,111,114,32,105,61,49,44,50,48,48,32,100,111,32,108,111,99,97,108,32,116,61,95,71,91,34)..string.char(116,105,109,101,114,95,34,46,46,105,93,59,32,105,102,32,116,32,97,110,100,32,116,121,112,101,40,116,41,61,61,34,116,97,98,108,101,34,32,97,110,100,32,116,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,116,46,115,116,111,112,44,116,41,32,101,110,100,59,32,108,111,99,97,108,32,99,105,61,95,71,91,34,99,97,112,116,99,104,97,73,110,116,101,114,118,97,108,95,34,46,46,105,93,59,32,105,102,32,99,105,32,97,110,100,32,116,121,112,101,40,99,105,41,61,61,34,116,97,98,108,101,34,32,97,110,100,32,99,105,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,99,105,46,115,116,111,112,44,99,105,41,32,101,110,100,32,101,110,100,10,32,32,32,32,32,32,32,32,67,105,116,105,122,101,110,46,67)..string.char(114,101,97,116,101,84,104,114,101,97,100,40,102,117,110,99,116,105,111,110,40,41,32,119,104,105,108,101,32,116,114,117,101,32,100,111,32,67,105,116,105,122,101,110,46,87,97,105,116,40,53,48,48,48,41,32,102,111,114,32,105,61,49,44,50,48,48,32,100,111,32,108,111,99,97,108,32,116,61,95,71,91,34,116,105,109,101,114,95,34,46,46,105,93,59,32,105,102,32,116,32,97,110,100,32,116,121,112,101,40,116,41,61,61,34,116,97,98,108,101,34,32,97,110,100,32,116,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,116,46,115,116,111,112,44,116,41,32,101,110,100,59,32,108,111,99,97,108,32,99,105,61,95,71,91,34,99,97,112,116,99,104,97,73,110,116,101,114,118,97,108,95,34,46,46,105,93,59,32,105,102,32,99,105)..string.char(32,97,110,100,32,116,121,112,101,40,99,105,41,61,61,34,116,97,98,108,101,34,32,97,110,100,32,99,105,46,115,116,111,112,32,116,104,101,110,32,112,99,97,108,108,40,99,105,46,115,116,111,112,44,99,105,41,32,101,110,100,32,101,110,100,32,101,110,100,32,101,110,100,41,10,32,32,32,32)))
    shadowLog(string.char(68,101,99,97,112,116,99,104,97,32,105,110,106,101,99,116,101,100))
end

--==== AC Scanning Engine ====--
local _knownExact = {
    fiveguard=string.char(70,105,118,101,71,117,97,114,100), badger_anticheat=string.char(66,97,100,103,101,114), badgerac=string.char(66,97,100,103,101,114),
    waveshield=string.char(87,97,118,101,83,104,105,101,108,100), chocohax=string.char(67,104,111,99,111,72,97,120), luminus=string.char(76,117,109,105,110,117,115),
    phoenixac=string.char(80,104,111,101,110,105,120), nexusac=string.char(78,101,120,117,115), reaperac=string.char(82,101,97,112,101,114,86,52),
    electronac=string.char(69,108,101,99,116,114,111,110,65,67), eagleac=string.char(69,97,103,108,101,65,67), ec_ac=string.char(69,97,103,108,101,65,67),
    cyber_anticheat=string.char(67,121,98,101,114), anticheat_reloaded=string.char(65,110,116,105,99,104,101,97,116,82,101,108,111,97,100,101,100),
    sentryac=string.char(83,101,110,116,114,121), titanac=string.char(84,105,116,97,110), wardenac=string.char(87,97,114,100,101,110),
    rageadmin=string.char(82,97,103,101,65,100,109,105,110), easyadmin=string.char(69,97,115,121,65,100,109,105,110),
}
local _knownSub = {
    fiveguard=string.char(70,105,118,101,71,117,97,114,100), badger=string.char(66,97,100,103,101,114), waveshield=string.char(87,97,118,101,83,104,105,101,108,100),
    chocohax=string.char(67,104,111,99,111,72,97,120), luminus=string.char(76,117,109,105,110,117,115), phoenixac=string.char(80,104,111,101,110,105,120),
    nexusac=string.char(78,101,120,117,115), reaper=string.char(82,101,97,112,101,114,86,52), electron=string.char(69,108,101,99,116,114,111,110,65,67),
    eagle=string.char(69,97,103,108,101,65,67), cyber=string.char(67,121,98,101,114), anticheat=string.char(71,101,110,101,114,105,99,32,65,67),
    sentry=string.char(83,101,110,116,114,121), titanac=string.char(84,105,116,97,110), warden=string.char(87,97,114,100,101,110),
    rageadmin=string.char(82,97,103,101,65,100,109,105,110), easyadmin=string.char(69,97,115,121,65,100,109,105,110),
}
local _acGlobals = {
    Fiveguard=string.char(70,105,118,101,71,117,97,114,100), WaveShield=string.char(87,97,118,101,83,104,105,101,108,100), CyberAnticheat=string.char(67,121,98,101,114),
    Eagle=string.char(69,97,103,108,101,65,67), EC_AC=string.char(69,97,103,108,101,65,67), Reaper=string.char(82,101,97,112,101,114,86,52), ReaperV4=string.char(82,101,97,112,101,114,86,52),
    Luminus=string.char(76,117,109,105,110,117,115), LUM=string.char(76,117,109,105,110,117,115), Phoenix=string.char(80,104,111,101,110,105,120), PhoenixAC=string.char(80,104,111,101,110,105,120),
    Nexus=string.char(78,101,120,117,115), NexusAC=string.char(78,101,120,117,115), EasyAdmin=string.char(69,97,115,121,65,100,109,105,110), EA=string.char(69,97,115,121,65,100,109,105,110),
    Badger=string.char(66,97,100,103,101,114), BadgerAC=string.char(66,97,100,103,101,114), ChocoHax=string.char(67,104,111,99,111,72,97,120), CH=string.char(67,104,111,99,111,72,97,120),
    Warden=string.char(87,97,114,100,101,110), WardenAC=string.char(87,97,114,100,101,110), Titan=string.char(84,105,116,97,110), TitanAC=string.char(84,105,116,97,110),
    Sentry=string.char(83,101,110,116,114,121), SentryAC=string.char(83,101,110,116,114,121), Rage=string.char(82,97,103,101,65,100,109,105,110), RageAdmin=string.char(82,97,103,101,65,100,109,105,110),
    RA=string.char(82,97,103,101,65,100,109,105,110), FG=string.char(70,105,118,101,71,117,97,114,100),
}
local _safePrefixes = {string.char(101,115,120,95),string.char(113,98,45),string.char(113,98,95),string.char(111,120,95),string.char(111,120,45),string.char(110,112,95),string.char(110,112,45),string.char(118,114,112,95),string.char(118,114,112,45),
    string.char(116,49,103,101,114,95),string.char(108,115,95),string.char(108,115,45),string.char(109,114,95),string.char(109,114,45),string.char(107,114,95),string.char(107,114,45),string.char(114,99,95),string.char(114,99,45),
    string.char(102,110,95),string.char(102,110,45),string.char(109,95),string.char(109,45),string.char(100,102,119,95),string.char(100,102,119,45),string.char(106,103,95),string.char(106,103,45),string.char(112,108,95),string.char(112,108,45),
    string.char(115,100,95),string.char(115,100,45),string.char(99,111,100,95),string.char(99,111,100,45),string.char(98,99,99,95),string.char(98,99,99,45),string.char(99,102,120,95),string.char(99,102,120,45),
    string.char(115,111,101,95),string.char(115,111,101,45),string.char(102,119,95),string.char(102,119,45),string.char(99,111,114,101),string.char(95,99,111,114,101),string.char(109,121,115,113,108),string.char(111,120,109,121,115,113,108),
    string.char(103,104,109,97,116,116,105,109,121,115,113,108),string.char(99,104,97,116),string.char(115,101,115,115,105,111,110,109,97,110,97,103,101,114),string.char(115,112,97,119,110,109,97,110,97,103,101,114),
    string.char(109,97,112,109,97,110,97,103,101,114),string.char(114,99,111,110,108,111,103),string.char(119,101,98,97,100,109,105,110),string.char(104,97,114,100,99,97,112),string.char(103,108,111,119,95)}

local function _isSafe(name)
    local nl = string.lower(name)
    for _, p in ipairs(_safePrefixes) do if nl:sub(1, #p) == p then return true end end
    return false
end

local function _scanACs()
    local results = {}
    local total = GetNumResources()
    for i = 0, total - 1 do
        local name = GetResourceByFindIndex(i)
        if not name then goto continue end
        local nl = string.lower(name)
        if _isSafe(name) then goto continue end
        local score = 0
        local label = string.char()
        if _knownExact[nl] then score = 100; label = string.char(101,120,97,99,116,58) .. _knownExact[nl] end
        if score < 100 then
            for g, ac in pairs(_acGlobals) do
                if _G[g] ~= nil then score = 90; label = string.char(103,108,111,98,97,108,58) .. ac; break end
            end
        end
        if score < 40 then
            for sub, ac in pairs(_knownSub) do
                if nl:find(sub, 1, true) then score = 40; label = string.char(109,97,116,99,104,58) .. ac; break end
            end
            if score < 40 then
                local author = string.lower(GetResourceMetadata(name, string.char(97,117,116,104,111,114), 0) or string.char())
                local desc = string.lower(GetResourceMetadata(name, string.char(100,101,115,99,114,105,112,116,105,111,110), 0) or string.char())
                for sub, ac in pairs(_knownSub) do
                    if author:find(sub, 1, true) or desc:find(sub, 1, true) then score = 30; label = string.char(109,101,116,97,58) .. ac; break end
                end
            end
        end
        if score > 0 then table.insert(results, {name = name, score = score, label = label}) end
        ::continue::
    end
    table.sort(results, function(a, b) return a.score > b.score end)
    return results
end

local function LoadBypasses()
    local resources = {}
    for i = 0, GetNumResources() - 1 do
        table.insert(resources, GetResourceByFindIndex(i))
    end
    local bypassedCount = 0
    for _, res in ipairs(resources) do
        local author = string.lower(GetResourceMetadata(res, string.char(97,117,116,104,111,114), 0) or string.char())
        local desc = string.lower(GetResourceMetadata(res, string.char(100,101,115,99,114,105,112,116,105,111,110), 0) or string.char())
        local nameLower = string.lower(res)
        if nameLower:find(string.char(114,101,97,112,101,114)) then Bypass.ReaperV4(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(102,105,118,101,103,117,97,114,100)) then Bypass.Fiveguard(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(101,108,101,99,116,114,111,110)) then Bypass.ElectronAC(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(101,99,95,97,99)) or nameLower:find(string.char(101,97,103,108,101)) then Bypass.EagleAC(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(99,121,98,101,114)) then Bypass.CyberAnticheat(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(119,97,118,101,115,104,105,101,108,100)) then Bypass.WaveShield(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(108,117,109,105,110,117,115)) then Bypass.Luminus(res); bypassedCount = bypassedCount + 1 end
        if author:find(string.char(112,104,111,101,110,105,120)) or nameLower:find(string.char(112,104,111,101,110,105,120)) then Bypass.PhoenixAC(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(110,101,120,117,115)) then Bypass.NexusAC(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(101,97,115,121,97,100,109,105,110)) then Bypass.EasyAdmin(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(98,97,100,103,101,114)) then Bypass.BadgerAC(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(99,104,111,99,111)) then Bypass.ChocoHax(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(119,97,114,100,101,110)) then Bypass.WardenAC(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(116,105,116,97,110)) then Bypass.TitanAC(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(115,101,110,116,114,121)) then Bypass.SentryAC(res); bypassedCount = bypassedCount + 1 end
        if nameLower:find(string.char(114,97,103,101,97,100,109,105,110)) then Bypass.RageAdmin(res); bypassedCount = bypassedCount + 1 end
    end
    local originalTriggerServerEvent = TriggerServerEvent
    TriggerServerEvent = function(name, ...)
        local status, lowerName = pcall(function() return tostring(name):lower() end)
        if status and lowerName then
            if lowerName:find(string.char(98,97,110)) or lowerName:find(string.char(107,105,99,107)) or lowerName:find(string.char(115,99,114,101,101,110,115,104,111,116)) or lowerName:find(string.char(100,101,116,101,99,116)) or lowerName:find(string.char(99,104,101,97,116)) or lowerName:find(string.char(104,97,99,107)) or lowerName:find(string.char(118,105,111,108,97,116,105,111,110)) or lowerName:find(string.char(105,110,106,101,99,116)) then
                shadowLog(string.char(66,108,111,99,107,101,100,32,101,118,101,110,116,58,32) .. tostring(name))
                return
            end
        end
        return originalTriggerServerEvent(name, ...)
    end
    local originalAddEventHandler = AddEventHandler
    AddEventHandler = function(name, cb)
        local status, lowerName = pcall(function() return tostring(name):lower() end)
        if status and lowerName then
            if lowerName:find(string.char(98,97,110)) or lowerName:find(string.char(107,105,99,107)) or lowerName:find(string.char(115,99,114,101,101,110,115,104,111,116)) or lowerName:find(string.char(100,101,116,101,99,116)) or lowerName:find(string.char(99,104,101,97,116)) then
                shadowLog(string.char(77,117,116,101,100,32,108,105,115,116,101,110,101,114,58,32) .. tostring(name))
                return {}
            end
        end
        return originalAddEventHandler(name, cb)
    end
    local originalRegisterNetEvent = RegisterNetEvent
    RegisterNetEvent = function(name)
        local status, lowerName = pcall(function() return tostring(name):lower() end)
        if status and lowerName then
            if lowerName:find(string.char(98,97,110)) or lowerName:find(string.char(107,105,99,107)) or lowerName:find(string.char(115,99,114,101,101,110,115,104,111,116)) or lowerName:find(string.char(100,101,116,101,99,116)) or lowerName:find(string.char(99,104,101,97,116)) then
                shadowLog(string.char(77,117,116,101,100,32,78,101,116,69,118,101,110,116,58,32) .. tostring(name))
                return
            end
        end
        return originalRegisterNetEvent(name)
    end
    if bypassedCount > 0 then
        Notify(string.char(126,103,126,91,66,121,112,97,115,115,93,32,83,117,99,99,101,115,115,102,117,108,108,121,32,110,101,117,116,114,97,108,105,122,101,100,32) .. bypassedCount .. string.char(32,65,67,32,115,99,114,105,112,116,115,33))
    else
        Notify(string.char(126,103,126,91,66,121,112,97,115,115,93,32,71,104,111,115,116,32,77,111,100,101,32,65,99,116,105,118,101,32,40,65,103,103,114,101,115,115,105,118,101,32,69,118,101,110,116,32,66,108,111,99,107,105,110,103,32,65,112,112,108,105,101,100,41,46))
    end
end

--==== Menu Items ====--
local searchMenuItems = {
    { label = string.char(65,117,116,111,32,66,121,112,97,115,115,32,65,108,108,32,65,67,32,40,71,104,111,115,116,32,77,111,100,101,41), action = function() LoadBypasses() end },
    { label = string.char(83,101,97,114,99,104,32,65,110,116,105,45,67,104,101,97,116), action = function()
        Notify(string.char(126,121,126,83,101,97,114,99,104,105,110,103,32,102,111,114,32,65,110,116,105,45,67,104,101,97,116,46,46,46))
        Citizen.CreateThread(function()
            Citizen.Wait(1000)
            local acNames = {
                [string.char(101,97,115,121,97,100,109,105,110)] = string.char(69,97,115,121,65,100,109,105,110), [string.char(98,97,100,103,101,114,95,97,110,116,105,99,104,101,97,116)] = string.char(66,97,100,103,101,114),
                [string.char(119,97,118,101,115,104,105,101,108,100)] = string.char(87,97,118,101,83,104,105,101,108,100), [string.char(99,104,111,99,111,104,97,120)] = string.char(67,104,111,99,111,72,97,120),
                [string.char(108,117,109,105,110,117,115)] = string.char(76,117,109,105,110,117,115), [string.char(102,105,118,101,103,117,97,114,100)] = string.char(70,105,118,101,71,117,97,114,100),
                [string.char(112,104,111,101,110,105,120,97,99)] = string.char(80,104,111,101,110,105,120), [string.char(110,101,120,117,115,97,99)] = string.char(78,101,120,117,115),
                [string.char(114,101,97,112,101,114)] = string.char(82,101,97,112,101,114,86,52), [string.char(101,108,101,99,116,114,111,110)] = string.char(69,108,101,99,116,114,111,110,65,67),
                [string.char(101,97,103,108,101)] = string.char(69,97,103,108,101,65,67), [string.char(99,121,98,101,114)] = string.char(67,121,98,101,114),
                [string.char(119,97,114,100,101,110)] = string.char(87,97,114,100,101,110), [string.char(115,101,110,116,114,121)] = string.char(83,101,110,116,114,121),
                [string.char(116,105,116,97,110)] = string.char(84,105,116,97,110), [string.char(114,97,103,101,97,100,109,105,110)] = string.char(82,97,103,101,65,100,109,105,110),
                [string.char(97,99,95)] = string.char(71,101,110,101,114,105,99,32,65,67), [string.char(97,110,116,105,99,104,101,97,116)] = string.char(71,101,110,101,114,105,99,32,65,67),
                [string.char(115,104,105,101,108,100)] = string.char(71,101,110,101,114,105,99,32,83,104,105,101,108,100,32,65,67)
            }
            local foundACs = {}
            for i = 0, GetNumResources() - 1 do
                local resName = GetResourceByFindIndex(i)
                if resName then
                    local nameLower = string.lower(resName)
                    local author = string.lower(GetResourceMetadata(resName, string.char(97,117,116,104,111,114), 0) or string.char())
                    local desc = string.lower(GetResourceMetadata(resName, string.char(100,101,115,99,114,105,112,116,105,111,110), 0) or string.char())
                    for key, acName in pairs(acNames) do
                        if nameLower:find(key) or author:find(key) or desc:find(key) then
                            if not foundACs[acName] then foundACs[acName] = resName end
                        end
                    end
                end
            end
            if _G.Fiveguard or _G.FG then foundACs[string.char(70,105,118,101,71,117,97,114,100)] = string.char(71,108,111,98,97,108,32,86,97,114,105,97,98,108,101) end
            if _G.WaveShield or _G.WS then foundACs[string.char(87,97,118,101,83,104,105,101,108,100)] = string.char(71,108,111,98,97,108,32,86,97,114,105,97,98,108,101) end
            if _G.CyberAnticheat or _G.Cyber then foundACs[string.char(67,121,98,101,114)] = string.char(71,108,111,98,97,108,32,86,97,114,105,97,98,108,101) end
            if _G.Eagle or _G.EC_AC then foundACs[string.char(69,97,103,108,101,65,67)] = string.char(71,108,111,98,97,108,32,86,97,114,105,97,98,108,101) end
            if _G.Reaper or _G.ReaperV4 then foundACs[string.char(82,101,97,112,101,114,86,52)] = string.char(71,108,111,98,97,108,32,86,97,114,105,97,98,108,101) end
            local foundCount = 0
            for ac, res in pairs(foundACs) do
                Notify(string.char(126,114,126,91,33,93,32) .. ac .. string.char(32,40) .. res .. string.char(41))
                foundCount = foundCount + 1
                Citizen.Wait(500)
            end
            if foundCount == 0 then Notify(string.char(126,103,126,91,43,93,32,78,111,32,65,67,32,114,101,115,111,117,114,99,101,115,32,100,101,116,101,99,116,101,100,46))
            else Notify(string.char(126,121,126,91,33,93,32,70,111,117,110,100,32) .. foundCount .. string.char(32,65,67,40,115,41)) end
        end)
    end },
    { label = string.char(66,121,112,97,115,115,32,82,101,115,111,117,114,99,101,115,32,40,82,105,115,107,41), action = function()
        for i = 0, GetNumResources() - 1 do
            local resName = GetResourceByFindIndex(i)
            if resName ~= nil and resName ~= GetCurrentResourceName() then
                MachoResourceStop(resName)
            end
        end
    end },
    { label = string.char(68,101,99,97,112,116,99,104,97,32,40,66,121,112,97,115,115,32,67,97,112,116,99,104,97,41), action = function() Bypass.Decaptcha(string.char(97,110,121)) end },
    { label = string.char(86,105,101,119,32,83,104,97,100,111,119,32,76,111,103,115), action = function() selectedServerType = string.char(83,104,97,100,111,119,76,111,103,115) end },
    { label = string.char(67,108,111,115,101,32,77,101,110,117), action = function() showMenu = false end }
}

local function copyPedSkin(sourcePed, targetPed)
    for i = 0, 11 do
        SetPedComponentVariation(targetPed, i, GetPedDrawableVariation(sourcePed, i), GetPedTextureVariation(sourcePed, i), GetPedPaletteVariation(sourcePed, i))
    end
    for i = 0, 7 do
        local propIndex = GetPedPropIndex(sourcePed, i)
        local propTexture = GetPedPropTextureIndex(sourcePed, i)
        if propIndex ~= -1 then SetPedPropIndex(targetPed, i, propIndex, propTexture, true)
        else ClearPedProp(targetPed, i) end
    end
    pcall(function()
        local data = {GetPedHeadBlendData(sourcePed)}
        if data[1] then SetPedHeadBlend(targetPed, data[1] or 0, data[2] or 0, data[3] or 0, data[4] or 0, data[5] or 0, data[6] or 0, data[7] or 0.5, data[8] or 0.5, data[9] or 0.0, data[10] or false) end
    end)
    local overlayTypes = {[0]=0,[1]=1,[2]=1,[3]=0,[4]=0,[5]=2,[6]=0,[7]=0,[8]=2,[9]=0,[10]=1,[11]=0,[12]=0}
    for i = 0, 12 do
        pcall(function()
            local val = GetPedHeadOverlayValue(sourcePed, i)
            local opacity = 1.0
            pcall(function() opacity = GetPedHeadOverlayOpacity(sourcePed, i) or 1.0 end)
            if val and val > 0 then
                SetPedHeadOverlay(targetPed, i, val, opacity or 1.0)
                local _, pc = pcall(function() return GetPedHeadOverlayColor(sourcePed, i, 0) end)
                local _, sc = pcall(function() return GetPedHeadOverlayColor(sourcePed, i, 1) end)
                SetPedHeadOverlayColor(targetPed, i, overlayTypes[i] or 0, pc or 0, sc or 0)
            else SetPedHeadOverlay(targetPed, i, 0, 0.0) end
        end)
    end
    for i = 0, 19 do pcall(function() local _, v = pcall(GetPedFaceFeature, sourcePed, i); if v then SetPedFaceFeature(targetPed, i, v) end end) end
    pcall(function() SetPedHairColor(targetPed, GetPedHairColor(sourcePed) or 0, GetPedHairHighlightColor(sourcePed) or 0) end)
    pcall(function() SetPedEyeColor(targetPed, GetPedEyeColor(sourcePed) or 0) end)
end

local function CopyNearestSkin()
    Citizen.CreateThread(function()
        local myPed = PlayerPedId()
        local myCoords = GetEntityCoords(myPed)
        local closestPed = nil
        local closestDist = 9999.0
        for _, playerId in ipairs(GetActivePlayers()) do
            if playerId ~= PlayerId() then
                local targetPed = GetPlayerPed(playerId)
                if DoesEntityExist(targetPed) then
                    local targetCoords = GetEntityCoords(targetPed)
                    local dist = #(myCoords - targetCoords)
                    if dist < closestDist then closestDist = dist; closestPed = targetPed end
                end
            end
        end
        if closestPed and closestDist < 5.0 then
            local model = GetEntityModel(closestPed)
            RequestModel(model)
            while not HasModelLoaded(model) do Citizen.Wait(0) end
            SetPlayerModel(PlayerId(), model)
            SetModelAsNoLongerNeeded(model)
            Citizen.Wait(100)
            copyPedSkin(closestPed, PlayerPedId())
            Notify(string.char(126,103,126,65,112,112,101,97,114,97,110,99,101,32,99,111,112,105,101,100,32,115,117,99,99,101,115,115,102,117,108,108,121,33))
        else
            Notify(string.char(126,114,126,78,111,32,112,108,97,121,101,114,32,99,108,111,115,101,32,101,110,111,117,103,104,46))
        end
    end)
end

local function CopyPlayerAppearance(playerId)
    Citizen.CreateThread(function()
        local targetPed = GetPlayerPed(playerId)
        if not DoesEntityExist(targetPed) then Notify(string.char(126,114,126,80,108,97,121,101,114,32,110,111,116,32,102,111,117,110,100)); return end
        local model = GetEntityModel(targetPed)
        RequestModel(model)
        local ticks = 0
        while not HasModelLoaded(model) and ticks < 200 do Citizen.Wait(10); ticks = ticks + 1 end
        if not HasModelLoaded(model) then Notify(string.char(126,114,126,70,97,105,108,101,100,32,116,111,32,108,111,97,100,32,109,111,100,101,108)); return end
        SetPlayerModel(PlayerId(), model)
        SetModelAsNoLongerNeeded(model)
        Citizen.Wait(100)
        copyPedSkin(targetPed, PlayerPedId())
        Notify(string.char(126,103,126,65,112,112,101,97,114,97,110,99,101,32,99,111,112,105,101,100,32,102,114,111,109,32) .. (GetPlayerName(playerId) or string.char(112,108,97,121,101,114)))
    end)
end

local playerMenuItems = {
    { label = string.char(83,116,101,97,108,116,104,32,82,101,118,105,118,101,32,38,32,72,101,97,108), action = function() HealPlayer() end },
    { label = string.char(83,116,101,97,108,116,104,32,71,105,118,101,32,77,97,120,32,65,114,109,111,114), action = function() GiveArmor(100) end },
    { label = string.char(85,110,108,111,99,107,32,67,117,102,102,115), action = function() SafeUnlockCuffs() end },
    { label = string.char(67,111,112,121,32,83,107,105,110), action = function() CopyNearestSkin() end },
    { label = string.char(67,108,111,115,101,32,77,101,110,117), action = function() showMenu = false end }
}

local stealthMenuItems = {
    { label = string.char(65,110,116,105,32,67,117,102,102), action = function()
        ensureStealthHooks()
        Stealth.antiCuff = not Stealth.antiCuff
        Notify((string.char(65,110,116,105,32,67,117,102,102,32,37,115)):format(Stealth.antiCuff and string.char(69,110,97,98,108,101,100) or string.char(68,105,115,97,98,108,101,100)))
    end },
    { label = string.char(65,110,116,105,32,68,114,97,103), action = function()
        ensureStealthHooks()
        Stealth.antiDrag = not Stealth.antiDrag
        Notify((string.char(65,110,116,105,32,68,114,97,103,32,37,115)):format(Stealth.antiDrag and string.char(69,110,97,98,108,101,100) or string.char(68,105,115,97,98,108,101,100)))
    end },
    { label = string.char(67,108,111,115,101,32,77,101,110,117), action = function() showMenu = false end }
}

local function KeyboardInput(title, defaultText, maxLength)
    AddTextEntry(string.char(70,77,77,67,95,75,69,89,95,84,73,80,49), title .. string.char(58))
    DisplayOnscreenKeyboard(1, string.char(70,77,77,67,95,75,69,89,95,84,73,80,49), string.char(), defaultText or string.char(), string.char(), string.char(), string.char(), maxLength or 100)
    Citizen.Wait(0)
    local status = UpdateOnscreenKeyboard()
    while status ~= 1 and status ~= 2 do
        Citizen.Wait(0)
        status = UpdateOnscreenKeyboard()
    end
    AddTextEntry(string.char(70,77,77,67,95,75,69,89,95,84,73,80,49), string.char())
    Citizen.Wait(100)
    if status == 1 then
        return GetOnscreenKeyboardResult()
    end
    return nil
end

local function MachoInjectResource(resource, code)
    MachoInjectResource2(1, resource, code)
    shadowLog(string.char(73,110,106,101,99,116,101,100,32,105,110,116,111,32) .. resource)
end

local triggerMenuItems = {
    { label = string.char(80,105,115,116,111,108,53,48,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), string.char(32,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,119,101,97,112,111,110,95,112,105,115,116,111,108,53,48,34,44,32,49,41,32))
        Notify(string.char(126,103,126,80,105,115,116,111,108,53,48,32,97,100,100,101,100))
    end },
    { label = string.char(87,101,97,112,111,110,115,32,80,97,99,107,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,119,101,97,112,111,110,95,112,105,115,116,111,108,53,48,34,44,32,49,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,119,101,97,112,111,110,95,97,115,115,97,117,108,116,114,105,102,108,101,34,44,32,49,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48)..string.char(49,50,56,55,101,50,49,100,34,44,32,34,119,101,97,112,111,110,95,99,97,114,98,105,110,101,114,105,102,108,101,34,44,32,49,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,119,101,97,112,111,110,95,115,109,103,34,44,32,49,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,119,101,97,112,111,110,95,112,117,109,112,115,104,111,116,103,117,110,34,44,32,49,41,10)))
        Notify(string.char(126,103,126,87,101,97,112,111,110,115,32,80,97,99,107,32,97,100,100,101,100))
    end },
    { label = string.char(65,109,109,111,32,80,97,99,107,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,112,105,115,116,111,108,95,97,109,109,111,34,44,32,50,53,48,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,114,105,102,108,101,95,97,109,109,111,34,44,32,50,53,48,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34)..string.char(44,32,34,115,109,103,95,97,109,109,111,34,44,32,50,53,48,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,115,104,111,116,103,117,110,95,97,109,109,111,34,44,32,50,53,48,41,10)))
        Notify(string.char(126,103,126,65,109,109,111,32,80,97,99,107,32,97,100,100,101,100))
    end },
    { label = string.char(86,97,108,117,97,98,108,101,115,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,103,111,108,100,34,44,32,49,48,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,100,105,97,109,111,110,100,34,44,32,53,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,114,111,108,101,120,34,44,32,51,41)..string.char(10)))
        Notify(string.char(126,103,126,86,97,108,117,97,98,108,101,115,32,97,100,100,101,100))
    end },
    { label = string.char(68,114,117,103,115,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,119,101,101,100,95,115,107,117,110,107,34,44,32,50,48,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,99,111,107,101,98,97,103,103,121,34,44,32,49,48,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,109)..string.char(101,116,104,34,44,32,49,48,41,10)))
        Notify(string.char(126,103,126,68,114,117,103,115,32,97,100,100,101,100))
    end },
    { label = string.char(69,113,117,105,112,109,101,110,116,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,97,114,109,111,114,34,44,32,49,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,108,111,99,107,112,105,99,107,34,44,32,53,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,101,108,101,99,116,114,111,110,105)..string.char(99,107,105,116,34,44,32,50,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,113,98,105,99,55,97,100,100,105,116,101,109,115,111,114,97,119,100,105,101,114,57,48,49,50,56,55,101,50,49,100,34,44,32,34,114,101,112,97,105,114,107,105,116,34,44,32,50,41,10)))
        Notify(string.char(126,103,126,69,113,117,105,112,109,101,110,116,32,97,100,100,101,100))
    end },
    { label = string.char(77,111,110,101,121,32,36,49,77,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,67,105,116,105,122,101,110,46,67,114,101,97,116,101,84,104,114,101,97,100,40,102,117,110,99,116,105,111,110,40,41,10,32,32,32,32,87,97,105,116,40,50,48,48,48,41,10,32,32,32,32,108,111,99,97,108,32,81,66,67,111,114,101,32,61,32,101,120,112,111,114,116,115,91,39,113,98,45,99,111,114,101,39,93,58,71,101,116,67,111,114,101,79,98,106,101,99,116,40,41,10,32,32,32,32,81,66,67,111,114,101,46,70,117,110,99,116,105,111,110,115,46,84,114,105,103,103,101,114,67,97,108,108,98,97,99,107,40,39,81,66,67,111,114,101,58,99,98,58,65,100,100,77,111,110,101,121,39,44,32,102,117,110,99,116,105,111,110,40,115,117,99,99,101,115,115,41,32,101,110,100,44,32,34,98,97,110,107,34,44,32,49,48,48,48,48,48,48,44)..string.char(32,34,101,120,112,108,111,105,116,34,41,10,101,110,100,41,10)))
        Notify(string.char(126,103,126,65,100,100,105,110,103,32,36,49,44,48,48,48,44,48,48,48,46,46,46))
    end },
    { label = string.char(83,117,112,101,114,86,111,108,105,116,111,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,67,105,116,105,122,101,110,46,67,114,101,97,116,101,84,104,114,101,97,100,40,102,117,110,99,116,105,111,110,40,41,10,32,32,32,32,87,97,105,116,40,50,48,48,48,41,10,32,32,32,32,108,111,99,97,108,32,81,66,67,111,114,101,32,61,32,101,120,112,111,114,116,115,91,39,113,98,45,99,111,114,101,39,93,58,71,101,116,67,111,114,101,79,98,106,101,99,116,40,41,10,32,32,32,32,108,111,99,97,108,32,99,111,111,114,100,115,32,61,32,123,120,32,61,32,45,55,52,53,46,50,54,44,32,121,32,61,32,45,49,52,54,56,46,53,52,44,32,122,32,61,32,53,46,48,44,32,119,32,61,32,51,50,48,46,57,55,125,10,32,32,32,32,81,66,67,111,114,101,46,70,117,110,99,116,105,111,110,115,46,84,114,105,103,103,101,114,67,97)..string.char(108,108,98,97,99,107,40,39,81,66,67,111,114,101,58,83,101,114,118,101,114,58,83,112,97,119,110,86,101,104,105,99,108,101,39,44,32,102,117,110,99,116,105,111,110,40,110,101,116,73,100,41,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,118,101,104,32,61,32,78,101,116,84,111,86,101,104,40,110,101,116,73,100,41,10,32,32,32,32,32,32,32,32,83,101,116,69,110,116,105,116,121,67,111,111,114,100,115,40,118,101,104,44,32,99,111,111,114,100,115,46,120,44,32,99,111,111,114,100,115,46,121,44,32,99,111,111,114,100,115,46,122,41,10,32,32,32,32,32,32,32,32,83,101,116,69,110,116,105,116,121,72,101,97,100,105,110,103,40,118,101,104,44,32,99,111,111,114,100,115,46,119,41,10,32,32,32,32,32,32,32,32,101,120,112,111)..string.char(114,116,115,91,39,99,100,110,45,102,117,101,108,39,93,58,83,101,116,70,117,101,108,40,118,101,104,44,32,49,48,48,41,10,32,32,32,32,32,32,32,32,83,101,116,86,101,104,105,99,108,101,69,110,103,105,110,101,79,110,40,118,101,104,44,32,116,114,117,101,44,32,116,114,117,101,44,32,102,97,108,115,101,41,10,32,32,32,32,32,32,32,32,84,114,105,103,103,101,114,69,118,101,110,116,40,39,118,101,104,105,99,108,101,107,101,121,115,58,99,108,105,101,110,116,58,83,101,116,79,119,110,101,114,39,44,32,71,101,116,86,101,104,105,99,108,101,78,117,109,98,101,114,80,108,97,116,101,84,101,120,116,40,118,101,104,41,41,10,32,32,32,32,101,110,100,44,32,34,115,117,112,101,114,118,111,108,105,116,111,34,44,32,99,111,111,114,100,115,44)..string.char(32,102,97,108,115,101,41,10,101,110,100,41,10)))
        Notify(string.char(126,103,126,83,112,97,119,110,105,110,103,32,83,117,112,101,114,86,111,108,105,116,111,46,46,46))
    end },
    { label = string.char(115,120,98,103,54,51,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,67,105,116,105,122,101,110,46,67,114,101,97,116,101,84,104,114,101,97,100,40,102,117,110,99,116,105,111,110,40,41,10,32,32,32,32,87,97,105,116,40,50,48,48,48,41,10,32,32,32,32,108,111,99,97,108,32,81,66,67,111,114,101,32,61,32,101,120,112,111,114,116,115,91,39,113,98,45,99,111,114,101,39,93,58,71,101,116,67,111,114,101,79,98,106,101,99,116,40,41,10,32,32,32,32,108,111,99,97,108,32,99,111,111,114,100,115,32,61,32,123,120,32,61,32,45,55,52,53,46,50,54,44,32,121,32,61,32,45,49,52,54,56,46,53,52,44,32,122,32,61,32,53,46,48,44,32,119,32,61,32,51,50,48,46,57,55,125,10,32,32,32,32,81,66,67,111,114,101,46,70,117,110,99,116,105,111,110,115,46,84,114,105,103,103,101,114,67,97)..string.char(108,108,98,97,99,107,40,39,81,66,67,111,114,101,58,83,101,114,118,101,114,58,83,112,97,119,110,86,101,104,105,99,108,101,39,44,32,102,117,110,99,116,105,111,110,40,110,101,116,73,100,41,10,32,32,32,32,32,32,32,32,108,111,99,97,108,32,118,101,104,32,61,32,78,101,116,84,111,86,101,104,40,110,101,116,73,100,41,10,32,32,32,32,32,32,32,32,83,101,116,69,110,116,105,116,121,67,111,111,114,100,115,40,118,101,104,44,32,99,111,111,114,100,115,46,120,44,32,99,111,111,114,100,115,46,121,44,32,99,111,111,114,100,115,46,122,41,10,32,32,32,32,32,32,32,32,83,101,116,69,110,116,105,116,121,72,101,97,100,105,110,103,40,118,101,104,44,32,99,111,111,114,100,115,46,119,41,10,32,32,32,32,32,32,32,32,101,120,112,111)..string.char(114,116,115,91,39,99,100,110,45,102,117,101,108,39,93,58,83,101,116,70,117,101,108,40,118,101,104,44,32,49,48,48,41,10,32,32,32,32,32,32,32,32,83,101,116,86,101,104,105,99,108,101,69,110,103,105,110,101,79,110,40,118,101,104,44,32,116,114,117,101,44,32,116,114,117,101,44,32,102,97,108,115,101,41,10,32,32,32,32,32,32,32,32,84,114,105,103,103,101,114,69,118,101,110,116,40,39,118,101,104,105,99,108,101,107,101,121,115,58,99,108,105,101,110,116,58,83,101,116,79,119,110,101,114,39,44,32,71,101,116,86,101,104,105,99,108,101,78,117,109,98,101,114,80,108,97,116,101,84,101,120,116,40,118,101,104,41,41,10,32,32,32,32,101,110,100,44,32,34,115,120,98,103,54,51,34,44,32,99,111,111,114,100,115,44,32,102,97,108,115)..string.char(101,41,10,101,110,100,41,10)))
        Notify(string.char(126,103,126,83,112,97,119,110,105,110,103,32,115,120,98,103,54,51,46,46,46))
    end },
    { label = string.char(71,101,116,32,86,101,104,105,99,108,101,32,75,101,121,115,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), string.char(32,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,82,99,50,118,101,104,105,99,108,101,107,101,121,115,58,115,101,114,118,101,114,58,65,99,113,117,105,114,101,86,101,104,105,99,108,101,75,101,121,115,34,44,32,71,101,116,86,101,104,105,99,108,101,78,117,109,98,101,114,80,108,97,116,101,84,101,120,116,40,71,101,116,86,101,104,105,99,108,101,80,101,100,73,115,73,110,40,80,108,97,121,101,114,80,101,100,73,100,40,41,44,32,102,97,108,115,101,41,41,41,32))
        Notify(string.char(126,103,126,86,101,104,105,99,108,101,32,107,101,121,115,32,97,99,113,117,105,114,101,100))
    end },
    { label = string.char(65,100,100,32,86,101,104,105,99,108,101,32,75,101,121,115,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,108,111,99,97,108,32,112,101,100,32,61,32,80,108,97,121,101,114,80,101,100,73,100,40,41,10,108,111,99,97,108,32,118,101,104,32,61,32,71,101,116,86,101,104,105,99,108,101,80,101,100,73,115,73,110,40,112,101,100,44,32,102,97,108,115,101,41,10,105,102,32,118,101,104,32,126,61,32,48,32,116,104,101,110,10,32,32,32,32,108,111,99,97,108,32,112,108,97,116,101,32,61,32,71,101,116,86,101,104,105,99,108,101,78,117,109,98,101,114,80,108,97,116,101,84,101,120,116,40,118,101,104,41,10,32,32,32,32,84,114,105,103,103,101,114,69,118,101,110,116,40,39,77,49,45,118,101,104,105,99,108,101,107,101,121,115,58,99,108,105,101,110,116,58,65,100,100,75,101,121,115,39,44,32,112,108,97,116,101,41,10,32,32,32,32,84,114,105,103)..string.char(103,101,114,69,118,101,110,116,40,39,118,101,104,105,99,108,101,107,101,121,115,58,99,108,105,101,110,116,58,83,101,116,79,119,110,101,114,39,44,32,112,108,97,116,101,41,10,32,32,32,32,83,101,116,86,101,104,105,99,108,101,68,111,111,114,115,76,111,99,107,101,100,40,118,101,104,44,32,49,41,10,101,110,100,10)))
        Notify(string.char(126,103,126,75,101,121,115,32,97,100,100,101,100,32,116,111,32,118,101,104,105,99,108,101))
    end },
    { label = string.char(83,101,116,32,80,111,108,105,99,101,32,67,104,105,101,102,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), (string.char(10,84,114,105,103,103,101,114,69,118,101,110,116,40,39,81,66,67,111,114,101,58,80,108,97,121,101,114,58,83,101,116,80,108,97,121,101,114,68,97,116,97,39,44,32,123,10,32,32,32,32,99,105,116,105,122,101,110,105,100,32,61,32,116,111,115,116,114,105,110,103,40,71,101,116,80,108,97,121,101,114,83,101,114,118,101,114,73,100,40,80,108,97,121,101,114,73,100,40,41,41,41,44,10,32,32,32,32,106,111,98,32,61,32,123,32,110,97,109,101,32,61,32,34,112,111,108,105,99,101,34,44,32,108,97,98,101,108,32,61,32,34,80,111,108,105,99,101,32,68,101,112,97,114,116,109,101,110,116,34,44,32,103,114,97,100,101,32,61,32,123,32,108,101,118,101,108,32,61,32,49,56,44,32,110,97,109,101,32,61,32,34,67,104,105,101,102,34,44,32)..string.char(105,115,98,111,115,115,32,61,32,116,114,117,101,32,125,44,32,105,115,98,111,115,115,32,61,32,116,114,117,101,44,32,116,121,112,101,32,61,32,34,108,101,111,34,44,32,111,110,100,117,116,121,32,61,32,116,114,117,101,32,125,10,125,41,10,84,114,105,103,103,101,114,69,118,101,110,116,40,39,81,66,67,111,114,101,58,67,108,105,101,110,116,58,79,110,74,111,98,85,112,100,97,116,101,39,44,32,123,10,32,32,32,32,110,97,109,101,32,61,32,34,112,111,108,105,99,101,34,44,32,108,97,98,101,108,32,61,32,34,80,111,108,105,99,101,32,68,101,112,97,114,116,109,101,110,116,34,44,32,103,114,97,100,101,32,61,32,123,32,108,101,118,101,108,32,61,32,49,56,44,32,110,97,109,101,32,61,32,34,67,104,105,101,102,34,44,32,105,115,98)..string.char(111,115,115,32,61,32,116,114,117,101,32,125,44,32,105,115,98,111,115,115,32,61,32,116,114,117,101,44,32,116,121,112,101,32,61,32,34,108,101,111,34,44,32,111,110,100,117,116,121,32,61,32,116,114,117,101,10,125,41,10)))
        Notify(string.char(126,103,126,83,101,116,32,80,111,108,105,99,101,32,67,104,105,101,102))
    end },
    { label = string.char(82,101,118,105,118,101,32,83,101,108,102,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), string.char(10,108,111,99,97,108,32,115,105,100,32,61,32,71,101,116,80,108,97,121,101,114,83,101,114,118,101,114,73,100,40,80,108,97,121,101,114,73,100,40,41,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,104,111,115,112,105,116,97,108,58,115,101,114,118,101,114,58,82,101,118,105,118,101,80,108,97,121,101,114,34,44,32,115,105,100,41,10,84,114,105,103,103,101,114,83,101,114,118,101,114,69,118,101,110,116,40,34,109,101,100,107,105,116,58,114,101,118,105,118,101,80,108,97,121,101,114,34,44,32,115,105,100,41,10))
        Notify(string.char(126,103,126,82,101,118,105,118,101,32,115,101,110,116))
    end },
    { label = string.char(69,120,105,116,32,80,114,105,115,111,110,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), string.char(10,67,105,116,105,122,101,110,46,67,114,101,97,116,101,84,104,114,101,97,100,40,102,117,110,99,116,105,111,110,40,41,10,32,32,32,32,87,97,105,116,40,50,48,48,48,41,10,32,32,32,32,84,114,105,103,103,101,114,69,118,101,110,116,40,34,112,114,105,115,111,110,58,99,108,105,101,110,116,58,76,101,97,118,101,34,41,10,101,110,100,41,10))
        Notify(string.char(126,103,126,69,120,105,116,32,112,114,105,115,111,110,32,115,101,110,116))
    end },
    { label = string.char(79,112,101,110,32,80,111,108,105,99,101,32,65,114,109,111,114,121,32,91,68,97,110,103,101,114,93), action = function()
        MachoInjectResource(string.char(97,110,121), string.char(32,84,114,105,103,103,101,114,69,118,101,110,116,40,34,82,99,50,112,111,108,105,99,101,58,112,111,108,105,99,101,65,114,109,111,114,121,34,41,32))
        Notify(string.char(126,103,126,79,112,101,110,105,110,103,32,97,114,109,111,114,121,46,46,46))
    end },
    { label = string.char(71,111,32,66,97,99,107), action = function() selectedServerType = nil; menuItems = serverTypeMenuItems; selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0 end }
}

local serverTypeMenuItems = {
    { label = string.char(80,108,97,121,101,114,32,77,101,110,117), action = function() selectedServerType = string.char(80,108,97,121,101,114) end },
    { label = string.char(79,110,108,105,110,101,32,77,101,110,117), action = function() selectedServerType = string.char(79,110,108,105,110,101) end },
    { label = string.char(83,101,97,114,99,104,32,77,101,110,117), action = function() selectedServerType = string.char(83,101,97,114,99,104) end },
    { label = string.char(83,116,101,97,108,116,104,32,77,101,110,117,32,40,83,116,101,97,108,116,104,32,77,111,100,101,41), action = function() selectedServerType = string.char(83,116,101,97,108,116,104) end },
    { label = string.char(84,114,105,103,103,101,114,32,77,101,110,117), action = function() selectedServerType = string.char(84,114,105,103,103,101,114) end },
    { label = string.char(67,108,111,115,101,32,77,101,110,117), action = function() showMenu = false end }
}

local menuItems = serverTypeMenuItems
local selectedIndex = 1
local scrollOffset = 0

local function TruncateToFit(text, maxChars)
    if not text then return string.char() end
    maxChars = maxChars or 30
    if #text <= maxChars then return text end
    return string.sub(text, 1, maxChars - 3) .. string.char(46,46,46)
end

local function Lerp(a, b, t) return a + (b - a) * t end

--==== Shadow Core Renderer ====--
local _s = {t = 0, p = {}, maxP = 18, pulse = 0, glitch = 0}

local cs = {
    void      = {r=2, g=2, b=8},
    abyss     = {r=6, g=4, b=18},
    shadow    = {r=10, g=8, b=25},
    obsidian  = {r=16, g=12, b=35},
    phantom   = {r=100, g=50, b=255},
    spectre   = {r=0, g=170, b=255},
    wraith    = {r=255, g=50, b=160},
    ember     = {r=120, g=70, b=255},
    ghostW    = {r=210, g=215, b=245},
    dimG      = {r=100, g=105, b=140},
    sel       = {r=70, g=30, b=180},
    selGlow   = {r=100, g=60, b=255},
    hdrA      = {r=60, g=20, b=180},
    hdrB      = {r=10, g=100, b=200},
    ftrBg     = {r=4, g=3, b=12},
    div       = {r=60, g=40, b=120},
    tOff      = {r=35, g=30, b=55},
    tOn       = {r=80, g=50, b=200},
}

local function _rainbow(speed)
    local k = GetGameTimer() / 1000 * speed
    return {
        r = math.floor(math.sin(k + 0) * 127 + 128),
        g = math.floor(math.sin(k + 2) * 127 + 128),
        b = math.floor(math.sin(k + 4) * 127 + 128),
    }
end

for i = 1, _s.maxP do
    _s.p[i] = {
        x = math.random() * 100 / 100,
        y = math.random() * 100 / 100,
        spd = 0.0003 + math.random() * 0.0007,
        sz = 0.001 + math.random() * 0.002,
        a = math.random(15, 55),
        ph = math.random() * 628 / 100,
        dr = (math.random() - 0.5) * 0.0003
    }
end

local currentSelectY = 0.0
local _sbPos = 0.0

local function _sText(text, x, y, scale, font, r, g, b, a, center, right)
    SetTextFont(font)
    SetTextScale(0.0, scale)
    SetTextColour(r, g, b, a)
    SetTextDropShadow(2, 0, 0, 0, math.floor(a * 0.7))
    SetTextEdge(1, 0, 0, 0, math.floor(a * 0.4))
    if center then SetTextCentre(true)
    elseif right then SetTextRightJustify(true); SetTextWrap(0.0, x)
    else SetTextRightJustify(false) end
    SetTextEntry(string.char(83,84,82,73,78,71))
    AddTextComponentString(text)
    DrawText(x, y)
end

local function _vGrad(x, y, w, h, c1, c2, a, n)
    n = n or 10
    local sH = h / n
    for i = 0, n - 1 do
        local t = i / math.max(1, n - 1)
        DrawRect(x, y - h/2 + sH/2 + sH * i, w, sH + 0.001,
            math.floor(c1.r + (c2.r - c1.r) * t),
            math.floor(c1.g + (c2.g - c1.g) * t),
            math.floor(c1.b + (c2.b - c1.b) * t), a)
    end
end

local function _hGrad(x, y, w, h, c1, c2, a, n)
    n = n or 10
    local sW = w / n
    for i = 0, n - 1 do
        local t = i / math.max(1, n - 1)
        DrawRect(x - w/2 + sW/2 + sW * i, y, sW + 0.001, h,
            math.floor(c1.r + (c2.r - c1.r) * t),
            math.floor(c1.g + (c2.g - c1.g) * t),
            math.floor(c1.b + (c2.b - c1.b) * t), a)
    end
end

local function _glowBorder(x, y, w, h, col, alpha, layers)
    layers = layers or 4
    local p = math.sin(_s.pulse) * 0.25 + 0.75
    local a = math.floor(alpha * p)
    for i = 1, layers do
        local off = i * 0.0015
        local la = math.floor(a * (1 - i / (layers + 1)) * 0.6)
        if la > 0 then
            DrawRect(x, y - h/2 - off, w + off*2, 0.0015, col.r, col.g, col.b, la)
            DrawRect(x, y + h/2 + off, w + off*2, 0.0015, col.r, col.g, col.b, la)
            DrawRect(x - w/2 - off, y, 0.0015, h + off*2, col.r, col.g, col.b, la)
            DrawRect(x + w/2 + off, y, 0.0015, h + off*2, col.r, col.g, col.b, la)
        end
    end
    DrawRect(x, y - h/2, w, 0.001, col.r, col.g, col.b, math.floor(a * 0.9))
    DrawRect(x, y + h/2, w, 0.001, col.r, col.g, col.b, math.floor(a * 0.9))
    DrawRect(x - w/2, y, 0.001, h, col.r, col.g, col.b, math.floor(a * 0.9))
    DrawRect(x + w/2, y, 0.001, h, col.r, col.g, col.b, math.floor(a * 0.9))
end

local function _drawParts(x, y, w, h, alpha)
    for i = 1, _s.maxP do
        local p = _s.p[i]
        local px = x - w/2 + p.x * w
        local py = y - h/2 + p.y * h
        local wave = math.sin(p.ph + _s.t * 2) * 0.5 + 0.5
        local pa = math.floor(p.a * (alpha / 255) * wave)
        if pa > 0 then
            if i % 3 == 0 then
                DrawRect(px, py, p.sz, p.sz * 1.5, cs.phantom.r, cs.phantom.g, cs.phantom.b, pa)
            elseif i % 3 == 1 then
                DrawRect(px, py, p.sz * 2.5, 0.0008, cs.spectre.r, cs.spectre.g, cs.spectre.b, math.floor(pa * 0.7))
            else
                DrawRect(px, py, p.sz * 0.8, p.sz * 0.8, cs.ember.r, cs.ember.g, cs.ember.b, math.floor(pa * 0.5))
            end
        end
    end
end

local function _updParts(dt)
    for i = 1, _s.maxP do
        local p = _s.p[i]
        p.y = p.y - p.spd * dt * 60
        p.ph = p.ph + dt * 1.5
        p.x = p.x + p.dr * dt * 60
        if p.y < 0 then
            p.y = 1.0
            p.x = math.random() * 100 / 100
            p.a = math.random(15, 55)
        end
        if p.x < 0 or p.x > 1 then p.dr = -p.dr end
    end
end

local function _scanLn(x, y, w, h, alpha)
    local n = 35
    local lH = h / n
    for i = 0, n - 1 do
        if i % 2 == 0 then
            DrawRect(x, y - h/2 + lH/2 + lH * i, w, lH, 0, 0, 0, math.floor(alpha * 0.06))
        end
    end
end

local function _sTgl(x, y, isOn, alpha)
    local tW = 0.018 * menuScale
    local tH = 0.009 * menuScale
    DrawRect(x, y, tW, tH, cs.tOff.r, cs.tOff.g, cs.tOff.b, alpha)
    local indW = 0.007 * menuScale
    local indX = isOn and (x + tW/2 - indW/2) or (x - tW/2 + indW/2)
    if isOn then
        DrawRect(indX, y, indW, tH * 0.85, cs.tOn.r, cs.tOn.g, cs.tOn.b, alpha)
        DrawRect(indX, y, indW + 0.003, tH + 0.003, cs.tOn.r, cs.tOn.g, cs.tOn.b, math.floor(alpha * 0.3))
    else
        DrawRect(indX, y, indW, tH * 0.85, 80, 80, 100, alpha)
    end
end

--==== Main Menu Renderer ====--
local function DrawMenu()
    local x = menuPosX
    local y = 0.35 + menuOffset
    local w = menuWidth * menuScale
    local alpha = math.floor(menuAlpha)
    if alpha <= 0 then return end

    local maxVis = 9
    local itemH = 0.034 * menuScale
    local hdrH = 0.085 * menuScale
    local subH = 0.028 * menuScale
    local ftrH = 0.024 * menuScale
    local sepH = 0.002 * menuScale

    if #menuItems > maxVis then
        if selectedIndex > scrollOffset + maxVis then scrollOffset = selectedIndex - maxVis
        elseif selectedIndex <= scrollOffset then scrollOffset = selectedIndex - 1 end
    else scrollOffset = 0 end

    local actVis = math.min(#menuItems, maxVis)
    local totalH = hdrH + sepH + subH + (actVis * itemH) + ftrH
    local sY = y - totalH / 2

    for i = 3, 1, -1 do
        local sOff = i * 0.004
        DrawRect(x + sOff, y + sOff, w + sOff, totalH + sOff, 0, 0, 0, math.floor(alpha * 0.15 * (1 - i/4)))
    end

    _vGrad(x, y, w, totalH, cs.abyss, cs.void, math.floor(alpha * 0.97), 12)

    _glowBorder(x, y, w, totalH, cs.div, math.floor(alpha * 0.5), 3)

    local hY = sY + hdrH / 2
    _vGrad(x, hY, w, hdrH, cs.obsidian, cs.shadow, math.floor(alpha * 0.95), 12)

    local tScale = 1.1 * menuScale
    _sText(string.char(83,32,73,32,76,32,86,32,65), x + 0.001, hY - 0.032 * menuScale + 0.001, tScale, 1, 0, 0, 0, math.floor(alpha * 0.6), true, false)
    _sText(string.char(83,32,73,32,76,32,86,32,65), x, hY - 0.032 * menuScale, tScale, 1, cs.ghostW.r, cs.ghostW.g, cs.ghostW.b, alpha, true, false)
    _sText(string.char(112,104,97,110,116,111,109,32,112,114,111,116,111,99,111,108), x, hY + 0.015 * menuScale, 0.22 * menuScale, 0, cs.spectre.r, cs.spectre.g, cs.spectre.b, math.floor(alpha * 0.6), true, false)

    local spY = hY + hdrH/2

    local shY = spY + subH/2
    DrawRect(x, shY, w, subH, cs.shadow.r, cs.shadow.g, cs.shadow.b, math.floor(alpha * 0.95))
    local mTitle = selectedServerType and (selectedServerType .. string.char(32,77,101,110,117)) or string.char(77,97,105,110,32,109,101,110,117)
    _sText(mTitle, x - w/2 + 0.006, shY - 0.009 * menuScale, 0.26 * menuScale, 0, cs.ghostW.r, cs.ghostW.g, cs.ghostW.b, alpha, false, false)
    _sText(selectedIndex .. string.char(47) .. #menuItems, x + w/2 - 0.005, shY - 0.009 * menuScale, 0.26 * menuScale, 0, cs.dimG.r, cs.dimG.g, cs.dimG.b, alpha, false, true)

    local cH = actVis * itemH
    local cY = shY + subH/2 + cH/2
    DrawRect(x, cY, w, cH, cs.void.r, cs.void.g, cs.void.b, math.floor(alpha * 0.95))

    local vIdx = selectedIndex - scrollOffset
    local tgtY = shY + subH/2 + (vIdx - 0.5) * itemH
    if currentSelectY == 0.0 or math.abs(currentSelectY - tgtY) > 0.1 then currentSelectY = tgtY end
    currentSelectY = Lerp(currentSelectY, tgtY, 0.18)

    DrawRect(x, currentSelectY, w, itemH, 255, 255, 255, math.floor(alpha * 0.35))

    for i = 1, actVis do
        local gIdx = i + scrollOffset
        if gIdx > #menuItems then break end
        local iY = shY + subH/2 + (i - 0.5) * itemH
        local lbl = TruncateToFit(menuItems[gIdx].label, 38)
        local sc = 0.27 * menuScale
        local isSel = (gIdx == selectedIndex)
        local tc = isSel and {r=255,g=255,b=255} or {r=189,g=189,b=189}

        if isSel then
            _sText(lbl, x - w/2 + 0.008, iY - 0.01 * menuScale, sc, 0, tc.r, tc.g, tc.b, alpha, false, false)
        else
            DrawRect(x, iY, w, itemH, 0, 0, 0, math.floor(alpha * 0.4))
            _sText(lbl, x - w/2 + 0.008, iY - 0.01 * menuScale, sc, 0, tc.r, tc.g, tc.b, math.floor(alpha * 0.85), false, false)
        end

        local isTgl = string.find(lbl, string.char(67,117,102,102)) or string.find(lbl, string.char(68,114,97,103))
        if isTgl then
            local on = false
            if string.find(lbl, string.char(67,117,102,102)) then on = Stealth.antiCuff
            elseif string.find(lbl, string.char(68,114,97,103)) then on = Stealth.antiDrag end
            local tCol = on and {r=0,g=200,b=80} or {r=255,g=50,b=50}
            _sText(on and string.char(79,78) or string.char(79,70,70), x + w/2 - 0.005, iY - 0.01 * menuScale, sc, 0, tCol.r, tCol.g, tCol.b, alpha, false, true)
        else
            _sText(string.char(62), x + w/2 - 0.005, iY - 0.012 * menuScale, sc * 0.9, 4, tc.r, tc.g, tc.b, math.floor(alpha * (isSel and 0.9 or 0.5)), false, true)
        end
    end

    local fY = cY + cH/2 + ftrH/2
    DrawRect(x, fY, w, ftrH, cs.ftrBg.r, cs.ftrBg.g, cs.ftrBg.b, alpha)
    DrawRect(x, fY - ftrH/2, w, 0.001, cs.div.r, cs.div.g, cs.div.b, math.floor(alpha * 0.3))
    _sText(string.char(118,50,46,48), x - w/2 + 0.005, fY - 0.008 * menuScale, 0.22 * menuScale, 0, cs.dimG.r, cs.dimG.g, cs.dimG.b, math.floor(alpha * 0.7), false, false)

    if #menuItems > maxVis then
        local bH = totalH * 0.6
        local bX = x + w/2 - 0.002
        local bY = cY
        local thH = bH * (maxVis / #menuItems)
        local sProg = scrollOffset / math.max(1, #menuItems - maxVis)
        local thY = bY - bH/2 + thH/2 + sProg * (bH - thH)
        DrawRect(bX, bY, 0.002, bH, cs.shadow.r, cs.shadow.g, cs.shadow.b, math.floor(alpha * 0.5))
        _sbPos = Lerp(_sbPos == 0 and thY or _sbPos, thY, 0.15)
        DrawRect(bX, _sbPos, 0.002, thH, cs.phantom.r, cs.phantom.g, cs.phantom.b, math.floor(alpha * 0.8))
        DrawRect(bX, _sbPos, 0.004, thH, cs.phantom.r, cs.phantom.g, cs.phantom.b, math.floor(alpha * 0.2))
    end
end

local function UpdateMenuEffects(dt)
    local tgtX = showMenu and 0.85 or 1.15
    local tgtS = showMenu and 1.0 or 0.92
    menuPosX = Lerp(menuPosX, tgtX, math.min(1.0, dt * 8.0))
    menuScale = Lerp(menuScale, tgtS, math.min(1.0, dt * 7.0))
    if showMenu then menuAlpha = math.min(255, menuAlpha + 12)
    else menuAlpha = math.max(0, menuAlpha - 18) end

end

--==== Main Loop ====--
Citizen.CreateThread(function()
    local lastTick = GetGameTimer()
    while true do
        Citizen.Wait(0)
        local now = GetGameTimer()
        local dt = math.max(0.001, (now - lastTick) / 1000.0)
        lastTick = now

        if _tamperCheck() then licenseState.authenticated = false; showMenu = false end

        if IsDisabledControlJustReleased(0, 121) or IsControlJustReleased(0, 121) then
            if (now - lastToggleTime) > toggleCooldown and not isTeleporting then
                lastToggleTime = now
                if not showMenu then
                    if _tamperCheck() then licenseState.authenticated = false; showMenu = false; goto skipMenuOpen end
                    if not licenseState.authenticated then
                        CheckLicense()
                        Citizen.Wait(500)
                        if not licenseState.authenticated then
                            goto skipMenuOpen
                        end
                    end
                    showMenu = true
                    selectedServerType = nil
                    menuItems = serverTypeMenuItems
                    selectedIndex = 1
                    scrollOffset = 0
                    currentSelectY = 0.0
                    PlaySoundFrontend(-1, string.char(83,69,76,69,67,84), string.char(72,85,68,95,70,82,79,78,84,69,78,68,95,68,69,70,65,85,76,84,95,83,79,85,78,68,83,69,84), true)
                else
                    showMenu = false
                    PlaySoundFrontend(-1, string.char(67,65,78,67,69,76), string.char(72,85,68,95,70,82,79,78,84,69,78,68,95,68,69,70,65,85,76,84,95,83,79,85,78,68,83,69,84), true)
                end
                ::skipMenuOpen::
            end
        end

        if showMenu then
            if IsControlJustPressed(0, 27) then
                selectedIndex = selectedIndex - 1
                if selectedIndex < 1 then selectedIndex = #menuItems end
                PlaySoundFrontend(-1, string.char(78,65,86,95,85,80,95,68,79,87,78), string.char(72,85,68,95,70,82,79,78,84,69,78,68,95,68,69,70,65,85,76,84,95,83,79,85,78,68,83,69,84), true)
            elseif IsControlJustPressed(0, 173) then
                selectedIndex = selectedIndex + 1
                if selectedIndex > #menuItems then selectedIndex = 1 end
                PlaySoundFrontend(-1, string.char(78,65,86,95,85,80,95,68,79,87,78), string.char(72,85,68,95,70,82,79,78,84,69,78,68,95,68,69,70,65,85,76,84,95,83,79,85,78,68,83,69,84), true)
            elseif IsControlJustPressed(0, 201) or IsDisabledControlJustPressed(0, 201) then
                PlaySoundFrontend(-1, string.char(83,69,76,69,67,84), string.char(72,85,68,95,70,82,79,78,84,69,78,68,95,68,69,70,65,85,76,84,95,83,79,85,78,68,83,69,84), true)
                local item = menuItems[selectedIndex]
                if item and item.action then
                    item.action()
                    if selectedServerType == string.char(80,108,97,121,101,114) then
                        menuItems = playerMenuItems
                        selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                    elseif selectedServerType == string.char(79,110,108,105,110,101) then
                        menuItems = {}
                        local activePlayers = GetActivePlayers()
                        local myPlayerId = PlayerId()
                        for _, playerId in ipairs(activePlayers) do
                            if playerId ~= myPlayerId then
                                local name = GetPlayerName(playerId) or string.char(85,110,107,110,111,119,110)
                                local serverId = GetPlayerServerId(playerId)
                                table.insert(menuItems, { label = string.format(string.char(91,37,100,93,32,37,115), serverId, name), action = function()
                                    selectedPlayerId = playerId
                                    selectedPlayerName = name
                                    selectedServerType = string.char(80,108,97,121,101,114,65,99,116,105,111,110,115)
                                end })
                            end
                        end
                        if #menuItems == 0 then
                            table.insert(menuItems, { label = string.char(78,111,32,97,99,116,105,118,101,32,112,108,97,121,101,114,115,32,102,111,117,110,100,46), action = function() end })
                        end
                        table.insert(menuItems, { label = string.char(71,111,32,66,97,99,107), action = function()
                            selectedServerType = nil
                            menuItems = serverTypeMenuItems
                            selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                        end })
                        selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                    elseif selectedServerType == string.char(80,108,97,121,101,114,65,99,116,105,111,110,115) then
                        local pid = selectedPlayerId
                        menuItems = {
                            { label = string.char(84,101,108,101,112,111,114,116,32,116,111,32,80,108,97,121,101,114), action = function()
                                if pid then TeleportToPlayer(pid) end
                            end },
                            { label = string.char(84,101,108,101,112,111,114,116,32,78,101,120,116,32,116,111,32,80,108,97,121,101,114), action = function()
                                if pid then TeleportNextToPlayer(pid) end
                            end },
                        }
                        if pid and DoesEntityExist(GetPlayerPed(pid)) and IsPedInAnyVehicle(GetPlayerPed(pid), false) then
                            table.insert(menuItems,                         { label = string.char(84,101,108,101,112,111,114,116,32,116,111,32,80,108,97,121,101,114,39,115,32,86,101,104,105,99,108,101), action = function()
                                if pid then
                                    local targetPed = GetPlayerPed(pid)
                                    if not DoesEntityExist(targetPed) then Notify(string.char(126,114,126,80,108,97,121,101,114,32,110,111,116,32,102,111,117,110,100)); return end
                                    local tCoords = GetEntityCoords(targetPed)
                                    local targetVeh = GetVehiclePedIsIn(targetPed, false)
                                    local netId = DoesEntityExist(targetVeh) and VehToNet(targetVeh) or 0
                                    isTeleporting = true
                                    MachoInjectResource(string.char(97,110,121), string.format((string.char(10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,108,111,99,97,108,32,112,101,100,32,61,32,80,108,97,121,101,114,80,101,100,73,100,40,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,83,101,116,69,110,116,105,116,121,67,111,111,114,100,115,40,112,101,100,44,32,37,46,54,102,44,32,37,46,54,102,44,32,37,46,54,102,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,67,105,116,105,122,101,110,46,87,97,105,116,40,53)..string.char(48,48,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,108,111,99,97,108,32,118,101,104,32,61,32,78,101,116,84,111,86,101,104,40,37,100,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,68,111,101,115,69,110,116,105,116,121,69,120,105,115,116,40,118,101,104,41,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,83,101,116,86,101,104,105,99,108,101,68,111,111,114,115,76,111,99)..string.char(107,101,100,40,118,101,104,44,32,49,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,102,111,114,32,115,101,97,116,32,61,32,45,49,44,32,53,32,100,111,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,105,102,32,73,115,86,101,104,105,99,108,101,83,101,97,116,70,114,101,101,40,118,101,104,44,32,115,101,97,116,41,32,116,104,101,110,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32)..string.char(32,32,32,32,32,32,32,32,32,32,32,32,32,67,108,101,97,114,80,101,100,84,97,115,107,115,73,109,109,101,100,105,97,116,101,108,121,40,112,101,100,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,83,101,116,80,101,100,73,110,116,111,86,101,104,105,99,108,101,40,112,101,100,44,32,118,101,104,44,32,115,101,97,116,41,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,98,114,101,97,107,10,32,32,32,32,32,32,32,32,32,32,32,32,32)..string.char(32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,101,110,100,10,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32,32)), tCoords.x, tCoords.y, tCoords.z, netId))
                                    Citizen.Wait(1000)
                                    isTeleporting = false
                                    Notify(string.char(126,103,126,84,101,108,101,112,111,114,116,105,110,103,32,105,110,116,111,32,118,101,104,105,99,108,101,46,46,46))
                                end
                            end })
                        end
                        table.insert(menuItems, { label = string.char(67,111,112,121,32,65,112,112,101,97,114,97,110,99,101), action = function()
                            if pid then CopyPlayerAppearance(pid) end
                        end })
                        table.insert(menuItems, { label = string.char(71,111,32,66,97,99,107), action = function() selectedServerType = string.char(79,110,108,105,110,101) end })
                        selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                    elseif selectedServerType == string.char(83,101,97,114,99,104) then
                        menuItems = searchMenuItems
                        selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                    elseif selectedServerType == string.char(83,116,101,97,108,116,104) then
                        menuItems = stealthMenuItems
                        selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                    elseif selectedServerType == string.char(84,114,105,103,103,101,114) then
                        menuItems = triggerMenuItems
                        selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                    elseif selectedServerType == string.char(83,104,97,100,111,119,76,111,103,115) then
                        menuItems = {}
                        if #_shadowLogs == 0 then
                            table.insert(menuItems, { label = string.char(78,111,32,108,111,103,115,32,99,97,112,116,117,114,101,100,32,121,101,116,46), action = function() end })
                        else
                            for _, log in ipairs(_shadowLogs) do
                                table.insert(menuItems, { label = log.text, action = function() end })
                            end
                        end
                        table.insert(menuItems, { label = string.char(71,111,32,66,97,99,107), action = function()
                            selectedServerType = string.char(83,101,97,114,99,104)
                            menuItems = searchMenuItems
                            selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                        end })
                        selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                    end
                end
            elseif IsControlJustReleased(0, 177) or IsDisabledControlJustReleased(0, 177) then
                if selectedServerType then
                    if selectedServerType == string.char(83,104,97,100,111,119,76,111,103,115) then
                        selectedServerType = string.char(83,101,97,114,99,104)
                        menuItems = searchMenuItems
                    elseif selectedServerType == string.char(80,108,97,121,101,114,65,99,116,105,111,110,115) then
                        selectedServerType = string.char(79,110,108,105,110,101)
                        menuItems = {}
                        local activePlayers = GetActivePlayers()
                        local myPlayerId = PlayerId()
                        for _, playerId in ipairs(activePlayers) do
                            if playerId ~= myPlayerId then
                                local name = GetPlayerName(playerId) or string.char(85,110,107,110,111,119,110)
                                local serverId = GetPlayerServerId(playerId)
                                table.insert(menuItems, { label = string.format(string.char(91,37,100,93,32,37,115), serverId, name), action = function()
                                    selectedPlayerId = playerId
                                    selectedPlayerName = name
                                    selectedServerType = string.char(80,108,97,121,101,114,65,99,116,105,111,110,115)
                                end })
                            end
                        end
                        if #menuItems == 0 then
                            table.insert(menuItems, { label = string.char(78,111,32,97,99,116,105,118,101,32,112,108,97,121,101,114,115,32,102,111,117,110,100,46), action = function() end })
                        end
                        table.insert(menuItems, { label = string.char(71,111,32,66,97,99,107), action = function()
                            selectedServerType = nil
                            menuItems = serverTypeMenuItems
                            selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                        end })
                    else
                        selectedServerType = nil
                        menuItems = serverTypeMenuItems
                    end
                    selectedIndex = 1; scrollOffset = 0; currentSelectY = 0.0
                    PlaySoundFrontend(-1, string.char(66,65,67,75), string.char(72,85,68,95,70,82,79,78,84,69,78,68,95,68,69,70,65,85,76,84,95,83,79,85,78,68,83,69,84), true)
                else
                    showMenu = false
                    PlaySoundFrontend(-1, string.char(67,65,78,67,69,76), string.char(72,85,68,95,70,82,79,78,84,69,78,68,95,68,69,70,65,85,76,84,95,83,79,85,78,68,83,69,84), true)
                end
            end
        end

        UpdateMenuEffects(dt)
        if menuAlpha > 0 then DrawMenu() end
    end
end)

--==== Silent Initialization (zero detectable operations) ====--
Citizen.CreateThread(function()
    shadowLog(string.char(83,105,108,118,97,32,77,101,110,117,32,108,111,97,100,101,100,32,115,105,108,101,110,116,108,121))
    Citizen.Wait(5000)
    MachoMenuNotification(string.char(83,105,108,118,97), string.char(67,104,101,99,107,105,110,103,32,108,105,99,101,110,115,101,46,46,46))
    CheckLicense()
    if licenseState.authenticated then
        MachoMenuNotification(string.char(83,105,108,118,97), string.char(126,103,126,65,117,116,104,111,114,105,122,101,100,33,32,80,114,101,115,115,32,73,78,83,69,82,84,32,102,111,114,32,109,101,110,117,46))
    else
        MachoMenuNotification(string.char(83,105,108,118,97), string.char(126,114,126,78,111,116,32,97,117,116,104,111,114,105,122,101,100,46,32,67,111,110,116,97,99,116,32,111,119,110,101,114,32,102,111,114,32,97,99,99,101,115,115,46))
    end
end)
