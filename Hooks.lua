local addon = ZebraKarmaLoot

function addon:AddHooks()
    self:SecureHook("HandleModifiedItemClick", "ModifiedClickHandler")
--    self:SecureHook("SetItemRef", "SetItemRefHandler")
    self:HookScript(KarmaRollFrameAwardButton, "OnClick", addon.NiKarmaAward_OnClick)
    self:HookScript(KarmaRollFrameDeclareButton, "OnClick", addon.NiKarmaDeclare_OnClick)
end

function addon:RemoveHooks()
    self:Unhook(KarmaRollFrameAwardButton, "OnClick")
--        self:Unhook("SetItemRef")
    self:Unhook("HandleModifiedItemClick")
end

--------------------------------------------------------------------------------
-- Hook handlers
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
--]]

function addon.NiKarmaAward_OnClick(frame, button, down)
    -- Nasty link from here to Ni_Karma, but it looks like there is no better way
    local link = KarmaRollFrameItem:GetText()
    local player = nks.RollList[KarmaRollFrame.selectedRoller][1]

    if link then
        addon:AwardLoot(link, player)
    end
end

function addon.NiKarmaDeclare_OnClick(frame, button, down)
    -- Nasty link from here to Ni_Karma, but it looks like there is no better way
    local link = KarmaRollFrameItem:GetText()

    if link then
        addon:DeclareItem(link)
    end
end
