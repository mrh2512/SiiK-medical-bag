local QBCore = exports['qb-core']:GetCoreObject()

local function isAllowedJob(src)
    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return false end
    local job = Player.PlayerData.job and Player.PlayerData.job.name or nil
    return job and Config.AllowedJobs[job] == true
end

local function notify(src, msg, ntype)
    TriggerClientEvent('QBCore:Notify', src, msg, ntype or 'primary')
end

local function makeStashId(ownerCid)
    local r = math.random(100000, 999999)
    return ('medbag_%s_%s_%s'):format(ownerCid or 'nocid', os.time(), r)
end

local function invType()
    return (Config.Inventory or 'qb'):lower()
end

local function invName()
    local t = invType()
    if Config.InventoryResources and Config.InventoryResources[t] then
        return Config.InventoryResources[t]
    end
    -- backwards-compat (older config versions)
    return Config.InventoryResource or 'qb-inventory'
end


-- Safely call an export if it exists
local function tryExport(resource, exportName, ...)
    local ok, res = pcall(function(...)
        return exports[resource][exportName](exports[resource], ...)
    end, ...)
    if ok then return true, res end
    return false, nil
end

-- Usable item: start placement on client
QBCore.Functions.CreateUseableItem(Config.BagItem, function(source, item)
    if not isAllowedJob(source) then
        notify(source, "You can't use this.", 'error')
        return
    end
    TriggerClientEvent('SiiK-medical-bag:client:BeginPlace', source, {
        slot = item and item.slot or nil,
        info = item and (item.info or item.metadata or {}) or {}
    })
end)

-- Send all placed bags to a client
RegisterNetEvent('SiiK-medical-bag:server:RequestBags', function()
    local src = source
    local rows = MySQL.query.await('SELECT id, stash_id, owner_cid, x, y, z, h FROM siik_medical_bags', {})
    TriggerClientEvent('SiiK-medical-bag:client:LoadBags', src, rows or {})
end)

-- Place confirmed
RegisterNetEvent('SiiK-medical-bag:server:PlaceBag', function(data)
    local src = source
    if not isAllowedJob(src) then return end
    if type(data) ~= 'table' or type(data.coords) ~= 'table' then return end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end
    local ownerCid = Player.PlayerData.citizenid

    -- If the bag item already has a stash_id in metadata, reuse it
    local existingStashId = nil
    if type(data.item) == 'table' then
        if type(data.item.info) == 'table' and data.item.info.stash_id then
            existingStashId = tostring(data.item.info.stash_id)
        elseif type(data.item.metadata) == 'table' and data.item.metadata.stash_id then
            existingStashId = tostring(data.item.metadata.stash_id)
        end
    end

    local stashId = existingStashId or makeStashId(ownerCid)

    -- Remove the specific bag item (slot-aware so metadata is preserved correctly)
    local slot = (type(data.item) == 'table' and data.item.slot) and tonumber(data.item.slot) or nil
    local removed = false
    if slot then
        removed = Player.Functions.RemoveItem(Config.BagItem, 1, slot)
    else
        removed = Player.Functions.RemoveItem(Config.BagItem, 1, false)
    end

    if not removed then
        notify(src, "You don't have a medical bag.", 'error')
        return
    end
    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.BagItem], 'remove', 1)

    local x, y, z = data.coords.x, data.coords.y, data.coords.z
    local h = data.heading or 0.0

    local insertId = MySQL.insert.await([[
        INSERT INTO siik_medical_bags (stash_id, owner_cid, x, y, z, h)
        VALUES (?, ?, ?, ?, ?, ?)
    ]], { stashId, ownerCid, x, y, z, h })

    if not insertId then
        -- give item back if DB insert failed (preserve stash_id)
        local info = { stash_id = stashId }
        local added = Player.Functions.AddItem(Config.BagItem, 1, slot or false, info)
        if added then
            TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.BagItem], 'add', 1)
        end
        notify(src, "Failed to place bag (DB).", 'error')
        return
    end

    local payload = {
        id = insertId,
        stash_id = stashId,
        owner_cid = ownerCid,
        x = x, y = y, z = z, h = h
    }

    TriggerClientEvent('SiiK-medical-bag:client:AddBag', -1, payload)
end)

