Config = Config or {}

-- Inventory support:
-- qb-inventory, ps-inventory, lj-inventory, qs-inventory (Quasar), codem-inventory (mInventory Remake)
-- Set Config.Inventory to the system you use.
Config.Inventory = 'qb' -- 'qb' | 'ps' | 'lj' | 'qs' | 'codem'

-- Resource names (change only if you renamed the inventory resource folder)
Config.InventoryResources = {
  qb = 'qb-inventory',
  ps = 'ps-inventory',
  lj = 'lj-inventory',
  qs = 'qs-inventory',
  codem = 'codem-inventory',
}

Config.Debug = false

-- Jobs allowed to place/open/pickup
Config.AllowedJobs = {
  ambulance = true,
}

-- Item used to place the bag
Config.BagItem = 'medicalbag'

-- Prop model for the placed bag
Config.BagProp = `xm_prop_x17_bag_med_01a`

-- Stash settings
Config.Stash = {
  Label = 'Medical Bag',
  Slots = 30,
  Weight = 60000, -- grams (60kg)
}

-- Target options
Config.Target = {
  Distance = 2.0,
  IconOpen = 'fas fa-briefcase-medical',
  IconPickup = 'fas fa-hand',
}

-- Placement settings (ghost preview + rotate)
Config.Place = {
  MaxDistance = 3.0,
  GroundSnap = false,

  GhostAlpha = 160,          -- transparency of preview
  Step = 0.08,               -- forward/back step size
  RotateStep = 5.0,          -- degrees per keypress
  RayDistance = 6.0,         -- raycast length from camera
  ShowHelpText = true,

  -- Keybinds (GTA default controls)
  ConfirmKey = 38,           -- E
  CancelKey  = 177,          -- BACKSPACE
  RotateLeftKey  = 174,      -- LEFT arrow
  RotateRightKey = 175,      -- RIGHT arrow
  ForwardKey = 172,          -- UP arrow
  BackKey    = 173,          -- DOWN arrow
}
