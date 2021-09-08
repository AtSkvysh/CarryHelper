--[[
TODO:
Post-release:
20) Settings for UI colours, size, etc., adjustable goldDelay value and panelTimeout
21) Optional string for carry name, to make things simplier on user's end in some scenarios
]]

--[[
Changelog:
0.1.4: API bump for Waking Flame.

0.1.3: Catch incoming trade party names regardless of whether the UI is running or not. The rest of the functionality should stay the same.

0.1.2: Remove unnecessary unitTag usage.
       Change alphas of colour boxes of people who haven't traded yet.

0.1.1: Switch to looping through the entire UI group and checking for names there,
instead of looping through all the current members.

0.1.0: Initial version
]]

CarryHelper = {
  name = "CarryHelper",
  title = "CarryHelper",
  version = "0.1.4",
  varVersion = 1,
  shareAmount = 0, -- gold share for each person
  numGroupMembers = 0, -- number of group members
  numTraded = 0, -- number of people that traded for gold. we want this to be numGroupMembers-2
  tradePartyName = "", -- name of the party trading with
  trackerEnabled = false, -- global check if we're running the panel or not
  slashCommands = "/ch", -- slash command trigger
  startGold = 0, -- gold that you started the tracker with
  expectedGold = 0, -- gold you expect to end with
  panels = { }, -- UI panel table
  units = { }, -- character names and their status (in terms of traded gold)
  sendingGold = false, -- check if we're sending gold to the right person
  panelTimeout = 20, -- timeout for the panel when we successfully trade everyone (seconds)
  destroyingUI = false, -- check for whether or not we're destroing UI once panelTimeout passes, to avoid doing additional trades accidentally
  showUI = false, -- boolean for displaying UI to move it around
  goldDelay = 300, -- delay between opening trade window and adding gold
}

function CarryHelper.DisplayMessage(message)  -- Display message if debugging
  if CarryHelper.settings.debug then
    d(message)
  end
end

function CarryHelper.StartTracker() -- Start the tracker if all conditions via chat command are met
  CarryHelper.trackerEnabled = true
  CarryHelper.settings.trackersStarted = CarryHelper.settings.trackersStarted + 1
  CarryHelper.destroyingUI = false
  CarryHelper.numTraded = 0
  CarryHelper.startGold = GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER)
  CarryHelper.expectedGold = CarryHelper.startGold - math.abs(CarryHelper.shareAmount*(CarryHelper.numGroupMembers-2))
  SCENE_MANAGER:GetScene("hud"):AddFragment(CarryHelper.fragment)
  SCENE_MANAGER:GetScene("hudui"):AddFragment(CarryHelper.fragment)
  CarryHelper.Reset()
  EVENT_MANAGER:RegisterForEvent("CarryHelperTradeConsidering", EVENT_TRADE_INVITE_CONSIDERING, CarryHelper.TradeConsidering)
  EVENT_MANAGER:RegisterForEvent("CarryHelperTradeWaiting", EVENT_TRADE_INVITE_WAITING, CarryHelper.TradeWaiting)
  EVENT_MANAGER:RegisterForEvent("CarryHelperTradeAccepted", EVENT_TRADE_INVITE_ACCEPTED, CarryHelper.TradeAccepted)
  EVENT_MANAGER:RegisterForEvent("CarryHelperTradeSucceeded", EVENT_TRADE_SUCCEEDED, CarryHelper.TradeSucceeded)
  EVENT_MANAGER:RegisterForEvent("CarryHelperLeftGroup", EVENT_GROUP_MEMBER_LEFT, CarryHelper.GroupStatusCheck)
  
  local message = "Starting CarryHelper tracker with " .. CarryHelper.numGroupMembers .. " members in the group and " .. CarryHelper.shareAmount .. " gold share.\n"
  message = message .. "Current gold is " .. CarryHelper.startGold .. ". Expected end gold is " .. CarryHelper.expectedGold .. "."
  CarryHelper.DisplayMessage(message)