-- Open stash (supports qb-inventory style + common inventory open events)
RegisterNetEvent('SiiK-medical-bag:server:OpenBag', function(stashId)
    local src = source
    if not isAllowedJob(src) then return end
    if type(stashId) ~= 'string' or stashId == '' then return end

    local invSystem = invType()
    local other = { maxweight = Config.Stash.Weight, slots = Config.Stash.Slots, label = Config.Stash.Label }

    -- QS Inventory (Quasar)
    if invSystem == 'qs' then
        TriggerClientEvent('SiiK-medical-bag:client:OpenStashQS', src, stashId, other)
        return
    end

    -- CodeM mInventory Remake
    if invSystem == 'codem' then
        TriggerClientEvent('SiiK-medical-bag:client:OpenStashCodem', src, stashId, other)
        return
    end

    -- qb-inventory / ps-inventory / lj-inventory (and most forks)
    local inv = invName()

    -- Method A: common export signature
    local okA = pcall(function()
        exports[inv]:OpenInventory(src, 'stash', stashId, other)
    end)
    if okA then return end

    -- Method B: older signature used by some inventories
    local okB = pcall(function()
        exports[inv]:OpenInventory('stash', stashId, other, src)
    end)
    if okB then return end

    -- Method C: client open events used by qb/lj/ps-style UIs
    TriggerClientEvent('inventory:client:SetCurrentStash', src, stashId)
    TriggerClientEvent('inventory:client:OpenInventory', src, 'stash', stashId, other)
end)

local function stashIsEmpty(stashId)
    local inv = invName()

    local ok, data = tryExport(inv, 'GetStashItems', stashId)
    if ok and type(data) == 'table' then
        for _, v in pairs(data) do
            if v and (v.amount or v.count) and tonumber(v.amount or v.count) and tonumber(v.amount or v.count) > 0 then
                return false
            end
        end
        return true
    end

    ok, data = tryExport(inv, 'GetInventory', 'stash', stashId)
    if ok and type(data) == 'table' then
        local items = data.items or data
        if type(items) == 'table' then
            for _, v in pairs(items) do
                if v and (v.amount or v.count) and tonumber(v.amount or v.count) and tonumber(v.amount or v.count) > 0 then
                    return false
                end
            end
            return true
        end
    end

    ok, data = tryExport(inv, 'GetStash', stashId)
    if ok and type(data) == 'table' then
        local items = data.items or {}
        for _, v in pairs(items) do
            if v and (v.amount or v.count) and tonumber(v.amount or v.count) and tonumber(v.amount or v.count) > 0 then
                return false
            end
        end
        return true
    end

    return false, "unknown"
end

local function clearStash(stashId)
    local inv = invName()

    local ok = pcall(function()
        exports[inv]:ClearStash(stashId)
    end)
    if ok then return true end

    ok = pcall(function()
        exports[inv]:SaveStashItems(stashId, {})
    end)
    if ok then return true end

    return false
end

-- Pickup request (only if stash empty)
RegisterNetEvent('SiiK-medical-bag:server:PickupBag', function(bagId)
    local src = source
    if not isAllowedJob(src) then return end

    local idNum = tonumber(bagId)
    if not idNum then return end

    local row = MySQL.single.await('SELECT id, stash_id FROM siik_medical_bags WHERE id = ?', { idNum })
    if not row then
        notify(src, "Bag not found.", 'error')
        return
    end

    local Player = QBCore.Functions.GetPlayer(src)
    if not Player then return end

    -- Give the bag item back WITH metadata so it keeps the same stash_id when re-placed
    local info = { stash_id = row.stash_id }
    local added = Player.Functions.AddItem(Config.BagItem, 1, false, info)
    if not added then
        notify(src, "No space to pick up the bag.", 'error')
        return
    end

    TriggerClientEvent('inventory:client:ItemBox', src, QBCore.Shared.Items[Config.BagItem], 'add', 1)

    -- Remove world bag entry; DO NOT clear stash (items persist inside)
    MySQL.query.await('DELETE FROM siik_medical_bags WHERE id = ?', { idNum })
    TriggerClientEvent('SiiK-medical-bag:client:RemoveBag', -1, idNum)

    notify(src, "Picked up medical bag.", 'success')
end)
