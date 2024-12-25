---@class MountMerchantConfig
---@field capacity integer Number of mounts sold by this merchant
---@field selection MountIndex[] Set of mounts which this merchant sells. Uses numeric indices of the mountConfig table. It's up to you not to screw this up.

---@alias SupportedEffect
---| '"fatigueRestore"'
---| '"speedBonus"'
---| '"endurance"'
---| '"strength"'
---| '"intelligence"'
---| '"willpower"'
---| '"luck"'
---| '"agility"'
---| '"personality"'
---| '"speed"'

---@alias EffectMagnitude integer
---@alias EffectTable table<SupportedEffect, EffectMagnitude>

---@class MountContainerData
---@field carryCapacityBase integer Base carrying capacity of the container, before player strength scaling
---@field carryCapacityPerStrength integer Carrying capacity of the container per unit of player strength

---@class PetData
---@field baseId string recordId of the creature this one inherits from. Mandatory because some fields may not be set by scripts
---@field levelPct number percentage of the player's level (rounded) to use for the pet's level
---@field healthPct number percentage of the player's health (rounded) to use for the pet's health
---@field fatiguePct number percentage of the player's fatigue (rounded) to use for the pet's fatigue
---@field magickaPct number percentage of the player's magicka (rounded) to use for the pet's magicka
---@field damageChop integer base chop damage before player level scaling
---@field damageThrust integer base chop damage before player level scaling
---@field damageSlash integer base chop damage before player level scaling
---@field damagePerLevelPct number percentage of the base damage by which to scale the creature's, based on player level. Probably way too powerful
---@field chopMinDmgPct number percentage of the final damage calculation, to be used as minimum damage for the chop attack
---@field slashMinDmgPct number percentage of the final damage calculation, to be used as minimum damage for the slash attack
---@field thrustMinDmgPct number percentage of the final damage calculation, to be used as minimum damage for the thrust attack
---@field spells? string[] list of spells to teach the pet when it is summoned
---@field aura? EffectTable list of spell effects to grant to the player when the pet is summoned
---@field attributes table<string, number> percentage of each of the player's attributes to grant to the pet. Mandatory because not all fields may be set (properly) by the server.

--- All values are optional because they're filled in by `KeyItemTemplate` in dreamMount_functions
---@class MountKey
---@field value? integer
---@field weight? number
---@field icon? string
---@field model? string

---@class MountData
---@field name string Human-readable name of the mount. Used in a bunch of places
---@field item string recordId of the clothing item used by this mount
---@field model? string basename of the animation rig used by this mount. Only used for shirt type mounts
---@field mountedEffects? EffectTable Determines magical bonuses granted by this mount when summoned, but not mounted
---@field containerData? MountContainerData Determines weight capacity of the mount's container, if it has one
---@field petData? PetData Determines magical and visual statistics about the mount itself
---@field key? MountKey
---@field mountType? MountType Optional as it defaults to Shirt (1)

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
      mountedEffects = {
        endurance = 45,
        strength = 10,
        RestoreFatigue = MountDefaultFatigueRestore,
      },
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
          RestoreFatigue = 1,
          FortifyFatigue = 50,
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
      mountedEffects = {
        speed = 60,
        RestoreFatigue = MountDefaultFatigueRestore * 1.5,
      },
    },
    -- 3
    {
      -- Stronger feather, less damage
      name = "Pack Guar 2",
      item = 'rot_c_guar1A_shirt0',
      model = 'mountedguar1',
      mountedEffects = {
        speed = 60,
        RestoreFatigue = MountDefaultFatigueRestore * 1.5,
      },
    },
    -- 4
    {
      -- Buff strength & attack
      name = "Redoran War Guar",
      item = 'rot_c_guar2A_shirt0_redoranwar',
      model = 'mountedguar2',
      mountedEffects = {
        speed = 80,
        RestoreFatigue = MountDefaultFatigueRestore / 2,
      },
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
      mountedEffects = {
        speed = 80,
        RestoreFatigue = MountDefaultFatigueRestore * 2,
      },
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
      mountedEffects = {
        speed = 100,
        RestoreFatigue = MountDefaultFatigueRestore * 1.25,
      },
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
      mountedEffects = {
        speed = 200,
      },
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
    {
      name = "Mecha Gizka",
      id = "dm_mechagizka_shirt",
      partId = "dm_mechagizka",
    },
    {
      name = "Orange and Green Gizka",
      id = "dm_orangeandgreengizka_shirt",
      partId = "dm_orangeandgreengizka",
    },
    {
      name = "Orange and Black Gizka",
      id = "dm_orangeandblackgizka_shirt",
      partId = "dm_orangeandblackgizka",
    },
    {
      name = "Orange and Black Gizka (2)",
      id = "dm_orangeandblackgizka2_shirt",
      partId = "dm_orangeandblackgizka2",
    },
  },
}
