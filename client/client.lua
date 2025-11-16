local VORPcore = exports.vorp_core:GetCore()
local prompts = GetRandomIntInRange(0, 0xffffff)
local PromptGroup2 = GetRandomIntInRange(0, 0xffffff)
local openmenu
local CloseBanks
local inmenu = false
local currentBankName = nil -- [เพิ่ม] เก็บชื่อธนาคารที่เปิดอยู่
local currentBankInfo = nil -- [เพิ่ม] เก็บข้อมูลธนาคารที่เปิดอยู่
local T = Translation.Langs[Config.Lang]
-- local MenuData = exports.vorp_menu:GetMenuData() -- [ลบ] ไม่ใช้ vorp_menu

AddEventHandler("onResourceStop", function(resourceName)
    if resourceName == GetCurrentResourceName() then
        for _, v in pairs(Config.banks) do
            if v.BlipHandle then
                RemoveBlip(v.BlipHandle)
            end
            if v.NPC then
                DeleteEntity(v.NPC)
                DeletePed(v.NPC)
                SetEntityAsNoLongerNeeded(v.NPC)
            end
        end
        DisplayRadar(true)
        -- MenuData.CloseAll() -- [ลบ]
        SetNuiFocus(false, false) -- [เพิ่ม]
        inmenu = false
        ClearPedTasks(PlayerPedId())
    end
end)

---------------- BLIPS ---------------------
-- (ส่วนนี้เหมือนเดิม)
local function AddBlip(index)
    if Config.banks[index].blipAllowed then
        local blip = BlipAddForCoords(1664425300, Config.banks[index].BankLocation.x, Config.banks[index].BankLocation.y, Config.banks[index].BankLocation.z)
        SetBlipSprite(blip, Config.banks[index].blipsprite, true)
        SetBlipScale(blip, 0.2)
        SetBlipName(blip, Config.banks[index].name)
        Config.banks[index].BlipHandle = blip
    end
end

---------------- NPC ---------------------
-- (ส่วนนี้เหมือนเดิม)
local function LoadModel(model)
    if not HasModelLoaded(model) then
        RequestModel(model, false)
        repeat Wait(0) until HasModelLoaded(model)
    end
end

local function SpawnNPC(index)
    local v = Config.banks[index]
    LoadModel(v.NpcModel)
    local npc = CreatePed(joaat(v.NpcModel), v.NpcPosition.x, v.NpcPosition.y, v.NpcPosition.z, v.NpcPosition.h, false, false, false, false)
    repeat Wait(0) until DoesEntityExist(npc)
    PlaceEntityOnGroundProperly(npc, true)
    Citizen.InvokeNative(0x283978A15512B2FE, npc, true)
    SetEntityCanBeDamaged(npc, false)
    SetEntityInvincible(npc, true)
    Wait(1000)
    TaskStandStill(npc, -1)
    SetBlockingOfNonTemporaryEvents(npc, true)
    SetModelAsNoLongerNeeded(v.NpcModel)
    Config.banks[index].NPC = npc
end

-- (ส่วน Prompt, getDistance, CreateNpcByDistance เหมือนเดิม)
local function PromptSetUp()
    local str = T.openmenu
    openmenu = UiPromptRegisterBegin()
    UiPromptSetControlAction(openmenu, Config.Key)
    str = VarString(10, 'LITERAL_STRING', str)
    UiPromptSetText(openmenu, str)
    UiPromptSetEnabled(openmenu, true)
    UiPromptSetVisible(openmenu, true)
    UiPromptSetStandardMode(openmenu, true)
    UiPromptSetGroup(openmenu, prompts, 0)
    UiPromptRegisterEnd(openmenu)
end

local function PromptSetUp2()
    local str = T.closemenu
    CloseBanks = UiPromptRegisterBegin()
    UiPromptSetControlAction(CloseBanks, Config.Key)
    str = VarString(10, 'LITERAL_STRING', str)
    UiPromptSetText(CloseBanks, str)
    UiPromptSetEnabled(CloseBanks, true)
    UiPromptSetVisible(CloseBanks, true)
    UiPromptSetStandardMode(CloseBanks, true)
    UiPromptSetGroup(CloseBanks, PromptGroup2, 0)
    UiPromptRegisterEnd(CloseBanks)
end

local function getDistance(config)
    local coords = GetEntityCoords(PlayerPedId())
    local coords2 = vector3(config.x, config.y, config.z)
    return #(coords - coords2)
end

