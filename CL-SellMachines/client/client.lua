local QBCore = exports['qb-core']:GetCoreObject()

local placing = false

local vendingMachineBlips = {}

RegisterNetEvent("QBCore:Client:OnPlayerUnload", function()
    QBCore.Functions.TriggerCallback('CL-SellMachines:GetData', function(result)
        if result then
            if Config.ConnectedOwners[result.citizenid] then
                Config.ConnectedOwners[result.citizenid] = nil
            end
        end
    end, "new")     
end)

RegisterNetEvent('QBCore:Client:OnPlayerLoaded', function()
    QBCore.Functions.TriggerCallback('CL-SellMachines:GetData', function(result)
        if result then
            for i, location in ipairs(result) do
                local object = GetClosestObjectOfType(location.x, location.y, location.z, 3.0, GetHashKey(Config.VendingMachineObject), false, false, false)
                if not DoesEntityExist(object) then
                    object = CreateObject(Config.VendingMachineObject, location.x, location.y, location.z, true, true, true)
                    while not DoesEntityExist(object) do
                        Wait(0)
                    end
                    if DoesEntityExist(object) then
                        SetEntityAsMissionEntity(object, true, true)
                        PlaceObjectOnGroundProperly(object)
                        FreezeEntityPosition(object, true)
                        SetEntityInvincible(object, true)
                        exports[Config.Target]:AddTargetEntity(object, {
                            name = "SellMachines",
                            options = {
                                {
                                    icon = "fa fa-store",
                                    label = "Vending Machine",
                                    action = function()
                                        QBCore.Functions.TriggerCallback('CL-SellMachines:GetData', function(result)
                                            if result then
                                                if not Config.ConnectedOwners[result.citizenid] then
                                                    TriggerServerEvent("CL-SellMachines:AddData", "owners", false, false, false, false, result.citizenid, result.playersource)
                                                end
                                                TriggerEvent("CL-SellMachine:OpenSellerMachineMenu", result.player, location, result.money)
                                            else
                                                TriggerServerEvent("CL-SellMachines:Buyer", location)
                                            end
                                        end, "get", location)     
                                    end,
                                },
                            },
                            distance = 2.0,
                        })
                        if location.name then
                            TriggerEvent("CL-SellMachine:CreateBlip", location, location.name)
                        end
                    end
                end
            end
        end
    end, "machines")
end)

RegisterNetEvent("onResourceStart", function(resource)
    if GetCurrentResourceName() == resource then
        QBCore.Functions.TriggerCallback('CL-SellMachines:GetData', function(result)
            if result then
                for i, location in ipairs(result) do
                    local object = CreateObject(Config.VendingMachineObject, location.x, location.y, location.z, true, true, true)
                    while not DoesEntityExist(object) do
                        Wait(0)
                    end
                    if DoesEntityExist(object) then
                        TriggerEvent("CL-SellMachines:RemoveTargetObject", location, location.name)
                        SetEntityAsMissionEntity(object, true, true)
                        PlaceObjectOnGroundProperly(object)
                        FreezeEntityPosition(object, true)
                        SetEntityInvincible(object, true)
                        exports[Config.Target]:AddTargetEntity(object, {
                            name = "SellMachines",
                            options = {
                                {
                                    icon = "fa fa-store",
                                    label = "Vending Machine",
                                    action = function()
                                        QBCore.Functions.TriggerCallback('CL-SellMachines:GetData', function(result)
                                            if result then
                                                if not Config.ConnectedOwners[result.citizenid] then
                                                    TriggerServerEvent("CL-SellMachines:AddData", "owners", false, false, false, false, result.citizenid, result.playersource)
                                                end
                                                TriggerEvent("CL-SellMachine:OpenSellerMachineMenu", result.player, location, result.money)
                                            else
                                                TriggerServerEvent("CL-SellMachines:Buyer", location)
                                            end
                                        end, "get", location)     
                                    end,
                                },
                            },
                            distance = 2.0,
                        })
                        if location.name then
                            TriggerEvent("CL-SellMachine:CreateBlip", location, location.name)
                        end
                    end
                end
            end
        end, "machines")
    end
end)

RegisterNetEvent('CL-SellMachines:SyncTable', function(ActiveOwners)
	Config.ConnectedOwners = ActiveOwners
end)

