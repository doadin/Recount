-- Elsia: This handles filters for zones/instances

local Recount = _G.Recount

local _

local UnitIsGhost = UnitIsGhost

function Recount:SetZoneFilter(instanceType)
	
	if not instanceType then return end
	
	if Recount.db.profile.ZoneFilters[instanceType] then
		if Recount.db.profile.HideCollect and not Recount.CurrentDataCollect and Recount.db.profile.GlobalDataCollect then
			Recount.MainWindow:Show()
			Recount:RefreshMainWindow()
			Recount.SecondaryWindow:Show()
			Recount:RefreshSecondaryWindow()
		end
		Recount.CurrentDataCollect = true
	else
		if Recount.db.profile.HideCollect and (Recount.CurrentDataCollect or not Recount.db.profile.GlobalDataCollect) then
			Recount.MainWindow:Hide()
			Recount.SecondaryWindow:Hide()
		end
		Recount.CurrentDataCollect = false
	end
end

-- Elsia: This handles filters for groupings

-- groupType: 1 solo, 2 party, 3 raid

function Recount:SetGroupFilter(groupType)

	 if Recount.db.profile.GroupFilters[groupType] then
		if Recount.db.profile.HideCollect and not Recount.CurrentDataCollect and Recount.db.profile.GlobalDataCollect then
			Recount.MainWindow:Show()
			Recount:RefreshMainWindow()
			Recount.SecondaryWindow:Show()
			Recount:RefreshSecondaryWindow()
		end
		Recount.CurrentDataCollect = true
	else
		if Recount.db.profile.HideCollect and (Recount.CurrentDataCollect or not Recount.db.profile.GlobalDataCollect) then
			Recount.MainWindow:Hide()
			Recount.SecondaryWindow:Hide()
		end
		Recount.CurrentDataCollect = false
	 end
end


-- Elsia: This handles the combined case of group/zone filtering

function Recount:SetZoneGroupFilter(instanceType,groupType)
	
	if not instanceType or not groupType then return end
	
	if Recount.db.profile.ZoneFilters[instanceType] and Recount.db.profile.GroupFilters[groupType] then
		if Recount.db.profile.HideCollect and not Recount.MainWindow:IsShown() and not Recount.SecondaryWindow:IsShown() and Recount.db.profile.GlobalDataCollect then
			Recount.MainWindow:Show()
			Recount:RefreshMainWindow()
			Recount.SecondaryWindow:Show()
			Recount:RefreshSecondaryWindow()
		end
		Recount.CurrentDataCollect = true
	else
		if Recount.db.profile.HideCollect and Recount.MainWindow:IsShown() and Recount.SecondaryWindow:IsShown() or not Recount.db.profile.GlobalDataCollect then
			Recount.MainWindow:Hide()
			Recount.SecondaryWindow:Hide()
		end
		Recount.CurrentDataCollect = false
	end
end


-- Elsia: Main entry, call this to update main window visibility based on collection filters.

function Recount:UpdateZoneGroupFilter()
	local groupType, instanceType

	if Recount.inRaid then
	   groupType = 3
	elseif Recount.inGroup then
	   groupType = 2
	else
	   groupType = 1
	end

	_, instanceType = IsInInstance()
	if instanceType == nil then
		_, instanceType = C_Scenario.IsInScenario()
	end
	
	if instanceType == "none" then -- Check if we are in an open area combat zone (ala Wintergrasp)
		local pvpType = GetZonePVPInfo()
		if pvpType == "combat" then
			instanceType = "pvp"
		end
	end
--	Recount:DPrint("IT: "..instanceType)
	if not UnitIsGhost(Recount.PlayerName) then Recount:SetZoneGroupFilter(instanceType, groupType) end -- Use zone-based filters.
end

function Recount:GetGroupState(groupType)
	 if groupType == 3 then
	    	return Recount.inRaid
	 elseif groupType == 2 then
	 	return not Recount.inRaid and Recount.inGroup
	 else
		return not Recount.inRaid and not Recount.inGroup 
	 end
end