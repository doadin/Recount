local me={}
local SM = LibStub:GetLibrary("LibSharedMedia-3.0")
local Events = LibStub("AceEvent-3.0")
local AceLocale = LibStub("AceLocale-3.0")
local L = AceLocale:GetLocale( "Recount" )
local LD = LibStub("LibDropdown-1.0")

local dbCombatants

local string_format = string.format
local string_match = string.match
local math_max = math.max
local math_floor = math.floor
local tinsert = table.insert
local tremove = table.remove
local type = type
local pairs = pairs
local ipairs = ipairs
local strsub = strsub
 
local CreateFrame = CreateFrame

function Recount:CreateSecondaryWindow()
	Recount.SecondaryWindow=Recount:CreateFrame("Recount_SecondaryWindow",L["Secondary"],140,200, function() Recount.SecondaryWindow.timeid=Recount:ScheduleRepeatingTimer("RefreshSecondaryWindow",1,true);Recount.db.profile.SecondaryWindowVis=true end, function() if Recount.SecondaryWindow.timeid then Recount:CancelTimer(Recount.SecondaryWindow.timeid); Recount.SecondaryWindow.timeid=nil end ;Recount.db.profile.SecondaryWindowVis=false end)

	local theFrame=Recount.SecondaryWindow

	theFrame:SetResizable(true)
	theFrame:SetMinResize(140,63)
	theFrame:SetMaxResize(400,520)		

	theFrame.SaveSecondaryWindowPosition = Recount.SaveSecondaryWindowPosition
	
	theFrame:SetScript("OnSizeChanged", function(self)
						if ( self.isResizing ) then
							Recount:ResizeSecondaryWindow()
							
							Recount.db.profile.SecondaryWindowHeight=self:GetHeight()
							Recount.db.profile.SecondaryWindowWidth=self:GetWidth()
						end
					end)

	theFrame.TitleClick=CreateFrame("FRAME",nil,theFrame)
	theFrame.TitleClick:SetAllPoints(theFrame.Title)
	theFrame.TitleClick:EnableMouse(true)
	theFrame.TitleClick:SetScript("OnMouseDown",function(self,button) 
							if button=="RightButton" then
								Recount:OpenModeDropDown(self)
--[[								Recount:ModeDropDownOpen(self)
								ToggleDropDownMenu(1, nil, Recount_ModeDropDownMenu)--]]
							end

							local parent=self:GetParent()
							if ( ( ( not parent.isLocked ) or ( parent.isLocked == 0 ) ) and ( button == "LeftButton" ) ) then
							  Recount:SetWindowTop(parent)
							  parent:StartMoving();
							  parent.isMoving = true;
							 end
							end)
	theFrame.TitleClick:SetScript("OnMouseUp", function(self) 
						local parent=self:GetParent()
						if ( parent.isMoving ) then
						  parent:StopMovingOrSizing();
						  parent.isMoving = false;
						  parent:SaveSecondaryWindowPosition()
						 end
						end)

	theFrame.ScrollBar=CreateFrame("SCROLLFRAME","Recount_SecondaryWindow_ScrollBar",theFrame,"FauxScrollFrameTemplate")
	theFrame.ScrollBar:SetScript("OnVerticalScroll", function(self,offset) FauxScrollFrame_OnVerticalScroll(self,offset,20, Recount.RefreshSecondaryWindow) end)
	Recount:SetupScrollbar("Recount_SecondaryWindow_ScrollBar")

	if not Recount.db.profile.SecondaryWindow.ShowScrollbar then
		Recount:HideScrollbarElements("Recount_SecondaryWindow_ScrollBar")
	end

	theFrame.DragBottomRight = CreateFrame("Button", "RecountResizeGripRight", theFrame) -- Grip Buttons from Omen2
	theFrame.DragBottomRight:Show()
	theFrame.DragBottomRight:SetFrameLevel( theFrame:GetFrameLevel() + 10)
	theFrame.DragBottomRight:SetNormalTexture("Interface\\AddOns\\Recount\\textures\\ResizeGripRight")
	theFrame.DragBottomRight:SetHighlightTexture("Interface\\AddOns\\Recount\\textures\\ResizeGripRight")
	theFrame.DragBottomRight:SetWidth(16)
	theFrame.DragBottomRight:SetHeight(16)
	theFrame.DragBottomRight:SetPoint("BOTTOMRIGHT", theFrame, "BOTTOMRIGHT", 0, 0)
	theFrame.DragBottomRight:EnableMouse(true)
	theFrame.DragBottomRight:SetScript("OnMouseDown", function(self,button) if ((( not self:GetParent().isLocked ) or ( self:GetParent().isLocked == 0 ) ) and ( button == "LeftButton" ) ) then self:GetParent().isResizing = true; self:GetParent():StartSizing("BOTTOMRIGHT") end end ) -- Elsia: disallow resizing when locked.
	theFrame.DragBottomRight:SetScript("OnMouseUp", function(self,button) if self:GetParent().isResizing == true then self:GetParent():StopMovingOrSizing(); self:GetParent():SaveSecondaryWindowPosition(); self:GetParent().isResizing = false; end end )
	theFrame.DragBottomLeft = CreateFrame("Button", "RecountResizeGripLeft", theFrame)
	theFrame.DragBottomLeft:Show()
	theFrame.DragBottomLeft:SetFrameLevel( theFrame:GetFrameLevel() + 10)
	theFrame.DragBottomLeft:SetNormalTexture("Interface\\AddOns\\Recount\\textures\\ResizeGripLeft")
	theFrame.DragBottomLeft:SetHighlightTexture("Interface\\AddOns\\Recount\\textures\\ResizeGripLeft")
	theFrame.DragBottomLeft:SetWidth(16)
	theFrame.DragBottomLeft:SetHeight(16)
	theFrame.DragBottomLeft:SetPoint("BOTTOMLEFT", theFrame, "BOTTOMLEFT", 0, 0)
	theFrame.DragBottomLeft:EnableMouse(true)
	theFrame.DragBottomLeft:SetScript("OnMouseDown", function(self,button) if ((( not self:GetParent().isLocked ) or ( self:GetParent().isLocked == 0 ) ) and ( button == "LeftButton" ) ) then self:GetParent().isResizing = true; self:GetParent():StartSizing("BOTTOMLEFT") end end ) -- Elsia: disallow resizing when locked.
	theFrame.DragBottomLeft:SetScript("OnMouseUp", function(self,button) if self:GetParent().isResizing == true then self:GetParent():StopMovingOrSizing(); self:GetParent():SaveSecondaryWindowPosition(); self:GetParent().isResizing = false; end end )
	--Recount:ShowGrips(not Recount.db.profile.Locked)
	
	theFrame.RightButton=CreateFrame("Button",nil,theFrame)
	theFrame.RightButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Up.blp")
	theFrame.RightButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-NextPage-Down.blp")	
	theFrame.RightButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight.blp")
	theFrame.RightButton:SetWidth(16)
	theFrame.RightButton:SetHeight(18)