RegisterNetEvent("CL-SellMachine:CreateBlip", function(location, name)
    local blip = AddBlipForCoord(location.x, location.y, location.z)
    SetBlipSprite(blip, 52)
    SetBlipScale(blip, 0.8)
    SetBlipColour(blip, 2)
    SetBlipAsShortRange(blip, true)
    BeginTextCommandSetBlipName("STRING")
    AddTextComponentString(name)
    EndTextCommandSetBlipName(blip)
    vendingMachineBlips[name] = blip
end)

RegisterNetEvent("CL-SellMachine:UpdateBlip", function(location, name, newname)
    if vendingMachineBlips[name] then
        TriggerEvent("CL-SellMachine:DeleteBlip", name)
        TriggerEvent("CL-SellMachine:CreateBlip", location, newname)
    else
        TriggerEvent("CL-SellMachine:CreateBlip", location, name)
    end
end)

RegisterNetEvent("CL-SellMachine:DeleteBlip", function(name)
    if vendingMachineBlips[name] then
        RemoveBlip(vendingMachineBlips[name])
        vendingMachineBlips[name] = nil
    end
end)

RegisterNetEvent("CL-SellMachines:RemoveTargetObject", function(coords, name)
    local object = GetClosestObjectOfType(coords.x, coords.y, coords.z, 3.0, GetHashKey("p_ld_coffee_vend_s"), false, false, false)
    if DoesEntityExist(object) then
        DeleteObject(object)
        exports[Config.Target]:RemoveZone("SellMachines")
        if name then
            TriggerEvent("CL-SellMachine:DeleteBlip", name)
        end
    end
end)

RegisterNetEvent('CL-SellMachines:Place', function()
    QBCore.Functions.TriggerCallback('CL-SellMachines:GetData', function(result)
        if not result and not placing then
            placing = true
            local playerPed = PlayerPedId()
            local objectCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
            local object = CreateObject(Config.VendingMachineObject, objectCoords.x, objectCoords.y, objectCoords.z, true, true, true)
            SetEntityCollision(object, false, true)
            SetEntityAlpha(object, 128, true) 
            while true do
                local newObjectCoords = GetOffsetFromEntityInWorldCoords(playerPed, 0.0, 5.0, 0.0)
                SetEntityCoords(object, newObjectCoords.x, newObjectCoords.y, newObjectCoords.z)
                PlaceObjectOnGroundProperly(object)
                if IsControlPressed(0, 175) then 
                    SetEntityRotation(object, 0.0, 0.0, GetEntityRotation(object).z + 15.0)
                    Wait(50)
                elseif IsControlPressed(0, 174) then
                    SetEntityRotation(object, 0.0, 0.0, GetEntityRotation(object).z - 15.0)
                    Wait(50)
                end
                if IsControlJustPressed(0, 38) then
                    if not IsBlacklistedZone() then
                        PlaceObjectOnGroundProperly(object)
                        SetEntityCollision(object, true, true)
                        FreezeEntityPosition(object, true)
                        SetEntityAlpha(object, 255, true) 
                        TriggerServerEvent("CL-SellMachines:AddData", "newmachine", newObjectCoords)
                        exports[Config.Target]:AddTargetEntity(object, {
                            name = "SellMachines",
                            options = {
                                {
                                    icon = "fa fa-store",
                                    label = "Vending Machine",
                                    action = function()
                                        QBCore.Functions.TriggerCallback('CL-SellMachines:GetData', function(result)
                                            if result then
                                                if not Config.ConnectedOwners[result.citizenid] then
                                                    TriggerServerEvent("CL-SellMachines:AddData", "owners", false, false, false, false, result.citizenid, result.playersource)
                                                end
                                                TriggerEvent("CL-SellMachine:OpenSellerMachineMenu", result.player, newObjectCoords, result.money)
                                            else
                                                TriggerServerEvent("CL-SellMachines:Buyer", newObjectCoords)
                                            end
                                        end, "get", newObjectCoords)
                                    end,
                                },
                            },
                            distance = 2.0,
                        })
                    else
                        DeleteObject(object)
                        QBCore.Functions.Notify("You cant place a vending machine in this area", "error")
                    end
                    placing = false
                    break
                end
                if IsControlJustPressed(0, 177) then
                    DeleteObject(object)
                    placing = false
                    break
                end
                Wait(0)
            end
        end
    end, "new")
end)

