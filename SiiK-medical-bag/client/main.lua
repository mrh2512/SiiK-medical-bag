local QBCore = exports['qb-core']:GetCoreObject()

local BridgeRes = Config.BridgeResource or 'SiiK-bridge'

local function getInvKey()
    if Config.UseBridge and GetResourceState(BridgeRes) == 'started' then
        local ok, key = pcall(function()
            return exports[BridgeRes]:GetActiveInventory()
        end)
        if ok and key and key ~= '' then return key end
    end
    return Config.Inventory or 'qb'
end


local Placed = {} -- [bagId] = { entity=..., stash_id=..., x=..., y=..., z=..., h=... }

local placing = false
local ghostEnt = nil

local function dbg(...)
    if Config.Debug then
        print('[SiiK-medical-bag]', ...)
    end
end

local function isAllowedJob()
    local data = QBCore.Functions.GetPlayerData()
    local job = data.job and data.job.name or nil
    return job and Config.AllowedJobs[job] == true
end

local function loadModel(model)
    if type(model) == 'string' then model = joaat(model) end
    if not IsModelInCdimage(model) then return false end
    RequestModel(model)
    local timeout = GetGameTimer() + 8000
    while not HasModelLoaded(model) do
        Wait(10)
        if GetGameTimer() > timeout then return false end
    end
    return true
end

local function getGroundZ(x, y, z)
    local found, gz = GetGroundZFor_3dCoord(x, y, z + 1.0, 0)
    if found then return gz end
    return z
end

local function addTargetToEntity(bagId, ent, stashId)
    exports['qb-target']:AddTargetEntity(ent, {
        options = {
            {
                icon = Config.Target.IconOpen,
                label = 'Open Medical Bag',
                action = function()
                    if not isAllowedJob() then
                        QBCore.Functions.Notify("You can't use this.", 'error')
                        return
                    end
                    TriggerServerEvent('SiiK-medical-bag:server:OpenBag', stashId)
                end,
            },
            {
                icon = Config.Target.IconPickup,
                label = 'Pick Up Medical Bag',
                action = function()
                    if not isAllowedJob() then
                        QBCore.Functions.Notify("You can't use this.", 'error')
                        return
                    end
                    TriggerServerEvent('SiiK-medical-bag:server:PickupBag', bagId)
                end,
            },
        },
        distance = Config.Target.Distance
    })
end

local function spawnBag(row)
    local id = tonumber(row.id)
    if not id or Placed[id] then return end

    local model = Config.BagProp
    if not loadModel(model) then
        dbg('Failed to load model')
        return
    end

    local x, y, z, h = row.x, row.y, row.z, row.h or 0.0
    if Config.Place.GroundSnap then
        z = getGroundZ(x, y, z)
    end

    local ent = CreateObject(model, x, y, z, false, false, false)
    SetEntityHeading(ent, h)
    PlaceObjectOnGroundProperly(ent)
    FreezeEntityPosition(ent, true)
    SetEntityInvincible(ent, true)
    SetEntityAsMissionEntity(ent, true, true)

    Placed[id] = {
        entity = ent,
        stash_id = row.stash_id,
        x = x, y = y, z = z, h = h
    }

    addTargetToEntity(id, ent, row.stash_id)

    dbg('Spawned bag', id, row.stash_id)
end

local function deleteBag(id)
    local data = Placed[id]
    if not data then return end

    local ent = data.entity
    if ent and DoesEntityExist(ent) then
        DeleteEntity(ent)
    end

    Placed[id] = nil
end

-- Initial load (on player loaded)
RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    Wait(1500)
    TriggerServerEvent('SiiK-medical-bag:server:RequestBags')
end)

RegisterNetEvent('SiiK-medical-bag:client:LoadBags', function(rows)
    for _, row in ipairs(rows or {}) do
        spawnBag(row)
    end
end)

RegisterNetEvent('SiiK-medical-bag:client:AddBag', function(row)
    spawnBag(row)
end)

RegisterNetEvent('SiiK-medical-bag:client:RemoveBag', function(bagId)
    deleteBag(tonumber(bagId))
end)

-- ===== Placement Mode (ghost + rotate) =====

local function drawHelpText(msg)
    BeginTextCommandDisplayHelp('STRING')
    AddTextComponentSubstringPlayerName(msg)
    EndTextCommandDisplayHelp(0, false, true, -1)
end

local function rotationToDirection(rot)
    local z = math.rad(rot.z)
    local x = math.rad(rot.x)
    local num = math.abs(math.cos(x))
    return vector3(-math.sin(z) * num, math.cos(z) * num, math.sin(x))
end

local function raycastFromGameplayCam(distance)
    local camRot = GetGameplayCamRot(2)
    local camCoord = GetGameplayCamCoord()
    local direction = rotationToDirection(camRot)
    local dest = camCoord + (direction * distance)

    local ray = StartShapeTestRay(
        camCoord.x, camCoord.y, camCoord.z,
        dest.x, dest.y, dest.z,
        17,
        PlayerPedId(),
        0
    )

    local _, hit, endCoords = GetShapeTestResult(ray)
    return hit == 1, endCoords
end

local function ensureGhostDeleted()
    if ghostEnt and DoesEntityExist(ghostEnt) then
        DeleteEntity(ghostEnt)
    end
    ghostEnt = nil
end