end

function CarryHelper.EndTracker() -- End tracker if we traded everyone or used a chat command or left the group
  CarryHelper.trackerEnabled = false
  CarryHelper.numTraded = 0
  CarryHelper.numGroupMembers = 0
  CarryHelper.startGold = 0
  CarryHelper.expectedGold = 0
  CarryHelper.shareAmount = 0
  CarryHelper.HideUI()
  EVENT_MANAGER:UnregisterForUpdate("CarryHelperCountdown")
  EVENT_MANAGER:UnregisterForEvent("CarryHelperTradeConsidering", EVENT_TRADE_INVITE_CONSIDERING)
  EVENT_MANAGER:UnregisterForEvent("CarryHelperTradeWaiting", EVENT_TRADE_INVITE_WAITING)
  EVENT_MANAGER:UnregisterForEvent("CarryHelperTradeAccepted", EVENT_TRADE_INVITE_ACCEPTED)
  EVENT_MANAGER:UnregisterForEvent("CarryHelperTradeSucceeded", EVENT_TRADE_SUCCEEDED)
end

function CarryHelper.TradeConsidering(eventCode, charName, displayName) -- Incoming trade request event function
  CarryHelper.tradePartyName = displayName
  if CarryHelper.trackerEnabled then
    local message = "Incoming trade request from " .. CarryHelper.tradePartyName
    CarryHelper.DisplayMessage(message)
  end
end

function CarryHelper.TradeWaiting(eventCode, charName, displayName) -- Waiting for other party to accept trade request event function
  CarryHelper.tradePartyName = displayName
  if CarryHelper.trackerEnabled then
    local message = "Sending trade request to " .. CarryHelper.tradePartyName
    CarryHelper.DisplayMessage(message)
  end
end

function CarryHelper.TradeAccepted() -- Trade accepted event function
  CarryHelper.sendingGold = false
  if CarryHelper.trackerEnabled and not CarryHelper.destroyingUI then
    for i = 1, CarryHelper.numGroupMembers do
      if CarryHelper.tradePartyName == CarryHelper.units[i].playerName then -- We only want to trade with people who haven't gotten their money yet
        if CarryHelper.units[i].count == 0 then
          TradeSetMoney(CarryHelper.shareAmount)
          CarryHelper.sendingGold = true -- Inform the next function that we indeed traded the gold
          if CarryHelper.settings.autoAccept then
            zo_callLater(CarryHelper.CallTradeAccept, CarryHelper.goldDelay) -- give a sufficient delay before auto-accepting the trade
          end
          local message = "Initiating trade of " .. CarryHelper.shareAmount .. " gold piece(s) to " .. CarryHelper.tradePartyName
          CarryHelper.DisplayMessage(message)
        else
          local message = CarryHelper.tradePartyName .. " already got their gold."
          CarryHelper.DisplayMessage(message)
        end
        break
      end
    end
  end
end

function CarryHelper.CallTradeAccept() -- Auto accept trade function, needs to be called after a slight delay
  TradeAccept()
end

function CarryHelper.TradeSucceeded() -- Trade succeeded with the help of the addon, although it assumes that the gold value was unaltered
  if CarryHelper.trackerEnabled then
    if CarryHelper.sendingGold then
      for i = 1, CarryHelper.numGroupMembers do -- We want to change that person's panel to green, so find it and do so
        if CarryHelper.tradePartyName == CarryHelper.units[i].playerName then
          CarryHelper.units[i].count = 1
          CarryHelper.UpdateStatus(i)
          CarryHelper.numTraded = CarryHelper.numTraded + 1
          CarryHelper.CheckTradeNumbers()
          CarryHelper.settings.goldTotal = CarryHelper.settings.goldTotal + CarryHelper.shareAmount
          if CarryHelper.shareAmount > CarryHelper.settings.goldHighScore then
            CarryHelper.settings.goldHighScore = CarryHelper.shareAmount
          end
          local message = "Successfully traded " .. CarryHelper.shareAmount .. " gold piece(s) to " .. CarryHelper.tradePartyName
          CarryHelper.DisplayMessage(message)
          break
        end
      end
    end
  end