local function CreateNpcByDistance(distance, index)
    if Config.banks[index].NpcAllowed then
    if distance <= 40 then
        if not Config.banks[index].NPC then
            SpawnNPC(index)
        end
    else
        if Config.banks[index].NPC then
            SetEntityAsNoLongerNeeded(Config.banks[index].NPC)
            DeleteEntity(Config.banks[index].NPC)
            Config.banks[index].NPC = nil
        end
    end
    end
end

local function GetBankInfo(bankConfig)
    local result = VORPcore.Callback.TriggerAwait("vorp_bank:getinfo", bankConfig.city)
    Openbank(bankConfig.city, result[1], result[2]) -- [แก้ไข] bankConfig.city คือ bankName
    TaskStandStill(PlayerPedId(), -1)
    DisplayRadar(false)
end

-- (Main loop - CreateThread - เหมือนเดิม)
CreateThread(function()
    repeat Wait(2000) until LocalPlayer.state.IsInSession
    PromptSetUp()
    PromptSetUp2()

    while true do
        local sleep = 1000
        local player = PlayerPedId()
        local dead = IsEntityDead(player)

        if not inmenu and not dead then
            for index, bankConfig in pairs(Config.banks) do
                if bankConfig.StoreHoursAllowed then
                    local hour = GetClockHours()
                    if hour >= bankConfig.StoreClose or hour < bankConfig.StoreOpen then
                        if not Config.banks[index].BlipHandle and bankConfig.blipAllowed then
                            AddBlip(index)
                        end

                        if Config.banks[index].BlipHandle then
                            BlipAddModifier(Config.banks[index].BlipHandle, joaat('BLIP_MODIFIER_MP_COLOR_10'))
                        end

                        if Config.banks[index].NPC then
                            DeleteEntity(Config.banks[index].NPC)
                            DeletePed(Config.banks[index].NPC)
                            SetEntityAsNoLongerNeeded(Config.banks[index].NPC)
                            Config.banks[index].NPC = nil
                        end

                        local distance = getDistance(bankConfig.BankLocation)

                        if distance <= bankConfig.distOpen then
                            sleep = 0
                            local label2 = VarString(10, 'LITERAL_STRING', T.openHours .. " " .. bankConfig.StoreOpen .. T.amTimeZone .. " - " .. bankConfig.StoreClose .. T.pmTimeZone)
                            UiPromptSetActiveGroupThisFrame(PromptGroup2, label2, 0, 0, 0, 0)

                            if UiPromptHasStandardModeCompleted(CloseBanks, 0) then
                                Wait(1000)
                                VORPcore.NotifyRightTip(T.closed, 4000)
                            end
                        end
                    elseif hour >= bankConfig.StoreOpen then
                        if not Config.banks[index].BlipHandle and bankConfig.blipAllowed then
                            AddBlip(index)
                        end

                        if Config.banks[index].BlipHandle then
                            BlipAddModifier(Config.banks[index].BlipHandle, joaat('BLIP_MODIFIER_MP_COLOR_32'))
                        end

                        local distance = getDistance(bankConfig.BankLocation)
                        CreateNpcByDistance(distance, index)
                        if distance <= bankConfig.distOpen then
                            sleep = 0

                            local label = VarString(10, 'LITERAL_STRING', T.bank .. " " .. bankConfig.name)
                            UiPromptSetActiveGroupThisFrame(prompts, label, 0, 0, 0, 0)

                            if UiPromptHasStandardModeCompleted(openmenu, 0) then
                                inmenu = true
                                GetBankInfo(bankConfig)
                            end
                        end
                    end
                else
                    local distance = getDistance(bankConfig.BankLocation)
                    if not Config.banks[index].BlipHandle and bankConfig.blipAllowed then
                        AddBlip(index)
                    end

                    CreateNpcByDistance(distance, index)

                    if distance <= bankConfig.distOpen then
                        sleep = 0
                        local label = VarString(10, 'LITERAL_STRING', T.bank .. " " .. bankConfig.name)
                        UiPromptSetActiveGroupThisFrame(prompts, label, 0, 0, 0, 0)

                        if UiPromptHasStandardModeCompleted(openmenu, 0) then
                            inmenu = true
                            GetBankInfo(bankConfig)
                        end
                    end
                end
            end
        end
        Wait(sleep)
    end
end)

-- [แก้ไข] ฟังก์ชัน CloseMenu()
local function CloseMenu()
    -- MenuData.CloseAll() -- [ลบ]
    SendNUIMessage({ action = 'close' }) -- [เพิ่ม]
    SetNuiFocus(false, false)            -- [เพิ่ม]
    inmenu = false
    ClearPedTasks(PlayerPedId())
    DisplayRadar(true)
    currentBankName = nil -- [เพิ่ม]
    currentBankInfo = nil -- [เพิ่ม]
