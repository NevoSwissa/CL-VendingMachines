local QBCore = exports['qb-core']:GetCoreObject()

QBCore.Functions.CreateUseableItem('cl_machine', function(source, item)
    TriggerClientEvent("CL-SellMachines:Place", source)
end)

QBCore.Functions.CreateCallback("CL-SellMachines:GetData", function(source, cb, type, coords)
    local playerSource = source
    local Player = QBCore.Functions.GetPlayer(playerSource)
    if Player ~= nil then
        if type == "get" then
            local target_location_str = string.format("%f,%f,%f", round(coords.x, 3), round(coords.y, 3), round(coords.z, 3))
            MySQL.Async.fetchScalar("SELECT citizenid FROM cl_sellmachines WHERE location = @location", {
                ['@location'] = target_location_str
            }, function(owner_citizenid)
                if owner_citizenid == Player.PlayerData.citizenid then
                    local money = MySQL.Sync.fetchScalar("SELECT money FROM cl_sellmachines WHERE citizenid = @citizenid", { ['@citizenid'] = owner_citizenid })
                    cb({player = GetPlayerName(playerSource), money = money, playersource = playerSource, citizenid = owner_citizenid})
                else
                    cb(false)
                end
            end)
        elseif type == "new" then
            local results = MySQL.Sync.fetchAll('SELECT * FROM cl_sellmachines WHERE citizenid = @citizenid', { ['@citizenid'] = Player.PlayerData.citizenid })
            if #results > 0 then
                local money = MySQL.Sync.fetchScalar("SELECT money FROM cl_sellmachines WHERE citizenid = @citizenid", { ['@citizenid'] = results[1].citizenid })
                cb({player = GetPlayerName(playerSource), money = money, playersource = playerSource})
            else
                cb(false)
            end
        elseif type == "machines" then
            MySQL.Async.fetchAll("SELECT name, location FROM cl_sellmachines", {}, function(results)
                local machines = {}
                for i, result in ipairs(results) do
                    local location = split(result.location, ",")
                    table.insert(machines, {name = result.name, x = tonumber(location[1]), y = tonumber(location[2]), z = tonumber(location[3])})
                end
                cb(machines)
            end)
        end
    end
end)

RegisterNetEvent("CL-SellMachine:DestroyVendingMachine", function(data)
    local target_location_str = string.format("%f,%f,%f", round(data.objectCoords.x, 3), round(data.objectCoords.y, 3), round(data.objectCoords.z, 3))
    local playerSource = source
    local Player = QBCore.Functions.GetPlayer(playerSource)
    local owner_citizenid = MySQL.scalar.await('SELECT citizenid FROM cl_sellmachines WHERE location = ?', {target_location_str})
    if owner_citizenid == Player.PlayerData.citizenid then
        MySQL.Async.fetchAll("SELECT items, name, money FROM cl_sellmachines WHERE citizenid = @citizenid", { ['@citizenid'] = owner_citizenid }, function(result)
            if #result == 0 then 
                return 
            end
            local items = json.decode(result[1].items) or {}
            if items then
                for k, v in pairs(items) do
                    Player.Functions.AddItem(v.name, v.quantity)
                end
                Player.Functions.AddMoney("bank", result[1].money)
                TriggerClientEvent("CL-SellMachines:RemoveTargetObject", playerSource, data.objectCoords, result[1].name)
            end
        end)
        MySQL.Async.execute("DELETE FROM cl_sellmachines WHERE location = @location", { ['@location'] = target_location_str })
        TriggerClientEvent('QBCore:Notify', playerSource, owner_citizenid .. " vending machine have been deleted")
    end
end)

RegisterServerEvent('CL-SellMachine:Withdraw', function(amount, paymenttype, moneyavailable, coords)
    local playerSource = source
    local Player = QBCore.Functions.GetPlayer(playerSource)
    local newamount = moneyavailable - amount
    local target_location_str = string.format("%f,%f,%f", round(coords.x, 3), round(coords.y, 3), round(coords.z, 3))
    local owner_citizenid = MySQL.scalar.await('SELECT citizenid FROM cl_sellmachines WHERE location = ?', {target_location_str})
    if owner_citizenid == Player.PlayerData.citizenid then
        if paymenttype == "cash" then
            Player.Functions.AddMoney("cash", amount)
        elseif paymenttype == "bank" then
            Player.Functions.AddMoney("bank", amount)
        end
        MySQL.Async.execute("UPDATE cl_sellmachines SET money = @money WHERE citizenid = @citizenid", {
            ['@citizenid'] = owner_citizenid,
            ['@money'] = newamount,
        }, function()
            TriggerClientEvent('QBCore:Notify', playerSource, "Successfully updated vending machine money with citizenid: " .. owner_citizenid, "success")
        end)
    else
        TriggerClientEvent('QBCore:Notify', playerSource, "No vending machine found for: " .. owner_citizenid, "error")
    end
end)