--	theFrame.RightButton:SetPoint("TOPRIGHT",theFrame,"TOPRIGHT",-38+16,-12)
	theFrame.RightButton:SetPoint("RIGHT",theFrame.CloseButton,"LEFT",0,0)
	theFrame.RightButton:SetScript("OnClick",function() Recount:SecondaryWindowNextMode() end)
	theFrame.RightButton:SetFrameLevel(theFrame.RightButton:GetFrameLevel()+1)

	theFrame.LeftButton=CreateFrame("Button",nil,theFrame)
	theFrame.LeftButton:SetNormalTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Up.blp")
	theFrame.LeftButton:SetPushedTexture("Interface\\Buttons\\UI-SpellbookIcon-PrevPage-Down.blp")
	theFrame.LeftButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight.blp")
	theFrame.LeftButton:SetWidth(16)
	theFrame.LeftButton:SetHeight(18)
	theFrame.LeftButton:SetPoint("RIGHT",theFrame.RightButton,"LEFT",0,0)
	theFrame.LeftButton:SetScript("OnClick",function() Recount:SecondaryWindowPrevMode() end)
	theFrame.LeftButton:SetFrameLevel(theFrame.LeftButton:GetFrameLevel()+1)

	theFrame.ResetButton=CreateFrame("Button",nil,theFrame)
	theFrame.ResetButton:SetNormalTexture("Interface\\Addons\\Recount\\Textures\\icon-reset")
	theFrame.ResetButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight.blp")
	theFrame.ResetButton:SetWidth(16)
	theFrame.ResetButton:SetHeight(16)
	theFrame.ResetButton:SetPoint("RIGHT",theFrame.LeftButton,"LEFT",0,0)
	theFrame.ResetButton:SetScript("OnClick",function() Recount:ShowReset() end)
	theFrame.ResetButton:SetFrameLevel(theFrame.ResetButton:GetFrameLevel()+1)

	theFrame.FileButton=CreateFrame("Button",nil,theFrame)
	theFrame.FileButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Up.blp")