end

-- [แก้ไข] ฟังก์ชัน Openbank()
function Openbank(bankName, bankinfo, allbanks)
    -- MenuData.CloseAll() -- [ลบ]
    if not bankinfo.money then
        CloseMenu()
        return
    end

    -- [เพิ่ม] เก็บข้อมูลไว้ให้ NUI Callbacks ใช้
    currentBankName = bankName
    currentBankInfo = bankinfo

    -- [เพิ่ม] ส่งข้อมูลไป NUI
    SendNUIMessage({
        action = 'open',
        bankName = bankName,
        bankInfo = bankinfo,
        allBanks = allbanks,
        config = Config, -- ส่ง Config ไปด้วย
        translations = T -- ส่งภาษาไปด้วย
    })

    -- [เพิ่ม] เปิดเมาส์
    SetNuiFocus(true, true)

    -- [ลบ] ลบ MenuData.Open ทั้งหมด (บรรทัด 248-418)
end

-- [ลบ] ลบฟังก์ชัน Openallbanks(bankName, allbanks) ทั้งหมด (บรรทัด 420-456)
-- (เราจะย้าย Logic นี้ไปไว้ใน NUI Callback 'transferMoney')

-- ===================================================
-- [เพิ่ม] NUI CALLBACKS (รับคำสั่งจาก UI ใหม่)
-- ===================================================

-- รับคำสั่งปิดจาก UI (เช่น กด ESC)
RegisterNUICallback('close', function(data, cb)
    CloseMenu()
    cb('ok')
end)

-- รับคำสั่ง "ฝากเงิน"
RegisterNUICallback('depositCash', function(data, cb)
    -- (คัดลอก Logic 'dcash' จาก Openbank เดิมมาที่นี่)
    local myInput = {
        type = "enableinput",
        inputType = "input",
        button = T.inputsLang.confirmCash,
        placeholder = T.inputsLang.insertAmountCash,
        style = "block",
        attributes = {
            inputHeader = T.inputsLang.depositCash,
            type = "text",
            pattern = "[0-9.]{1,10}",
            title = T.inputsLang.numOnlyCash,
            style = "border-radius: 10px; background-color: ; border:none;"
        }
    }

    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(cb_input)
        local result = tonumber(cb_input)
        if result ~= nil and result > 0 then
            TriggerServerEvent("vorp_bank:depositcash", result, Config.banks[currentBankName].city, currentBankInfo)
            CloseMenu()
        else
            VORPcore.NotifyRightTip(T.invalid, 4000)
        end
    end)
    cb('ok')
end)

-- รับคำสั่ง "ฝากทอง"
RegisterNUICallback('depositGold', function(data, cb)
    -- (คัดลอก Logic 'dgold' จาก Openbank เดิมมาที่นี่)
    local myInput = {
        type = "enableinput",
        inputType = "input",
        button = T.inputsLang.confirmGold,
        placeholder = T.inputsLang.insertAmountGold,
        style = "block",
        attributes = {
            inputHeader = T.inputsLang.depositGold,
            type = "text",
            pattern = "[0-9.]{1,10}",
            title = T.inputsLang.numOnlyGold,
            style = "border-radius: 10px; background-color: ; border:none;"
        }
    }

    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(cb_input)
        local result = tonumber(cb_input)
        if result ~= nil and result > 0 then
            TriggerServerEvent("vorp_bank:depositgold", result, Config.banks[currentBankName].city, currentBankInfo)
            CloseMenu()
        else
            VORPcore.NotifyRightTip(T.invalid, 4000)
        end
    end)
    cb('ok')
end)

-- รับคำสั่ง "ถอนเงิน"
RegisterNUICallback('withdrawCash', function(data, cb)
    -- (คัดลอก Logic 'wcash' จาก Openbank เดิมมาที่นี่)
    local myInput = {
        type = "enableinput",
        inputType = "input",
        button = T.inputsLang.confirmCashW,
        placeholder = T.inputsLang.insertAmountCashW,
        style = "block",
        attributes = {
            inputHeader = T.inputsLang.withdrawCash,
            type = "text",
            pattern = "[0-9.]{1,10}",
            title = T.inputsLang.numOnlyCashW,
            style = "border-radius: 10px; background-color: ; border:none;"
        }
    }

    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(cb_input)
        local result = tonumber(cb_input)
        if result ~= nil and result > 0 then
            TriggerServerEvent("vorp_bank:withcash", result, Config.banks[currentBankName].city, currentBankInfo)
            CloseMenu()
        else
            VORPcore.NotifyRightTip(T.invalid, 4000)
        end
    end)
    cb('ok')
