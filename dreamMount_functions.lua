-- Need separate data structure for clothing records
-- Fix bugs with switching spells
-- Need to remove all mount effects when dismounting

local Concat = table.concat
local Format = string.format

local AddSpell = tes3mp.AddSpell
local AddItem = inventoryHelper.addItem
local AddRecordTypeToPacket = packetBuilder.AddRecordByType
local ClearRecords = tes3mp.ClearRecords
local ClearSpellbookChanges = tes3mp.ClearSpellbookChanges
local ContainsItem = inventoryHelper.containsItem
local ListBox = tes3mp.ListBox
local Load = jsonInterface.load
local RemoveClosestItem = inventoryHelper.removeClosestItem
local RunConsoleCommandOnPlayer = logicHandler.RunConsoleCommandOnPlayer
local Save = jsonInterface.quicksave
local SendBaseInfo = tes3mp.SendBaseInfo
local SendMessage = tes3mp.SendMessage
local SendRecordDynamic = tes3mp.SendRecordDynamic
local SendSpellbookChanges = tes3mp.SendSpellbookChanges
local SetModel = tes3mp.SetModel
local SetRecordType = tes3mp.SetRecordType
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
local SpellRecordType = enumerations.recordType.SPELL

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
local DreamMountPrevSpellId = 'dreamMountPreviousSpellId'

local DreamMountAdminRankRequired = 2

local MountDefaultFatigueRestore = 3

