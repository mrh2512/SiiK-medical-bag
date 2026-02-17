A portable personal stash system for medical roleplay.

Supports:

✅ qb-inventory v2.0.0+

✅ qs-inventory

✅ Gamebuild 3095+

✅ Auto stash registration

✅ Safe model loading with fallback

📦 Requirements

qb-core

qb-inventory v2.0.0+ OR

qs-inventory

Gamebuild 3095+ recommended

🔧 INSTALLATION GUIDE
1️⃣ Place Resource

Drop the folder into:

resources/[qb]/SiiK-medical-bag


Add to server.cfg:

ensure SiiK-medical-bag


Make sure it starts after:

ensure qb-core
ensure qb-inventory (or qs-inventory)

2️⃣ Add The Item (VERY IMPORTANT)

Open:

qb-inventory/shared/items.lua


Add:

["medicalbag"] = {
    name = "medicalbag",
    label = "Medical Bag",
    weight = 1000,
    type = "item",
    image = "medicalbag.png",
    unique = true,
    useable = true,
    shouldClose = true,
    description = "A portable medical supply bag."
},


⚠️ unique = true is REQUIRED
⚠️ The name MUST match:

Config.BagItem = "medicalbag"


Restart your server after adding the item.

3️⃣ Configure Inventory Type

Open:

shared/config.lua


Set one of these:

For qb-inventory v2:
Config.Inventory = 'qb'

For qs-inventory:
Config.Inventory = 'qs'

4️⃣ Stash Settings

Inside config:

Config.Stash = {
    slots = 20,
    weight = 10000, -- qb-inventory uses grams (10000 = 10kg)
}


Adjust as needed.

5️⃣ Job Restriction (Optional)
Config.JobRestricted = true

Config.AllowedJobs = {
    ambulance = true,
    doctor = true,
}


If disabled:

Config.JobRestricted = false

🧠 How It Works

Player uses medical bag item

Script generates a unique stash ID

Inventory is registered automatically

Stash opens via qb-inventory v2 or qs-inventory

Each bag has its own storage

🎒 Bag Model

Default model:

xm_prop_x17_bag_med_01a


If that ever fails to load, the script automatically falls back to:

prop_ld_health_pack


You can change it in:

shared/config.lua


Example:

Config.BagProp = "prop_ld_health_pack"

❗ TROUBLESHOOTING
❌ SCRIPT ERROR table index is nil

✔ Make sure:

Config.BagItem = "medicalbag"


Matches your item name exactly.

❌ Bag model failed to load

✔ You are on build 3095+
✔ Config.BagProp is correct
✔ Resource restarted

If needed, switch to:

Config.BagProp = "prop_ld_health_pack"

❌ Bag opens but stash empty every time

Make sure:

unique = true


Is set on the item.

❌ Nothing happens when using bag

Ensure qb-core started first

Ensure inventory started first

Ensure item exists

Restart server fully (not just resource)

🛠 Supported Inventory Functions
qb-inventory v2:

OpenInventory

RegisterInventory

CreateInventory

GetInventory

qs-inventory:

RegisterStash

OpenInventory

🔥 Recommended Server Order
ensure qb-core
ensure qb-inventory
ensure SiiK-medical-bag

❤️ Credits

Original script: SiiK
Updated for qb-inventory v2 & qs-inventory compatibility
Model loading & stability fixes included