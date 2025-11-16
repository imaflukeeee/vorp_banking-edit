local VORPcore = exports.vorp_core:GetCore()
local T = Translation.Langs[Config.Lang]

-- [FIXED] 1. แก้ไข registerStorage ให้ใช้ Config กลาง
local function registerStorage(bankName, bankId, invspace)
    local isRegistered = exports.vorp_inventory:isCustomInventoryRegistered(bankId)
    if not isRegistered then
        local data = {
            id = bankId,
            name = T.namebank, -- [FIXED] ใช้ชื่อกลางจาก language.lua
            limit = invspace,
            acceptWeapons = Config.GlobalCanStoreWeapons, -- [FIXED] ใช้ Config กลาง
            shared = true,
            ignoreItemStackLimit = true,
            webhook = "", -- add here your webhook url for discord logging
        }
        exports.vorp_inventory:registerInventory(data)
        Wait(200)
    end
end

-- [NO CHANGE] ฟังก์ชันนี้ถูกต้องแล้ว เพราะยังต้องเช็คว่าอยู่ใกล้ "ธนาคารใดก็ได้"
local function IsNearBank(source, bankName)
    local playerPed = GetPlayerPed(source)
    local playerCoords = GetEntityCoords(playerPed)
    local bankLocation = Config.banks[bankName].BankLocation
    local distance = #(playerCoords - vector3(bankLocation.x, bankLocation.y, bankLocation.z))

    if distance <= Config.banks[bankName].distOpen + 10.0 then -- Adjusted Distance check to make sure it's within range (if any bank is facing issue then you can increase this value)
        return true
    else
        return false
    end
end

-- [FIXED] 2. ฟังก์ชัน getinfo ที่แก้ไขแล้ว (ตามที่คุณส่งมา)
VORPcore.Callback.Register('vorp_bank:getinfo', function(source, cb, bankName)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local charidentifier = Character.charIdentifier
    local identifier = Character.identifier
    local allBanks = {}

    MySQL.query("SELECT * FROM bank_users WHERE charidentifier = @charidentifier AND name = @bankName",
        { charidentifier = charidentifier, bankName = Config.GlobalBankName }, function(result)
            if result[1] then
                local money = result[1].money
                local gold = result[1].gold
                local invspace = result[1].invspace
                local bankinfo = { money = money, gold = gold, invspace = invspace, name = Config.GlobalBankName }

                local allBanksResult = MySQL.query.await("SELECT * FROM bank_users WHERE charidentifier = @charidentifier", { charidentifier = charidentifier })
                if allBanksResult[1] then
                    allBanks = allBanksResult
                end

                return cb({ bankinfo, allBanks })
            else
                local defaultMoney = 0
                local defaultGold = 0
                local defaultInvspace = 10
                local parameters = {
                    name = Config.GlobalBankName,
                    identifier = identifier,
                    charidentifier = charidentifier,
                    money = defaultMoney,
                    gold = defaultGold,
                    invspace = defaultInvspace
                }

                MySQL.insert.await("INSERT INTO bank_users ( `name`,`identifier`,`charidentifier`,`money`,`gold`,`invspace`) VALUES ( @name, @identifier, @charidentifier, @money, @gold, @invspace)", parameters)
                
                MySQL.query("SELECT * FROM bank_users WHERE charidentifier = @charidentifier AND name = @bankName", { charidentifier = charidentifier, bankName = Config.GlobalBankName }, function(result1)
                    if result1[1] then
                        local money = defaultMoney
                        local gold = defaultGold
                        local invspace = defaultInvspace
                        local bankinfo = { money = money, gold = gold, invspace = invspace, name = Config.GlobalBankName }

                        local allBanksResult = MySQL.query.await("SELECT * FROM bank_users WHERE charidentifier = @charidentifier", { charidentifier = charidentifier })
                        if allBanksResult[1] then
                            allBanks = allBanksResult
                        end
                        return cb({ bankinfo, allBanks })
                    end
                end)
            end
        end)
end)

-- [FIXED] 3. ฟังก์ชัน UpgradeSafeBox ที่แก้ไขให้ใช้ Config กลาง
RegisterServerEvent('vorp_bank:UpgradeSafeBox', function(slotsToBuy, currentspace, bankName)
    local _source        = source
    local Character      = VORPcore.getUser(_source).getUsedCharacter
    local charidentifier = Character.charIdentifier
    local money          = Character.money

    -- [FIXED] ใช้ Config กลาง (ต้องเพิ่มใน config.lua)
    local maxslots       = Config.GlobalMaxSlots
    local costslot       = Config.GlobalCostSlot
    -- [FIXED] ชื่อบัญชีใน DB ต้องเป็นชื่อกลาง
    local name           = Config.GlobalBankName

    local amountToPay    = costslot * slotsToBuy
    local FinalSlots     = currentspace + slotsToBuy

    if not IsNearBank(_source, bankName) then
        return VORPcore.NotifyRightTip(_source, T.notnear, 4000)
    end

    if money < amountToPay then
        return VORPcore.NotifyRightTip(_source, T.nomoney, 4000)
    end

    if FinalSlots > maxslots then
        return VORPcore.NotifyRightTip(_source, T.maxslots .. " | " .. slotsToBuy .. " / " .. maxslots, 4000)
    end

    Character.removeCurrency(0, amountToPay)
    local Parameters = { ['charidentifier'] = charidentifier, ['invspace'] = FinalSlots, ['name'] = name }
    MySQL.update("UPDATE bank_users SET invspace=@invspace WHERE charidentifier=@charidentifier AND name = @name", Parameters)
    
    -- [FIXED] bankId ต้องเป็นรหัสคลังกลาง
    local bankId = "vorp_banking_global_" .. charidentifier
    
    registerStorage(bankName, bankId, currentspace)
    exports.vorp_inventory:updateCustomInventorySlots(bankId, FinalSlots)
    VORPcore.NotifyRightTip(_source, T.success .. (costslot * slotsToBuy) .. " | " .. FinalSlots .. " / " .. maxslots, 4000)
end)