end

function CarryHelper.CheckTradeNumbers() -- After every traded person, check if we have traded everyone we should've
  if CarryHelper.numGroupMembers - CarryHelper.numTraded <= 2 then
    local message = "Successfully traded all " .. CarryHelper.numTraded .. " members (excluding you and the carry). "
    CarryHelper.settings.trackersSuccessful = CarryHelper.settings.trackersSuccessful + 1
    if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) == CarryHelper.expectedGold then
      message = message .. "Current gold matches expected gold."
    else
      message = message .. "Current gold does NOT match the expected gold. "
      if GetCurrencyAmount(CURT_MONEY, CURRENCY_LOCATION_CHARACTER) >= CarryHelper.expectedGold then
        message = message .. "Did you miss someone?"
      else
        message = message .. "Did you give away too much?"
      end
    end
    CarryHelper.DisplayMessage(message)
    message = "Will remove tracker panel in " .. CarryHelper.panelTimeout .. " seconds."
    CarryHelper.DisplayMessage(message)
    CarryHelper.destroyingUI = true
    EVENT_MANAGER:RegisterForUpdate("CarryHelperCountdown", CarryHelper.panelTimeout*1000, function() CarryHelper.TradeTrackerTimeout() end)
  end
end

function CarryHelper.TradeTrackerTimeout() -- Initiate panel removal and tracker end once we've waited long enough
  EVENT_MANAGER:UnregisterForUpdate("CarryHelperCountdown")
  local message = "CarryHelper panel removed due to timeout."
  CarryHelper.DisplayMessage(message)
  CarryHelper.EndTracker()
end

function CarryHelper.GroupStatusCheck(eventCode, memberCharacterName, reason, isLocalPlayer, isLeader, memberDisplayName, actionRequiredVote) -- Check if we've left the group and remove the UI if so
  if CarryHelper.trackerEnabled then
    if GetGroupSize() == 0 or GetUnitDisplayName("player") == memberDisplayName then
      EVENT_MANAGER:RegisterForUpdate("CarryHelperCountdown", CarryHelper.panelTimeout*1000, function() CarryHelper.TradeTrackerTimeout() end)
      local message = "No longer part of group. Will remove tracker panel in " .. CarryHelper.panelTimeout .. " seconds."
      CarryHelper.DisplayMessage(message)
      CarryHelper.destroyingUI = true
    end
  end
end

function CarryHelper.HandleSlashCommands(cmd) -- Slash command function
  local options = {}
  local searchResult = { string.match(cmd,"^(%S*)%s*(.-)$") }
  for i,v in pairs(searchResult) do
      if (v ~= nil and v ~= "") then
          options[i] = string.lower(v)
      end
  end
  if options[1] == "start" then -- If we do /ch start, check for additional argument
    if tonumber(options[2]) ~= nil then
      options[2] = tonumber(options[2])
      if options[2] == math.floor(options[2]) and options[2] > 0 then
        if not CarryHelper.trackerEnabled then
          CarryHelper.numGroupMembers = GetGroupSize()
          if CarryHelper.numGroupMembers >= 4 then
            CarryHelper.shareAmount = options[2]
            CarryHelper.StartTracker()
          else
            CHAT_ROUTER:AddSystemMessage("CH: Tracker does not make sense with less than 4 people in the group")
          end
        else
          CHAT_ROUTER:AddSystemMessage("CH: Tracker already active.")
        end
      else
        CHAT_ROUTER:AddSystemMessage("CH: Invalid number specified. Must be a positive number with no decimals.")
      end
    else
      CHAT_ROUTER:AddSystemMessage("CH: Number as additional argument expected.")
    end
  elseif options[1] == "end" then -- We can also end the tracker with /ch end
    if CarryHelper.trackerEnabled then
      CarryHelper.EndTracker()
      CHAT_ROUTER:AddSystemMessage("CH: Destroying the tracker and UI.")
    else
      CHAT_ROUTER:AddSystemMessage("CH: No active tracker.")
    end
  elseif options[1] == "stats" then
    CarryHelper.DisplayStats()
  else -- If anything else was provided, display available commands instead
    CHAT_ROUTER:AddSystemMessage("CH: Available commands:")
    CHAT_ROUTER:AddSystemMessage("/ch start <amount> – Enable trade tracker with the specified amount of gold as a single share.")
    CHAT_ROUTER:AddSystemMessage("/ch end – Disable trade tracker, destroy UI and clear associated variables.")
    CHAT_ROUTER:AddSystemMessage("/ch stats – Display silly stats.")
  end
