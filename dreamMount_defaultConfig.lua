---@class MountMerchantConfig
---@field capacity integer Number of mounts sold by this merchant
---@field selection MountIndex[] Set of mounts which this merchant sells. Uses numeric indices of the mountConfig table. It's up to you not to screw this up.

---@class MountData
---@field name string Human-readable name of the mount. Used in a bunch of places
---@field item string recordId of the clothing item used by this mount
---@field model? string basename of the animation rig used by this mount. Only used for shirt type mounts

---@class BodyPart Bodypart record data used by generated clothing records for mounts
---@field id string record id of the bodypart to use
---@field model string path relative to meshes/ used for the bodypart record
---Part field is hardcoded to 14 (tail) and refers to the actual bodypart slot used
---Subtype refers to skin/armor/clothing and is 1 (clothing)

---@class ClothingRecord
---@field name string Visible string of the clothing record
---@field id string record id of the mount clothing. *must* be unique.
---@field partId string Bodypart record which is used by this item
---NOTE: This method only supports creating shirts, and at that, creating shirts which have one bodypart slot
---We may want to expand or change this later, but it's currently unknown how much leeway we have to do that

---@enum MerchantName
local MerchantID = {
    ald_ruhn = "galtis guvron",
    ald_velothi = "sedam omalen",
    balmora = "ra'virr",
    caldera = "verick gemain",
    gnisis = "fenas madach",
    hla_oad = "perien aurelie",
    khuul = "thongar",
    mournhold = "ten-tongues_weerhat",
    raven_rock = "sathyn andrano",
    seyda_neen = 'arrille',
    suran = "ralds oril",
    vivec = "mevel fererus",
}

local MountDefaultFatigueRestore = 3

return {
  ---@type { [MerchantName]: MountMerchantConfig}
  Merchants = {
    [MerchantID.ald_ruhn] = {
      capacity = 1,
      selection = { 4 }
    },
    [MerchantID.ald_velothi] = {
      capacity = 1,
      selection = { 1 }
    },
    [MerchantID.balmora] = {
      capacity = 3,
      selection = { 1, 2 }
    },
    [MerchantID.caldera] = {
      capacity = 2,
      selection = { 3, 4 }
    },
    [MerchantID.gnisis] = {
      capacity = 1,
      selection = { 2 }
    },
    [MerchantID.hla_oad] = {
      capacity = 2,
      selection = { 2, 3 }
    },
    [MerchantID.khuul] = {
      capacity = 1,
      selection = { 1 }
    },
    [MerchantID.mournhold] = {
      capacity = 3,
      selection = { 4, 6, 2 }
    },
    [MerchantID.raven_rock] = {
      capacity = 3,
      selection = { 5, 6, 3 }
    },
    [MerchantID.seyda_neen] = {
      capacity = 3,
      selection = { 1, 2, 3 }
    },
    [MerchantID.suran] = {
      capacity = 1,
      selection = { 3 }
    },
    [MerchantID.vivec] = {
      capacity = 3,
      selection = { 3, 5, 2 }
    },
  },
  ---@type MountData[]
  Mounts = {
    -- 1
    {
      name = 'Guar',
      item = 'rot_c_guar00_shirtC3',
      model = 'mountedguar2',
      speedBonus = 70,
      fatigueRestore = MountDefaultFatigueRestore,
      petData = {
        baseId = "guar",
        levelPct = 0.50,
        healthPct = 0.50,
        magickaPct = 0.50,
        fatiguePct = 0.50,
        damageChop = 3,
        damageSlash = 3,
        damageThrust = 3,
        damagePerLevelPct = 0.03,
        chopMinDmgPct = 0.40,
        slashMinDmgPct = 0.40,
        thrustMinDmgPct = 0.40,
        attributes = {
          Strength = 0.60,
          Intelligence = 0.20,
          Agility = 0.90,
          Willpower = 0.35,
          Luck = 0.80,
          Personality = 0.20,
          Speed = 1.25,
        },
        aura = {
          fatigueRestore = 1,
          fatigueFortify = 50,
        },
        spells = {},
      },
      containerData = {
        carryCapacityBase = 30,
        carryCapacityPerStrength = 1.25,
      }
    },
    -- 2
    {
      -- Weaker feather, more damage
      name = "Pack Guar 1",
      item = 'rot_c_guar1B_shirtC3',
      model = 'mountedguar1',
      speedBonus = 60,
      fatigueRestore = MountDefaultFatigueRestore * 1.5,
    },
    -- 3
    {
      -- Stronger feather, less damage
      name = "Pack Guar 2",
      item = 'rot_c_guar1A_shirt0',
      model = 'mountedguar1',
      speedBonus = 60,
      fatigueRestore = MountDefaultFatigueRestore * 1.5,
    },
    -- 4
    {
      -- Buff strength & attack
      name = "Redoran War Guar",
      item = 'rot_c_guar2A_shirt0_redoranwar',
      model = 'mountedguar2',
      speedBonus = 80,
      fatigueRestore = MountDefaultFatigueRestore / 2,
      key = {
        icon = "c/tx_belt_expensive03.dds",
        model = "c/c_belt_expensive_3.nif",
      }
    },
    -- 5
    {
      -- Large personality buff, illusion buff
      name = "Guar with Drapery (Fine)",
      item = 'rot_c_guar2B_shirt0_ordinator',
      model = 'mountedguar2',
      speedBonus = 80,
      fatigueRestore = MountDefaultFatigueRestore * 2,
      key = {
        icon = "c/tx_belt_exquisite01.dds",
        model = "c/c_belt_exquisite_1.nif",
      },
    },
    -- 6
    {
      -- Smaller personality buff, mysticism buff
      name = "Guar with Drapery (Simple)",
      item = 'rot_c_guar2C_shirt0_scout',
      model = 'mountedguar2',
      speedBonus = 100,
      fatigueRestore = MountDefaultFatigueRestore * 1.25,
      key = {
        icon = "c/tx_belt_exquisite01.dds",
        model = "c/c_belt_exquisite_1.nif",
      },
    },
    -- 7
    {
      -- Not a pet
      name = "Red Speeder",
      item = 'sw_speeder1test',
      mountType = 0,
      speedBonus = 200,
      key = {
        name = "Red Speeder Key",
        value = 5000,
      },
    },
  },
  ---@type BodyPart[]
  Parts = {
    {
      id = "dm_mechagizka",
      model = "s3/mount/gizka/mechagizka.nif",
    },
    {
      id = "dm_orangegizka",
      model = "s3/mount/gizka/gizkaora.nif",
    },
    {
      id = "dm_orangeandblackgizka",
      model = "s3/mount/gizka/gizkaorabl.nif",
    },
    {
      id = "dm_orangeandblackgizka2",
      model = "s3/mount/gizka/gizkaorabl2.nif"
    },
    {
      id = "dm_orangeandgreengizka",
      model = "s3/mount/gizka/gizkaoragr.nif"
    },
    {
      id = "dm_redgizka",
      model = "s3/mount/gizka/gizkared.nif",
    },
  },
  ---@type ClothingRecord[]
  Clothes = {
    {
      name = "Red Gizka",
      id = "dm_redgizka_shirt",
      partId = "dm_redgizka",
    },
    {
      name = "Orange Gizka",
      id = "dm_ojgizka_shirt",
      partId = "dm_orangegizka",
    },
  },
}