RegisterNetEvent("CL-SellMachine:OpenSellerMachineMenu", function(player, coords, money)
    local SellMachineMenu = {
        {
            header = player .. " Vending Machine",
            icon = "fa-solid fa-circle-info",
            isMenuHeader = true,
        }
    }
    SellMachineMenu[#SellMachineMenu+1] = {
        header = "Add Item",
        text = "Add item to your vending machine",
        icon = "fa-solid fa-cart-plus",
        params = {
            event = "CL-SellMachine:Additem",
            args = {
                coords = coords,
            }
        }
    }
    SellMachineMenu[#SellMachineMenu+1] = {
        header = "View Items",
        text = "View the items stored in your vending machine",
        icon = "fa-solid fa-inbox",
        params = {
            isServer = true,
            event = "CL-SellMachine:GetItemsList",
            args = {
                objectCoords = coords,
            },
        }
    }
    SellMachineMenu[#SellMachineMenu+1] = {
        header = "Choose Name",
        text = "Choose a name for your vending machine",
        icon = "fa-solid fa-file-signature",
        params = {
            event = "CL-SellMachine:ChooseName",
            args = {
                coords = coords,
            }
        }
    }
    SellMachineMenu[#SellMachineMenu+1] = {
        header = "Money Available : " .. money .. "$",
        text = "Withdraw the money from the vending machine",
        icon = "fa-solid fa-money-bill-transfer",
        params = {
            event = "CL-SellMachine:ChooseAmount",
            args = {
                type = "money",
                coords = coords,
                moneyavailable = money,
                coords = coords,
            }
        }
    }
    SellMachineMenu[#SellMachineMenu+1] = {
        header = "Destroy Machine",
        text = "Destroy the machine, you will recieve the items stored",
        icon = "fa-solid fa-house-circle-xmark",
        params = {
            isServer = true,
            event = "CL-SellMachine:DestroyVendingMachine",
            args = {
                objectCoords = coords,
            }
        }
    }
    exports['qb-menu']:openMenu(SellMachineMenu)
end)

RegisterNetEvent("CL-SellMachine:OpenItemsMenu", function(items, owner, coords)
    local ItemsMenu = {
        {
            header = owner .. " Vending Machine",
            icon = "fa-solid fa-circle-info",
            isMenuHeader = true,
        }
    }
    for k, v in pairs(items) do
        ItemsMenu[#ItemsMenu+1] = {
            header = "<img src=nui://qb-inventory/html/images/"..QBCore.Shared.Items[v.name].image.." width=30px> ".." ┇ " .. QBCore.Shared.Items[v.name].label,
            text = "<br> Price : " .. v.price .. "$ (Per) <br> In Stock : " .. v.quantity,
            params = {
                isServer = true,
                event = "CL-SellMachine:RemoveData",
                args = {
                    type = "remove",
                    item = v.name,
                    quantity = v.quantity,
                    owner_citizenid = owner,
                    objectCoords = coords,
                },
            }
        }
    end
    exports['qb-menu']:openMenu(ItemsMenu)
end)

RegisterNetEvent("CL-SellMachine:OpenBuyerMachineMenu", function(items, owner, coords, money)
    local BuyMachineMenu = {
        {
            header = owner .. " Vending Machine",
            icon = "fa-solid fa-shop",
            isMenuHeader = true,
        }
    }
    for k, v in pairs(items) do
        BuyMachineMenu[#BuyMachineMenu+1] = {
            header = "<img src=nui://qb-inventory/html/images/"..QBCore.Shared.Items[v.name].image.." width=30px> ".." ┇ " .. QBCore.Shared.Items[v.name].label,
            text = "Buy : " .. QBCore.Shared.Items[v.name].label .. "<br> From : " .. owner .. "<br> For : " .. v.price .. "$ (Per) <br> In Stock : " .. v.quantity,
            icon = "fa-solid fa-cart-shopping",
            params = {
                event = "CL-SellMachine:ChooseAmount",
                args = {
                    type = "buy",
                    item = v.name,
                    quantity = v.quantity,
                    owner_citizenid = owner,
                    objectCoords = coords,
                    moneyavailable = money,
                },
            }
        }
    end
    exports['qb-menu']:openMenu(BuyMachineMenu)
end)

