local ProcessCommand = commandHandler.ProcessCommand
local RegisterCommand = customCommandHooks.registerCommand
local RegisterHandler = customEventHooks.registerHandler
local SendMessage = tes3mp.SendMessage

local DreamMountFunctions = require('custom.dreamMount.dreamMount_functions')

local Format = string.format

local DreamMountNoCallbackErr = 'No DreamMount callback associated with this function %s!\n%s'
local DreamMountUnsupportedCommandStr = '%sUnsupported DreamMount subcommand %s%s!'

local function localRegisterThing(registerFunction, lookupModule, eventName, callbackName)
  registerFunction(eventName, function(...)
                     local DWGenericCallback = lookupModule[callbackName]

                     assert(DWGenericCallback
                            , Format(DreamMountNoCallbackErr
                                     , callbackName
                                     , debug.traceback(3)))

                     DWGenericCallback(...)
  end)
end

local mountFuncs = {
  menu = 'showPreferredMountMenu',
  reloadConfig = 'reloadMountConfig',
  defaultConfig = 'defaultMountConfig',
  clearPlayerVars = 'clearCustomVariablesCommand',
}

local function reloadMountFuncs(pid)
    ProcessCommand(pid, {'load', 'custom.dreamMount.dreamMount_functions'})
    DreamMountFunctions.initMountData()
end

local function unsupportedCommandString(failedCommand)
  return Format(DreamMountUnsupportedCommandStr
                            , color.MediumBlue, failedCommand, color.Red)
end

local function handleMountCommand(pid, cmd)
  local subCommand = cmd[2]

  if not subCommand then DreamMountFunctions['toggleMountCommand'](pid)
  elseif subCommand == 'reload' and DreamMountFunctions.validateUser(pid) then reloadMountFuncs(pid)
  elseif mountFuncs[subCommand] then DreamMountFunctions[mountFuncs[subCommand]](pid, cmd)
  else SendMessage(pid, unsupportedCommandString(subCommand), false) end

end

RegisterCommand('ride', handleMountCommand)

for eventName, callbackName in pairs {
  OnServerPostInit = 'initMountData',
  OnGUIAction = 'setPreferredMount',
  OnPlayerDisconnect = 'slowSaveOnEmptyWorld'
} do
  localRegisterThing(RegisterHandler, DreamMountFunctions, eventName, callbackName)
end
