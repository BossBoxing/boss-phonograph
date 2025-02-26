----------------
-- VARIABLES
----------------
local RSGCore = exports['rsg-core']:GetCoreObject() -- Core
local soundId = Config.secretKey -- Unique identifier
local volume = Config.initVolume -- Initial volume
local objectPosition = {}
local heading, confirmed
local spawnedPhonograph = false -- handle one person can place only 1 phonograph in game

----------------
-- UTILS
----------------

-- RegisterCommand('test-boss-phonograph', function()
--     print("Let's go")
--     TriggerEvent('boss_phonograph:client:placeProp', 'p_phonograph01x')
-- end, false)

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

----------------
-- MENU
----------------
-- Function to create and open the phonograph menu
local function OpenPhonographMenu(entity, networkEntityId)
    local data = {
        title = 'BOSS-PHONOGRAPH', -- The big title of the menu
        subtitle = 'Music Player', -- The subtitle of the menu
        numberOnScreen = 4,
        onBack = function() jo.menu.show(false) end,
        onExit = function() jo.menu.show(false) end
    }
    local menu = jo.menu.create(soundId .. '-' .. networkEntityId, data)

    -- Play music item
    menu:addItem({
        title = "Play",
        onClick = function()
            jo.menu.show(false)
            local input = lib.inputDialog('Boss Phonograph', {
                {
                    type = 'input',
                    label = 'Enter Music URL',
                    description = 'Ex. https://www.youtube.com/watch?v=RrxePKps87k',
                    required = true,
                    placeholder = 'Input a URL'
                }
            })

            if input ~= nil and input[1] ~= nil then 
                if input and input[1] and input[1]:sub(1, 4) == 'http' then
                    local url = input[1]
                    TriggerServerEvent('boss_phonograph:server:playMusic',
                                       soundId .. '-' .. networkEntityId,
                                       GetEntityCoords(entity), url, volume)
                    jo.notif.right("Let's Rock!", 'hud_textures', 'check',
                                   'COLOR_GREEN', 5000)
                else
                    jo.notif.right('Invalid or empty URL!', 'hud_textures', 'times',
                                   'COLOR_RED', 5000)
                end
            end
            jo.menu.show(true)
        end
    })

    -- Stop music item
    menu:addItem({
        title = "Stop",
        onClick = function()
            TriggerServerEvent('boss_phonograph:server:stopMusic',
                               soundId .. '-' .. networkEntityId)
            jo.notif.right('Music stopped.', 'hud_textures', 'stop',
                           'COLOR_YELLOW', 5000)
            jo.menu.show(false)
        end
    })

    -- Volume Up item
    menu:addItem({
        title = "Volume Up",
        onClick = function()
            -- print('Clicked Volume Up')
            -- Increase volume
            if volume < 1.0 then
                volume = volume + 0.1
                if volume > 1.0 then volume = 1.0 end
                TriggerServerEvent('boss_phonograph:server:setVolume',
                                   soundId .. '-' .. networkEntityId, volume)
                -- Notify success using the correct format
                jo.notif.right('Volume increased to ' ..
                                   math.floor(volume * 100) .. '%',
                               'hud_textures', 'check', 'COLOR_GREEN', 5000)
            else
                jo.notif.right('Volume is already at maximum.', 'hud_textures',
                               'times', 'COLOR_RED', 5000)
            end
        end
    })

    -- Volume Down item
    menu:addItem({
        title = "Volume Down",
        onClick = function()
            -- print('Clicked Volume Down')
            -- Decrease volume
            if volume > 0.0 then
                volume = volume - 0.1
                if volume < 0.0 then volume = 0.0 end
                TriggerServerEvent('boss_phonograph:server:setVolume',
                                   soundId .. '-' .. networkEntityId, volume)
                jo.notif.right('Volume decreased to ' ..
                                   math.floor(volume * 100) .. '%',
                               'hud_textures', 'check', 'COLOR_GREEN', 5000)
            else
                jo.notif.right('Volume is already at minimum.', 'hud_textures',
                               'times', 'COLOR_RED', 5000)
            end
        end
    })

    menu:send()
    jo.menu.setCurrentMenu(soundId .. '-' .. networkEntityId)
    jo.menu.show(true)
end

----------------
-- Prop Section
----------------

function RotationToDirection(rotation)
    local adjustedRotation = {
        x = (math.pi / 180) * rotation.x,
        y = (math.pi / 180) * rotation.y,
        z = (math.pi / 180) * rotation.z
    }
    local direction = {
        x = -math.sin(adjustedRotation.z) *
            math.abs(math.cos(adjustedRotation.x)),
        y = math.cos(adjustedRotation.z) *
            math.abs(math.cos(adjustedRotation.x)),
        z = math.sin(adjustedRotation.x)
    }
    return direction
end

function RayCastGamePlayCamera(distance)
    local cameraRotation = GetGameplayCamRot()
    local cameraCoord = GetGameplayCamCoord()
    local direction = RotationToDirection(cameraRotation)
    local destination = {
        x = cameraCoord.x + direction.x * distance,
        y = cameraCoord.y + direction.y * distance,
        z = cameraCoord.z + direction.z * distance
    }
    local a, b, c, d, e = GetShapeTestResult(
                              StartShapeTestRay(cameraCoord.x, cameraCoord.y,
                                                cameraCoord.z, destination.x,
                                                destination.y, destination.z,
                                                -1, PlayerPedId(), 0))
    return b, c, e
end

----------------
-- EVENTS
----------------

-- Prop Events

