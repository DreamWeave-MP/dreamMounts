-- STL Functions
local Concat = table.concat
local Format = string.format
local Traceback = debug.traceback
local Uppercase = string.upper

-- TES3MP Functions
local AddBodyPartRecord = packetBuilder.AddBodyPartRecord
local AddClothingRecord = packetBuilder.AddClothingRecord
local AddContainerItem = tes3mp.AddContainerItem
local AddContainerRecord = packetBuilder.AddContainerRecord
local AddCreatureRecord = packetBuilder.AddCreatureRecord
local AddItem = inventoryHelper.addItem
local AddObject = tes3mp.AddObject
local AddRecordTypeToPacket = packetBuilder.AddRecordByType
local BuildObjectData = dataTableBuilder.BuildObjectData
local ClearObjectList = tes3mp.ClearObjectList
local ClearRecords = tes3mp.ClearRecords
local ContainsItem = inventoryHelper.containsItem
local CreateObjectAtPlayer = logicHandler.CreateObjectAtPlayer
local DeleteObjectForEveryone = logicHandler.DeleteObjectForEveryone
local EventStatus = customEventHooks.makeEventStatus
local GetActorCell = tes3mp.GetActorCell
local GetActorListSize = tes3mp.GetActorListSize
local GetActorMpNum = tes3mp.GetActorMpNum
local GetActorRefNum = tes3mp.GetActorRefNum
local GetCell = tes3mp.GetCell
local GetPosX = tes3mp.GetPosX
local GetPosY = tes3mp.GetPosY
local ListBox = tes3mp.ListBox
local Load = jsonInterface.load
local MessageBox = tes3mp.MessageBox
local ProcessCommand = commandHandler.ProcessCommand
local ReadReceivedActorList = tes3mp.ReadReceivedActorList
local RemoveClosestItem = inventoryHelper.removeClosestItem
local RunConsoleCommandOnObject = logicHandler.RunConsoleCommandOnObject
local RunConsoleCommandOnPlayer = logicHandler.RunConsoleCommandOnPlayer
local Save = jsonInterface.quicksave
local SendBaseInfo = tes3mp.SendBaseInfo
local SendConsoleCommand = tes3mp.SendConsoleCommand
local SendContainer = tes3mp.SendContainer
local SendMessage = tes3mp.SendMessage
local SendObjectActivate = tes3mp.SendObjectActivate
local SendObjectPlace = tes3mp.SendObjectPlace
local SendObjectScale = tes3mp.SendObjectScale
local SendRecordDynamic = tes3mp.SendRecordDynamic
local SetAIForActor = logicHandler.SetAIForActor
local SetContainerItemCharge = tes3mp.SetContainerItemCharge
local SetContainerItemCount = tes3mp.SetContainerItemCount
local SetContainerItemEnchantmentCharge = tes3mp.SetContainerItemEnchantmentCharge
local SetContainerItemRefId = tes3mp.SetContainerItemRefId
local SetContainerItemSoul = tes3mp.SetContainerItemSoul
local SetCurrentMpNum = tes3mp.SetCurrentMpNum
local SetModel = tes3mp.SetModel
local SetObjectActivatingPid = tes3mp.SetObjectActivatingPid
local SetObjectListAction = tes3mp.SetObjectListAction
local SetObjectListCell = tes3mp.SetObjectListCell
local SetObjectListConsoleCommand = tes3mp.SetObjectListConsoleCommand
local SetObjectListPid = tes3mp.SetObjectListPid
local SetObjectMpNum = tes3mp.SetObjectMpNum
local SetObjectPosition = tes3mp.SetObjectPosition
local SetObjectRefId = tes3mp.SetObjectRefId
local SetObjectRefNum = tes3mp.SetObjectRefNum
local SetObjectRotation = tes3mp.SetObjectRotation
local SetObjectScale = tes3mp.SetObjectScale
local SetPlayerAsObject = tes3mp.SetPlayerAsObject
local SetRecordType = tes3mp.SetRecordType
local SlowSave = jsonInterface.save
local TablePrint = tableHelper.print

--TES3MP Globals
local AddToInventory = enumerations.inventory.ADD
local AIFollow = enumerations.ai.FOLLOW
local BarterDialogue = enumerations.dialogueChoice.BARTER
local BodyPartRecord = enumerations.recordType.BODYPART
local ClothingRecord = enumerations.recordType.CLOTHING
local ContainerRecordType = enumerations.recordType.CONTAINER
local ContainerSet = enumerations.container.SET
local CreatureRecordType = enumerations.recordType.CREATURE
local EquipEnums = enumerations.equipment
local FortifyAttribute = enumerations.effects.FORTIFY_ATTRIBUTE
local LoadedCells = LoadedCells
local RecordStores = RecordStores
local RemoveFromInventory = enumerations.inventory.REMOVE
local RestoreFatigue = enumerations.effects.RESTORE_FATIGUE
local Players = Players
local MiscRecordType = enumerations.recordType.MISCELLANEOUS
local SpellRecordType = enumerations.recordType.SPELL

-- Local Constants
local DreamMountStrings = require('custom.dreamMount.dreamMount_strings')
local DreamMountDefaults = require('custom.dreamMount.dreamMount_defaultConfig')

--- Since mwscripts are not reloadable clientside,
--- we won't bother to make them reloadable on the backend either
local MWScripts = require('custom.dreamMount.dreamMount_mwscripts')

local DreamMountAdminRankRequired = 2
local DreamMountsGUIID = 381342
local DreamMountsMountActivateGUIID = 381343

---@enum MountType
local MountTypes = {
    Gauntlet = 0,
    Shirt = 1,
}

---@enum EquipEnum
local MountSlotMap = {
    [MountTypes.Gauntlet] = 'LEFT_GAUNTLET',
    [MountTypes.Shirt] = 'SHIRT',
}

-- We don't currently use armor types, but we might later and
-- I don't feel like drawing the enums out again
---@diagnostic disable-next-line: unused-local
local ArmorTypes = {
    Helmet = 0,
    Cuirass = 1,
    LPauldron = 2,
    RPauldron = 3,
    Greaves = 4,
    Boots = 5,
    LGauntlet = 6,
    RGauntlet = 7,
    Shield = 8,
    LBracer = 9,
    RBracer = 10,
    LENGTH = 11,
}


local DefaultKeyName = "Reins"
-- CustomVariables index keys
local DreamMountVarTable = 'dreamMountVars'
local DreamMountEnabledKey = 'isMounted'
local DreamMountPreferredMountKey = 'preferredMount'
local DreamMountPrevItemId = 'previousItemId'
local DreamMountPrevMountTypeKey = 'previousMountType'
local DreamMountPrevSpellId = 'previousSpellId'
local DreamMountPrevAuraId = 'previousAuraId'
local DreamMountSummonRefNumKey = 'summonRefNum'
local DreamMountSummonCellKey = 'summonCellDescription'
local DreamMountSummonWasEnabledKey = 'hadMountSummon'
local DreamMountCurrentSummonsKey = 'summonsTable'
local DreamMountSummonInventoryDataKey = 'dreamMountSummonInventories'

--- Populated during DreamMountFunctions:createKeyRecords
---@type table <string, boolean>
local KeyRecords = {}

---@alias MountIndex integer

local KeyItemTemplate = {
    value = 3000,
    icon = "c/tx_belt_common01.tga",
    model = "c/c_belt_common_1.nif",
    weight = 0.0,
}

---@class DreamMountFunctions
---@field mountRefs table <string, string> Stores a map of mount refNums to their owners for the purpose of UI messages

local DreamMountFunctions = {
    mountConfig = {},
    mountMerchants = {},
    mountParts = {},
    mountClothing = {},
    mountRefs = {},
}

