local NAME="ZebraKarmaLoot"

ZebraKarmaLoot = LibStub("AceAddon-3.0"):NewAddon(NAME, "AceConsole-3.0", "AceEvent-3.0", "AceHook-3.0", "AceComm-3.0")
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
    self.lootWindowId = 1
    self.isLootWindowOpen = false
end

function addon:OnEnable()
    addon:RegisterEvent("LOOT_OPENED", "OnLootOpened")
    addon:RegisterEvent("LOOT_CLOSED", "OnLootClosed")
    addon:AddHooks()
    addon:Comms_Start()

    ZKLFrameItemScrollFrame:Show()
end

function addon:OnDisable()
    addon:Comms_Stop()
    addon:RemoveHooks()
    addon:UnregisterEvent("LOOT_CLOSED")
    addon:UnregisterEvent("LOOT_OPENED")
end

--------------------------------------------------------------------------------
-- Fixup locale in UI
--------------------------------------------------------------------------------
function addon:LocalizeUi()
    ZKLFrameSendListButton:SetText(L["Send Loot List"])
    ZKLFrameClearListButton:SetText(L["Clear Loot List"])
end

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

function addon:ItemList_Add(itemId, lootIndex)
    local existingItem = self:ItemList_Find(itemId)

    -- Do not allow adding the same item if the loot window ID is different
    -- This is most likely the same window being opened again
    -- FIXME: is lootWindowId necessary now?
    if existingItem and
       existingItem.lootIndex == lootIndex and
       existingItem.lootWindowId ~= self.lootWindowId
    then
        return
    end

    -- Allow adding the same item to the list twice. It may happen.
    local name, link, rarity, _, _, type, subType = GetItemInfo(itemId)
    if name then
        local info = self:GetTable()
        info.link = link
        info.id = itemId
        info.lootWindowId = self.lootWindowId
        info.lootIndex = lootIndex -- This is either the index in loot window, or nil

        -- Ignore the other info for now

        -- Insert it into table
        table.insert(self.itemList, info)
        info.itemIdx = #self.itemList
        self.itemList.numItems = #self.itemList

        self:UpdateItemList(ZKLFrameItemScrollFrame)
    end
end

function addon:ItemList_Find(itemIdOrIdx)
    if self.itemList[itemIdOrIdx] then
        return self.itemList[itemIdOrIdx]
    end

    for i, v in ipairs(self.itemList) do
        if v.id == itemIdOrIdx then
            return v
        end
    end
end

function addon:ItemList_Remove(itemIdOrIdx)
    local itemIdx = itemIdOrIdx
    if not self.itemList[itemIdx] then
        local item = self:ItemList_Find(itemIdx)
        itemIdx = item and item.itemIdx or -1
    end

    if itemIdx then
        self:FreeTable(self.itemList[itemIdx])
        table.remove(self.itemList, itemIdx)

        self.itemList.numItems = #self.itemList

        self:UpdateItemList(ZKLFrameItemScrollFrame)
    end

end

function addon:DeclareItem(link)
    -- Silly check
    if not link then return end

    local itemId = self:GetIdFromLink(link)

    if not itemId then return end

    -- Find the item in the itemList
    local item = self:ItemList_Find(itemId)
    if not item then return end

    -- Tell the frames that we're waiting for declarations
    self:Frames_ItemRollStart(item.itemIdx)
end

function addon:AwardLoot(link, player)
    -- Silly check
    if not link then return end

    local itemId = self:GetIdFromLink(link)

    if not itemId then return end

    -- Find the item in the itemList
    local item = self:ItemList_Find(itemId)
    if not item then return end

    -- Tell the frames that we're done with the item
    self:Frames_WinnerAnnounce(item.itemIdx)

    if self:GiveLootToPlayer(item.lootIndex, player) then
        self:ItemList_Remove(itemId)
    else
        -- TODO: Queue it and automatically award when window opens.
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

            local item = self:ItemList_Find(itemIdx)

            link:SetText(item.link)
            local SelfLootBtn = getglobal(itemButton:GetName().."SelfLoot")

            if item.lootIndex then
                SelfLootBtn:Show()
            else
                SelfLootBtn:Hide()
            end

            itemButton.itemIdx = itemIdx


            -- Todo: Highlight selected?
            itemButton:Show()
        else
            itemButton.itemIdx = itemIdx
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

function addon:RemoveItem(frame)
    local itemIdx = frame.itemIdx
    if not itemIdx then return end

    self:ItemList_Remove(itemIdx)
end

function addon:ShowTooltip(frame)
    local itemIdx = frame.itemIdx
    if not itemIdx then return end

    local item = self:ItemList_Find(itemIdx)
    if not item then return end

    GameTooltip:SetOwner(frame, "ANCHOR_PRESERVE")
    GameTooltip:SetHyperlink(item.link)
    GameTooltip:Show()
end

function addon:GetLoot(frame)
    local itemIdx = frame.itemIdx
    if not itemIdx then return end

    local item = self:ItemList_Find(itemIdx)
    if not item then return end

    local playerName = UnitName("player")
    if self:GiveLootToPlayer(item.lootIndex, playerName) then
        self:ItemList_Remove(itemId)
    else
        -- TODO: Queue it and automatically loot it when window opens.
    end
end

function addon:HideTooltip(frame)
    GameTooltip:Hide()
end

function addon:SendItemList()
    for i,v in ipairs(addon.itemList) do
        self:Frames_Broadcast(i, v.id)
    end
end

--------------------------------------------------------------------------------
-- Event handlers
--------------------------------------------------------------------------------

-- Handle auto-populating the loot list when loot frame is opened
function addon:OnLootOpened()
    self.isLootWindowOpen = true

    local numItems = GetNumLootItems()
    if numItems < 1 then return end

    for i=1,numItems do
        link = GetLootSlotLink(i)
        if link then
            local itemId = self:GetIdFromLink(link)

            -- The add function handles the same window being opened twice
            self:ItemList_Add(itemId, i)
        end
    end
end

-- Use a counter to assist in maintaining a single list of items
-- when loot window is re-opened
function addon:OnLootClosed()
    self.isLootWindowOpen = false
    self.lootWindowId = self.lootWindowId + 1
end

--------------------------------------------------------------------------------
-- Array handling for low garbage generation
--------------------------------------------------------------------------------
tableStore = {}

-- TODO: Empty placeholders until I can use something more decent
function addon:GetTable()
    return {}
end

function addon:FreeTable(tbl)
    return
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

function addon:GiveLootToPlayer(lootIndex, playerName)
    local method, partyId = GetLootMethod()
    if method == "master" and partyId == 0 then
        if self.isLootWindowOpen then
            local playerIdx = -1

            for i=1, 40 do
                if GetMasterLootCandidate(i) == playerName then
                    playerIdx = i
                    break
                end
            end

            if lootIndex and playerIdx ~= -1 then
                GiveMasterLoot(lootIndex, playerIdx)
                return true
            end
        end
    end
end