RegisterNetEvent('boss_phonograph:client:placePropPhonograph')
AddEventHandler('boss_phonograph:client:placePropPhonograph', function()
    if spawnedPhonograph then
        jo.notif.right("You already placed a phonograph!", 'hud_textures', 'times', 'COLOR_RED', 5000)
        return
    end

    prop = joaat(Config.prop)
    heading = 0.0
    confirmed = false

    RequestModel(prop)
    while not HasModelLoaded(prop) do Wait(0) end

    local hit, coords
    while not hit do
        hit, coords = RayCastGamePlayCamera(10.0)
        Wait(0)
    end

    local propObject = CreateObject(prop, coords.x, coords.y, coords.z, true, false, true)

    CreateThread(function()
        lib.showTextUI(
                -- ('Current Mode: %s  \n'):format("translate") ..
                -- '[W/S/A/D]      - Translate Mode  \n' ..
                '[LEFT/RIGHT]   - Rotate Mode  \n' ..
                '[E]            - Place On Ground  \n' ..
                '[B]            - Delete item  \n'
                -- '[Esc]          - Done Editing  \n'
        )
        -- lib.showTextUI(
        -- 'Boss Phonograph - Placing a phonograph <br>' ..
        -- '[LEFT/RIGHT]    - Rotate  <br>' ..
        -- '[E]             - Place   <br>' ..
        -- '[B]             - Delete  <br>', {
        --     position = 'right-center',
        -- })

        while not confirmed do
            Wait(0)
            hit, coords, entity = RayCastGamePlayCamera(10.0)
            SetEntityCoordsNoOffset(propObject, coords.x, coords.y, coords.z, false, false, false, true)
            FreezeEntityPosition(propObject, true)
            SetEntityCollision(propObject, false, false)
            SetEntityAlpha(propObject, 100, false)

            if IsControlPressed(0, RSGCore.Shared.Keybinds['LEFT']) then heading = heading + 5.0 end
            if IsControlPressed(0, RSGCore.Shared.Keybinds['RIGHT']) then heading = heading - 5.0 end

            if IsControlJustPressed(0, RSGCore.Shared.Keybinds['B']) then
                DeleteObject(propObject)
                confirmed = true
            end

            if heading > 360.0 then heading = 0.0 elseif heading < 0.0 then heading = 360.0 end
            SetEntityHeading(propObject, heading)

            if IsControlJustPressed(0, RSGCore.Shared.Keybinds['E']) then
                confirmed = true
                spawnedPhonograph = true
                SetEntityAlpha(propObject, 255, false)
                SetEntityCollision(propObject, true, true)
                -- table.insert(objectPosition, propObject)

                -- Save owner on the server
                local networkId = NetworkGetNetworkIdFromEntity(propObject)
                objectPosition[Config.secretKey .. '-' .. networkId] = propObject
                TriggerServerEvent('boss_phonograph:server:saveOwner', Config.secretKey .. '-' .. networkId)
            end
        end
        lib.hideTextUI()
    end)
end)

RegisterNetEvent('boss_phonograph:client:removePhonograph')
AddEventHandler('boss_phonograph:client:removePhonograph', function(id)
    for key, obj in pairs(objectPosition) do
        if key == id then
            DeleteObject(obj)
            objectPosition[key] = nil
            spawnedPhonograph = false
            exports.xsound:Destroy(id)
            break
        end
    end

    jo.notif.right('Pick it up.', 'hud_textures', 'stop', 'COLOR_YELLOW', 5000)
end)

-- Main events

-- Listen for music play event from the server
RegisterNetEvent('boss_phonograph:client:playMusic')
AddEventHandler('boss_phonograph:client:playMusic',
                function(id, coords, url, volume)
    exports.xsound:PlayUrlPos(id, url, volume, coords)
    exports.xsound:Distance(id, 10)
end)

-- Listen for stop event from the server
RegisterNetEvent('boss_phonograph:client:stopMusic')
AddEventHandler('boss_phonograph:client:stopMusic', function(id)
    exports.xsound:Destroy(id) -- ลบเสียงจาก xsound
end)

-- Listen for volume change from the server
RegisterNetEvent('boss_phonograph:client:setVolume')
AddEventHandler('boss_phonograph:client:setVolume', function(id, newVolume)
    volume = newVolume
    exports.xsound:setVolume(id, volume)
end)

----------------
-- HANDLE
----------------

-- Check Player aim to phonograph
CreateThread(function()
    exports['rsg-target']:AddTargetModel('p_phonograph01x', {
        options = {
            {
                icon = 'fas fa-music',
                label = "LET'S ROCK!",
                action = function(entity)
                    local networkEntityId =
                        NetworkGetNetworkIdFromEntity(entity)
                    OpenPhonographMenu(entity, networkEntityId)
                end
            },
            {
                icon = 'fas fa-music',
                label = "PICK UP",
                action = function(entity)
                    local networkEntityId =
                        NetworkGetNetworkIdFromEntity(entity)
                    TriggerServerEvent('boss_phonograph:server:pickUp', networkEntityId)
                end
            },
        },
        distance = 2.5
    })
end)

-- Cleanup on resource stop
AddEventHandler("onResourceStop", function(resourceName)
    if GetCurrentResourceName() ~= resourceName then return end

    local isOpen, text = lib.isTextUIOpen()
    if isOpen then lib.hideTextUI() end

    -- Remove all spawned objects
    for key, obj in pairs(objectPosition) do -- ใช้ pairs() แทน ipairs()
        if DoesEntityExist(obj) then
            DeleteObject(obj)
        end
    end

    -- Clear the table
    objectPosition = {}

    -- Reset flag
    spawnedPhonograph = false
end)