-- [NO CHANGE] DiscordLogs ไม่ต้องแก้ (การที่มัน log ชื่อสาขาที่ไปกดถือว่าถูกต้องแล้ว)
DiscordLogs = function(transactionAmount, bankName, playerName, transactionType, targetBankName, currencyType, itemName)
    local logTitle = T.Webhooks.LogTitle
    local webhookURL, logMessage = "", ""
    local currencySymbol = currencyType == "gold" and "G" or "$"

    if transactionType == "withdraw" then
        webhookURL = Config.WithdrawLogWebhook
        logMessage = string.format(T.Webhooks.WithdrawLogDescription, playerName, transactionAmount .. currencySymbol,
            bankName)
    elseif transactionType == "deposit" then
        webhookURL = Config.DepositLogWebhook
        logMessage = string.format(T.Webhooks.DepositLogDescription, playerName, transactionAmount .. currencySymbol,
            bankName)
    elseif transactionType == "transfer" then
        webhookURL = Config.TransferLogWebhook
        logMessage = string.format(T.Webhooks.TransferLogDescription, playerName, transactionAmount .. currencySymbol,
            bankName, targetBankName)
    elseif transactionType == "take" then
        webhookURL = Config.TakeLogWebhook
        logMessage = string.format(T.Webhooks.TakeLogDescription, playerName, transactionAmount, itemName, bankName)
    elseif transactionType == "move" then
        webhookURL = Config.MoveLogWebhook
        logMessage = string.format(T.Webhooks.MoveLogDescription, playerName, transactionAmount, itemName, bankName)
    end

    VORPcore.AddWebhook(logTitle, webhookURL, logMessage)
end

-- [FIXED] 4. ลบฟังก์ชัน 'vorp_bank:transfer' ทิ้งทั้งหมด
-- (เนื่องจากระบบบัญชีกลางไม่จำเป็นต้องใช้การโอนเงินระหว่างสาขา)
--[[
RegisterServerEvent('vorp_bank:transfer', function(amount, fromBank, toBank)
    ... (โค้ดเดิมทั้งหมดถูกลบ) ...
end)
]]

-- [FIXED] 5. แก้ไข depositcash ให้ใช้บัญชีกลาง
RegisterServerEvent('vorp_bank:depositcash', function(amount, bankName)
    local _source = source
    local playerCharacter = VORPcore.getUser(_source).getUsedCharacter
    local characterId = playerCharacter.charIdentifier
    local playerCash = tonumber(playerCharacter.money)

    if not IsNearBank(_source, bankName) then
        return VORPcore.NotifyRightTip(_source, T.notnear, 4000)
    end

    if playerCash >= amount then
        -- [FIXED] ใช้ Config.GlobalBankName
        MySQL.query("SELECT money FROM bank_users WHERE charidentifier = @characterId AND name = @bankName", { characterId = characterId, bankName = Config.GlobalBankName }, function(result)
            if result[1] then
                playerCharacter.removeCurrency(0, amount)
                DiscordLogs(amount, bankName, playerCharacter.firstname .. ' ' .. playerCharacter.lastname, "deposit", "cash")
                local newBalance = result[1].money + amount
                -- [FIXED] ใช้ Config.GlobalBankName
                MySQL.update("UPDATE bank_users SET money=@newBalance WHERE charidentifier=@characterId AND name = @bankName", { characterId = characterId, newBalance = newBalance, bankName = Config.GlobalBankName })
                VORPcore.NotifyRightTip(_source, T.youdepo .. amount, 4000)
            end
        end)
    else
        VORPcore.NotifyRightTip(_source, T.invalid, 4000)
    end
end)

-- [FIXED] 6. แก้ไข depositgold ให้ใช้บัญชีกลาง
RegisterServerEvent('vorp_bank:depositgold', function(amount, bankName)
    local _source = source
    local playerCharacter = VORPcore.getUser(_source).getUsedCharacter
    local characterId = playerCharacter.charIdentifier
    local playerGold = tonumber(playerCharacter.gold)

    if not IsNearBank(_source, bankName) then
        return VORPcore.NotifyRightTip(_source, T.notnear, 4000)
    end

    if playerGold >= amount then
        playerCharacter.removeCurrency(1, amount)
        -- [FIXED] ใช้ Config.GlobalBankName
        MySQL.update("UPDATE bank_users SET gold = gold + @amount WHERE charidentifier = @characterId AND name = @bankName", { characterId = characterId, amount = amount, bankName = Config.GlobalBankName })
        VORPcore.NotifyRightTip(_source, T.youdepog .. amount, 4000)
    else
        VORPcore.NotifyRightTip(_source, T.invalid, 4000)
    end
end)


