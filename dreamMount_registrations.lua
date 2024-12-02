local Format = string.format
local Traceback = debug.traceback

local AddSpell = tes3mp.AddSpell
local ClearSpellbookChanges = tes3mp.ClearSpellbookChanges
local ProcessCommand = commandHandler.ProcessCommand
local RegisterCommand = customCommandHooks.registerCommand
local RegisterHandler = customEventHooks.registerHandler
local SendMessage = tes3mp.SendMessage
local SendSpellbookChanges = tes3mp.SendSpellbookChanges
local SetSpellbookChangesAction = tes3mp.SetSpellbookChangesAction

local SpellbookAdd = enumerations.spellbook.ADD
local SpellbookRemove = enumerations.spellbook.REMOVE

local MediumBlue = color.MediumBlue
local Red = color.Red

local DreamMountFunctionsPath = 'custom.dreamMount.dreamMount_functions'
local DreamMountFunctions = require(DreamMountFunctionsPath)

local DreamMountNoCallbackErr = 'No DreamMount callback associated with this function %s!\n%s'
local DreamMountUnsupportedCommandStr = '%sUnsupported DreamMount subcommand %s%s!'
local DreamCoreNoPlayerSpellbookWithoutSelfStr = 'Cannot call player spellbook update without self!\n'
local DreamCoreInvalidSpellDataStr = 'Invalid spellData table provided!\n'

---@class SpellSendData
---@field self table Player table
---@field spellData table<string, boolean>
local function updatePlayerSpellbook(self, spellData)
  assert(self,  DreamCoreNoPlayerSpellbookWithoutSelfStr .. Traceback(3))
  assert(type(spellData) == 'table', DreamCoreInvalidSpellDataStr .. Traceback(3))

  local playerId = self.pid
  ClearSpellbookChanges(playerId)

  for spellId, addOrRemove in pairs(spellData) do
    SetSpellbookChangesAction(playerId , (addOrRemove and SpellbookAdd) or SpellbookRemove)
    AddSpell(playerId, spellId)
  end

  SendSpellbookChanges(playerId)
end

--- Extend built-in functionality of certain object types on server initialization
local function extendBuiltins()
  Player['updateSpellbook'] = updatePlayerSpellbook
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

---@alias CommandId
---| "'showPreferredMountMenu'"
---| "'reloadMountConfig'"
---| "'defaultMountConfig'"
---| "'clearCustomVariablesCommand'"

---@type table <Subcommand, CommandId>
local mountFuncs = {
  menu = 'showPreferredMountMenu',
  reloadConfig = 'reloadMountConfig',
  defaultConfig = 'defaultMountConfig',
  clearPlayerVars = 'clearCustomVariablesCommand',
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
  OnPlayerDisconnect = 'slowSaveOnEmptyWorld'
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