RegisterServerEvent('CL-SellMachine:GetItemsList', function(data)
    local playerSource = source
    local Player = QBCore.Functions.GetPlayer(playerSource)
    local target_location_str = string.format("%f,%f,%f", round(data.objectCoords.x, 3), round(data.objectCoords.y, 3), round(data.objectCoords.z, 3))
    local owner_citizenid = MySQL.scalar.await('SELECT citizenid FROM cl_sellmachines WHERE location = ?', {target_location_str})
    if owner_citizenid == Player.PlayerData.citizenid then
        MySQL.Async.fetchAll("SELECT items FROM cl_sellmachines WHERE citizenid = @citizenid", { ['@citizenid'] = owner_citizenid }, function(result)
            if #result == 0 then 
                return 
            end
            local items = json.decode(result[1].items) or {}
            if items then
                TriggerClientEvent("CL-SellMachine:OpenItemsMenu", playerSource, items, owner_citizenid, target_location_str)            
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', playerSource, "No vending machine found at location: " .. target_location_str, "error")
    end
end)

RegisterNetEvent("CL-SellMachine:CreateName", function(name, objectCoords)
    local playerSource = source
    local Player = QBCore.Functions.GetPlayer(playerSource)
    local target_location_str = string.format("%f,%f,%f", round(objectCoords.x, 3), round(objectCoords.y, 3), round(objectCoords.z, 3))
    local owner_citizenid = MySQL.scalar.await('SELECT citizenid FROM cl_sellmachines WHERE location = ?', {target_location_str})
    if owner_citizenid == Player.PlayerData.citizenid then
        MySQL.Async.fetchAll("SELECT name FROM cl_sellmachines WHERE citizenid = @citizenid", { ['@citizenid'] = owner_citizenid }, function(result)
            if result[1].name then
                TriggerClientEvent("CL-SellMachine:UpdateBlip", playerSource, objectCoords, result[1].name, name)
            else
                TriggerClientEvent("CL-SellMachine:UpdateBlip", playerSource, objectCoords, name)
            end
            MySQL.Async.execute("UPDATE cl_sellmachines SET name = @name WHERE citizenid = @citizenid", {
                ['@citizenid'] = owner_citizenid,
                ['@name'] = name
            }, function()
                TriggerClientEvent('QBCore:Notify', playerSource, "Successfully updated vending machine name with citizenid: " .. owner_citizenid .. " To : " .. name, "success")
            end)
        end)
    else
        TriggerClientEvent('QBCore:Notify', playerSource, "No vending machine found at location: " .. target_location_str, "error")
    end
end)

RegisterServerEvent('CL-SellMachines:Buyer', function(objectCoords)
    local playerSource = source
    local Player = QBCore.Functions.GetPlayer(playerSource)
    local target_location_str = string.format("%f,%f,%f", round(objectCoords.x, 3), round(objectCoords.y, 3), round(objectCoords.z, 3))
    local owner_citizenid = MySQL.scalar.await('SELECT citizenid FROM cl_sellmachines WHERE location = ?', {target_location_str})
    if owner_citizenid then
        MySQL.Async.fetchAll("SELECT items, money FROM cl_sellmachines WHERE citizenid = @citizenid", { ['@citizenid'] = owner_citizenid }, function(result)
            if #result == 0 then 
                return 
            end
            local items = json.decode(result[1].items) or {}
            if items then
                TriggerClientEvent("CL-SellMachine:OpenBuyerMachineMenu", playerSource, items, owner_citizenid, objectCoords, result[1].money)            
            end
        end)
    else
        TriggerClientEvent('QBCore:Notify', playerSource, "No vending machine found at location: " .. target_location_str, "error")
    end
end)

RegisterNetEvent("CL-SellMachine:Buy", function(amount, paymenttype, item, quantity, coords, owner, moneyavailable)
    local target_location_str = string.format("%f,%f,%f", round(coords.x, 3), round(coords.y, 3), round(coords.z, 3))
    local playerSource = source
    local Player = QBCore.Functions.GetPlayer(playerSource)
    MySQL.Async.fetchAll("SELECT items FROM cl_sellmachines WHERE location = @location", { ['@location'] = target_location_str }, function(result)
        if #result == 0 then
            TriggerClientEvent('QBCore:Notify', playerSource, "No vending machine found at location: " .. target_location_str, "error")
            return
        end
        local existing_items = json.decode(result[1].items) or {}
        for i=1, #existing_items do
            if existing_items[i].name == item then
                local totalPrice = tonumber(existing_items[i].price) * amount
                if paymenttype == "cash" then
                    if Player.PlayerData.money.cash >= totalPrice then
                        Player.Functions.RemoveMoney("cash", totalPrice)
                        Player.Functions.AddItem(existing_items[i].name, amount)
                        existing_items[i].quantity = existing_items[i].quantity - amount
                        if existing_items[i].quantity <= 0 then
                            table.remove(existing_items, i)
                        end
                        MySQL.Async.execute("UPDATE cl_sellmachines SET items = @items, money = @money WHERE citizenid = @citizenid", {
                            ['@citizenid'] = owner,
                            ['@items'] = json.encode(existing_items),
                            ['@money'] = moneyavailable + totalPrice
                        }, function()
                            TriggerClientEvent('QBCore:Notify', playerSource, "Successfully purchased item: " .. item .. " from vending machine with citizenid: " .. owner, "success")
                        end)
                        if Config.ConnectedOwners[owner] then
                            TriggerClientEvent('QBCore:Notify', Config.ConnectedOwners[owner].Source, "Someone purchased  " .. item .. " for " .. totalPrice .. "$ from your vending machine", "success")
                        end
                        break
                    else
                        TriggerClientEvent('QBCore:Notify', playerSource, "You dont have enough money to buy " .. item, "error")
                        return
                    end
                elseif paymenttype == "bank" then
                    if Player.PlayerData.money.bank >= totalPrice then
                        Player.Functions.RemoveMoney("bank", totalPrice)
                        Player.Functions.AddItem(existing_items[i].name, amount)
                        existing_items[i].quantity = existing_items[i].quantity - amount
                        if existing_items[i].quantity <= 0 then
                            table.remove(existing_items, i)
                        end
                        MySQL.Async.execute("UPDATE cl_sellmachines SET items = @items, money = @money WHERE citizenid = @citizenid", {
                            ['@citizenid'] = owner,
                            ['@items'] = json.encode(existing_items),
                            ['@money'] = moneyavailable + totalPrice
                        }, function()
                            TriggerClientEvent('QBCore:Notify', playerSource, "Successfully purchased item: " .. item .. " from vending machine with citizenid: " .. owner, "success")
                        end)
                        if Config.ConnectedOwners[owner] then
                            TriggerClientEvent('QBCore:Notify', Config.ConnectedOwners[owner].Source, "Someone purchased  " .. item .. " for " .. totalPrice .. "$ from your vending machine", "success")
                        end
                        break
                    else
                        TriggerClientEvent('QBCore:Notify', playerSource, "You dont have enough money to buy " .. item, "error")
                        return
                    end
                end
            end
        end
    end)
end)

RegisterNetEvent("CL-SellMachine:RemoveData", function(data)
    if data.type == "remove" then
        local playerSource = source
        local Player = QBCore.Functions.GetPlayer(playerSource)
        local totalWeight = QBCore.Player.GetTotalWeight(Player.PlayerData.items)
        local itemInfo = QBCore.Shared.Items[data.item:lower()]
        if (totalWeight + (itemInfo['weight'] * data.quantity)) <= Config.MaxInventoryWeight then
            MySQL.Async.fetchAll("SELECT items FROM cl_sellmachines WHERE citizenid = @citizenid", { ['@citizenid'] = data.owner_citizenid }, function(result)
                if #result == 0 then
                    TriggerClientEvent('QBCore:Notify', playerSource, "No vending machine found : " .. data.owner_citizenid, "error")
                    return
                end
                local existing_items = json.decode(result[1].items) or {}
                for i=1, #existing_items do
                    if existing_items[i].name == data.item then
                        Player.Functions.AddItem(existing_items[i].name, data.quantity)
                        existing_items[i].quantity = existing_items[i].quantity - data.quantity
                        if existing_items[i].quantity <= 0 then
                            table.remove(existing_items, i)
                        end
                        MySQL.Async.execute("UPDATE cl_sellmachines SET items = @items WHERE citizenid = @citizenid", {
                            ['@citizenid'] = data.owner_citizenid,
                            ['@items'] = json.encode(existing_items)
                        }, function()
                            TriggerClientEvent('QBCore:Notify', playerSource, "Successfully deleted item: " .. data.item .. " from vending machine with citizenid: " .. data.owner_citizenid, "success")
                        end)
                        break
                    end
                end
            end)
        end
    end
end)

RegisterServerEvent('CL-SellMachines:AddData', function(type, coords, name, price, quantity, citizenid, ownersource)
    local playerSource = source
    local Player = QBCore.Functions.GetPlayer(playerSource)
    local GetItem = Player.Functions.GetItemByName(name)
    if Player then
        if type == "items" then
            if GetItem ~= nil and GetItem.amount >= quantity then
                local target_location_str = string.format("%f,%f,%f", round(coords.x, 3), round(coords.y, 3), round(coords.z, 3))
                local owner_citizenid = MySQL.scalar.await('SELECT citizenid FROM cl_sellmachines WHERE location = ?', {target_location_str})
                local item = {
                    name = name,
                    price = price,
                    quantity = quantity
                }
                if owner_citizenid == Player.PlayerData.citizenid then
                    MySQL.Async.fetchAll("SELECT items FROM cl_sellmachines WHERE citizenid = @citizenid", { ['@citizenid'] = owner_citizenid }, function(result)
                        local existing_items = json.decode(result[1].items) or {}
                        if #existing_items >= Config.ItemsLimit then
                            TriggerClientEvent('QBCore:Notify', playerSource, "Vending machine with citizenid: " .. owner_citizenid .. " already has " .. Config.ItemsLimit .. " items.", "error")
                            return
                        end
                        local itemExists = false
                        for _, existing_item in pairs(existing_items) do
                            if existing_item.name == item.name then
                                itemExists = true
                                break
                            end
                        end
                        if itemExists then
                            TriggerClientEvent('QBCore:Notify', playerSource, "Item already exists in vending machine with citizenid: " .. owner_citizenid .. ".", "error")
                            return
                        end
                        table.insert(existing_items, item)
                        MySQL.Async.execute("UPDATE cl_sellmachines SET items = @items WHERE citizenid = @citizenid", {
                            ['@citizenid'] = owner_citizenid,
                            ['@items'] = json.encode(existing_items)
                        }, function()
                            TriggerClientEvent('QBCore:Notify', playerSource, "Successfully added " .. name .. " to vending machine with citizenid: " .. owner_citizenid, "success")
                        end)
                        if #existing_items < Config.ItemsLimit and not itemExists then
                            Player.Functions.RemoveItem(name, quantity, false)
                        end
                    end)   
                else 
                    TriggerClientEvent('QBCore:Notify', playerSource, "No vending machine found at location: " .. target_location_str, "error")
                end    
            else
                TriggerClientEvent('QBCore:Notify', playerSource, "You dont have enough : " .. name, "error")
            end
        elseif type == "newmachine" then
            local location = { x = round(coords.x, 3), y = round(coords.y, 3), z = round(coords.z, 3) }
            local location_str = string.format("%f,%f,%f", location.x, location.y, location.z)
            MySQL.Async.execute("INSERT INTO cl_sellmachines (citizenid, location) VALUES (@citizenid, @location)", {
                ['@citizenid'] = Player.PlayerData.citizenid,
                ['@location'] = location_str
            }, function()
                TriggerClientEvent('QBCore:Notify', playerSource, "Successfully added location to vending machine with citizenid: " .. Player.PlayerData.citizenid, "success")
            end) 
        elseif type == "owners" then
            Config.ConnectedOwners[citizenid] = {['Citizenid'] = citizenid, ['Source'] = ownersource}
            TriggerClientEvent("CL-SellMachines:SyncTable", -1, Config.ConnectedOwners)
        end
    end
end)

function round(num, numDecimalPlaces)
    local mult = 10^(numDecimalPlaces or 0)
    return math.floor(num * mult + 0.5) / mult
end

function split(inputstr, sep)
    if sep == nil then
        sep = "%s"
    end
    local t={}
    for str in string.gmatch(inputstr, "([^"..sep.."]+)") do
        table.insert(t, str)
    end
    return t
end