--	theFrame.FileButton:SetPushedTexture("Interface\\Buttons\\UI-GuildButton-PublicNote-Down.blp")	-- Texture disappeared with MOP
	theFrame.FileButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight.blp")
	theFrame.FileButton:SetWidth(16)
	theFrame.FileButton:SetHeight(16)
	theFrame.FileButton:SetPoint("RIGHT",theFrame.ResetButton,"LEFT",0,0)
	theFrame.FileButton:SetScript("OnClick",function(self) 
						Recount:OpenFightDropDown(self)
--[[						Recount:FightDropDownOpen(self)
						ToggleDropDownMenu(1, nil, Recount_FightDropDownMenu) ]]
						end)
	theFrame.FileButton:SetFrameLevel(theFrame.FileButton:GetFrameLevel()+1)

	theFrame.ConfigButton=CreateFrame("Button",nil,theFrame)
	theFrame.ConfigButton:SetNormalTexture("Interface\\Addons\\Recount\\Textures\\icon-config")
	theFrame.ConfigButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight.blp")
	theFrame.ConfigButton:SetWidth(16)
	theFrame.ConfigButton:SetHeight(16)
	theFrame.ConfigButton:SetPoint("RIGHT",theFrame.FileButton,"LEFT",0,0)
	theFrame.ConfigButton:SetScript("OnClick",function() Recount:ShowConfig() end)
	theFrame.ConfigButton:SetFrameLevel(theFrame.ConfigButton:GetFrameLevel()+1)

	theFrame.ReportButton=CreateFrame("Button",nil,theFrame)
	theFrame.ReportButton:SetNormalTexture("Interface\\Buttons\\UI-GuildButton-MOTD-Up.blp")
	theFrame.ReportButton:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight.blp")
	theFrame.ReportButton:SetWidth(16)
	theFrame.ReportButton:SetHeight(16)
	theFrame.ReportButton:SetPoint("RIGHT",theFrame.ConfigButton,"LEFT",0,0)
	theFrame.ReportButton:SetScript("OnClick",function() Recount:ShowReport("Secondary",Recount.ReportData) end)
	theFrame.ReportButton:SetFrameLevel(theFrame.ReportButton:GetFrameLevel()+1)

	Recount.SecondaryWindow.Rows={}
	Recount.SecondaryWindow.CurRows=0
	Recount.SecondaryWindow.RowsCreated=0
	
	Recount.SecondaryWindow.DispTableSorted={}
	Recount.SecondaryWindow.DispTableLookup={}

	theFrame.SavePosition=Recount.SaveSecondaryWindowPosition
	Recount:RestoreSecondaryWindowPosition(Recount.db.profile.SecondaryWindow.Position.x,Recount.db.profile.SecondaryWindow.Position.y,Recount.db.profile.SecondaryWindow.Position.w,Recount.db.profile.SecondaryWindow.Position.h)
	--Recount:ResizeSecondaryWindow()
	Recount:SetupSecondaryWindowButtons()
	Recount.SecondaryWindow.timeid=Recount:ScheduleRepeatingTimer("RefreshSecondaryWindow",1,true)

	if not Recount.db.profile.SecondaryWindowVis then
		theFrame:Hide()
	end
end