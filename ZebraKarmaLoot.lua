local NAME="ZebraKarmaLoot"

ZebraKarmaLoot = LibStub("AceAddon-3.0"):NewAddon(NAME, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0")
local addon = ZebraKarmaLoot
addon.ADDONNAME = NAME
addon.VERSION = "0.0.1"

local L = LibStub("AceLocale-3.0"):GetLocale("ZebraKarmaLoot")

-- Number of items we can display in scroll frame
addon.const = {}
addon.const.ItemListCount = 1
addon.const.ItemButtonHeight = 20

local L = LibStub("AceLocale-3.0"):GetLocale(addon.ADDONNAME, true)


function addon:OnInitialize()
    self:SetDebugging(false)
    self.itemList = self:GetTable()
    self.itemList.numItems = 0
end

function addon:OnEnable()
    --addon:RegisterEvent()
    self:SecureHook("HandleModifiedItemClick", "ModifiedClickHandler")
--    self:SecureHook("SetItemRef", "SetItemRefHandler")
    ZKLFrameItemScrollFrame:Show()
end

function addon:OnDisable()
    --    self:Unhook("SetItemRef")
    self:Unhook("HandleModifiedItemClick")
    --addon:UnregisterEvent()
end

--------------------------------------------------------------------------------
-- Fixup locale in UI
--------------------------------------------------------------------------------
function addon:LocalizeUi()
    ZKLFrameSendListButton:SetText(L["Send Loot List"])
    ZKLFrameClearListButton:SetText(L["Clear Loot List"])
end

--------------------------------------------------------------------------------
-- Hooked functions for list manipulation
--------------------------------------------------------------------------------
function addon:ModifiedClickHandler(link)
    self:Debug("Modified click:", link, self:GetIdFromLink(link))
    self:ItemList_Add(self:GetIdFromLink(link))
end

--[[ Is this really necessary?
function addon:SetItemRefHandler(link, text, button)
    self:Debug("Modified click:", link, self:GetIdFromLink(link))
    self:ItemList_Add(self:GetIdFromLink(link))
end
]]--

--------------------------------------------------------------------------------
-- Item list handling
--------------------------------------------------------------------------------
function addon:ItemList_Clear()
    self:FreeTable(self.itemList)
    self.itemList = self:GetTable()
    self.itemList.numItems = 0
    self:UpdateItemList(ZKLFrameItemScrollFrame)

    -- Stupid check. If Ni_Karma is not there what are we doing running?
    if KarmaRollFrameClearButton then
        KarmaRollFrameClearButton:Click()
    end
end

function addon:ItemList_Add(itemId)
    -- Allow adding the same item to the list twice. It may happen.
    local name, link, rarity, _, _, type, subType = GetItemInfo(itemId)
    if name then
        local info = self:GetTable()
        info.link = link
        info.id = itemId

        -- Ignore the other info for now
        local idx = self.itemList.numItems + 1
        self.itemList[idx] = info
        self.itemList.numItems = idx

        self:UpdateItemList(ZKLFrameItemScrollFrame)
    end
end

--------------------------------------------------------------------------------
-- Scrollbar handling
--------------------------------------------------------------------------------

function addon:GetItemButton(i)
	local button = getglobal("ZKLFrameItemButton"..i)
	if not button then
		-- Create a new button. Assume button (i-1) was already created
		button = CreateFrame("Button", "ZKLFrameItemButton"..i, ZKLFrame, "ZKLItemButtonTemplate")
        button:SetPoint("TOPLEFT", "ZKLFrameItemButton"..(i-1), "BOTTOMLEFT")
		button:SetNormalTexture("");
		button:SetText("");
	end

	self.numItemButtons = math.max(i, self.numItemButtons or 0)

	return button
end

-- this is a "static" method. note the "."
function addon.ItemScrollFrame_Update(frame)
    addon:UpdateItemList(frame)
end

function addon:UpdateItemList(frame)
    local buttonCount = math.floor(
        frame:GetHeight() / self.const.ItemButtonHeight)

    -- If frame were resizable, we'd have to hide buttons not visible here.
    -- Since it is not the case, we don't need that.

    FauxScrollFrame_Update(frame,
                           addon.itemList.numItems, buttonCount,
                           addon.const.ItemButtonHeight);

    local lootOffset = FauxScrollFrame_GetOffset(frame) or 0

    for i=1, buttonCount do
        local itemIdx = lootOffset + i
        local itemButton = addon:GetItemButton(i)
        if itemIdx <= addon.itemList.numItems then
            local link = getglobal(itemButton:GetName() .. "Link")
            if not link then
                self:Print("ALERT! Big doodoo! Item button has no text field!")
                return
            end
            -- Todo: Make itemlist management functions
            link:SetText(self.itemList[itemIdx].link)

            itemButton.itemIdx = itemIdx

            -- Todo: Highlight selected?
            itemButton:Show()
        else
            itemButton:Hide()
        end
    end

end

function addon:SendItemToNiKarma(frame)
    local itemIdx = frame.itemIdx
    if not itemIdx then return end

    -- Stupid check. If Ni_Karma is not there what are we doing running?
    if KarmaRollFrameClearButton then
        KarmaRollFrameClearButton:Click()
    end

    if addon.itemList and
        addon.itemList[itemIdx] and
        addon.itemList[itemIdx].link
    then
        KarmaLootItem_OnClick(addon.itemList[itemIdx].link)
    end
end

--------------------------------------------------------------------------------
-- Array handling for low garbage generation
--------------------------------------------------------------------------------
tableStore = {}

function addon:GetTable()
    local last = #tableStore
    local tbl
    if last == 0 then
        tbl = {}
    else
        tbl = tableStore[last]
        tableStore[last] = nil
    end

    return tbl
end

function addon:FreeTable(tbl)
    for i, v in pairs(tbl) do
        -- erase first, we don't want to do infinite loops over self referencing
        -- tables
        tbl[i] = nil
        if type(v) == "table" then
            self:FreeTable(v)
        end
    end

    -- TODO: check for already added entries.
    if #tableStore < 50 then
        table.insert(tableStore, tbl)
    end
end

--------------------------------------------------------------------------------
-- Helper functions
--------------------------------------------------------------------------------

function addon:GetIdFromLink(link)
    local _, _, id = string.find(link,"item:(%d+):")
    return tonumber(id)
end

-- Local variable to control debugging
local debugEnabled = false

-- Enable/Disable debugging
-- TODO: Debug levels?
function addon:SetDebugging(enabled)
	debugEnabled = enabled
end

-- Print a debug statement
function addon:Debug(...)
	return debugEnabled and self:Print(date(), ": ", ...)
end
