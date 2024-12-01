local Concat = table.concat
local Format = string.format

local AddSpell = tes3mp.AddSpell
local AddItem = inventoryHelper.addItem
local ClearSpellbookChanges = tes3mp.ClearSpellbookChanges
local ContainsItem = inventoryHelper.containsItem
local ListBox = tes3mp.ListBox
local Load = jsonInterface.load
local RemoveClosestItem = inventoryHelper.removeClosestItem
local RunConsoleCommandOnPlayer = logicHandler.RunConsoleCommandOnPlayer
local Save = jsonInterface.quicksave
local SendBaseInfo = tes3mp.SendBaseInfo
local SendMessage = tes3mp.SendMessage
local SendSpellbookChanges = tes3mp.SendSpellbookChanges
local SetModel = tes3mp.SetModel
local SetSpellbookChangesAction = tes3mp.SetSpellbookChangesAction
local SlowSave = jsonInterface.save

local Players = Players

local AddToInventory = enumerations.inventory.ADD
local FortifyAttribute = enumerations.effects.FORTIFY_ATTRIBUTE
-- local LeftGauntletSlot = enumerations.equipment.LEFT_GAUNTLET
local RemoveFromInventory = enumerations.inventory.REMOVE
local RestoreFatigue = enumerations.effects.RESTORE_FATIGUE
local ShirtSlot = enumerations.equipment.SHIRT
local SpellbookAdd = enumerations.spellbook.ADD
local SpellbookRemove = enumerations.spellbook.REMOVE

local DreamMountsGUIID = 381342
local DreamMountConfigPath = 'custom/dreamMountConfig.json'
local GuarMountFilePathStr = 'rot/anim/%s.nif'

local DreamMountListString
local DreamMountDefaultConfigSavedString =
    Format('%sSaved default mount config to %sdata/%s\n'
    , color.MediumBlue, color.Green, DreamMountConfigPath)

local DreamMountUnauthorizedUserMessage =
    Format('%sYou are not authorized to run %sdreamMount %sadmin commands!\n'
    , color.Red, color.MediumBlue, color.Red)

local DreamMountConfigReloadedMessage =
    Format(
    '%sMount config reloaded, %smenu reconstructed, %sand spell records remade! %sDreamMount%s has completely reinitialized.\n'
    , color.MediumBlue, color.Green, color.MediumBlue, color.Navy, color.Green)

local DreamMountResetVarsString = Format('%sReset DreamMount variables for %s'
, color.MediumBlue, color.Green)

local DreamMountNoPreferredMountStr = Format('%sdoes not have a preferred mount set!\n'
                                             , color.Red)
local DreamMountNoPreferredMountMessage = '%s%s %s'

local DreamMountNoStarwindStr = Format('%sStarwind%s mounts not yet supported!\n'
                                       , color.MediumBlue, color.Red)

local DreamMountPreferredMountString = 'Select your preferred mount.'

local DreamMountSingleVarResetPattern = '%s%s.\n'
local DreamMountMenuItemPattern = '%s\n%s'
local DreamMountSpellNameTemplate = '%s Speed Buff'
local DreamMountLogPrefix = 'DreamMount'
local DreamMountLogStr = '[ %s ]: %s'

local DreamMountEquipCommandStr = 'player->equip %s'

local DreamMountNoPidProvided = 'No PlayerID provided!\n%s'
local DreamMountInvalidSpellEffectErrorStr = 'Cannot create a spell effect with no magnitude!'
local DreamMountNoPrevMountErr = 'No previous mount to remove, aborting!'
local DreamMountMissingMountName = 'No mount name!'
local DreamMountCreatedSpellRecordStr = 'Created spell record %s'
local DreamMountDismountStr = '%s dismounted from mount of type: %s, replacing previously equipped item: %s'
local DreamMountMountStr = '%s mounted %s'

local DreamMountEnabledKey = 'dreamMountIsMounted'
local DreamMountPreferredMountKey = 'dreamMountPreferredMount'
local DreamMountPrevMountTypeKey = 'dreamMountPreviousMountType'
local DreamMountPrevItemId = 'dreamMountPreviousItemId'

local DreamMountAdminRankRequired = 2

local MountDefaultFatigueRestore = 3

local GauntletMountType = 0
local ShirtMountType = 1

