local Format = string.format
local Traceback = debug.traceback

local AddSpell = tes3mp.AddSpell
local ClearSpellbookChanges = tes3mp.ClearSpellbookChanges
local ContainsItem = inventoryHelper.containsItem
local EquipItem = tes3mp.EquipItem
local ProcessCommand = commandHandler.ProcessCommand
local RegisterCommand = customCommandHooks.registerCommand
local RegisterHandler = customEventHooks.registerHandler
local SendEquipment = tes3mp.SendEquipment
local SendMessage = tes3mp.SendMessage
local SendSpellbookChanges = tes3mp.SendSpellbookChanges
local SetSpellbookChangesAction = tes3mp.SetSpellbookChangesAction

local SpellbookAdd = enumerations.spellbook.ADD
local SpellbookRemove = enumerations.spellbook.REMOVE

local MediumBlue = color.MediumBlue
local Red = color.Red

local DreamMountFunctionsPath = 'custom.dreamMount.dreamMount_functions'
local DreamMountFunctions = require(DreamMountFunctionsPath)

local DreamMountUnsupportedCommandStr = '%sUnsupported DreamMount subcommand %s%s!\n'

local DreamMountInvalidEquipSlotErr = "Invalid equipment slot provided %s!"
local DreamMountNoCallbackErr = 'No DreamMount callback associated with this function %s!\n%s'
local DreamCoreNoPlayerSpellbookWithoutSelfErr = 'Cannot call player spellbook update without self!\n'
local DreamCoreInvalidSpellDataErr = 'Invalid spellData table provided!\n'

local ItemTemplate = dataTableBuilder.BuildObjectData()
local EquipEnums = enumerations.equipment

---@alias SpellSendData table<string, boolean>
---@alias EquipSendData table<string, string|false>

---@param self table Player table indexed from Players[pid]
---@param spellData SpellSendData
local function updatePlayerSpellbook(self, spellData)
  assert(self,  DreamCoreNoPlayerSpellbookWithoutSelfErr .. Traceback(3))
  assert(type(spellData) == 'table', DreamCoreInvalidSpellDataErr .. Traceback(3))

  local playerId = self.pid
  ClearSpellbookChanges(playerId)

  for spellId, addOrRemove in pairs(spellData) do
    SetSpellbookChangesAction(playerId , (addOrRemove and SpellbookAdd) or SpellbookRemove)
    AddSpell(playerId, spellId)
  end

  SendSpellbookChanges(playerId)
end

---@param self table Player table index from Players[pid]
---@param equipmentUpdateTable EquipSendData
local function updateEquipment(self, equipmentUpdateTable)
  local myPid = self.pid
  local myData = self.data
  local prevEquipment = self.previousEquipment
  local myEquipment = myData.equipment
  local myInventory = myData.inventory

  for equipmentSlot, itemId in pairs(equipmentUpdateTable) do
    local slotId = EquipEnums[equipmentSlot]
    assert(slotId, Format(DreamMountInvalidEquipSlotErr, equipmentSlot))
    if itemId ~= false and ContainsItem(myInventory, itemId) then
      local targetItem = ItemTemplate
      targetItem.refId = itemId

      EquipItem(myPid, slotId
                          , targetItem.refId, targetItem.count
                          , targetItem.charge, targetItem.enchantmentCharge)
      prevEquipment[slotId] = myEquipment[slotId]
      myEquipment[slotId] = targetItem
    else
      myEquipment[slotId] = nil
    end
  end
  SendEquipment(myPid)
end

--- Extend built-in functionality of certain object types on server initialization
local function extendBuiltins()
  Player['updateSpellbook'] = updatePlayerSpellbook
  Player['updateEquipment'] = updateEquipment
end

---@class HandlerRegistration
---@field registrar function
---@field callbackModule table
---@field event string
---@field callbackName string
---@field canUseSelf boolean

---Replacement for internal registration functions which uses table lookups
---in order to avoid "stuck" references to functions when reloading
---@param registerData HandlerRegistration
local function localRegisterThing(registerData)
  local lookupModule = registerData.callbackModule
  local callbackName = registerData.callbackName
  local DWGenericCallback = lookupModule[callbackName]

  assert(DWGenericCallback
  , Format(DreamMountNoCallbackErr
  , callbackName
  , Traceback(3)))

  registerData.registrar(registerData.event, registerData.canUseSelf
    and function(...) return DWGenericCallback(lookupModule, ...) end
    or function(...) return DWGenericCallback(...) end
  )
end

---@param pid PlayerId
local function reloadMountFuncs(pid)
    ProcessCommand(pid, { 'load', DreamMountFunctionsPath })
    DreamMountFunctions:initMountData()
end

---@param failedCommand string
---@return string Unsupported mount message
local function unsupportedCommandString(failedCommand)
  return Format(DreamMountUnsupportedCommandStr
                            , MediumBlue, failedCommand, Red)
end

---@alias Subcommand
---| "'menu'"
---| "'reloadConfig'"
---| "'defaultConfig'"
---| "'clearPlayerVars'"
---| "'summon'"

---@alias CommandId
---| "'showPreferredMountMenu'"
---| "'reloadMountConfig'"
---| "'defaultMountConfig'"
---| "'clearCustomVariablesCommand'"
---| "'summonCreatureMount'"

---@type table <Subcommand, CommandId>
local mountFuncs = {
  menu = 'showPreferredMountMenu',
  reloadConfig = 'reloadMountConfig',
  defaultConfig = 'defaultMountConfig',
  clearPlayerVars = 'clearCustomVariablesCommand',
  summon = "summonCreatureMount",
}

---@param pid PlayerId
---@param cmd string[]
local function handleMountCommand(pid, cmd)
  local subCommand = cmd[2]

  if not subCommand then DreamMountFunctions:toggleMountCommand(pid)
  elseif subCommand == 'reload' and DreamMountFunctions.validateUser(pid) then reloadMountFuncs(pid)
  elseif mountFuncs[subCommand] then DreamMountFunctions[mountFuncs[subCommand]](DreamMountFunctions, pid, cmd)
  else SendMessage(pid, unsupportedCommandString(subCommand), false) end

end

for eventName, callbackName in pairs {
  OnServerPostInit = 'initMountData',
  OnGUIAction = 'setPreferredMount',
  OnPlayerDisconnect = 'slowSaveOnEmptyWorld',
  OnObjectDialogueChoice = 'reloadMountMerchants',
  OnActorCellChange = 'trackPlayerMountCell',
  OnActorDeath = 'onMountDied',
} do localRegisterThing
  {
    registrar = RegisterHandler,
    event = eventName,
    callbackModule = DreamMountFunctions,
    callbackName = callbackName,
    canUseSelf = true
  }
end

RegisterCommand('ride', handleMountCommand)
RegisterHandler('OnServerPostInit', extendBuiltins)