end)

-- รับคำสั่ง "ถอนทอง"
RegisterNUICallback('withdrawGold', function(data, cb)
    -- (คัดลอก Logic 'wgold' จาก Openbank เดิมมาที่นี่)
    local myInput = {
        type = "enableinput",
        inputType = "input",
        button = T.inputsLang.confirmGoldW,
        placeholder = T.inputsLang.insertAmountGoldW,
        style = "block",
        attributes = {
            inputHeader = T.inputsLang.withdrawGold,
            type = "text",
            pattern = "[0-9.]{1,10}",
            title = T.inputsLang.numOnlyGoldW,
            style = "border-radius: 10px; background-color: ; border:none;"
        }
    }

    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(cb_input)
        local result = tonumber(cb_input)
        if result ~= nil and result > 0 then
            TriggerServerEvent("vorp_bank:withgold", result, Config.banks[currentBankName].city, currentBankInfo)
            CloseMenu()
        else
            VORPcore.NotifyRightTip(T.invalid, 4000)
        end
    end)
    cb('ok')
end)

-- รับคำสั่ง "เปิดตู้เซฟ"
RegisterNUICallback('openStorage', function(data, cb)
    -- (คัดลอก Logic 'bitem' จาก Openbank เดิมมาที่นี่)
    if currentBankInfo.invspace > 0 then
        TriggerServerEvent("vorp_banking:server:OpenBankInventory", currentBankName)
        CloseMenu()
    else
        VORPcore.NotifyRightTip(" you need to buy slots first", 4000)
    end
    cb('ok')
end)

-- รับคำสั่ง "อัปเกรดตู้เซฟ"
RegisterNUICallback('upgradeStorage', function(data, cb)
    -- (คัดลอก Logic 'upitem' จาก Openbank เดิมมาที่นี่)
    local invspace = currentBankInfo.invspace
    local myInput = {
        type = "enableinput",
        inputType = "input",
        button = T.inputsLang.confirmUp,
        placeholder = T.inputsLang.insertAmountUp,
        style = "block",
        attributes = {
            inputHeader = T.inputsLang.upgradeSlots,
            type = "text",
            pattern = "[0-9]{1,10}",
            title = T.inputsLang.numOnlyUp,
            style = "border-radius: 10px; background-color: ; border:none;"
        }
    }

    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(cb_input)
        local result = tonumber(cb_input)
        if result ~= nil and result > 0 then
            TriggerServerEvent("vorp_bank:UpgradeSafeBox", math.floor(result), invspace, currentBankName)
            CloseMenu()
        else
            VORPcore.NotifyRightTip(T.invalid, 4000)
        end
    end)
    cb('ok')
end)

-- รับคำสั่ง "โอนเงิน"
RegisterNUICallback('transferMoney', function(data, cb)
    -- (คัดลอก Logic 'transfer' จาก Openallbanks เดิมมาที่นี่)
    -- 'data' ที่ส่งมาจาก JS จะมี 'targetBankName'
    local targetBank = data.targetBankName
    if not targetBank then
        print("vorp_banking: NUI did not send targetBankName")
        cb('error')
        return
    end

    local myInput = {
        type = "enableinput",
        inputType = "input",
        button = T.inputsLang.Transfer,
        placeholder = T.inputsLang.insertAmountCash,
        style = "block",
        attributes = {
            inputHeader = T.inputsLang.depositTransfer,
            type = "text",
            pattern = "[0-9.]{1,10}",
            title = T.inputsLang.numOnlyCash,
            style = "border-radius: 10px; background-color: ; border:none;"
        }
    }
    TriggerEvent("vorpinputs:advancedInput", json.encode(myInput), function(cb_input)
        local result = tonumber(cb_input)
        if result ~= nil and result > 0 then
            -- data.current.info ถูกแทนที่ด้วย targetBank
            -- bankName ถูกแทนที่ด้วย currentBankName
            TriggerServerEvent("vorp_bank:transfer", result, targetBank, currentBankName)
            CloseMenu() -- [เพิ่ม] ปิดเมนูหลังโอน
        else
            VORPcore.NotifyRightTip(T.invalid, 4000)
        end
    end)
    cb('ok')
end)