local DreamMountConfig = {}

local DreamMountConfigDefault = {
    {
        name = 'Guar',
        item = 'rot_c_guar00_shirtC3',
        model = 'mountedguar2',
        speedBonus = 70,
        fatigueRestore = MountDefaultFatigueRestore,
    },
    {
        name = "Pack Guar 1",
        item = 'rot_c_guar1B_shirtC3',
        model = 'mountedguar1',
        speedBonus = 60,
        fatigueRestore = MountDefaultFatigueRestore,
    },
    {
        name = "Pack Guar 2",
        item = 'rot_c_guar1A_shirt0',
        model = 'mountedguar1',
        speedBonus = 60,
        fatigueRestore = MountDefaultFatigueRestore,
    },
    {
        name = "Redoran War Guar",
        item = 'rot_c_guar2A_shirt0_redoranwar',
        model = 'mountedguar2',
        speedBonus = 80,
        fatigueRestore = MountDefaultFatigueRestore / 2,
    },
    {
        name = "Guar with Drapery (Fine)",
        item = 'rot_c_guar2B_shirt0_ordinator',
        model = 'mountedguar2',
        speedBonus = 100,
        fatigueRestore = MountDefaultFatigueRestore * 2,
    },
    {
        name = "Guar with Drapery (Simple)",
        item = 'rot_c_guar2C_shirt0_scout',
        model = 'mountedguar2',
        speedBonus = 100,
        fatigueRestore = MountDefaultFatigueRestore * 1.25,
    }
}

local TemplateEffects = {
    FortifySpeed = {
        attribute = 4,
        area = 0,
        duration = 0,
        id = FortifyAttribute,
        rangeType = 0,
        skill = -1,
        magnitudeMin = nil,
        magnitudeMax = nil
    },
    RestoreFatigue = {
        attribute = -1,
        area = 0,
        duration = 0,
        id = RestoreFatigue,
        rangeType = 0,
        skill = -1,
        magnitudeMin = 3,
        magnitudeMax = 3
    },
}

local InventoryItemTemplate = {
    charge = -1,
    count = 1,
    refId = '',
    soul = '',
}

local function mountLog(message)
    print(Format(DreamMountLogStr, DreamMountLogPrefix, message))
end

local function getTemplateEffect(templateEffect, magnitude)
    assert(magnitude and magnitude > 0, DreamMountInvalidSpellEffectErrorStr)
    local effect = {}
    for k, v in pairs(templateEffect) do effect[k] = v end
    effect.magnitudeMin = magnitude
    effect.magnitudeMax = magnitude
    return effect
end

local function getRestoreFatigueEffect(magnitude)
    return getTemplateEffect(TemplateEffects.RestoreFatigue, magnitude)
end

local function getFortifySpeedEffect(magnitude)
    return getTemplateEffect(TemplateEffects.FortifySpeed, magnitude)
end

local function getFilePath(model)
    return Format(GuarMountFilePathStr, model)
end

local function getMountSpellIdString(mountIndex)
    return Format(DreamMountSpellNameTemplate, DreamMountConfig[mountIndex].item)
end

local function getMountSpellNameString(mountIndex)
    return Format(DreamMountSpellNameTemplate, DreamMountConfig[mountIndex].name)
end

local function getMountEffect(effectTable, mountIndex)
    return getMountSpellIdString(mountIndex),
        {
            name = getMountSpellNameString(mountIndex),
            subtype = 1,
            cost = 0,
            flags = 0,
            effects = effectTable
        }
end

local function mountEquipCommand(refId)
    return Format(DreamMountEquipCommandStr, refId)
end

local function addOrRemoveItem(addOrRemove, mount, player)
    local inventory = player.data.inventory
    local hasMountAlready = ContainsItem(inventory, mount)

    if addOrRemove == hasMountAlready then return end

    (addOrRemove and AddItem or RemoveClosestItem)(inventory, mount, 1)

    local inventoryItem = InventoryItemTemplate
    inventoryItem.refId = mount

    player:LoadItemChanges ({ inventoryItem, }, (addOrRemove and AddToInventory or RemoveFromInventory))
end

local function enableModelOverrideMount(player, characterData, mountModel)
    characterData.modelOverride = getFilePath(mountModel)
    player:LoadCharacter()
end