end

function CarryHelper.DisplayStats()
  CHAT_ROUTER:AddSystemMessage("Carry Helper stats:")
  CHAT_ROUTER:AddSystemMessage("Trackers started: " .. CarryHelper.settings.trackersStarted)
  CHAT_ROUTER:AddSystemMessage("Successfully finished trackers: " .. CarryHelper.settings.trackersSuccessful)
  local gold, suffix = CarryHelper.GetGoldSuffix(CarryHelper.settings.goldTotal)
  CHAT_ROUTER:AddSystemMessage("Total gold traded: " .. gold .. suffix)
  gold, suffix = CarryHelper.GetGoldSuffix(CarryHelper.settings.goldHighScore)
  CHAT_ROUTER:AddSystemMessage("Largest amount of gold traded: " .. gold .. suffix)
end

function CarryHelper.InitializeControls() -- Initialize UI when first loading the addon
	local wm = GetWindowManager()
  -- Setup the first panel with the pre-defined text separately
  local panel = wm:CreateControlFromVirtual("CarryHelperPanel" .. 0, CarryHelperFrame, "CarryHelperPanel")
  CarryHelper.panels[0] = {
		panel = panel,
		bg = panel:GetNamedChild("Backdrop"),
		name = panel:GetNamedChild("Name"),
  }
  CarryHelper.panels[0].bg:SetEdgeColor(0, 0, 0, 0)
  CarryHelper.panels[0].bg:SetCenterColor(0, 0, 0, 1)
  
	for i = 1, GROUP_SIZE_MAX do
		local panel = wm:CreateControlFromVirtual("CarryHelperPanel" .. i, CarryHelperFrame, "CarryHelperPanel")

		CarryHelper.panels[i] = {
			panel = panel,
			bg = panel:GetNamedChild("Backdrop"),
			name = panel:GetNamedChild("Name"),
			stat = panel:GetNamedChild("Stat"),
		}

		CarryHelper.panels[i].bg:SetEdgeColor(0, 0, 0, 0)
		CarryHelper.panels[i].stat:SetColor(0, 0, 0, 0)
	end

	CarryHelperFrame:ClearAnchors()
	CarryHelperFrame:SetAnchor(TOPLEFT, GuiRoot, TOPLEFT, CarryHelper.settings.left, CarryHelper.settings.top)

	CarryHelper.fragment = ZO_HUDFadeSceneFragment:New(CarryHelperFrame)
end