local function mountLog(message)
    print(Format(DreamMountStrings.Patterns.LogStr, DreamMountStrings.Log.LogPrefix, message))
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

local function getFilePath(model)
    return Format(DreamMountStrings.Paths.AnimRigPath, model)
end

local function actorPacketUniqueIndex(actorIndex)
    return Format("%s-%s", GetActorRefNum(actorIndex), GetActorMpNum(actorIndex))
end

local function round(number)
    return math.floor(number + 0.5)
end

local function addOrRemoveItem(addOrRemove, mount, player)
    local inventory = player.data.inventory
    local hasMountAlready = ContainsItem(inventory, mount)

    if addOrRemove == hasMountAlready then return end

    (addOrRemove and AddItem or RemoveClosestItem)(inventory, mount, 1)

    player:LoadItemChanges ({{ refId = mount, count = 1, }}, (addOrRemove and AddToInventory or RemoveFromInventory))
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
    assert(pid, Format(DreamMountStrings.Err.NoPidProvided, Traceback(3)))
end

local function unauthorizedUserMessage(pid)
    assertPidProvided(pid)
    SendMessage(pid, DreamMountStrings.UI.UnauthorizedUserMessage, false)
end

---@param player JSONPlayer
--- Uses the TM command to forcefully close any open menus once
--- Then invoke it a second time to restore the HUD
local function CloseMenu(player)
    local pid = player.pid
    for _ = 1, 2 do
        ClearObjectList()
        SetObjectListPid(pid)
        SetObjectListCell(player.data.location.cell)
        SetObjectListConsoleCommand("TM")
        SetPlayerAsObject(pid)
        AddObject()
        table.insert(player.consoleCommandsQueued, "TM")
        SendConsoleCommand(false)
    end
end

---@param player JSONPlayer
---@return table
local function getPlayerMountVars(player)
    assert(player and player:IsLoggedIn(), DreamMountStrings.Err.UnloggedPlayerSummonErr .. Traceback(3))
    local customVariables = player.data.customVariables
    if not customVariables[DreamMountVarTable] then customVariables[DreamMountVarTable] = {} end
    return customVariables[DreamMountVarTable]
end

local function dismountIfMounted(player)
    if getPlayerMountVars(player)[DreamMountEnabledKey] then
        DreamMountFunctions:toggleMount(player)
    end
end

--- Returns whether the player has the necessary key for their mount,
--- Or emits a warning message to them if they do not.
--- NOTE: ContainsItem only works with handlers, since validators won't have taken the inventory changes into account yet
--- So DON'T try to use this on the inventory validators like you were just thinking about doing
---@param player JSONPlayer
---@return true|nil ContainsItem True if the player has the item, nil if the message is emitted due to short circuiting
local function hasMountKey(player)
    local mountData = DreamMountFunctions:getMountData(player)
    local keyId = getMountKeyString(mountData)
    return ContainsItem(player.data.inventory, keyId) or player:Message(DreamMountStrings.UI.MissingMountKey)
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

local AttributeNames = {
    STRENGTH = 0,
    INTELLIGENCE = 1,
    WILLPOWER = 2,
    AGILITY = 3,
    SPEED = 4,
    ENDURANCE = 5,
    PERSONALITY = 6,
    LUCK = 7,
}

local Effects = {

    FortifyAttribute = function(attributeId, magnitudeMin, magnitudeMax)
        assert(attributeId >= 0 and attributeId <= 7, Format(DreamMountStrings.Err.ImpossibleAttributeIDErr, attributeId))
        assert(magnitudeMin, DreamMountStrings.Err.InvalidSpellEffectErrorStr .. Traceback(3))
        return {
            attribute = attributeId,
            id = FortifyAttribute,
            rangeType = 0,
            magnitudeMin = magnitudeMin,
            magnitudeMax = magnitudeMax or magnitudeMin,
            skill = -1,
        }
    end,

    RestoreFatigue = function(magnitudeMin, magnitudeMax)
        assert(magnitudeMin, DreamMountStrings.Err.InvalidSpellEffectErrorStr .. Traceback(3))
        return {
            id = RestoreFatigue,
            rangeType = 0,
            magnitudeMin = magnitudeMin,
            magnitudeMax = magnitudeMax or magnitudeMin,
            skill = -1,
        }
    end,
}

local function getPetAuraStrings(mountData)
    assert(mountData.name ~= nil and mountData.name ~= '', DreamMountStrings.Err.ImpossibleMountNameErr)
    return Format("%s_aura", mountData.name):lower(), Format("%s Aura", mountData.name)
end