RegisterNetEvent("CL-SellMachine:ChooseName", function(data)
    local Name = exports["qb-input"]:ShowInput({
        header = "Vending Machine Name",
        submitText = "Choose",
        inputs = {
            { 
                text = 'Name', 
                name = 'name', 
                type = 'text', 
                isRequired = true,
            },
        }
    })
    if Name ~= nil then
        if Name.name then
            for i, blacklistedword in ipairs(Config.BlackListedNames) do
                if Name.name == blacklistedword then
                    QBCore.Functions.Notify(Name.name .. " is a blacklisted word !", "error")
                    return
                end
            end
            TriggerServerEvent("CL-SellMachine:CreateName", Name.name, data.coords)
        end
    end
end)

RegisterNetEvent("CL-SellMachine:ChooseAmount", function(data)
    header = nil
    if data.type == "money" then
        header = data.moneyavailable .. "$ Available"
    else
        header = "Choose Amount"
    end
    local Amount = exports["qb-input"]:ShowInput({
        header = header,
        submitText = "Choose",
        inputs = {
            { 
                text = 'Amount', 
                name = 'amount', 
                type = 'number', 
                isRequired = true,
            },
            { 
                text = 'Payment Type', 
                name = 'paymenttype', 
                type = 'radio', 
                isRequired = true,
                options = { 
                    { 
                        value = "cash", 
                        text = "Cash" 
                    }, 
                    { 
                        value = "bank", 
                        text = "Bank" 
                    } 
                } 
            }
        }
    })
    if Amount ~= nil then
        if data.type == "buy" then
            local itemamount = tonumber(Amount.amount)
            if data.quantity >= itemamount and itemamount > 0 then
                TriggerServerEvent("CL-SellMachine:Buy", Amount.amount, Amount.paymenttype, data.item, data.quantity, data.objectCoords, data.owner_citizenid, data.moneyavailable) 
            else
                QBCore.Functions.Notify("You cant buy that amount", "error")
            end
        elseif data.type == "money" then
            local moneyamount = tonumber(Amount.amount)
            if data.moneyavailable >= moneyamount and moneyamount > 0 then
                TriggerServerEvent("CL-SellMachine:Withdraw", Amount.amount, Amount.paymenttype, data.moneyavailable, data.coords) 
            else
                QBCore.Functions.Notify("You cant withdraw that amount", "error")
            end
        end
    end
end)

RegisterNetEvent("CL-SellMachine:Additem", function(data)
    local Amount = exports["qb-input"]:ShowInput({
        header = "Add Sell Order",
        submitText = "Add Sell Order",
        inputs = {
            { 
                text = 'Sell', 
                name = 'item2sell', 
                type = 'text', 
                isRequired = true,
            },
            { 
                text = 'Amount', 
                name = 'amount2sell', 
                type = 'number', 
                isRequired = true,
            },
            { 
                text = 'For', 
                name = 'amount2recieve', 
                type = 'number', 
                isRequired = true,
            }
        }
    })
    if Amount ~= nil then
        local itemamount = tonumber(Amount.amount2sell)
        for i, blacklisteditem in ipairs(Config.BlackListedItems) do
            if Amount.item2sell == blacklisteditem then
                QBCore.Functions.Notify(Amount.item2sell .. " is a blacklisted item !", "error")
                return
            end
        end
        if QBCore.Shared.Items[Amount.item2sell] then
            TriggerServerEvent("CL-SellMachines:AddData", "items", data.coords, Amount.item2sell, Amount.amount2recieve, itemamount) 
        else
            QBCore.Functions.Notify(Amount.item2sell .. " does not exists !", "error")
        end
    end
end)

function IsBlacklistedZone()
    for k, v in pairs(Config.BlackListedLocations) do
        local pos = GetEntityCoords(PlayerPedId(), true)
        if (GetDistanceBetweenCoords(pos.x, pos.y, pos.z, v.Coords.x, v.Coords.y, v.Coords.z, false) < v.Distance ) then
            return true
        end
        return false
    end
end