local lastMoney = {}

-- [FIXED] 7. แก้ไข withcash ให้ใช้บัญชีกลาง
RegisterServerEvent('vorp_bank:withcash', function(amount, bankName)
    local _source = source
    local Character = VORPcore.getUser(_source).getUsedCharacter
    local playerFullName = Character.firstname .. ' ' .. Character.lastname
    local characterId = Character.charIdentifier

    if not IsNearBank(_source, bankName) then
        return VORPcore.NotifyRightTip(_source, T.notnear, 4000)
    end

    -- [FIXED] ใช้ Config.GlobalBankName
    MySQL.query("SELECT money FROM bank_users WHERE charidentifier = @characterId AND name = @bankName", { characterId = characterId, bankName = Config.GlobalBankName }, function(result)
        if result[1] then
            local bankBalance = tonumber(result[1].money)
            if bankBalance >= amount then
                if not lastMoney[_source] or lastMoney[_source] ~= bankBalance then
                    local newBalance = bankBalance - amount
                    -- [FIXED] ใช้ Config.GlobalBankName
                    MySQL.update("UPDATE bank_users SET money=@newBalance WHERE charidentifier=@characterId AND name = @bankName", { characterId = characterId, newBalance = newBalance, bankName = Config.GlobalBankName })
                    lastMoney[_source] = bankBalance
                    Character.addCurrency(0, amount)
                    DiscordLogs(amount, bankName, playerFullName, "withdraw", "cash")
                    VORPcore.NotifyRightTip(_source, T.withdrew .. amount, 4000)
                end
            else
                VORPcore.NotifyRightTip(_source, T.invalid .. amount, 4000)
            end
        end
    end)
end)

-- [FIXED] 8. แก้ไข withgold ให้ใช้บัญชีกลาง
RegisterServerEvent('vorp_bank:withgold', function(amount, bankName)
    local _source = source
    local playerCharacter = VORPcore.getUser(_source).getUsedCharacter
    local playerFullName = playerCharacter.firstname .. ' ' .. playerCharacter.lastname
    local characterId = playerCharacter.charIdentifier

    if not IsNearBank(_source, bankName) then
        return VORPcore.NotifyRightTip(_source, T.notnear, 4000)
    end

    -- [FIXED] ใช้ Config.GlobalBankName
    MySQL.query("SELECT gold FROM bank_users WHERE charidentifier = @characterId AND name = @bankName", { characterId = characterId, bankName = Config.GlobalBankName }, function(result)
        if result[1] then
            local bankGold = tonumber(result[1].gold)
            if bankGold >= amount then
                local newGoldBalance = bankGold - amount
                -- [FIXED] ใช้ Config.GlobalBankName
                MySQL.update("UPDATE bank_users SET gold = @newGoldBalance WHERE charidentifier = @characterId AND name = @bankName", { characterId = characterId, newGoldBalance = newGoldBalance, bankName = Config.GlobalBankName })
                playerCharacter.addCurrency(1, amount)
                DiscordLogs(amount, bankName, playerFullName, "withdraw", "gold")
                VORPcore.NotifyRightTip(_source, T.withdrewg .. amount, 4000)
            else
                VORPcore.NotifyRightTip(_source, T.invalid, 4000)
            end
        end
    end)
end)

-- [FIXED] 9. แก้ไข OpenBankInventory ให้ใช้คลังกลาง
RegisterServerEvent("vorp_banking:server:OpenBankInventory", function(bankName)
    local _source = source
    local user = VORPcore.getUser(_source)
    if not user then return end

    local Character = user.getUsedCharacter
    local characterId = Character.charIdentifier
    -- [FIXED] bankId ต้องเป็นรหัสคลังกลาง
    local bankId = "vorp_banking_global_" .. characterId

    if not IsNearBank(_source, bankName) then
        return VORPcore.NotifyRightTip(_source, T.notnear, 4000)
    end

    -- Check database for invSpace server side.
    -- [FIXED] ใช้ Config.GlobalBankName
    MySQL.scalar('SELECT `invspace` FROM `bank_users` WHERE `charidentifier` = @characterId AND `name` = @bankName LIMIT 1', {
        characterId = characterId, bankName = Config.GlobalBankName
    }, function(invSpace)
        if invSpace then
            registerStorage(bankName, bankId, invSpace)
            exports.vorp_inventory:openInventory(_source, bankId)
        else
            VORPcore.NotifyRightTip(_source, T.invOpenFail, 4000)
        end
    end)
end)

-- [NO CHANGE]
AddEventHandler("playerDropped", function()
    local _source = source
    for key, _ in pairs(lastMoney) do
        if key == _source then
            lastMoney[key] = nil
            break
        end
    end
end)