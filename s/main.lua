
-------------------
-- VARIABLES
-------------------
local RSGCore = exports['rsg-core']:GetCoreObject() -- Core
local currentlyPlaying = {}
local ownerPhonograph = {}

function printTable(tbl, indent)
    indent = indent or 0
    local formatting = string.rep("  ", indent)

    if type(tbl) ~= "table" then
        print(formatting .. tostring(tbl))
        return
    end

    for k, v in pairs(tbl) do
        local key = tostring(k)
        if type(v) == "table" then
            print(formatting .. key .. " = {")
            printTable(v, indent + 1)
            print(formatting .. "}")
        else
            print(formatting .. key .. " = " .. tostring(v))
        end
    end
end

-------------------
-- ITEM HANDLE
-------------------

RSGCore.Functions.CreateUseableItem("phonograph", function(source, item)
    local src = source
    if ownerPhonograph[src] then
        -- TriggerClientEvent('jo.notif.right', src, 'You are not the owner!', 'hud_textures', 'times', 'COLOR_RED', 5000)
        -- TriggerClientEvent('jo.notif.right', src, "You already placed a phonograph!", 'hud_textures', 'times', 'COLOR_RED', 5000)
        return
    end
    TriggerClientEvent("boss_phonograph:client:placePropPhonograph", src)
end)

-------------------
-- SERVER ITEM EVENTS
-------------------

RegisterNetEvent('boss_phonograph:server:saveOwner')
AddEventHandler('boss_phonograph:server:saveOwner', function(id)
    local src = source
    ownerPhonograph[src] = id

    printTable(currentlyPlaying)
    printTable(ownerPhonograph)
end)

RegisterNetEvent('boss_phonograph:server:pickUp')
AddEventHandler('boss_phonograph:server:pickUp', function(id)
    local src = source  -- Get player source
    id = Config.secretKey .. '-' .. id
    -- Ensure player is the owner of the phonograph
    if ownerPhonograph[src] and ownerPhonograph[src] == id then

        -- Stop music if it is playing
        if currentlyPlaying[id] then
            TriggerClientEvent('boss_phonograph:client:stopMusic', -1, id)
            currentlyPlaying[id] = nil  -- Remove from playing list
            print("[boss_phonograph] Music stopped for Phonograph ID: " .. id)
        else
            print("[boss_phonograph] No music playing for Phonograph ID: " .. id)
        end

        -- Remove ownership
        ownerPhonograph[src] = nil
        -- local networkEntityId = string.match(id, Config.secretKey .."%-(%d+)")
        -- print("Yes it is : ".. networkEntityId)
        TriggerClientEvent('boss_phonograph:client:removePhonograph', src, id)
        
        print("[boss_phonograph] Phonograph picked up by player: " .. src .. ", ID: " .. id)
    else
        -- Player is not the owner, notify them
        TriggerClientEvent('jo.notif.right', src, "You're not the owner!", 'hud_textures', 'times', 'COLOR_RED', 5000)
    end

    -- Debug output
    print("Currently Playing:")
    for k, v in pairs(currentlyPlaying) do
        print("Phonograph ID: " .. k .. " | Playing: " .. tostring(v))
    end

    print("Owner Phonograph:")
    for k, v in pairs(ownerPhonograph) do
        print("Player ID: " .. k .. " | Phonograph ID: " .. tostring(v))
    end
end)



-------------------
-- SERVER MSUCI EVENTS
-------------------

RegisterNetEvent('boss_phonograph:server:playMusic')
AddEventHandler('boss_phonograph:server:playMusic', function(id, coords, url, volume)
    local src = source
    local xPlayer = RSGCore.Functions.GetPlayer(src)

    if Config.fee and xPlayer.Functions.GetMoney('cash') >= Config.fee then
        xPlayer.Functions.RemoveMoney('cash', Config.fee)
    else
        jo.notif.right(src, "You don\'t have enough money." .. " $" .. Config.fee, 'hud_textures', 'times',
                               'COLOR_RED', 5000)
        return
    end

    if currentlyPlaying[id] then
        jo.notif.right(src, "Can't replace other song. Please wait", 'hud_textures', 'times',
                               'COLOR_RED', 5000)
        return
    end

    currentlyPlaying[id] = true

    TriggerClientEvent('boss_phonograph:client:playMusic', -1, id, coords, url, volume)

    SetTimeout(60000, function()
        if currentlyPlaying[id] then
            currentlyPlaying[id] = nil
        end
    end)

    printTable(currentlyPlaying)
    printTable(ownerPhonograph)
end)

RegisterNetEvent('boss_phonograph:server:stopMusic')
AddEventHandler('boss_phonograph:server:stopMusic', function(id)
    currentlyPlaying[id] = nil
    TriggerClientEvent('boss_phonograph:client:stopMusic', -1, id)

    printTable(currentlyPlaying)
    printTable(ownerPhonograph)
end)

RegisterNetEvent('boss_phonograph:server:setVolume')
AddEventHandler('boss_phonograph:server:setVolume', function(id, volume)
    TriggerClientEvent('boss_phonograph:client:setVolume', -1, id, volume)

    printTable(currentlyPlaying)
    printTable(ownerPhonograph)
end)

----------------
-- HANDLE
----------------

AddEventHandler('onResourceStop', function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for id, _ in pairs(currentlyPlaying) do
            TriggerClientEvent('boss_phonograph:client:stopMusic', -1, id)
        end
        currentlyPlaying = {}
        ownerPhonograph = {}
    end
end)
