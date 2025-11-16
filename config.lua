Config                    = {}

Config.Lang               = "English"

Config.WithdrawLogWebhook = ""

Config.DepositLogWebhook  = ""

Config.TransferLogWebhook = ""

Config.TakeLogWebhook     = ""

Config.MoveLogWebhook     = ""

Config.Key                = 0x760A9C6F -- [G]

Config.banktransfer       = true       -- If you want to use bank transfer

Config.feeamount          = 0.9        -- 0.9 is 10% of the transferred amount, 0.5 is 50% of the transferred amount, 0.7 is 30% of the transferred amount

Config.GlobalBankName = "GlobalBank" -- ชื่อบัญชีกลางในฐานข้อมูล (ห้ามเปลี่ยนหากไม่จำเป็น)

-- การตั้งค่ากลางสำหรับเมนูธนาคาร --
Config.GlobalGold = true           -- เปิด/ปิด การฝาก-ถอนทอง (ส่วนกลาง)
Config.GlobalItems = true          -- เปิด/ปิด ระบบเซฟบ็อกซ์ (ส่วนกลาง)
Config.GlobalUpgrade = true        -- เปิด/ปิด การอัปเกรดช่อง (ส่วนกลาง)
Config.GlobalCanStoreWeapons = true  -- เปิด/ปิด การเก็บอาวุธ (ส่วนกลาง)
Config.GlobalCostSlot = 10         -- ราคาอัปเกรด (ส่วนกลาง)
Config.GlobalMaxSlots = 100        -- จำนวนช่องสูงสุด (ส่วนกลาง)

Config.banks              = {

    Valentine = {                                              -- Names must be the same in databse BANKS TABLE
        city = "Valentine",                                    -- Names must be the same in databse BANKS TABLE
        name = "Valentine Bank",
        BankLocation = {x = -308.49, y = 782.4, z = 118.76}, -- Bank Location (X, Y, Z)
        blipsprite = -2128054417,
        blipAllowed = true,
        NpcAllowed = true,
        NpcModel = "S_M_M_BankClerk_01",
        NpcPosition = {x = -308.49, y = 782.4, z = 118.76, h = 357.62 }, -- NPC Postition (X, Y, Z, H)
        StoreHoursAllowed = false,
        StoreOpen = 7,                                                   -- am
        StoreClose = 22,                                                 -- pm
        distOpen = 3.5,
        gold = true,                                                     -- If you want deposit and withdraw gold
        items = true,                                                    -- If you want use safebox
        upgrade = true,                                                  -- If you want upgrade safebox
        costslot = 10,                                                   -- choose price for upgrade + 1 slot
        maxslots = 100,                                                  -- choose max slots for upgrade
        canStoreWeapons = true,
    },
Blackwater = {
        name = "Blackwater Bank",
        BankLocation = { x = -813.18, y = -1277.60, z = 43.68 },
        city = "Blackwater",
        blipsprite = -2128054417,
        blipAllowed = true,
        NpcAllowed = true,
        NpcModel = "S_M_M_BankClerk_01",
        NpcPosition = { x = -813.18, y = -1275.42, z = 42.64, h = 176.86 },
        StoreHoursAllowed = false,
        StoreOpen = 7,   -- am
        StoreClose = 21, -- pm
        distOpen = 3.5,
        gold = true,
        items = true,
        upgrade = true,
        costslot = 10,
        maxslots = 100,
        canStoreWeapons = true,

    },

    SaintDenis = {
        city = "SaintDenis",
        name = "Saint Denis Bank",
        BankLocation = { x = 2644.08, y = -1292.21, z = 52.29 },
        blipsprite = -2128054417,
        blipAllowed = true,
        NpcAllowed = true,
        NpcModel = "S_M_M_BankClerk_01",
        NpcPosition = { x = 2645.12, y = -1294.37, z = 51.25, h = 30.64 },
        StoreHoursAllowed = false,
        StoreOpen = 7,   -- am
        StoreClose = 23, -- pm
        distOpen = 3.5,
        gold = true,
        items = true,
        upgrade = true,
        costslot = 10,
        maxslots = 100,
        canStoreWeapons = true,


    },

    Rhodes = {
        name = "Rhodes Bank",
        BankLocation = { x = 1294.14, y = -1303.06, z = 77.04 },
        city = "Rhodes",
        blipsprite = -2128054417,
        blipAllowed = true,
        NpcAllowed = true,
        NpcModel = "S_M_M_BankClerk_01",
        NpcPosition = { x = 1292.84, y = -1304.74, z = 76.04, h = 327.08 },
        StoreHoursAllowed = false,
        StoreOpen = 7,   -- am
        StoreClose = 21, -- pm
        distOpen = 3.5,
        gold = false,
        items = false,
        upgrade = false,
        costslot = 10,
        maxslots = 50,
        canStoreWeapons = true,

    },
}
