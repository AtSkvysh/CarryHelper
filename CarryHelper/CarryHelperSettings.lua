function CarryHelper.SettingsBuildMenu() --construct the settings tab
  local LAM2 = LibAddonMenu2
  
  local addonPanel = {
    type                = 'panel',
    name                = CarryHelper.name,
    displayName         = ZO_ColorDef:New('3366cc'):Colorize(CarryHelper.name),
    version             = CarryHelper.version,
    registerForRefresh  = true,
    registerForDefaults = true,
  }
  
  local optionControls = {
    {
      type = "checkbox",
      name = "Enable auto trade accept",
      tooltip = "Enable automatic trade offer accept when a trade window pops up, removing one button press per trade. Will only happen for people that haven't traded yet and while the tracker is enabled.",
      getFunc = function() return CarryHelper.settings.autoAccept end,
      setFunc = function(value)
        CarryHelper.settings.autoAccept = value
      end
    }, 
    {
      type = "checkbox",
      name = "Show UI",
      tooltip = "Turns on UI so you can reposition it. Should be left disabled once you're done repositioning it.",
      getFunc = function() return CarryHelper.showUI end,
      setFunc = function(value)
        CarryHelper.showUI = value
        CarryHelper.TestUI()
      end
    }, 
    {
      type = "checkbox",
      name = "Enable debug",
      tooltip = "Enable messages in chat for debugging purposes. WARNING: will get spammy under normal circumstances. Only enable if you absolutely know what you're doing.",
      getFunc = function() return CarryHelper.settings.debug end,
      setFunc = function(value)
        CarryHelper.settings.debug = value
      end
    }, 
  }
    
  LAM2:RegisterAddonPanel('CarryHelperPanel', addonPanel)
  LAM2:RegisterOptionControls('CarryHelperPanel', optionControls)
end

function CarryHelper.SettingsLoad() --set the default settings, then load if there are any saved previously
  local defaultSettings = {
    debug = true,
    autoAccept = false,
    left = 1000,
    top = 500,
    maxRows = 6,
    trackersStarted = 0,
    trackersSuccessful = 0,
    goldTotal = 0,
    goldHighScore = 0,
  }
  CarryHelper.settings = ZO_SavedVars:New('CarryHelperSavedVariables', CarryHelper.varVersion, nil, defaultSettings)
end