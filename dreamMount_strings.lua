local Format = string.format

local color = color
local Green = color.Green
local Maroon = color.Maroon
local MediumBlue = color.MediumBlue
local Navy = color.Navy
local Red = color.Red

return {

  Paths = {
    AnimRigPath = 'rot/anim/%s.nif',
    BodyPartConfigPath = 'custom/dreamMountBodyParts.json',
    MerchantConfigPath = 'custom/dreamMountMerchants.json',
    ClothingConfigPath = 'custom/dreamMountClothing.json',
    MountConfigPath = 'custom/dreamMountConfig.json',
  },

  Err = {
    CreatePetNoIdErr = "No petId was provided to create the pet record!\n",
    CreatePetNoMountNameErr = "No mountName was provided to create the pet record!\n",
    CreatePetNoPetDataErr = "No playerPetData was provided to create the pet record!\n",
    CreatePetNoPlayerErr = "No player was provided to create the pet record!\n",
    DespawnNoPlayerErr = "despawnMountSummon was called without providing a player!\n",
    InvalidSpellEffectErrorStr = 'Cannot create a spell effect with no magnitude!\n',
    MerchantNotInCell = "Unable to locate actor by index in this cell!\n",
    MissingMountName = 'No mount name!',
    MountDoesNotExistErr = "%s's preferred mount does not exist in the mount config map!",
    NilCellErr = "Unable to read cell in reloadMountMerchants call!\n%s",
    NilObjectDataErr = "Received nil objectData in reloadMountMerchantsCall!\n%s",
    NilInventoryErr = "Received nil currentInventory in reloadMountMerchantsCall!\n%s",
    NoInventoryErr = 'No player inventory was provided to createMountMenuString!\n%s',
    NoPidProvided = 'No PlayerID provided!\n%s',
    NoPrevMountErr = 'No previous mount to remove for player %s, aborting!',
    ShouldHaveValidMountErr = "Player shouldn't have been able to open this menu without a valid mount!",
    UnloggedPlayerSummonErr = "Cannot summon a mount for an unlogged player!",
    EmptyMountConfigErr = "Empty mount config found on reload!\n",
    ActivateChoiceFailedToConvertErr = "failed to convert activation menu choice to a number, or none provided!",
    NoContainerForUnloggedPlayerErr = "Cannot activate container for an unlogged player!",
    ImpossibleActivationErr = "You can't have activated this object if you don't have a pet assigned!",
    ImpossibleUnloadedCellErr = "The cellDescription requested isn't loaded! This should never happen!\n",
    ImpossibleObjectDataErr = "Object data should have been initialized already, but it isn'! Bailing!\n",
    ImpossibleRefidErr = "Found null or empty refId during inventory iteration!\n",
    ImpossibleMountNameErr = "All mounts must have a name!",
    ImpossibleAttributeIDErr = "Invalid attribute ID provided: %s!",
    ImpossibleAttributeNameErr = "Invalid attribute name %s provided!\n%s",
    MissingSummonRefNumErr = "Refnum for player summon was either missing or failed to split!",
    InvalidBodyPartDataErr = "Id and model fields are required for all bodypart instances!\n",
    InvalidClothingDataErr = "Id, name, and partId fields are required for all clothing instances!\n",
  },

  Patterns = {
    LogStr = '[ %s ]: %s',
    MenuItem = '%s\n%s',
    NoPreferredMountMessage = '%s%s %s',
    SingleVarReset = '%s%s.\n',
    SpellNameTemplate = '%s Speed Buff',
  },

  Log = {
    CreatedSpellRecordStr = 'Created spell record %s',
    DismissedStr = "%s dismissed their mount!",
    DismountStr = '%s dismounted from mount of type: %s, replacing previously equipped item: %s',
    LogPrefix = 'DreamMount',
    MountActivatedStr = "%s activated their mount %s with index %s in cell %s",
    MountStr = '%s mounted %s',
    MountSummonSpawnedStr = "Spawned mount summon %s for player %s in %s as object %s",
    RemovingRecordStr = "Removing %s from recordStore on behalf of %s",
    SuccessfulContainerDespawnStr = "Successfully despawned old %s container with index %s for player %s",
  },

  UI = {
    ActivateMenuChoices = "Open Pack;Dismiss;Pet;Ride;Nothing",
    ActivateMenuHeader = "What would you like to do with your mount?",
    AllDefaultConfigsSaved = Format(
      "%sReset all %sDreamMount%s Configuration Files to their defaults!\n",
      Green,
      MediumBlue,
      Green
    ),
    ConfigReloadedMessage = Format(
      '%sMount config reloaded, %smenu reconstructed, %sand spell records remade! %sDreamMount%s has completely reinitialized.\n',
      MediumBlue,
      Green,
      MediumBlue,
      Navy,
      Green),
    DefaultConfigsReloading = Format(
      "%sReloading all %sDreamMount%s Configuration Files!\n",
      Green,
      MediumBlue,
      Green
    ),
    DefaultConfigSavedString = Format(
      '%sSaved default mount config to %sdata/',
      MediumBlue,
      Green),
    DefaultListString = "Cancel",
    InvalidResetPidErr = "%sInvalid player id provided for variable reset %s!\n",
    MissingMountKey = Red .. "You don't have the key for your mount!\n",
    MountMustBeSummonedStr = Red .. "Your currently selected mount must be summoned to use its container!\n",
    NoContainerDataErr = "This mount does not have any container data!\n",
    NoMountAvailableStr = Format(
      '%sYou do not have any mounts available! Seek one out in the world . . .\n',
      Maroon),
    NoPreferredMountStr = Format(
      '%sdoes not have a preferred mount set!\n',
      Red),
    NotAPetStr = "%s%s cannot be used as a pet!",
    PreferredMountMenuHeaderStr = "%s Your current one is: %s",
    PreferredMountString = 'Select your preferred mount.',
    ResetNotAllowedErr = "%sYou cannot reset DreamMount Variables for %s!\n",
    ResetVarsString = Format(
      '%sReset DreamMount variables for %s',
      MediumBlue,
      Green),
    SameMountStr = "%s%s%s was already your preferred mount!\n",
    UnauthorizedUserMessage = Format(
      '%sYou are not authorized to run %sdreamMount %sadmin commands!\n',
      Red,
      MediumBlue,
      Red),
    UnownedMountActivateStr = Red .. "You cannot activate this mount as it does not belong to you!",
  }

}
