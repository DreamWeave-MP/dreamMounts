-- Need separate data structure for clothing records

-- STL Functions
local Concat = table.concat
local Format = string.format

-- TES3MP Functions
local AddItem = inventoryHelper.addItem
local AddRecordTypeToPacket = packetBuilder.AddRecordByType
local ClearRecords = tes3mp.ClearRecords
local ContainsItem = inventoryHelper.containsItem
local ListBox = tes3mp.ListBox
local Load = jsonInterface.load
local RemoveClosestItem = inventoryHelper.removeClosestItem
local RunConsoleCommandOnPlayer = logicHandler.RunConsoleCommandOnPlayer
local Save = jsonInterface.quicksave
local SendBaseInfo = tes3mp.SendBaseInfo
local SendMessage = tes3mp.SendMessage
local SetModel = tes3mp.SetModel
local SendRecordDynamic = tes3mp.SendRecordDynamic
local SetRecordType = tes3mp.SetRecordType
local SlowSave = jsonInterface.save

--TES3MP Globals
local AddToInventory = enumerations.inventory.ADD
local FortifyAttribute = enumerations.effects.FORTIFY_ATTRIBUTE
local RemoveFromInventory = enumerations.inventory.REMOVE
local RestoreFatigue = enumerations.effects.RESTORE_FATIGUE
local Players = Players
local MiscRecordType = enumerations.recordType.MISCELLANEOUS
local SpellRecordType = enumerations.recordType.SPELL

-- Local Constants
local DreamMountAdminRankRequired = 2
local DreamMountsGUIID = 381342
local GauntletMountType = 0
local MountDefaultFatigueRestore = 3
local ShirtMountType = 1

local MountSlotMap = {
    [GauntletMountType] = "LEFT_GAUNTLET",
    [ShirtMountType] = "SHIRT",
}

-- Paths
local DefaultKeyName = "Reins"
local DreamMountConfigPath = 'custom/dreamMountConfig.json'
local GuarMountFilePathStr = 'rot/anim/%s.nif'

-- UI Messages
local DreamMountConfigReloadedMessage =
    Format(
    '%sMount config reloaded, %smenu reconstructed, %sand spell records remade! %sDreamMount%s has completely reinitialized.\n'
    , color.MediumBlue, color.Green, color.MediumBlue, color.Navy, color.Green)
local DreamMountDefaultConfigSavedString =
    Format('%sSaved default mount config to %sdata/%s\n'
    , color.MediumBlue, color.Green, DreamMountConfigPath)
local DreamMountListString
local DreamMountNoPreferredMountStr = Format('%sdoes not have a preferred mount set!\n' , color.Red)
local DreamMountResetVarsString = Format('%sReset DreamMount variables for %s'
, color.MediumBlue, color.Green)
local DreamMountPreferredMountString = 'Select your preferred mount.'
local DreamMountUnauthorizedUserMessage =
    Format('%sYou are not authorized to run %sdreamMount %sadmin commands!\n'
    , color.Red, color.MediumBlue, color.Red)

-- Patterns
local DreamMountNoPreferredMountMessage = '%s%s %s'
local DreamMountSingleVarResetPattern = '%s%s.\n'
local DreamMountMenuItemPattern = '%s\n%s'
local DreamMountSpellNameTemplate = '%s Speed Buff'
local DreamMountLogStr = '[ %s ]: %s'

-- Standard log messages
local DreamMountCreatedSpellRecordStr = 'Created spell record %s'
local DreamMountDismountStr = '%s dismounted from mount of type: %s, replacing previously equipped item: %s'
local DreamMountLogPrefix = 'DreamMount'
local DreamMountMountStr = '%s mounted %s'

-- Error Strings
local DreamMountInvalidSpellEffectErrorStr = 'Cannot create a spell effect with no magnitude!'
local DreamMountMissingMountName = 'No mount name!'
local DreamMountNoPidProvided = 'No PlayerID provided!\n%s'
local DreamMountNoPrevMountErr = 'No previous mount to remove for player %s, aborting!'

-- CustomVariables index keys
local DreamMountEnabledKey = 'dreamMountIsMounted'
local DreamMountPreferredMountKey = 'dreamMountPreferredMount'
local DreamMountPrevItemId = 'dreamMountPreviousItemId'
local DreamMountPrevMountTypeKey = 'dreamMountPreviousMountType'
local DreamMountPrevSpellId = 'dreamMountPreviousSpellId'