RegisterNetEvent('SiiK-medical-bag:client:BeginPlace', function(itemData)
    if placing then return end

    if not isAllowedJob() then
        QBCore.Functions.Notify("You can't use this.", 'error')
        return
    end

    local ped = PlayerPedId()
    if IsPedInAnyVehicle(ped, false) then
        QBCore.Functions.Notify('Exit the vehicle to place the bag.', 'error')
        return
    end

    placing = true

    local model = Config.BagProp
    if not loadModel(model) then
        placing = false
        QBCore.Functions.Notify('Bag model failed to load.', 'error')
        return
    end

    local baseHeading = GetEntityHeading(ped)
    local heading = baseHeading + 180.0
    local offset = 1.2

    local pcoords = GetEntityCoords(ped)
    ghostEnt = CreateObject(model, pcoords.x, pcoords.y, pcoords.z, false, false, false)
    SetEntityCollision(ghostEnt, false, false)
    FreezeEntityPosition(ghostEnt, true)
    SetEntityInvincible(ghostEnt, true)
    SetEntityAlpha(ghostEnt, Config.Place.GhostAlpha or 160, false)
    SetEntityCompletelyDisableCollision(ghostEnt, true, true)

    while placing do
        Wait(0)

        if Config.Place.ShowHelpText then
            drawHelpText(
                "~INPUT_CONTEXT~ Place  ~INPUT_CELLPHONE_CANCEL~ Cancel\n" ..
                "~INPUT_CELLPHONE_LEFT~ / ~INPUT_CELLPHONE_RIGHT~ Rotate\n" ..
                "~INPUT_CELLPHONE_UP~ / ~INPUT_CELLPHONE_DOWN~ Move"
            )
        end

        -- rotate
        if IsControlJustPressed(0, Config.Place.RotateLeftKey) then
            heading = heading - (Config.Place.RotateStep or 5.0)
        elseif IsControlJustPressed(0, Config.Place.RotateRightKey) then
            heading = heading + (Config.Place.RotateStep or 5.0)
        end

        -- move
        if IsControlPressed(0, Config.Place.ForwardKey) then
            offset = math.min((Config.Place.MaxDistance or 3.0), offset + (Config.Place.Step or 0.08))
        elseif IsControlPressed(0, Config.Place.BackKey) then
            offset = math.max(0.6, offset - (Config.Place.Step or 0.08))
        end

        -- placement point (camera raycast preferred)
        local hit, hitCoords = raycastFromGameplayCam(Config.Place.RayDistance or 6.0)
        local pos

        if hit then
            pos = vector3(hitCoords.x, hitCoords.y, hitCoords.z)
        else
            local pc = GetEntityCoords(ped)
            local fwd = GetEntityForwardVector(ped)
            pos = vector3(pc.x + fwd.x * offset, pc.y + fwd.y * offset, pc.z)
        end

        if Config.Place.GroundSnap then
            local gz = getGroundZ(pos.x, pos.y, pos.z)
            pos = vector3(pos.x, pos.y, gz)
        end

        SetEntityCoordsNoOffset(ghostEnt, pos.x, pos.y, pos.z, false, false, false)
        SetEntityHeading(ghostEnt, heading)

        -- cancel
        if IsControlJustPressed(0, Config.Place.CancelKey) then
            placing = false
            ensureGhostDeleted()
            QBCore.Functions.Notify('Placement cancelled.', 'error')
            break
        end

        -- confirm
        if IsControlJustPressed(0, Config.Place.ConfirmKey) then
            placing = false

            local finalCoords = GetEntityCoords(ghostEnt)
            local finalHeading = GetEntityHeading(ghostEnt)

            ensureGhostDeleted()

            TriggerServerEvent('SiiK-medical-bag:server:PlaceBag', {
                coords = { x = finalCoords.x, y = finalCoords.y, z = finalCoords.z },
                heading = finalHeading,
                item = {
                    slot = (type(itemData) == 'table' and itemData.slot) or nil,
                    info = (type(itemData) == 'table' and itemData.info) or {}
                }
            })

            QBCore.Functions.Notify('Medical bag placed.', 'success')
            break
        end
    end

    ensureGhostDeleted()
end)

AddEventHandler('onResourceStop', function(res)
    if res ~= GetCurrentResourceName() then return end
    placing = false
    ensureGhostDeleted()
end)


-- ===== Inventory bridges for non-qb inventories =====

RegisterNetEvent('SiiK-medical-bag:client:OpenStashQS', function(stashId, other)
    -- Quasar (qs-inventory) docs: RegisterStash is client-side
    -- other = { maxweight=..., slots=..., label=... }
    local ok = pcall(function()
        exports[Config.InventoryResources.qs]:RegisterStash(stashId, other.slots, other.maxweight)
    end)
    if not ok then
        QBCore.Functions.Notify('qs-inventory not found or RegisterStash failed.', 'error')
        return
    end

    -- Most bridges keep the qb-style open event for stashes
    TriggerServerEvent('inventory:server:OpenInventory', 'stash', stashId, { maxweight = other.maxweight, slots = other.slots })
    TriggerEvent('inventory:client:SetCurrentStash', stashId)
end)

RegisterNetEvent('SiiK-medical-bag:client:OpenStashCodem', function(stashId, other)
    -- CodeM mInventory Remake docs: TriggerServerEvent('codem-inventory:server:openstash', stashId, slots, weight, label)
    TriggerServerEvent('codem-inventory:server:openstash', stashId, other.slots, other.maxweight, other.label)
end)

