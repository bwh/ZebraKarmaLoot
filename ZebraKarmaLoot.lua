local NAME="ZebraKarmaLoot"

ZebraKarmaLoot = LibStub("AceAddon-3.0"):NewAddon(NAME, "AceConsole-3.0", "AceEvent-3.0")
local addon = ZebraKarmaLoot
addon.ADDONNAME = NAME
addon.VERSION = "0.0.1"

-- Number of items we can display in scroll frame
addon.const = {}
addon.const.ItemListCount = 1
addon.const.ItemButtonHeight = 20

local L = LibStub("AceLocale-3.0"):GetLocale(addon.ADDONNAME, true)


function addon:OnInitialize()
    self.itemList = self:GetTable()
    self.itemList.numItems = 0
end

function addon:OnEnable()
    --addon:RegisterEvent()
    ZKLFrameItemScrollFrame:Show()
end

function addon:OnDisable()
    --addon:UnregisterEvent()
end

--------------------------------------------------------------------------------
-- Item list handling
--------------------------------------------------------------------------------
function addon:ItemList_Clear()
    self:FreeTable(self.itemList)
    self.itemList = self:GetTable()
    self.itemList.numItems = 0
end

function addon:ItemList_Add(itemId)
    local name, link, rarity, _, _, type, subType = GetItemInfo(itemId)
    if name then
        local info = self:GetTable()
        info.link = link
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
    addon:Print("In here: " .. frame:GetName())
    addon:UpdateItemList(frame)
end

function addon:UpdateItemList(frame)
    frame = ZKLFrameItemScrollFrame

    self:Print(frame:GetName())
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

            -- Todo: Highlight selected?
            itemButton:Show()
        else
            itemButton:Hide()
        end
    end

end

--------------------------------------------------------------------------------
-- Array handling for low garbage generation
--------------------------------------------------------------------------------
addon.tableStore = {}

function addon:GetTable()
    local last = #addon.tableStore
    local tbl
    if last == 0 then
        tbl = {}
    else
        tbl = addon.tableStore[last]
        addon.tableStore[last] = nil
    end

    return tbl
end

function addon:FreeArray(tbl)
    for i, v in pairs(tbl) do
        print(i, v)
        if type(v) == "table" then
            self:FreeArray(v)
        end
        tbl[i] = nil
    end
    table.insert(addon.tableStore, tbl)
end