-- MWScripts

local MWScripts = {
    DreamMountDismount = [[
Begin DreamMountDismount
  short doOnce

  if ( doOnce == 0 )

    if ( DreamMountMount.doOnce )
      stopScript DreamMountMount
      set DreamMountMount.doOnce to 0
      pcforce1stperson
      player->loopgroup idle 2
    endif

    set doOnce to 1
    return
  endif

  enableplayerjumping
  enableplayerviewswitch

  if ( DreamMountMount.wasThirdPerson )
    pcforce3rdperson
  endif

  MessageBox "Dismount successful."
  set doOnce to 0
  stopscript DreamMountDismount

End DreamMountDismount
]],
    DreamMountMount = [[
Begin DreamMountMount
  short doOnce
  short wasThirdPerson

  if ( doOnce == 0 )
    set wasThirdPerson to ( PCGet3rdPerson )

    if ( player->GetSpellReadied == 0 )
      Messagebox "Engage your mount by\ndrawing your magic!"
      pcforce3rdperson
      player->loopgroup idlespell 100000 1
    endif

    disableplayerjumping
    disableplayerviewswitch
    set doOnce to 1
    return
  endif

  if ( player->GetSpellReadied )
    player->playgroup idle 2
    pcforce1stperson
    set doOnce to 0
    stopscript DreamMountMount
  endif

End DreamMountMount
]],
}

local DreamMountConfigDefault = {
    {
        name = 'Guar',
        item = 'rot_c_guar00_shirtC3',
        model = 'mountedguar2',
        speedBonus = 70,
        fatigueRestore = MountDefaultFatigueRestore,
    },
    -- 2
    {
        name = "Pack Guar 1",
        item = 'rot_c_guar1B_shirtC3',
        model = 'mountedguar1',
        speedBonus = 60,
        fatigueRestore = MountDefaultFatigueRestore * 1.5,
    },
    -- 3
    {
        name = "Pack Guar 2",
        item = 'rot_c_guar1A_shirt0',
        model = 'mountedguar1',
        speedBonus = 60,
        fatigueRestore = MountDefaultFatigueRestore * 1.5,
    },
    -- 4
    {
        name = "Redoran War Guar",
        item = 'rot_c_guar2A_shirt0_redoranwar',
        model = 'mountedguar2',
        speedBonus = 80,
        fatigueRestore = MountDefaultFatigueRestore / 2,
        key = {
            icon = "c/tx_belt_expensive_03.dds",
            model = "c/c_belt_expensive_3.nif",
        }
    },
    -- 5
    {
        name = "Guar with Drapery (Fine)",
        item = 'rot_c_guar2B_shirt0_ordinator',
        model = 'mountedguar2',
        speedBonus = 80,
        fatigueRestore = MountDefaultFatigueRestore * 2,
        key = {
            icon = "c/tx_belt_exquisite_01.dds",
            model = "c/c_belt_exquisite_1.nif",
        },
    },
    -- 6
    {
        name = "Guar with Drapery (Simple)",
        item = 'rot_c_guar2C_shirt0_scout',
        model = 'mountedguar2',
        speedBonus = 100,
        fatigueRestore = MountDefaultFatigueRestore * 1.25,
        key = {
            icon = "c/tx_belt_exquisite_01.dds",
            model = "c/c_belt_exquisite_1.nif",
        },
    },
    -- 7
    {
        name = "Red Speeder",
        item = 'sw_speeder1test',
        mountType = GauntletMountType,
        speedBonus = 200,
        key = {
            name = "Red Speeder Key",
            value = 5000,
        },
    },
}

--- Populated during DreamMountFunctions:createKeyRecords
---@type table <string, boolean>
local KeyRecords = {}