local function toggleMount(pid, player)
    local playerData = player.data
    local customVariables = playerData.customVariables
    local charData = playerData.character
    local isMounted = customVariables[DreamMountEnabledKey]
    local mountIndex = customVariables[DreamMountPreferredMountKey]

    if not isMounted then

        if not mountIndex then
            SendMessage(pid, Format(DreamMountNoPreferredMountMessage
                                    , color.Yellow, player.name, DreamMountNoPreferredMountStr))
            return
        end

        local mount = DreamMountConfig[mountIndex]
        local mountId = mount.item
        local targetSlot = mount.slot or ShirtSlot
        local replaceItem = playerData.equipment[targetSlot]

        customVariables[DreamMountPrevItemId] = (replaceItem.refId ~= '' and replaceItem.refId) or nil

        addOrRemoveItem(true, mountId, player)
        RunConsoleCommandOnPlayer(pid, mountEquipCommand(mountId), false)

        local mountType = mount.type

        if not mountType or mountType == ShirtMountType then
            enableModelOverrideMount(player, charData, mount.model)
        elseif mountType == GauntletMountType then
            SendMessage(pid, DreamMountNoStarwindStr, false)
            return
        end

        mountLog(Format(DreamMountMountStr, player.name, DreamMountConfig[mountIndex].name))

        customVariables[DreamMountPrevMountTypeKey] = mountType or ShirtMountType
        customVariables[DreamMountEnabledKey] = true
    else
        for _, mountData in ipairs(DreamMountConfig) do
            addOrRemoveItem(false, mountData.item, player)
        end

        local lastMountType = customVariables[DreamMountPrevMountTypeKey]

        if not lastMountType then
            error(DreamMountNoPrevMountErr)
        elseif lastMountType == ShirtMountType then
            charData.modelOverride = nil
            SetModel(pid, '')
            SendBaseInfo(pid)
        elseif lastMountType == GauntletMountType then
            SendMessage(pid, DreamMountNoStarwindStr, false)
            return
        end

        local prevItemId = customVariables[DreamMountPrevItemId]
        if prevItemId and ContainsItem(playerData.inventory, prevItemId) then
            RunConsoleCommandOnPlayer(pid, mountEquipCommand(prevItemId), false)
            customVariables[DreamMountPrevItemId] = nil
        end

        mountLog(Format(DreamMountDismountStr, player.name, lastMountType, prevItemId))

        customVariables[DreamMountPrevMountTypeKey] = nil
        customVariables[DreamMountEnabledKey] = false
    end

    ClearSpellbookChanges(pid)
    SetSpellbookChangesAction(pid, (customVariables[DreamMountEnabledKey] and SpellbookAdd) or SpellbookRemove)
    AddSpell(pid, getMountSpellIdString(playerData.customVariables.preferredMount))
    SendSpellbookChanges(pid)
end

