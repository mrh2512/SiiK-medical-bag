# ukn-medical-bag Create and made by SiiK Scripts for UK Network / owners chops

Placeable EMS medical bag stash for **QBCore** using **qb-target** and **jpr-inventory** (JPResources).

## Features
- EMS (**job: ambulance**) can use `medicalbag` item to enter **ghost placement mode** (rotate + move + confirm/cancel)
- Bag becomes a world prop with qb-target interactions:
  - Open Medical Bag (stash)
  - Pick Up Medical Bag (works even if not empty; `stash_id` is saved in the bag item metadata so the same inventory returns when re-placed)
- Placed bags persist across restarts (saved in SQL table `siik_medical_bags`)

## Dependencies
- qb-core
- qb-target
- oxmysql
- jpr-inventory

## Install
1. Drop `ukn-medical-bag` into your resources folder.
2. Import `sql/medical_bags.sql`.
3. Add to `server.cfg`:
   ```
   ensure SiiK-medical-bag
   ```
4. Add item to your items file (e.g. `qb-core/shared/items.lua`):
   ```lua
   ['medicalbag'] = {
     name = 'medicalbag',
     label = 'Medical Bag',
     weight = 2000,
     type = 'item',
     image = 'medicalbag.png',
     unique = true,
     useable = true,
     shouldClose = true,
     description = 'Placeable EMS medical bag stash'
   },
   ```
5. Put `medicalbag.png` into your inventory images folder.

## Notes
- Bag stash open tries multiple compatible methods (export + client events).
- Pickup requires stash to be empty; if your inventory build doesn't expose stash-read exports, pickup refuses (anti-dupe safety).

## Notes
- Pickup stores `stash_id` inside the `medicalbag` item metadata (`info.stash_id`).
- When you place the bag again, the script reuses the same `stash_id`, so your items are still inside.
