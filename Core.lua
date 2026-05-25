-- Initialize addon namespace
local addonName, ns = ...
DollyAndDot = ns

-- Configuration
ns.SPELL_NAME = "Meerah's Jukebox"
ns.SPELL_ID = 288851
ns.TOTAL_DURATION = 11.5

-- State
ns.isActive = false
ns.debugMode = false
ns.chatEnabled = true  -- Send lyrics to party/raid chat (enabled by default)
ns.frames = {}

-- Auto-detect best chat channel (matches FoodUwU pattern): instance > raid > party (nil if solo)
function ns:GetChatChannel()
    if IsInGroup(LE_PARTY_CATEGORY_INSTANCE) then
        return "INSTANCE_CHAT"
    elseif IsInRaid(LE_PARTY_CATEGORY_HOME) then
        return "RAID"
    elseif IsInGroup(LE_PARTY_CATEGORY_HOME) then
        return "PARTY"
    else
        return nil
    end
end

-- Send chat using the modern C_ChatInfo API (not the deprecated SendChatMessage)
function ns:SendChat(message, chatType)
    if C_ChatInfo and C_ChatInfo.SendChatMessage then
        C_ChatInfo.SendChatMessage(message, chatType, nil, nil)
    else
        SendChatMessage(message, chatType)
    end
end

-- Event frame — CLEU is protected in Midnight 12.0, use UNIT_SPELLCAST_SUCCEEDED instead
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("PLAYER_ENTERING_WORLD")

eventFrame:SetScript("OnEvent", function(frame, event, ...)
    if event == "PLAYER_ENTERING_WORLD" then
        frame:UnregisterEvent("PLAYER_ENTERING_WORLD")
    elseif event == "UNIT_SPELLCAST_SUCCEEDED" then
        local _, _, spellId = ...
        if spellId == ns.SPELL_ID then
            ns:StartKaraoke()
        end
    end
end)

function ns:StartKaraoke()
    if self.isActive then return end
    self.isActive = true
    self:CreateUI()
    self:StartAnimation()
end

function ns:StopKaraoke()
    self.isActive = false
    if self.frames.container then
        self.frames.container:Hide()
    end
    if self.frames.alpaca then
        self.frames.alpaca:Hide()
    end
    if self.animationFrame then
        self.animationFrame:SetScript("OnUpdate", nil)
    end
    if self.chatTimers then
        for _, timer in pairs(self.chatTimers) do
            timer:Cancel()
        end
        self.chatTimers = nil
    end
end

-- Slash commands
SLASH_DOLLYANDDOT1 = "/dolly"
SlashCmdList["DOLLYANDDOT"] = function(msg)
    if msg == "stop" then
        ns:StopKaraoke()
    elseif msg == "chat" then
        ns.chatEnabled = not ns.chatEnabled
        if ns.chatEnabled then
            print("|cFFFFFF00DollyAndDot|r chat |cFF00FF00ENABLED|r — lyrics will be sent to " .. ns:GetChatChannel())
        else
            print("|cFFFFFF00DollyAndDot|r chat |cFFFF0000DISABLED|r")
        end
    else
        ns:StartKaraoke()
    end
end
