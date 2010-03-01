local addon = ZebraKarmaLoot

local S = LibStub("AceSerializer-3.0")

-- I could pick it up from the frame addon, but that would defeat the purpose.
addon.CommPrefix = "ZebraKarmaFrames_1"

function addon:Comms_Start()
	self:RegisterComm(self.CommPrefix)
end

function addon:Comms_Stop()
	self:RegisterComm(self.CommPrefix)
end

function addon:SendComm(distribution, target, ...)
	msgRaw = S:Serialize(...)
	self:SendCommMessage(self.CommPrefix, msgRaw, distribution, target)
end

function addon:OnCommReceived(prefix, msgRaw, distribution, sender)
	if prefix ~= self.CommPrefix then return end

	local msg = {S:Deserialize(msgRaw)}
	if not msg[1] then
		self:Print(self.name .. " ERROR: Cannot unpack comms message")
		return
	end

	local handlerName = "On" .. msg[2]

	-- All messages are optional. We only listen to ones we care about - there
	-- may be other addons that listen to different events
	if self[handlerName] then
		self[handlerName](self, sender, select(3,unpack(msg)))
	end
end

--------------------------------------------------------------------------------
-- Incoming messages
--------------------------------------------------------------------------------

function addon:OnBTNCLICK(sender, declare)
	local use_bonus, for_offspec

	if declare == "Bonus" then
		use_bonus = true
	elseif declare == "Offspec" then
		for_offspec = true
	end

	KarmaRoll_AddPlayer(sender, use_bonus, for_offspec)
end

--------------------------------------------------------------------------------
-- Some messages we generate are in here
--------------------------------------------------------------------------------

function addon:Frames_Broadcast(index, itemId)
    self:SendComm("RAID", nil, "BROADCAST", index, itemId)
end

function addon:Frames_ItemRollStart(index)
    self:SendComm("RAID", nil, "ITEMROLLSTART", index)
end

function addon:Frames_WinnerAnnounce(index)
    self:SendComm("RAID", nil, "WINNERANNOUNCE", index)
end