local GauntletMountType = 0
local ShirtMountType = 1

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
        fatigueRestore = MountDefaultFatigueRestore * 1.5,
    },
    {
        name = "Pack Guar 2",
        item = 'rot_c_guar1A_shirt0',
        model = 'mountedguar1',
        speedBonus = 60,
        fatigueRestore = MountDefaultFatigueRestore * 1.5,
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
        speedBonus = 80,
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

local DreamMountFunctions = {
    MountConfig = {}
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

function DreamMountFunctions:createMountMenuString()
    DreamMountListString = ''
    for _, MountData in ipairs(self.mountConfig) do
        DreamMountListString = Format(DreamMountMenuItemPattern, DreamMountListString,
                                      MountData.name or DreamMountMissingMountName)
    end
end

function DreamMountFunctions:toggleMount(pid, player)
    local playerData = player.data
    local customVariables = playerData.customVariables
    local charData = playerData.character
    local isMounted = customVariables[DreamMountEnabledKey]
    local mountIndex = customVariables[DreamMountPreferredMountKey]

    if not isMounted then

        if not mountIndex then
            return SendMessage(pid, Format(DreamMountNoPreferredMountMessage
                                           , color.Yellow, player.name, DreamMountNoPreferredMountStr))
        end

        local mount = self.mountConfig[mountIndex]
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
            return SendMessage(pid, DreamMountNoStarwindStr, false)
        end

        mountLog(Format(DreamMountMountStr, player.name, self.mountConfig[mountIndex].name))

        customVariables[DreamMountPrevMountTypeKey] = mountType or ShirtMountType
        customVariables[DreamMountEnabledKey] = true
    else
        for _, mountData in ipairs(self.mountConfig) do
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
            return SendMessage(pid, DreamMountNoStarwindStr, false)
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

    if not mountIndex then return end

    local targetSpell = self:getMountSpellIdString(mountIndex)
    customVariables[DreamMountPrevSpellId] = (not isMounted and targetSpell) or nil
    -- print('from toggleMount', targetSpell, isMounted, customVariables[DreamMountPrevSpellId])
    player:updateSpellbook {
        [targetSpell] = not isMounted,
    }
end

function DreamMountFunctions.validateUser(pid)
    assertPidProvided(pid)
    local player = Players[pid]
    if not player or not player:IsLoggedIn() then return end

    if not canRunMountAdminCommands(player) then return unauthorizedUserMessage(pid) end

    return true
end

function DreamMountFunctions:loadMountConfig()
    self.mountConfig = Load(DreamMountConfigPath) or DreamMountConfigDefault

    if self.mountConfig == DreamMountConfigDefault then
        Save(DreamMountConfigPath, self.mountConfig)
    end

    assert(#self.mountConfig >= 1, 'Empty config found on reload!\n' .. debug.traceback(3))
end

function DreamMountFunctions.clearCustomVariablesCommand(_, pid, cmd)
    if not DreamMountFunctions.validateUser(pid) then return end

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
end

function DreamMountFunctions:setPreferredMount(_, pid, idGui, data)
    if idGui ~= DreamMountsGUIID then return end
    local player = Players[pid]

    if not player or not player:IsLoggedIn() then return end

    local selection = tonumber(data)

    if not selection or selection < 1 or selection > #self.mountConfig then return end
    -- print('updating preferred mount')

    player.data.customVariables[DreamMountPreferredMountKey] = selection
end

function DreamMountFunctions.showPreferredMountMenu(_, pid)
    return ListBox(pid, DreamMountsGUIID
                   , DreamMountPreferredMountString, DreamMountListString)
end

function DreamMountFunctions:slowSaveOnEmptyWorld()
    if #Players ~= 0 then return end
    SlowSave(DreamMountConfigPath, self.mountConfig)
end

function DreamMountFunctions:toggleMountCommand(pid)
    local player = Players[pid]
    if not player or not player:IsLoggedIn() then return end
    self:toggleMount(pid, player)
end

function DreamMountFunctions.defaultMountConfig(_, pid)
    if not DreamMountFunctions.validateUser(pid) then return end

    SlowSave(DreamMountConfigPath, DreamMountConfigDefault)

    SendMessage(pid, DreamMountDefaultConfigSavedString, false)
end

function DreamMountFunctions:reloadMountConfig(pid)
    if not DreamMountFunctions.validateUser(pid) then return end
    self:initMountData()
    SendMessage(pid, DreamMountConfigReloadedMessage, false)
end

function DreamMountFunctions.resetPlayerSpells()
    for _, player in pairs(Players) do
        local prevMountSpell = player.data.customVariables[DreamMountPrevSpellId]
        if prevMountSpell then

            if RecordStores['spell'].data.permanentRecords[prevMountSpell] ~= nil then
                player:updateSpellbook {
                    [prevMountSpell] = false,
                }
            end

            player:updateSpellbook {
                [prevMountSpell] = true,
            }

        end
    end
end

function DreamMountFunctions:initMountData()
    self:loadMountConfig()
    self:createMountMenuString()

    local spellRecords = RecordStores['spell']
    local permanentSpells = spellRecords.data.permanentRecords

    ClearRecords()
    SetRecordType(SpellRecordType)
    local spellsSaved = 0

    for index, mountData in ipairs(self.mountConfig) do
        local mountEffects = {}

        if mountData.speedBonus then
            mountEffects[#mountEffects + 1] = getFortifySpeedEffect(mountData.speedBonus)
        end

        if mountData.fatigueRestore then
            mountEffects[#mountEffects + 1] = getRestoreFatigueEffect(mountData.fatigueRestore)
        end

        if #mountEffects >= 1 then
            local mountSpellRecordId, mountSpell = self:getMountEffect(mountEffects, index)
            local spellString = buildSpellEffectString(mountSpellRecordId, mountSpell)

            permanentSpells[mountSpellRecordId] = mountSpell

            mountLog(Format(DreamMountCreatedSpellRecordStr, spellString))

            AddRecordTypeToPacket(mountSpellRecordId, mountSpell, 'spell')
            spellsSaved = spellsSaved + 1

        else
            -- This form works, but is hellaciously inefficient.
            -- We should instead have another function
            -- Which iterates over active players
            -- Checks if they have any mount effects enabled
            -- Re-adds appropriate ones
            -- And removes ones which shouldn't be there

            local removeSpellId = self:getMountSpellIdString(index)
            permanentSpells[removeSpellId] = nil
            -- for pid, _ in pairs(Players) do
            --     ClearSpellbookChanges(pid)
            --     SetSpellbookChangesAction(pid, SpellbookRemove)
            --     AddSpell(pid, removeSpellId)
            --     SendSpellbookChanges(pid)

                -- print('removed mount spell', index, 'for player', pid)
            -- end
        end
    end

    spellRecords:Save()

    local firstPlayer = next(Players)
    if spellsSaved < 1 or not firstPlayer then return end

    SendRecordDynamic(firstPlayer, true)
    self.resetPlayerSpells()
end

function DreamMountFunctions:getMountEffect(effectTable, mountIndex)
    return self:getMountSpellIdString(mountIndex),
        {
            name = self:getMountSpellNameString(mountIndex),
            subtype = 1,
            cost = 0,
            flags = 0,
            effects = effectTable
        }
end

---@param mountIndex integer
---@return string
function DreamMountFunctions:getMountSpellIdString(mountIndex)
    return Format(DreamMountSpellNameTemplate, self.mountConfig[mountIndex].item)
end

---@param mountIndex integer
---@return string
function DreamMountFunctions:getMountSpellNameString(mountIndex)
    return Format(DreamMountSpellNameTemplate, self.mountConfig[mountIndex].name)
end

return DreamMountFunctions
