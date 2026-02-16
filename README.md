🩺 SiiK Medical Bag (QBCore)

https://github.com/mrh2512/SiiK-bridge

A simple and optimized medical bag system for QBCore servers with multi-inventory support.

Players can place and open a medical bag which acts as a stash. Supports multiple popular inventory systems via configuration.

✅ Supported Inventories

You can now choose which inventory system to use directly in the config.

Supported:

qb-inventory

ps-inventory

lj-inventory

qs-inventory (Quasar Inventory)

codem-inventory (mInventory Remake)

📦 Installation

Place the resource in your resources folder.

Ensure the resource in server.cfg:

ensure SiiK-medical-bag


Set your preferred inventory in shared/config.lua.

⚙️ Configuration

Open:

shared/config.lua

Select Inventory
Config.Inventory = 'qb' -- 'qb' | 'ps' | 'lj' | 'qs' | 'codem'

If Your Inventory Folder Has a Custom Name
Config.InventoryResources = {
  qb = 'qb-inventory',
  ps = 'ps-inventory',
  lj = 'lj-inventory',
  qs = 'qs-inventory',
  codem = 'codem-inventory',
}


If you renamed your inventory resource, change it here.

Example:

qb = 'my-qb-inventory'

🧠 How It Works

Depending on your selected inventory:

qb / ps / lj → Uses OpenInventory export

qs-inventory → Uses RegisterStash and opens stash

codem-inventory → Uses codem-inventory:server:openstash event

Each bag creates a unique stash ID to prevent conflicts.

🔧 Features

Fully QBCore compatible

Multi-inventory support

Unique stash per bag

Clean and optimized code

Easy configuration

Lightweight

❗ Requirements

QBCore framework

One of the supported inventory systems

🛠 Troubleshooting
Bag does not open

Make sure your selected inventory matches Config.Inventory

Ensure the inventory resource name matches Config.InventoryResources

Confirm your inventory is started before this resource in server.cfg

Example order:

ensure qb-core
ensure qb-inventory
ensure SiiK-medical-bag

💡 Notes

If using qs-inventory, make sure it supports RegisterStash

If using codem-inventory, ensure you are using the mInventory Remake version

Do not run multiple inventory systems at the same time
   ```
4. Add item to your items file (e.g. `qb-core/shared/items.lua`):
   ```lua
["medicalbag"]         = {["name"] = "medicalbag",       ["label"] = "Medical Bag",       ["weight"] = 300,     ["type"] = "item",         ["image"] = "medicalbag.png",        ["unique"] = true,     ["useable"] = true,     ["shouldClose"] = true,   ["combinable"] = nil, ["description"] = "Medical Bag"},
   ```
5. Put `medicalbag.png` into your inventory images folder.

## Notes
- Bag stash open tries multiple compatible methods (export + client events).
- Pickup requires stash to be empty; if your inventory build doesn't expose stash-read exports, pickup refuses (anti-dupe safety).

## Notes
- Pickup stores `stash_id` inside the `medicalbag` item metadata (`info.stash_id`).
- When you place the bag again, the script reuses the same `stash_id`, so your items are still inside.


## Inventory Bridge Support
This version supports `SiiK-bridge` (auto-detect). Ensure `SiiK-bridge` is started before this resource.
`Config.UseBridge = true` in `shared/config.lua`.