local function getMountActiveEffects(inputMountEffects)
    local mountEffects = {}

    for effectName, effectMagnitude in pairs(inputMountEffects or {}) do
        local effectData
        local attributeName = AttributeNames[Uppercase(effectName)]
        local effectGenerator = Effects[effectName]
        if attributeName then
            effectData = Effects.FortifyAttribute(attributeName, effectMagnitude)
        elseif effectGenerator then
            effectData = effectGenerator(effectMagnitude)
        else
            error(Format("%s is not a supported effect name for mount active effects!", effectName))
        end
        mountEffects[#mountEffects + 1] = effectData
    end

    if #mountEffects > 0 then return mountEffects end
end

function DreamMountFunctions.addMountSpellEffect(effects, spellId, spellName, permanentSpells)
    local mountSpell = {
        name = spellName,
        effects = effects,
        subtype = 1,
    }
    local spellString = buildSpellEffectString(spellId, mountSpell)

    permanentSpells[spellId] = mountSpell

    mountLog(Format(DreamMountStrings.Log.CreatedSpellRecordStr, spellString))

    AddRecordTypeToPacket(spellId, mountSpell, 'spell')
end

function DreamMountFunctions:getMountData(player)
    assert(player and player:IsLoggedIn(), Traceback(3))
    local preferredMount = getPlayerMountVars(player)[DreamMountPreferredMountKey]
    return self.mountConfig[preferredMount]
end

function DreamMountFunctions:despawnBagRef(player)
    assert(player, DreamMountStrings.Err.DespawnNoPlayerErr .. Traceback(3))

    local containerData = self:getCurrentContainerData(player)
    if not containerData or not containerData.cell or not containerData.index then return end

    local containerIndex = Concat(containerData.index, '-')

    DeleteObjectForEveryone(containerData.cell, containerIndex)
    containerData.cell = nil
    containerData.index = nil

    mountLog(Format(DreamMountStrings.Log.SuccessfulContainerDespawnStr,
                    self:getContainerRecordId(player),
                    containerIndex,
                    player.name))
    player:QuicksaveToDrive()
end

function DreamMountFunctions:activateCurrentMountContainer(player)
    local pid = player.pid
    ClearObjectList()

    SetObjectListPid(pid)

    SetObjectListCell(GetCell(pid))

    local containerData = self:getCurrentContainerData(player)
    if not containerData then return end
    local splitIndex = containerData.index

    SetObjectRefNum(splitIndex[1])

    SetObjectMpNum(splitIndex[2])

    SetObjectActivatingPid(pid)

    AddObject()

    SendObjectActivate()
end

function DreamMountFunctions:updateCurrentMountContainer(player)
    local containerData = self:getCurrentContainerData(player)
    local containerId = self:getContainerRecordId(player)
    if not containerData or not containerId then return end
    local pid = player.pid
    local playerCellId = GetCell(pid)
    local playerCell = LoadedCells[playerCellId]

    local cellObjectData = playerCell.data.objectData
    local containerIndex = Concat(containerData.index, '-')

    cellObjectData[containerIndex].inventory = containerData.inventory
    -- Make another function (or use this one) which actually
    -- sends a packet containing the relevant inventory contents!
    -- For now we just want to see the items appear in JSON.
    ClearObjectList(pid)
    SetObjectListPid(pid)
    SetObjectListCell(playerCellId)
    SetObjectRefNum(containerData.index[1])
    SetObjectMpNum(containerData.index[2])
    SetObjectRefId(containerId)

    for _, item in ipairs(containerData.inventory) do
        assert(item.refId and item.refId ~= '', DreamMountStrings.Err.ImpossibleRefidErr .. Traceback(3))

        SetContainerItemRefId(item.refId)
        SetContainerItemCount(item.count or 1)
        SetContainerItemCharge(item.charge or -1)
        SetContainerItemEnchantmentCharge(item.enchantmentCharge or -1)
        SetContainerItemSoul(item.soul or '')
        AddContainerItem()
    end

    AddObject()
    SetObjectListAction(ContainerSet)
    SendContainer(false, false)
end

local function toggleSpell(spell, player, spellRecords)
    if not spellRecords then spellRecords = RecordStores['spell'].data.permanentRecords end

    player:updateSpellbook {
        [spell] = false,
    }

    if spellRecords[spell] then
        player:updateSpellbook {
            [spell] = true,
        }
    end
end

--- Destroys the player's summoned pet, if one exists.
--- This method also destroys the associated creature record, since current impl would
--- otherwide be really spammy.
---@param player JSONPlayer
function DreamMountFunctions:despawnMountSummon(player)
    assert(player, DreamMountStrings.Err.DespawnNoPlayerErr .. Traceback(3))

    local customVariables = getPlayerMountVars(player)
    local summonRef = customVariables[DreamMountSummonRefNumKey]
    local summonCell = customVariables[DreamMountSummonCellKey]
    if not summonRef and not summonCell then return end

    local preferredMount = customVariables[DreamMountPreferredMountKey]
    local mountData = self.mountConfig[preferredMount]
    if not mountData or not preferredMount then return end

    local mountName = mountData.name

    DeleteObjectForEveryone(summonCell, summonRef)

    local petAura = customVariables[DreamMountPrevAuraId]
    if petAura then
        player:updateSpellbook {
            [petAura] = false,
        }
    end

    customVariables[DreamMountPrevAuraId] = nil
    customVariables[DreamMountSummonRefNumKey] = nil
    customVariables[DreamMountSummonCellKey] = nil

    local currentSummons = customVariables[DreamMountCurrentSummonsKey]
    if currentSummons and currentSummons[mountName] then
        local summonToRemove = currentSummons[mountName]

        mountLog(Format(DreamMountStrings.Log.RemovingRecordStr, summonToRemove, player.name))

        local creatureRecordStore = RecordStores["creature"]
        local creatureRecords = creatureRecordStore.data.permanentRecords
        creatureRecords[summonToRemove] = nil
        creatureRecordStore:Save()

        currentSummons[mountName] = nil
    end
    player:QuicksaveToDrive()

    if self.mountRefs[summonRef] then self.mountRefs[summonRef] = nil end
end

---@class ObjectDataTable
---@field pid PlayerId
---@field refId string Record id of the object to add to the list
---@field refNum number Reference number (generated by the server, probably) of the object to add to the list
---@field mpNum number Plugin origin of the object. Should always be 0?
---@field clear boolean whether or not to clear the object list and assign it to the player on this call

---@param objectDataTable ObjectDataTable
local function addObjectInPlayerCellToObjectList(objectDataTable)
    local pid = objectDataTable.pid
    if objectDataTable.clear then
        ClearObjectList()
        SetObjectListPid(pid)
        SetObjectListCell(GetCell(pid))
    end
    SetObjectRefId(objectDataTable.refId)
    SetObjectRefNum(objectDataTable.refNum)
    SetObjectMpNum(objectDataTable.mpNum)
    AddObject()
end

--- Assign creature attributes here instead of as record data
--- Because spells, skills, and attributes can't be set by custom records
local function sendCreatureAttributePacket(attributePacketData)
    local Err = DreamMountStrings.Err
    local player = attributePacketData.player
    local playerPetData = attributePacketData.playerPetData
    local petId = attributePacketData.petId

    local playerQueuedCommands = player.consoleCommandsQueued
    local summonSplitIndex = getPlayerMountVars(player)[DreamMountSummonRefNumKey]:split('-')
    assert(summonSplitIndex, Err.MissingSummonRefNumErr)
    local summonRefNum = summonSplitIndex[1]
    local summonMpNum = summonSplitIndex[2]

    ---@type ObjectDataTable
    local objectData = {
        clear = true,
        pid = player.pid,
        refId = petId,
        refNum = summonRefNum,
        mpNum = summonMpNum,
    }

    local playerAttributes = player.data.attributes
    for attributeName, attributeValue in pairs(playerPetData.attributes or {}) do
        assert(AttributeNames[Uppercase(attributeName)],
            Format(Err.ImpossibleAttributeNameErr,
                attributeName,
                Traceback(3)))

        local finalValue = round(playerAttributes[attributeName].base * attributeValue)
        local attributeSetter = Format("set%s %s", attributeName, finalValue)
        addObjectInPlayerCellToObjectList(objectData)
        SetObjectListConsoleCommand(attributeSetter)
        playerQueuedCommands[#playerQueuedCommands + 1] = attributeSetter
        SendConsoleCommand(true)
    end

    for _, spellName in ipairs(playerPetData.spells or {}) do
        addObjectInPlayerCellToObjectList(objectData)
        local addSpellCommand = Format("addspell %s", spellName)
        SetObjectListConsoleCommand(addSpellCommand)
        playerQueuedCommands[#playerQueuedCommands + 1] = addSpellCommand
        SendConsoleCommand(true)
    end
end

--- Place the appropriate summon at the player's location,
--- Enabling the follow routine when doing so
---@param player JSONPlayer
---@param summonId string generated recordId for the mount summon
function DreamMountFunctions:spawnMountSummon(player, summonId)
    assert(player and player:IsLoggedIn(), DreamMountStrings.Err.UnloggedPlayerSummonErr)
    local pid = player.pid
    local playerCell = player.data.location.cell
    local customVariables = getPlayerMountVars(player)

    local summonIndex = CreateObjectAtPlayer(pid, BuildObjectData(summonId), "spawn")
    SetAIForActor(LoadedCells[playerCell], summonIndex, AIFollow, pid)

    customVariables[DreamMountSummonRefNumKey] = summonIndex
    customVariables[DreamMountSummonCellKey] = playerCell
    self.mountRefs[summonIndex] = player.name

    player:QuicksaveToDrive()
end

--- Remove and if necessary, re-add the relevant mount buff for the player
--- Used when resetting the spell records, or custom variables
local function resetMountSpellForPlayer(player, spellRecords)
    local prevMountSpell = getPlayerMountVars(player)[DreamMountPrevSpellId]
    if not prevMountSpell then return end
    toggleSpell(prevMountSpell, player, spellRecords)
end

local function resetSummonSpellForPlayer(player, mountData, spellRecords)
    if not mountData then return end
    local prevSummonSpell = getPetAuraStrings(mountData)
    toggleSpell(prevSummonSpell, player, spellRecords)
end

--- Resets all DreamMount state for a given player
---@param player JSONPlayer
function DreamMountFunctions:clearCustomVariables(player)
    -- De-summon summons
    self:despawnMountSummon(player)
    -- Dismount if necessary
    dismountIfMounted(player)
    self:despawnBagRef(player)

    player.data.customVariables[DreamMountVarTable] = {}
    player:QuicksaveToDrive()
end

local function clearCustomVarsForPlayer(player)
    if not player or not player:IsLoggedIn() then return end
    DreamMountFunctions:clearCustomVariables(player)
    SendMessage(player.pid,
                Format(DreamMountStrings.Patterns.SingleVarReset
                       , DreamMountStrings.UI.ResetVarsString
                       , player.name)
                , false)
end

local function createScriptRecords()
    local scriptRecordStore = RecordStores['script']
    local scriptRecords = scriptRecordStore.data.permanentRecords
    for scriptId, scriptText in pairs(MWScripts) do
        scriptRecords[scriptId] = { scriptText = scriptText }
    end
    scriptRecordStore:Save()
end

local function createPetRecord(petRecordInput)
    local Err = DreamMountStrings.Err

    local playerPetData = petRecordInput.playerPetData
    local mountName = petRecordInput.mountName
    local petId = petRecordInput.petId

    local player = petRecordInput.player
    local playerStats = player.data.stats

    assert(playerPetData, Err.CreatePetNoPetDataErr .. Traceback(3))
    assert(petId, Err.CreatePetNoIdErr .. Traceback(3))
    assert(player, Err.CreatePetNoPlayerErr .. Traceback(3))
    assert(mountName, Err.CreatePetNoMountNameErr .. Traceback(3))

    local creatureRecordStore = RecordStores["creature"]
    local creatureRecords = creatureRecordStore.data.permanentRecords

    ClearRecords()
    SetRecordType(CreatureRecordType)

    local petName = Format("%s's %s", player.name, mountName)
    local petLevel = playerPetData.levelPct * playerStats.level
    local damagePerLevelPct = playerPetData.damagePerLevelPct
    local chopMax = round(playerPetData.damageChop * (1 + (damagePerLevelPct * petLevel)))
    local slashMax = round(playerPetData.damageSlash * (1 + (damagePerLevelPct * petLevel)))
    local thrustMax = round(playerPetData.damageThrust * (1 + (damagePerLevelPct * petLevel)))

    local petRecord = {
        name = petName,
        baseId = playerPetData.baseId,
        health = round(playerPetData.healthPct * playerStats.healthBase),
        magicka = round(playerPetData.magickaPct * playerStats.magickaBase),
        fatigue = round(playerPetData.fatiguePct * playerStats.fatigueBase),
        level = round(petLevel),
        damageChop = { min = round(chopMax * playerPetData.chopMinDmgPct), max = chopMax },
        damageSlash = { min = round(slashMax * playerPetData.slashMinDmgPct), max = slashMax },
        damageThrust = { min = round(thrustMax * playerPetData.thrustMinDmgPct), max = thrustMax },
    }

    creatureRecords[petId] = petRecord
    creatureRecordStore:Save()
    AddCreatureRecord(petId, petRecord)
    SendRecordDynamic(player.pid, true)
end

local function saveContainerData(containerSaveData)
---@diagnostic disable-next-line: deprecated
    local player, containerId, containerIndex, containerCell = unpack(containerSaveData)
    local customVariables = player.data.customVariables

    if not customVariables[DreamMountSummonInventoryDataKey] then
        customVariables[DreamMountSummonInventoryDataKey] = {}
    end

    local inventoryData = customVariables[DreamMountSummonInventoryDataKey]
    if not inventoryData[containerId] then
        inventoryData[containerId] = {
            inventory = {},
        }
    end

    local containerData = inventoryData[containerId]
    containerData.index = containerIndex
    containerData.cell = containerCell
    player:QuicksaveToDrive()
end

function DreamMountFunctions:getCurrentContainerData(player)
    assert(player and player:IsLoggedIn(), Traceback(3))

    local customVariables = player.data.customVariables
    local mountInventories = customVariables[DreamMountSummonInventoryDataKey]
    if not mountInventories then return end

    return mountInventories[self:getContainerRecordId(player)]
end

function DreamMountFunctions:mountHasContainerData(player)
    local mountData = self:getMountData(player)

    if mountData and mountData.containerData then
        return true
    end
end

function DreamMountFunctions:getContainerRecordId(player)
    assert(player and player:IsLoggedIn(), Traceback(3))
    local mountName = self:getPlayerMountName(player)
    if not mountName then return end
    return Format("%s_%s_container", player.name, mountName):lower()
end

function DreamMountFunctions:getPlayerPetName(player)
    local mountData = self:getMountData(player)
    if not mountData or not mountData.petData then return end
    return Format("%s's %s", player.name, mountData.name)
end

function DreamMountFunctions:getPlayerMountName(player)
    local mountData = self:getMountData(player)
    return mountData and mountData.name
end

function DreamMountFunctions.sendContainerPlacePacket(containerPacket)
---@diagnostic disable-next-line: deprecated
	local pid, splitIndex, targetContainer, targetObject = unpack(containerPacket)

	ClearObjectList()
	SetObjectListPid(pid)
	SetObjectListCell(GetCell(pid))

	SetObjectRefNum(splitIndex[1])
	SetObjectMpNum(splitIndex[2])
	SetObjectRefId(targetContainer)

	local location = targetObject.location
	SetObjectPosition(location.posX, location.posY, location.posZ)
	SetObjectRotation(location.rotX, location.rotY, location.rotZ)

	SetObjectScale(targetObject.scale)

	AddObject()

	SendObjectPlace(false)
	SendObjectScale(false)
end

function DreamMountFunctions:createContainerServerside(player)
    local Err = DreamMountStrings.Err
    local targetContainer = self:getContainerRecordId(player)
    local pid = player.pid
    local cellDescription = GetCell(pid)
	local mpNum = WorldInstance:GetCurrentMpNum() + 1

	local uniqueIndex =  Format("0-%s", mpNum)

	local bagSpawnCell = LoadedCells[cellDescription]
	assert(bagSpawnCell, Err.ImpossibleUnloadedCellErr .. debug.traceback(3))

	bagSpawnCell:InitializeObjectData(uniqueIndex, targetContainer)

	local cellData = bagSpawnCell.data
	local cellPackets = cellData.packets
	local objectData = cellData.objectData
    local targetObject = objectData[uniqueIndex]

	assert(objectData[uniqueIndex], Err.ImpossibleObjectDataErr .. debug.traceback(3))

    targetObject.location = {
        posX = GetPosX(pid),
        posY = GetPosY(pid),
        posZ = -99999,
        rotX = 0,
        rotY = 0,
        rotZ = 0
    }

	targetObject.scale = 0.0001

	targetObject.inventory = {}

	for _, packetType in ipairs { 'place', 'scale', 'container' } do
		local packetTable = cellPackets[packetType]
		packetTable[#packetTable + 1] = uniqueIndex
	end

	WorldInstance:SetCurrentMpNum(mpNum)

	SetCurrentMpNum(mpNum)

    local splitIndex = uniqueIndex:split('-')
    saveContainerData {
        player,
        targetContainer,
        splitIndex,
        cellDescription,
    }

    return {
        pid,
        splitIndex,
        targetContainer,
        targetObject
    }
end

function DreamMountFunctions:selectedMountIsPet(player)
    return self:getPlayerPetName(player) ~= nil
end

function DreamMountFunctions:activateMountContainer(player)
    if not self:mountHasContainerData(player) then
        return player:Message(DreamMountStrings.UI.NoContainerDataErr)
    end

    self:despawnBagRef(player)
    self.sendContainerPlacePacket(self:createContainerServerside(player))
    self:updateCurrentMountContainer(player)
    self:activateCurrentMountContainer(player)
end

function DreamMountFunctions:handleMountActivateMenu(pid, activateMenuChoice)
    local Err = DreamMountStrings.Err
    activateMenuChoice = tonumber(activateMenuChoice)
    local player = Players[pid]

    assert(activateMenuChoice, Err.ActivateChoiceFailedToConvertErr)
    assert(player and player:IsLoggedIn(), Err.NoContainerForUnloggedPlayerErr)

    if activateMenuChoice == 0 then
        self:activateMountContainer(player)
    elseif activateMenuChoice == 1 then
        mountLog(Format(DreamMountStrings.Log.DismissedStr, player.name))
        self:despawnMountSummon(player)
        self:despawnBagRef(player)
    elseif activateMenuChoice == 2 then
        local petCellRef = getPlayerMountVars(player)[DreamMountSummonRefNumKey]
        local playerCell = player.data.location.cell
        assert(petCellRef, Err.ImpossibleActivationErr)

        RunConsoleCommandOnObject(pid, "loopgroup idle6 1 2",
                                  playerCell, petCellRef, true)
        RunConsoleCommandOnObject(pid, "loopgroup idle2 0 0",
                                  playerCell, petCellRef, true)
    elseif activateMenuChoice == 3 then
        self:toggleMount(player)
    end
end

function DreamMountFunctions:reloadMountMerchants(_, _, cellDescription, objects)
    local actorIndex, actor = next(objects)

    if actor.dialogueChoiceType ~= BarterDialogue then return end
    local expectedKeys = self.mountMerchants[actor.refId]
    if not expectedKeys then return end
    local Err = DreamMountStrings.Err

    local cell = LoadedCells[cellDescription]

    assert(cell, Format(Err.NilCellErr, Traceback(3)))

    local objectData = cell.data.objectData
    local reloadInventory = false
    local currentMountKeys = 0
    local cellRef = objectData[actorIndex]
    local currentInventory = cellRef.inventory

    assert(cellRef, Err.MerchantNotInCell .. Traceback(3))
    assert(objectData, Format(Err.NilObjectDataErr, Traceback(3)))
    assert(currentInventory, Format(Err.NilInventoryErr, Traceback(3)))

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

function DreamMountFunctions:createClothingRecords(firstPid)
    local clothingRecords = RecordStores['clothing']
    local permanentClothing = clothingRecords.data.permanentRecords

    if firstPid then
        ClearRecords()
        SetRecordType(ClothingRecord)
    end

    local clothesSaved = 0
    for _, clothingData in ipairs(self.mountClothing) do
        local newClothingId = clothingData.id
        local newClothingName = clothingData.name
        local newClothingParts = clothingData.parts
        local newClothingType = clothingData.clothingType

        local hasValidClothingData = newClothingType
            and newClothingId
            and newClothingName
            and newClothingParts

        assert(hasValidClothingData, DreamMountStrings.Err.InvalidClothingDataErr .. Traceback())

        local newClothing = {
            name = newClothingName,
            subtype = newClothingType,
        }

        local parts = {}
        for partType, partId in pairs(newClothingParts) do
            parts[#parts + 1] = {
                malePart = partId,
                partType = partType
            }
        end
        newClothing.parts = parts

        permanentClothing[newClothingId] = newClothing
        clothesSaved = clothesSaved + 1

        if firstPid then
            AddClothingRecord(newClothingId, newClothing)
        end
    end

    clothingRecords:Save()

    if firstPid and clothesSaved > 0 then SendRecordDynamic(firstPid, true) end
end

function DreamMountFunctions:createBodyPartRecords(firstPid)
    local partRecords = RecordStores['bodypart']
    local permanentParts = partRecords.data.permanentRecords

    if firstPid then
        ClearRecords()
        SetRecordType(BodyPartRecord)
    end

    local partsSaved = 0
    for _, partData in ipairs(self.mountParts) do
        local newPartId = partData.id
        local newPartModel = partData.model
        local newPartSlot = partData.partSlot
        local newPartType = partData.subType

        local hasValidBodyPartData = newPartId
            and newPartModel
            and newPartSlot
            and newPartType

        assert(hasValidBodyPartData,
            DreamMountStrings.Err.InvalidBodyPartDataErr)

        local newPart = {
            subtype = newPartType,
            part = newPartSlot,
            model = newPartModel
        }

        permanentParts[newPartId] = newPart
        partsSaved = partsSaved + 1

        if firstPid then
            AddBodyPartRecord(newPartId, newPart)
        end
    end

    partRecords:Save()

    if firstPid and partsSaved > 0 then SendRecordDynamic(firstPid, true) end
end

function DreamMountFunctions:createKeyRecords(firstPid)
    local miscRecords = RecordStores['miscellaneous']
    local permanentMiscRecords = miscRecords.data.permanentRecords

    if firstPid then
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

        if firstPid then
            AddRecordTypeToPacket(keyId, keyRecord, 'miscellaneous')
        end
    end

    miscRecords:Save()

    if firstPid and keysSaved > 0 then SendRecordDynamic(firstPid, true) end
end

---@param player JSONPlayer
---@return string|nil UI Display output for the player's currently available mounts. nil if none are currently available
function DreamMountFunctions:createMountMenuString(player)
    local Err = DreamMountStrings.Err
    local DreamMountListString = DreamMountStrings.UI.DefaultListString
    local playerInventory = player.data.inventory

    assert(playerInventory, Format(Err.NoInventoryErr, Traceback(3)))

    local possessedKeys = {}

    for _, item in ipairs(playerInventory) do
        local itemId = item.refId
        if KeyRecords[itemId] then possessedKeys[itemId] = true end
    end

    for _, MountData in ipairs(self.mountConfig) do
        local keyId = getMountKeyString(MountData)
        if possessedKeys[keyId] then
            DreamMountListString = Format(DreamMountStrings.Patterns.MenuItem, DreamMountListString,
                MountData.name or Err.MissingMountName)
        end
    end

    if DreamMountListString ~= DreamMountStrings.UI.DefaultListString then
        return DreamMountListString
    end
end

---@class MountActivationData
---@field player JSONPlayer
---@field mountIndex MountIndex
---@field mountVariables table<string, any>

---@param mountActivationData MountActivationData
function DreamMountFunctions:activateMount(mountActivationData)
    local Log = DreamMountStrings.Log

    local player = mountActivationData.player
    local playerName = player.name
    local playerData = player.data
    local charData = player.data.character
    local pid = player.pid

    local mountIndex = mountActivationData.mountIndex

    if not mountIndex then return player:Message(
            Format(
                DreamMountStrings.Patterns.NoPreferredMountMessage,
                color.Yellow, playerName, DreamMountStrings.UI.NoPreferredMountStr
            )
        )
    end
    local mountVariables = mountActivationData.mountVariables
    local mount = self.mountConfig[mountIndex]

    if not hasMountKey(player) then return end

    local mountId = mount.item
    local mountType = mount.mountType or MountTypes.Shirt
    local mountSlot = MountSlotMap[mountType]
    local mappedEquipSlot = EquipEnums[mountSlot]

    mountVariables[DreamMountSummonWasEnabledKey] = mountVariables[DreamMountSummonRefNumKey] ~= nil
    self:despawnBagRef(player)
    self:despawnMountSummon(player)

    local replaceItem = playerData.equipment[mappedEquipSlot]

    if replaceItem.refId and replaceItem.refId ~= ''
    then replaceItem = replaceItem.refId
    else replaceItem = nil
    end

    addOrRemoveItem(true, mountId, player)
    player:updateEquipment {
        [mountSlot] = mountId
    }

    if not mountType or mountType == MountTypes.Shirt then
        enableModelOverrideMount(player, charData, mount.model)
        RunConsoleCommandOnPlayer(pid, 'startscript DreamMountForceThirdPerson')
    elseif mountType == MountTypes.Gauntlet then
        RunConsoleCommandOnPlayer(pid, 'startscript DreamMountMount')
    end

    mountLog(Format(Log.MountStr, playerName, mount.name))

    mountVariables[DreamMountPrevItemId] = replaceItem
    mountVariables[DreamMountPrevMountTypeKey] = mountType
    mountVariables[DreamMountEnabledKey] = true
end

---@class MountDeactivationData
---@field player JSONPlayer
---@field mountVariables table<string, any>

---@param mountDeactivationData MountDeactivationData
function DreamMountFunctions:deactivateMount(mountDeactivationData)
    local Log = DreamMountStrings.Log

    local player = mountDeactivationData.player
    local playerName = player.name
    local mountVariables = mountDeactivationData.mountVariables

    local playerData = player.data
    local charData = playerData.character
    local pid = player.pid

    for _, mountData in ipairs(self.mountConfig) do
        addOrRemoveItem(false, mountData.item, player)
    end

    local lastMountType = mountVariables[DreamMountPrevMountTypeKey]

    if not lastMountType then
        error(Format(DreamMountStrings.Err.NoPrevMountErr, playerName))
    elseif lastMountType == MountTypes.Shirt then
        charData.modelOverride = nil
        SetModel(pid, '')
        SendBaseInfo(pid)
        RunConsoleCommandOnPlayer(pid, 'startscript DreamMountDisableForceThirdPerson')
    elseif lastMountType == MountTypes.Gauntlet then
        RunConsoleCommandOnPlayer(pid, 'startscript DreamMountDismount')
    end

    local prevItemId = mountVariables[DreamMountPrevItemId]
    if prevItemId and ContainsItem(player.data.inventory, prevItemId) then
        local equipmentSlot = MountSlotMap[lastMountType]
        player:updateEquipment {
            [equipmentSlot] = prevItemId
        }
        mountVariables[DreamMountPrevItemId] = nil
    end

    mountLog(Format(Log.DismountStr, playerName, lastMountType, prevItemId))
    mountVariables[DreamMountPrevItemId] = nil
    mountVariables[DreamMountPrevMountTypeKey] = nil
    mountVariables[DreamMountEnabledKey] = false

    -- Maybe we should add a command to disable this functionality?
    -- Or just disable the summon?
    if mountVariables[DreamMountSummonWasEnabledKey] then
        self:summonCreatureMount(pid)
    end
end

function DreamMountFunctions:toggleMount(player)
    local mountVariables = getPlayerMountVars(player)
    local isMounted = mountVariables[DreamMountEnabledKey]
    local mountIndex = mountVariables[DreamMountPreferredMountKey]

    if not isMounted then self:activateMount {
            player = player,
            mountIndex = mountIndex,
            mountVariables = mountVariables,
        } else self:deactivateMount {
            player = player,
            mountVariables = mountVariables,
        }
    end

    if not mountIndex then return end

    local targetSpell = self:getMountSpellIdString(mountIndex)
    mountVariables[DreamMountPrevSpellId] = (not isMounted and targetSpell) or nil
    player:updateSpellbook {
        [targetSpell] = not isMounted,
    }
    player:QuicksaveToDrive()
end

function DreamMountFunctions.validateUser(pid)
    assertPidProvided(pid)
    local player = Players[pid]
    if not player or not player:IsLoggedIn() then return end

    if not canRunMountAdminCommands(player) then return unauthorizedUserMessage(pid) end

    return true
end

function DreamMountFunctions:logConfig()
    mountLog("---------------BEGIN DREAMMOUNT CONFIG---------------")
    TablePrint(self.mountConfig)
    mountLog("---------------MERCHANT CONFIG---------------")
    TablePrint(self.mountMerchants)
    mountLog("---------------BODYPART CONFIG---------------")
    TablePrint(self.mountParts)
    mountLog("---------------CLOTHING CONFIG---------------")
    TablePrint(self.mountClothing)
    mountLog("---------------END DREAMMOUNT CONFIG---------------")
end

function DreamMountFunctions:loadMountConfig()
    local Paths = DreamMountStrings.Paths

    local mountConfigPath = Paths.MountConfigPath
    local merchantConfigPath = Paths.MerchantConfigPath
    local bodyPartConfigPath = Paths.BodyPartConfigPath
    local clothingConfigPath = Paths.ClothingConfigPath
    local refConfigPath = Paths.RefConfigPath

    local defaultClothing = DreamMountDefaults.Clothes
    local defaultMerchants = DreamMountDefaults.Merchants
    local defaultMounts = DreamMountDefaults.Mounts
    local defaultParts = DreamMountDefaults.Parts

    self.mountConfig = Load(mountConfigPath) or defaultMounts
    if self.mountConfig == defaultMounts then
        Save(mountConfigPath, self.mountConfig)
    end
    assert(#self.mountConfig >= 1, DreamMountStrings.Err.EmptyMountConfigErr .. Traceback(3))

    self.mountMerchants = Load(merchantConfigPath) or defaultMerchants
    if self.mountMerchants == defaultMerchants then
        Save(merchantConfigPath, self.mountMerchants)
    end

    self.mountParts = Load(bodyPartConfigPath) or defaultParts
    if self.mountParts == defaultParts then
        Save(bodyPartConfigPath, self.mountParts)
    end

    self.mountClothing = Load(clothingConfigPath) or defaultClothing
    if self.mountClothing == defaultClothing then
        Save(clothingConfigPath, self.mountClothing)
    end

    self.mountRefs = Load(refConfigPath) or {}
    if self.mountRefs == {} then
        Save(refConfigPath, self.mountRefs)
    end

    self:logConfig()
end

function DreamMountFunctions:clearCustomVariablesCommand(pid, cmd)
    local UI = DreamMountStrings.UI

    local targetPid = tonumber(cmd[3])
    local targetPlayer = Players[targetPid]
    local callerPlayer = Players[pid]
    local callerCanResetTargetVars = targetPid == pid or canRunMountAdminCommands(callerPlayer)

    if targetPlayer then
        if callerCanResetTargetVars then
            clearCustomVarsForPlayer(targetPlayer)
        else
            return callerPlayer:Message(
                Format(UI.ResetNotAllowedErr, color.Red, targetPlayer.name)
            )
        end
    elseif canRunMountAdminCommands(callerPlayer) and cmd[3] == "all" then
        local playersWhoReset = {}
        for index = 0, #Players do
            local player = Players[index]
            self:clearCustomVariables(player)
            playersWhoReset[#playersWhoReset + 1] = player.name
        end
        SendMessage(pid
                    , Format(DreamMountStrings.Patterns.SingleVarReset
                             , UI.ResetVarsString
                             , Concat(playersWhoReset, ','))
                    , false)
    elseif not cmd[3] then
        clearCustomVarsForPlayer(callerPlayer)
    else
        return callerPlayer:Message(
            Format(UI.InvalidResetPidErr, color.Red, cmd[3])
        )
    end
end

function DreamMountFunctions:setPreferredMount(_, pid, idGui, data)
    if idGui == DreamMountsMountActivateGUIID then
        return self:handleMountActivateMenu(pid, data)
    elseif idGui ~= DreamMountsGUIID then return end

    local player = Players[pid]

    if not player or not player:IsLoggedIn() then return end

    local selection = tonumber(data)

    if not selection or selection == 0 or selection > #self.mountConfig then return end

    local playerListString = self:createMountMenuString(player)
    assert(playerListString, DreamMountStrings.Err.ShouldHaveValidMountErr)

    local lineIndex = 0
    local selectedMountName
    for line in playerListString:gmatch("[^\n]+") do
        if lineIndex == selection then
            selectedMountName = line
            break
        end
        lineIndex = lineIndex + 1
    end

    local selectedMountIndex
    for mountIndex, mountData in ipairs(self.mountConfig) do
        if mountData.name == selectedMountName then
            selectedMountIndex = mountIndex
            break
        end
    end

    local customVariables = getPlayerMountVars(player)

    local prevPreferredMount = customVariables[DreamMountPreferredMountKey]
    if prevPreferredMount and prevPreferredMount == selectedMountIndex then
        return player:Message(Format(DreamMountStrings.UI.SameMountStr,
                                     color.MistyRose,
                                     selectedMountName,
                                     color.Maroon))
    end

    self:despawnMountSummon(player)
    self:despawnBagRef(player)
    dismountIfMounted(player)

    customVariables[DreamMountPreferredMountKey] = selectedMountIndex
    player:QuicksaveToDrive()
end

function DreamMountFunctions:showPreferredMountMenu(pid, _)
    local player = Players[pid]
    if not player or not player:IsLoggedIn() then return end
    local UI = DreamMountStrings.UI

    local DreamMountListString = self:createMountMenuString(player)

    if not DreamMountListString then
        return player:Message(UI.NoMountAvailableStr)
    end

    local listHeader = UI.PreferredMountString

    local currentPreferredMount = getPlayerMountVars(player)[DreamMountPreferredMountKey]
    if currentPreferredMount then
        local playerMountData = self.mountConfig[currentPreferredMount]
        if playerMountData then
            listHeader = Format(UI.PreferredMountMenuHeaderStr, listHeader, playerMountData.name)
        end
    end

    ListBox(pid, DreamMountsGUIID , listHeader, DreamMountListString)
end

function DreamMountFunctions:slowSaveOnEmptyWorld()
    if next(Players) then return end
    local Paths = DreamMountStrings.Paths
    SlowSave(Paths.MountConfigPath, self.mountConfig)
    SlowSave(Paths.MerchantConfigPath, self.mountMerchants)
    SlowSave(Paths.BodyPartConfigPath, self.mountParts)
    SlowSave(Paths.ClothingConfigPath, self.mountClothing)
    SlowSave(Paths.RefConfigPath, self.mountRefs)
end

function DreamMountFunctions:toggleMountCommand(pid)
    local player = Players[pid]
    if not player or not player:IsLoggedIn() then return end
    self:toggleMount(player)
end


function DreamMountFunctions:defaultMountConfig(pid, cmd)
    if not DreamMountFunctions.validateUser(pid) then return end
    local Paths = DreamMountStrings.Paths
    local UI = DreamMountStrings.UI

    ProcessCommand(pid, { 'load', 'custom.dreamMount.dreamMount_defaultConfig' })

    local subArg = cmd[3]
    if subArg then subArg = subArg:lower() end
    local doReload = (cmd[4] and cmd[4] == 'true') or (cmd[3] and cmd[3] == 'true')

    if not subArg or (subArg and subArg == 'true') then
        SlowSave(Paths.MountConfigPath, DreamMountDefaults.Mounts)
        SlowSave(Paths.MerchantConfigPath, DreamMountDefaults.Merchants)
        SlowSave(Paths.BodyPartConfigPath, DreamMountDefaults.Parts)
        SlowSave(Paths.ClothingConfigPath, DreamMountDefaults.Clothes)
        SendMessage(pid, UI.AllDefaultConfigsSaved, false)
    elseif subArg == "mount" then
        local path = Paths.MountConfigPath
        SlowSave(path, DreamMountDefaults.Mounts)
        SendMessage(pid, Format("%s%s\n", UI.DefaultConfigSavedString, path), false)
    elseif subArg == "merchant" then
        local path = Paths.MerchantConfigPath
        SlowSave(path, DreamMountDefaults.Merchants)
        SendMessage(pid, Format("%s%s\n", UI.DefaultConfigSavedString, path), false)
    elseif subArg == "bodypart" then
        local path = Paths.BodyPartConfigPath
        SlowSave(path, DreamMountDefaults.Parts)
        SendMessage(pid, Format("%s%s\n", UI.DefaultConfigSavedString, path), false)
    elseif subArg == "clothing" then
        local path = Paths.ClothingConfigPath
        SlowSave(path, DreamMountDefaults.Clothes)
        SendMessage(pid, Format("%s%s\n", UI.DefaultConfigSavedString, path), false)
    end

    if doReload then
        SendMessage(pid, UI.DefaultConfigsReloading, false)
        self:initMountData()
    end
end

function DreamMountFunctions:reloadMountConfig(pid)
    if not DreamMountFunctions.validateUser(pid) then return end
    ProcessCommand(pid, { 'load', 'custom.dreamMount.dreamMount_strings' })
    self:initMountData()
    SendMessage(pid, DreamMountStrings.UI.ConfigReloadedMessage, false)
end

function DreamMountFunctions:resetPlayerSpells()
    local spellRecords = RecordStores['spell'].data.permanentRecords
    for _, player in pairs(Players) do
        resetMountSpellForPlayer(player, spellRecords)
        resetSummonSpellForPlayer(player, self:getMountData(player), spellRecords)
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
        local mountEffects = getMountActiveEffects(mountData.mountedEffects)

        if mountEffects then
            local spellName = self:getMountSpellNameString(index)
            local spellId = self:getMountSpellIdString(index)
            self.addMountSpellEffect(mountEffects, spellId, spellName, permanentSpells)
            spellsSaved = spellsSaved + 1
        else
            local removeSpellId = self:getMountSpellIdString(index)
            permanentSpells[removeSpellId] = nil
        end

        local petData = mountData.petData
        if petData then
            local petEffects = getMountActiveEffects(petData.aura)
            if petEffects then
                local auraId = getPetAuraStrings(mountData)
                self.addMountSpellEffect(petEffects, auraId, "Guara", permanentSpells)
                spellsSaved = spellsSaved + 1
            else
                local removeSpellId = getPetAuraStrings(mountData)
                permanentSpells[removeSpellId] = nil
            end
        end
    end

    spellRecords:Save()

    if spellsSaved >= 0 and firstPlayer then
        SendRecordDynamic(firstPlayer, true)
    end

    self:resetPlayerSpells()
end

---@param player JSONPlayer
---@return string|nil recordId for the player's mount summon, nil if the player doesn't have a preferred mount set
function DreamMountFunctions:getPlayerMountSummon(player)
    local playerName = player.name
    local customVariables = getPlayerMountVars(player)

    local preferredMount = customVariables[DreamMountPreferredMountKey]
    if not preferredMount then
        return player:Message(Format(DreamMountStrings.Patterns.NoPreferredMountMessage,
                color.Yellow, playerName, DreamMountStrings.UI.NoPreferredMountStr))
    end

    local mountData = self.mountConfig[preferredMount]
    assert(mountData, Format(DreamMountStrings.Err.MountDoesNotExistErr, playerName))
    local mountRefNum = tostring( WorldInstance:GetCurrentMpNum() + 1 )

    return Format("%s_%s_%s_pet", playerName, mountRefNum, mountData.name):lower()
end

function DreamMountFunctions:createContainerRecord(containerRecordInput)
    local player = containerRecordInput.player
    local containerData = containerRecordInput.containerData

    ClearRecords()
    SetRecordType(ContainerRecordType)
    local containerRecordStore = RecordStores["container"]
    local containerRecords = containerRecordStore.data.permanentRecords

    local containerId = self:getContainerRecordId(player)
    if not containerId then return end
    local playerStrength = player.data.attributes.Strength.base
    local containerRecord = {
        name = self:getPlayerPetName(player),
        weight = containerData.carryCapacityBase + ( playerStrength * containerData.carryCapacityPerStrength ),
    }

    containerRecords[containerId] = containerRecord
    containerRecordStore:Save()
    AddContainerRecord(containerId, containerRecord)

    SendRecordDynamic(player.pid, true)
end

--- Note that currently mounts do not update properly when re-summoning
--- What'll need to be done is to replace the summon if it already exists
function DreamMountFunctions:summonCreatureMount(pid, _)
    local player = Players[pid]
    local customVariables = getPlayerMountVars(player)
    local UI = DreamMountStrings.UI

    local preferredMount = customVariables[DreamMountPreferredMountKey]
    if not preferredMount then
        return player:Message(Format(DreamMountStrings.Patterns.NoPreferredMountMessage,
            color.Yellow, player.name, UI.NoPreferredMountStr))
    end

    dismountIfMounted(player)

    local petId = self:getPlayerMountSummon(player)
    if not petId then return end

    local mountData = self.mountConfig[preferredMount]

    if not hasMountKey(player) then return end

    local mountName = mountData.name
    if not mountData.petData then
        return player:Message(Format(UI.NotAPetStr, color.Red, mountName))
    end

    self:despawnMountSummon(player)

    if not customVariables[DreamMountCurrentSummonsKey] then
        customVariables[DreamMountCurrentSummonsKey] = {}
    end

    local summonsTable = customVariables[DreamMountCurrentSummonsKey]
    summonsTable[mountName] = petId

    self:createContainerRecord {
        player = player,
        mountName = mountName,
        containerData = mountData.containerData
    }

    local petData = mountData.petData
    createPetRecord {
        mountName = mountName,
        petId = petId,
        player = player,
        playerPetData = petData,
    }

    self:spawnMountSummon(player, petId)

    sendCreatureAttributePacket {
        player = player,
        petId = petId,
        playerPetData = petData
    }

    local auraId = getPetAuraStrings(mountData)
    toggleSpell(auraId, player)
    customVariables[DreamMountPrevAuraId] = auraId

    mountLog(Format(DreamMountStrings.Log.MountSummonSpawnedStr,
                    mountName,
                    player.name,
                    player.data.location.cell,
                    customVariables[DreamMountSummonRefNumKey]))
end

function DreamMountFunctions:initMountData()
    local firstPlayer = next(Players)

    self:loadMountConfig()
    self:createMountSpells(firstPlayer)
    self:createKeyRecords(firstPlayer)
    self:createBodyPartRecords(firstPlayer)
    self:createClothingRecords(firstPlayer)
    createScriptRecords()
end

---@param mountIndex integer
---@return string
function DreamMountFunctions:getMountSpellIdString(mountIndex)
    return Format(DreamMountStrings.Patterns.SpellNameTemplate, self.mountConfig[mountIndex].item)
end

---@param mountIndex integer
---@return string
function DreamMountFunctions:getMountSpellNameString(mountIndex)
    return Format(DreamMountStrings.Patterns.SpellNameTemplate, self.mountConfig[mountIndex].name)
end

-- Include an extra unused param on table functions which don't actually use self,
-- since they'll be called with self as an argument whether we want them to or not
function DreamMountFunctions.trackPlayerMountCell(_, _, pid, _)
    local player = Players[pid]
    local customVariables = getPlayerMountVars(player)

    ReadReceivedActorList()
    for actorIndex = 0, GetActorListSize() - 1 do
        if actorPacketUniqueIndex(actorIndex) == customVariables[DreamMountSummonRefNumKey] then
            customVariables[DreamMountSummonCellKey] = GetActorCell(actorIndex)
            player:QuicksaveToDrive()
        end
    end
end

function DreamMountFunctions:onMountDied(_, pid, _)
    local player = Players[pid]
    local customVariables = getPlayerMountVars(player)

    ReadReceivedActorList()
    for actorIndex = 0, GetActorListSize() - 1 do
        local summonUniqueIndex = actorPacketUniqueIndex(actorIndex)
        if summonUniqueIndex == customVariables[DreamMountSummonRefNumKey] then
            self:despawnMountSummon(player)
        -- Somebody's mount died, but it wasn't ours.
        -- Despawn the mount and remove it from local tracking.
        elseif self.mountRefs[summonUniqueIndex] then
            local summonCell = GetActorCell(actorIndex)
            DeleteObjectForEveryone(summonCell, summonUniqueIndex)
            self.mountRefs[summonUniqueIndex] = nil
        end
    end
end

function DreamMountFunctions:openContainerForNonSummon(pid, _)
    local player = Players[pid]
    assert(player and player:IsLoggedIn(), Traceback(3))
    if not self:selectedMountIsPet(player) then
        self:activateMountContainer(player)
    else
        player:Message(DreamMountStrings.UI.MountMustBeSummonedStr)
    end
end

function DreamMountFunctions:cleanUpMountOnLogin(_, pid)
    local player = Players[pid]
    assert(player, DreamMountStrings.Err.UnloggedPlayerSummonErr .. '\n' .. Traceback(3))
    self:despawnBagRef(player)
    self:despawnMountSummon(player)
    dismountIfMounted(player)
end

function DreamMountFunctions.dismountOnHit(_, _, _, _, _, targetPlayers)
    for _, targetPlayer in pairs(targetPlayers) do
        dismountIfMounted(targetPlayer)
    end
end

function DreamMountFunctions:handleMountActivation(_, _, cellDescription, objects, _)
    local firstIndex, firstObject = next(objects)
    local activatingPlayer = Players[firstObject.activatingPid]
    local activatingName = activatingPlayer.name
    local owningPlayer = self.mountRefs[firstIndex]
    local UI = DreamMountStrings.UI

    if not owningPlayer then
        return
    elseif owningPlayer ~= activatingName then
        return MessageBox(activatingPlayer.pid, -1, UI.UnownedMountActivateStr)
    end

    mountLog(Format(DreamMountStrings.Log.MountActivatedStr,
                 activatingName,
                 firstObject.refId,
                 firstIndex,
                 cellDescription))

    activatingPlayer:MessageBox(DreamMountsMountActivateGUIID,
                                UI.ActivateMenuHeader,
                                UI.ActivateMenuChoices)

    return EventStatus(false, false)
end

function DreamMountFunctions:denyMountClothingRemoval(_, pid, _)
    local player = Players[pid]
    if not getPlayerMountVars(player)[DreamMountEnabledKey] then return end

    if tes3mp.GetInventoryChangesAction(pid) ~= RemoveFromInventory then return end

    local itemChangesCount = tes3mp.GetInventoryChangesSize(pid)

    local mountData = self:getMountData(player)
    local mountItemId = mountData.item:lower()

    for index = 0, itemChangesCount - 1 do
        local ObjectRefId = tes3mp.GetInventoryItemRefId(pid, index)

        if ObjectRefId and ObjectRefId == mountItemId then
            CloseMenu(pid)
            return customEventHooks.makeEventStatus(false, false)
        end
    end
end

function DreamMountFunctions:replaceMountClothingOnRemoval(_, pid, playerPacket)
    local player = Players[pid]
    if not getPlayerMountVars(player)[DreamMountEnabledKey] then return end

    local equipmentSlot, equipmentData = next(playerPacket.equipment)

    local mountData = self:getMountData(player)
    local mountItem = mountData.item:lower()

    local mountType = mountData.mountType or MountTypes.Shirt
    local mountSlot = MountSlotMap[mountType]
    local mappedEquipSlot = EquipEnums[mountSlot]

    local removedMountItem = equipmentData.refId ~= mountItem or equipmentData.count == 0
    if equipmentSlot == mappedEquipSlot and removedMountItem then
        CloseMenu(player)
        player:updateEquipment {
            [mountSlot] = mountData.item
        }
        return EventStatus(false, false)
    end
end

return DreamMountFunctions