function CarryHelper.Reset() -- Create UI
	local numGroupMembers = GetGroupSize()
	CarryHelper.units = { }
  -- Handle first panel with gold per person text
  local gold, suffix = CarryHelper.GetGoldSuffix(CarryHelper.shareAmount)
  CarryHelper.panels[0].name:SetText("Share p.p.: " .. gold .. suffix .. " gold")
  CarryHelper.panels[0].panel:SetAnchor(TOPLEFT, CarryHelperFrame, TOPLEFT, 0, 0)
  CarryHelper.panels[0].panel:SetHidden(false)
  CarryHelper.panels[0].bg:SetCenterColor(0, 0, 0, 1)
  --
  
	for i = 1, GROUP_SIZE_MAX do -- Handle other panels
		local soloPanel = i == 1 and numGroupMembers == 0

		if (i <= numGroupMembers or soloPanel) then
			local unitTag = (soloPanel) and "player" or GetGroupUnitTagByIndex(i)
			CarryHelper.units[i] = {
				panelId = i,
				count = 0,
				self = AreUnitsEqual("player", unitTag),
        playerName = GetUnitDisplayName(unitTag) or ""
			}
			CarryHelper.panels[i].name:SetText(GetUnitDisplayName(unitTag))

			CarryHelper.UpdateStatus(i)

			if (i <= CarryHelper.settings.maxRows) then -- Are we on the first column?
				CarryHelper.panels[i].panel:SetAnchor(TOPLEFT, CarryHelper.panels[i - 1].panel, BOTTOMLEFT, 0, 0)
			else -- 2nd column
				CarryHelper.panels[i].panel:SetAnchor(TOPLEFT, CarryHelper.panels[i - CarryHelper.settings.maxRows].panel, TOPRIGHT, 0, 0)
			end
			CarryHelper.panels[i].panel:SetHidden(false) -- Unhide panels for existing players
		else
			CarryHelper.panels[i].panel:SetAnchor(TOPLEFT, CarryHelperFrame, TOPLEFT, 0, 0)
			CarryHelper.panels[i].panel:SetHidden(true)
		end
	end
end

function CarryHelper.UpdateStatus(unitTag) -- Update name panels based on whether they got the gold or not
	local bg = CarryHelper.panels[CarryHelper.units[unitTag].panelId].bg

	if CarryHelper.units[unitTag].count >= 1 then -- GREEN
		bg:SetCenterColor(0, 1, 0, 1)
	elseif CarryHelper.units[unitTag].self then -- SELF, always red-ish
		bg:SetCenterColor(0, 0, 0, 0.35)
	else
		bg:SetCenterColor(0, 0, 0, 0.4) -- RED
	end
end

function CarryHelper.OnMoveStop() -- Move the frame
	CarryHelper.settings.left = CarryHelperFrame:GetLeft()
	CarryHelper.settings.top = CarryHelperFrame:GetTop()
end

function CarryHelper.ShowUI()
  if not CarryHelper.trackerEnabled then
    SCENE_MANAGER:GetScene("hud"):AddFragment(CarryHelper.fragment)
    SCENE_MANAGER:GetScene("hudui"):AddFragment(CarryHelper.fragment)
    CarryHelper.Reset()
    
  end
end

function CarryHelper.HideUI()
  for i = 0, GROUP_SIZE_MAX do
    CarryHelper.panels[i].panel:SetHidden(true)
  end
  SCENE_MANAGER:GetScene("hud"):RemoveFragment(CarryHelper.fragment)
  SCENE_MANAGER:GetScene("hudui"):RemoveFragment(CarryHelper.fragment)
end

function CarryHelper.TestUI() -- Unlock and move UI
  if CarryHelper.showUI then
    CarryHelper.ShowUI()
  else
    CarryHelper.HideUI()
  end
end

function CarryHelper.GetGoldSuffix(value) -- Get the number of 'k's.
  local suffix = ""
  while value/1000 >= 1 do
    value = value/1000
    suffix = suffix .. "k"
  end
  return value, suffix
end

function CarryHelper.OnAddOnLoaded(event, addonName) -- Initialize the addon
  if addonName == CarryHelper.name then
    EVENT_MANAGER:UnregisterForEvent(CarryHelper.name, EVENT_ADD_ON_LOADED)
    CarryHelper.SettingsLoad()
    CarryHelper.SettingsBuildMenu()
    CarryHelper.InitializeControls()
  end
end

EVENT_MANAGER:RegisterForEvent(CarryHelper.name, EVENT_ADD_ON_LOADED, CarryHelper.OnAddOnLoaded) -- Initializing event
SLASH_COMMANDS[CarryHelper.slashCommands] = CarryHelper.HandleSlashCommands -- Add slash commands