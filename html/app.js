(function () {
    // --- 1. DOM Elements ---
    const container = document.querySelector(".bank-container");
    const bankNameEl = document.getElementById("bank-name");
    const welcomeEl = document.getElementById("bank-welcome");
    const moneyEl = document.getElementById("stat-money");
    const goldEl = document.getElementById("stat-gold");
    const slotsEl = document.getElementById("stat-slots");

    const tabButtons = document.querySelectorAll(".tab-btn");
    const tabContents = document.querySelectorAll(".tab-content");

    // --- 2. Action Buttons (ตาม Logic เดิม) ---
    const btnDepositCash = document.getElementById("btn-deposit-cash");
    const btnWithdrawCash = document.getElementById("btn-withdraw-cash");
    const btnDepositGold = document.getElementById("btn-deposit-gold");
    const btnWithdrawGold = document.getElementById("btn-withdraw-gold");
    const btnOpenStorage = document.getElementById("btn-open-storage");
    const btnUpgradeStorage = document.getElementById("btn-upgrade-storage");
    const btnTransferConfirm = document.getElementById("btn-transfer-confirm");

    // --- 3. Transfer Elements ---
    const transferBankSelect = document.getElementById("transfer-bank-select");
    // [ลบ] const historyList = document.getElementById("history-list");

    // --- 4. State (เก็บข้อมูลที่ส่งมาจาก Lua) ---
    let currentTranslations = {};
    let currentAllBanks = [];
    let currentBankName = "";
    let currentConfig = {};

    // --- 5. NUI Post Function (ส่งข้อมูลกลับไป Lua) ---
    async function post(eventName, data = {}) {
        try {
            // [สำคัญ] ตั้งชื่อ Resource ของคุณให้ถูกต้อง
            const resourceName = "vorp_banking"; // (ถ้าคุณใช้ "vorp_banking-edit" ให้เปลี่ยนตรงนี้)

            const response = await fetch(`https://${resourceName}/${eventName}`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json; charset=UTF-8' },
                body: JSON.stringify(data)
            });
            
            if (!response.ok) {
                console.error(`NUI callback failed for ${eventName}`);
                return;
            }
            return await response.json();
        } catch (e) {
            console.error(`Error in post('${eventName}'):`, e);
        }
    }

    // --- 6. Window Message Listener (รับข้อมูลจาก Lua) ---
    window.addEventListener("message", function(event) {
        const data = event.data;
        if (data.action === "open") {
            container.style.display = "block";
            
            const bankInfo = data.bankInfo;
            currentConfig = data.config;
            currentTranslations = data.translations;
            currentAllBanks = data.allBanks || [];
            currentBankName = data.bankName; 

            // 6.1. อัปเดต Header & Stats
            bankNameEl.textContent = currentConfig.banks[currentBankName]?.name || currentBankName;
            welcomeEl.textContent = currentTranslations.welcome;
            moneyEl.textContent = "$" + (bankInfo.money ? bankInfo.money.toFixed(2) : "0.00");
            goldEl.textContent = (bankInfo.gold ? bankInfo.gold : "0") + " oz";
            slotsEl.textContent = `${bankInfo.invspace} Slots`;

            // 6.2. ซ่อน/แสดง แท็บ ตาม Config
            document.querySelector('[data-tab="gold"]').style.display = currentConfig.GlobalGold ? "flex" : "none";
            const showStorage = currentConfig.GlobalItems || currentConfig.GlobalUpgrade;
            document.querySelector('[data-tab="storage"]').style.display = showStorage ? "flex" : "none";
            
            // [แก้ไข] ซ่อนแท็บ "โอน" (เพราะเราใช้ Global Bank)
            // (ถ้าคุณยังต้องการใช้ระบบโอนเงิน ให้เปลี่ยน "none" เป็น "flex" ครับ)
            document.querySelector('[data-tab="transfer"]').style.display = "none"; 

            // 6.3. ซ่อน/แสดง ปุ่มในแท็บ "ตู้เซฟ"
            btnOpenStorage.style.display = currentConfig.GlobalItems ? "block" : "none";
            btnUpgradeStorage.style.display = currentConfig.GlobalUpgrade ? "block" : "none";

            // 6.4. สร้าง Dropdown "โอนเงิน" (เผื่อคุณเปิดใช้)
            transferBankSelect.innerHTML = "";
            currentAllBanks.forEach(bank => {
                if (bank.name !== currentBankName) {
                    const option = document.createElement("option");
                    option.value = bank.name;
                    option.textContent = `${bank.name} : ${bank.money}$`;
                    transferBankSelect.appendChild(option);
                }
            });

            // 6.5. [ลบ] ลบส่วนแสดงผลประวัติธุรกรรม

            // 6.6. รีเซ็ตกลับไปแท็บแรก
            tabButtons.forEach(btn => btn.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('active'));
            tabButtons[0].classList.add('active');
            tabContents[0].classList.add('active');

        } else if (data.action === "close") {
            container.style.display = "none";
        }
    });

    // --- 7. Tab system logic (สลับแท็บ) ---
    tabButtons.forEach(button => {
        button.addEventListener("click", () => {
            tabButtons.forEach(btn => btn.classList.remove('active'));
            tabContents.forEach(content => content.classList.remove('active'));
            button.classList.add('active');
            document.getElementById(`tab-${button.dataset.tab}`).classList.add('active');
        });
    });

    // --- 8. All button listeners (อ้างอิง Logic เดิม) ---
    btnDepositCash.addEventListener("click", () => post("depositCash"));
    btnWithdrawCash.addEventListener("click", () => post("withdrawCash"));
    btnDepositGold.addEventListener("click", () => post("depositGold"));
    btnWithdrawGold.addEventListener("click", () => post("withdrawGold"));
    btnUpgradeStorage.addEventListener("click", () => post("upgradeStorage"));
    btnOpenStorage.addEventListener("click", () => post("openStorage"));
    btnTransferConfirm.addEventListener("click", () => {
        const targetBank = transferBankSelect.value;
        if (targetBank) {
            post("transferMoney", { targetBankName: targetBank });
        }
    });

    // --- 9. ESC Listener (กด ESC เพื่อปิด) ---
    document.addEventListener("keydown", function(e) {
        if (e.key === "Escape") {
            post("close");
        }
    });

})();