local function loadDreamMountConfig()
    local mountConfig = Load(DreamMountConfigPath)
    if mountConfig then
        for mountIndex, mountData in ipairs(mountConfig) do
            if not DreamMountConfig[mountIndex] then DreamMountConfig[mountIndex] = {} end
            local liveMountData = DreamMountConfig[mountIndex]
            for mountKey, mountValue in pairs(mountData) do
                liveMountData[mountKey] = mountValue
            end
        end
    else
        Save(DreamMountConfigPath, DreamMountConfigDefault)

        DreamMountConfig = DreamMountConfigDefault
    end
    assert(#DreamMountConfig >= 1, 'Empty config found on reload!\n' .. debug.traceback(3))
end

local function createMountMenuString()
    DreamMountListString = ''
    for _, MountData in ipairs(DreamMountConfig) do
        DreamMountListString = Format(DreamMountMenuItemPattern, DreamMountListString,
                                      MountData.name or DreamMountMissingMountName)
    end
end

local function canRunMountAdminCommands(player)
    return player.data.settings.staffRank >= DreamMountAdminRankRequired
end

local function assertPidProvided(pid)
    assert(pid, Format(DreamMountNoPidProvided, debug.traceback(3)))
end

local function unauthorizedUserMessage(pid)
    assertPidProvided(pid)
    SendMessage(pid, DreamMountUnauthorizedUserMessage, false)
end

local function validateUser(pid)
    assertPidProvided(pid)
    local player = Players[pid]
    if not player or not player:IsLoggedIn() then return false end

    if not canRunMountAdminCommands(player) then
        unauthorizedUserMessage(pid)
        return false
    end

    return true
end

local function clearCustomVariables(player)
    local customVariables = player.data.customVariables
    for _, variableId in ipairs {
        DreamMountPrevMountTypeKey,
        DreamMountEnabledKey,
        DreamMountPrevMountTypeKey,
        DreamMountPreferredMountKey,
    } do
        customVariables[variableId] = nil
    end
end

local function buildSpellEffectString(mountSpellRecordId, mountSpell)
    local parts = {
        mountSpellRecordId,
        ':\n----------'
    }

    for _, spellEffect in ipairs(mountSpell.effects) do
        parts[#parts + 1] = '\n'
        for k, v in pairs(spellEffect) do
            parts[#parts + 1] = Format('%s: %s ', k, v)
        end
        parts[#parts + 1] = '\n----------'
    end

    return Concat(parts)
end

local function initMountData()
    loadDreamMountConfig()
    createMountMenuString()

    local permanentSpells = RecordStores['spell'].data.permanentRecords
    for index, mountData in ipairs(DreamMountConfig) do
        local mountEffects = {}

        if mountData.speedBonus then
            mountEffects[#mountEffects + 1] = getFortifySpeedEffect(mountData.speedBonus)
        end

        if mountData.fatigueRestore then
            mountEffects[#mountEffects + 1] = getRestoreFatigueEffect(mountData.fatigueRestore)
        end

        if #mountEffects >= 1 then
            local mountSpellRecordId, mountSpell = getMountEffect(mountEffects, index)
            permanentSpells[mountSpellRecordId] = mountSpell
            local spellString = buildSpellEffectString(mountSpellRecordId, mountSpell)

            mountLog(Format(DreamMountCreatedSpellRecordStr, spellString))

        elseif permanentSpells[getMountSpellIdString(index)] then
            permanentSpells[getMountSpellIdString(index)] = nil
        end
    end
    RecordStores['spell']:Save()
end

return {
    clearCustomVariablesCommand = function(pid, cmd)
        if not validateUser(pid) then return end

        local targetPlayer = cmd[2] and Players[tonumber(cmd[2])]
        if targetPlayer then
            if not targetPlayer:IsLoggedIn() then return end
            clearCustomVariables(targetPlayer)
            SendMessage(pid
                        , Format(DreamMountSingleVarResetPattern
                                 , DreamMountResetVarsString
                                 , targetPlayer.name)
                        , false)
        else
            local playersWhoReset = {}
            for index = 0, #Players do
                local player = Players[index]
                clearCustomVariables(player)
                playersWhoReset[#playersWhoReset + 1] = player.name
            end
            SendMessage(pid
                        , Format(DreamMountSingleVarResetPattern
                                 , DreamMountResetVarsString
                                 , Concat(playersWhoReset, ','))
                        , false)
        end
    end,
    setPreferredMount = function(_, pid, idGui, data)
        local player = Players[pid]
        if idGui ~= DreamMountsGUIID or not player or not player:IsLoggedIn() then return end

        local selection = tonumber(data)

        if selection < 1 or selection > #DreamMountConfig then return end

        player.data.customVariables[DreamMountPreferredMountKey] = selection
    end,
    showPreferredMountMenu = function(pid)
        return ListBox(pid, DreamMountsGUIID
                       , DreamMountPreferredMountString, DreamMountListString)
    end,
    slowSaveOnEmptyWorld = function()
        if #Players ~= 0 then return end
        SlowSave(DreamMountConfigPath, DreamMountConfig)
    end,
    toggleMountCommand = function(pid)
        local player = Players[pid]
        if not player or not player:IsLoggedIn() then return end
        toggleMount(pid, player)
    end,
    defaultMountConfig = function(pid)
        if not validateUser(pid) then return end

        SlowSave(DreamMountConfigPath, DreamMountConfigDefault)

        SendMessage(pid, DreamMountDefaultConfigSavedString, false)
    end,
    reloadMountConfig = function(pid)
        if not validateUser(pid) then return end
        initMountData()
        SendMessage(pid, DreamMountConfigReloadedMessage, false)
    end,
    initMountData = initMountData,
    validateUser = validateUser,
}