local DreamMountMerchants = {
    -- Seyda Neen
    ["arrille"] = {
        capacity = 3,
        selection = { 1, 2, 3 }
    },
    -- Caldera
    ["verick gemain"] = {
        capacity = 2,
        selection = { 3, 4 }
    },
    -- Khuul
    ['thongar'] = {
        capacity = 1,
        selection = { 1 }
    },
    -- Mournhold
    ['ten-tongues_weerhat'] = {
        capacity = 3,
        selection = { 4, 6, 2 }
    },
    -- Raven Rock
    ['sathyn andrano'] = {
        capacity = 3,
        selection = { 5, 6, 3 }
    },
    -- Hla Oad
    ['perien aurelie'] = {
        capacity = 2,
        selection = { 2, 3 }
    },
    -- Balmora
    ['ra\'virr'] = {
        capacity = 3,
        selection = { 1, 2 }
    },
    -- Vivec
    ['mevel fererus'] = {
        capacity = 3,
        selection = { 3, 5, 2 }
    },
    -- Suran
    ['ralds oril'] = {
        capacity = 1,
        selection = { 3 }
    },
    -- Ald Velothi
    ['sedam omalen'] = {
        capacity = 1,
        selection = { 1 }
    },
    -- Ald'ruhn
    ['galtis guvron'] = {
        capacity = 1,
        selection = { 4 }
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

local KeyItemTemplate = {
    value = 3000,
    icon = "c/tx_belt_common01.tga",
    model = "c/c_belt_common_1.nif",
    weight = 0.0,
    script = "",
    keyState = nil,
}

local DreamMountFunctions = {
    MountConfig = {}
}

local function mountLog(message)
    print(Format(DreamMountLogStr, DreamMountLogPrefix, message))
end

local function getKeyTemplate(mountData)
    local newKey = {}

    for k, v in pairs(KeyItemTemplate) do newKey[k] = v end
    for k, v in pairs(mountData.key or {}) do newKey[k] = v end

    if not newKey.name then
        newKey.name = Format("%s %s", mountData.name, DefaultKeyName)
    end

    return newKey
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

local function getMountKeyString(mountData)
    return Format("%s_%s", mountData.name, mountData.keyName or DefaultKeyName):lower()
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

local function resetMountSpellForPlayer(player, spellRecords)
    local prevMountSpell = player.data.customVariables[DreamMountPrevSpellId]
    if not prevMountSpell then return end

    player:updateSpellbook {
        [prevMountSpell] = false,
    }

    if spellRecords[prevMountSpell] then
        player:updateSpellbook {
            [prevMountSpell] = true,
        }
    end
end

local function createScriptRecords()
    local scriptRecordStore = RecordStores['script']
    local scriptRecords = scriptRecordStore.data.permanentRecords
    for scriptId, scriptText in pairs(MWScripts) do
        scriptRecords[scriptId] = { scriptText = scriptText }
    end
    scriptRecordStore:Save()
end

function DreamMountFunctions:reloadMountMerchants(_, _, cellDescription, objects)
    for _, actor in pairs(objects) do
        if actor.dialogueChoiceType ~= enumerations.dialogueChoice.BARTER then return end
        local expectedKeys = DreamMountMerchants[actor.refId]
        if not expectedKeys then return end

        local cell = LoadedCells[cellDescription]

        assert(cell,
               "Unable to read cell in reloadMountMerchants call!\n"
               .. debug.traceback(3))

        local objectData = cell.data.objectData
        local reloadInventory = false
        local currentMountKeys = 0
        local currentInventory = objectData[actor.uniqueIndex].inventory

        assert(objectData,
               "Received nil objectData in reloadMountMerchants call!\n"
               .. debug.traceback(3))
        assert(currentInventory,
               "Received nil currentInventory in reloadMountMerchants call!\n"
               .. debug.traceback(3))

        for _, object in pairs(currentInventory) do
            if KeyRecords[object.refId] then
                currentMountKeys = currentMountKeys + object.count
            end
        end

        local keysToAdd = expectedKeys.capacity - currentMountKeys
        if keysToAdd < 1 then return end

        for _ = 1, keysToAdd do
            local mountIndex = math.random(1, #expectedKeys.selection)
            local mountData = self.mountConfig[mountIndex]
            local keyId = getMountKeyString(mountData)
            AddItem(currentInventory, keyId, 1, -1, -1, "")
            if not reloadInventory then reloadInventory = true end
        end

        if not reloadInventory then return end

        for playerId, player in pairs(Players) do
            if player
                and player:IsLoggedIn()
                and player.data.location.cell == cellDescription
            then
                cell:LoadContainers(playerId, objectData, { actor.uniqueIndex })
            end
        end
    end
end

function DreamMountFunctions:createKeyRecords(firstPlayer)
    local miscRecords = RecordStores['miscellaneous']
    local permanentMiscRecords = miscRecords.data.permanentRecords

    if firstPlayer then
        ClearRecords()
        SetRecordType(MiscRecordType)
    end

    local keysSaved = 0
    KeyRecords = {}
    for _, mountData in ipairs(self.mountConfig) do
        local keyId = getMountKeyString(mountData)
        local keyRecord = getKeyTemplate(mountData)
        permanentMiscRecords[keyId] = keyRecord
        KeyRecords[keyId] = true
        keysSaved = keysSaved + 1

        if firstPlayer then
            AddRecordTypeToPacket(keyId, keyRecord, 'miscellaneous')
        end
    end

    miscRecords:Save()

    if firstPlayer and keysSaved > 0 then SendRecordDynamic(firstPlayer, true) end
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
        local mountType = mount.mountType or ShirtMountType
        local mountSlot = MountSlotMap[mountType]
        local mappedEquipSlot = enumerations.equipment[mountSlot]

        local replaceItem = playerData.equipment[mappedEquipSlot]

        if replaceItem.refId and replaceItem.refId ~= ''
        then replaceItem = replaceItem.refId
        else replaceItem = nil
        end

        addOrRemoveItem(true, mountId, player)
        player:updateEquipment {
            [mountSlot] = mountId
        }

        if not mountType or mountType == ShirtMountType then
            enableModelOverrideMount(player, charData, mount.model)
        elseif mountType == GauntletMountType then
            RunConsoleCommandOnPlayer(pid, 'startscript DreamMountMount')
        end

        mountLog(Format(DreamMountMountStr, player.name, mount.name))

        customVariables[DreamMountPrevItemId] = replaceItem
        customVariables[DreamMountPrevMountTypeKey] = mountType
        customVariables[DreamMountEnabledKey] = true
    else
        for _, mountData in ipairs(self.mountConfig) do
            addOrRemoveItem(false, mountData.item, player)
        end

        local lastMountType = customVariables[DreamMountPrevMountTypeKey]

        if not lastMountType then
            error(Format(DreamMountNoPrevMountErr, player.name))
        elseif lastMountType == ShirtMountType then
            charData.modelOverride = nil
            SetModel(pid, '')
            SendBaseInfo(pid)
        elseif lastMountType == GauntletMountType then
            RunConsoleCommandOnPlayer(pid, 'startscript DreamMountDismount')
        end

        local prevItemId = customVariables[DreamMountPrevItemId]
        if prevItemId and ContainsItem(playerData.inventory, prevItemId) then
            player:updateEquipment {
                 [MountSlotMap[lastMountType]] = prevItemId
            }
            customVariables[DreamMountPrevItemId] = nil
        end

        mountLog(Format(DreamMountDismountStr, player.name, lastMountType, prevItemId))
        customVariables[DreamMountPrevItemId] = nil
        customVariables[DreamMountPrevMountTypeKey] = nil
        customVariables[DreamMountEnabledKey] = false
    end

    if not mountIndex then return end

    local targetSpell = self:getMountSpellIdString(mountIndex)
    customVariables[DreamMountPrevSpellId] = (not isMounted and targetSpell) or nil
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

    local customVariables = player.data.customVariables

    if customVariables[DreamMountEnabledKey] then
        self:toggleMount(pid, player)
    end

    customVariables[DreamMountPreferredMountKey] = selection
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
    local spellRecords = RecordStores['spell'].data.permanentRecords
    for _, player in pairs(Players) do
        resetMountSpellForPlayer(player, spellRecords)
    end
end

function DreamMountFunctions:createMountSpells(firstPlayer)
    local spellRecords = RecordStores['spell']
    local permanentSpells = spellRecords.data.permanentRecords

    if firstPlayer then
        ClearRecords()
        SetRecordType(SpellRecordType)
    end

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
            local removeSpellId = self:getMountSpellIdString(index)
            permanentSpells[removeSpellId] = nil
        end
    end

    spellRecords:Save()

    if spellsSaved == 0 or not firstPlayer then return end

    SendRecordDynamic(firstPlayer, true)
    self.resetPlayerSpells()
end

function DreamMountFunctions:initMountData()
    local firstPlayer = next(Players)

    self:loadMountConfig()
    self:createMountMenuString()
    self:createMountSpells(firstPlayer)
    self:createKeyRecords(firstPlayer)
    createScriptRecords()
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
