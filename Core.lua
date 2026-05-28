-- Initialize addon namespace
local addonName, ns = ...
DollyAndDot = ns

-- Configuration
ns.SPELL_NAME = "Meerah's Jukebox"
ns.SPELL_ID = 288851
ns.TOTAL_DURATION = 11.5
-- sound/creature/meerah_jukebox/vo_835_meerah_jukebox_f.ogg — the extended jukebox song
ns.SOUND_FILE_ID = 3169894

-- Addon sync prefix for group communication
local ADDON_PREFIX = "DollyAndDot"

-- State
ns.isActive = false
ns.debugMode = false
ns.chatEnabled = true  -- Send lyrics to party/raid chat (enabled by default)
ns.frames = {}

-- Register addon message prefix for group sync
C_ChatInfo.RegisterAddonMessagePrefix(ADDON_PREFIX)

-- Auto-detect best chat channel: instance > raid > party (nil if solo)
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

-- Event frame
local eventFrame = CreateFrame("Frame")
eventFrame:RegisterEvent("UNIT_SPELLCAST_SUCCEEDED")
eventFrame:RegisterEvent("CHAT_MSG_ADDON")

eventFrame:SetScript("OnEvent", function(frame, event, ...)
    if event == "UNIT_SPELLCAST_SUCCEEDED" then
        local unitTarget, _, spellId = ...
        -- Only check player's own casts — untainted, no pcall needed
        -- Party member detection is handled via addon sync instead
        if unitTarget == "player" and spellId == ns.SPELL_ID then
            -- Block everything during combat
            if UnitAffectingCombat("player") then return end
            -- Broadcast to group so other addon users start too
            local channel = ns:GetChatChannel()
            if channel then
                C_ChatInfo.SendAddonMessage(ADDON_PREFIX, "START", channel)
            end
            -- Toy plays its own audio — don't double up
            ns:StartKaraoke(false)
        end
    elseif event == "CHAT_MSG_ADDON" then
        local prefix, message = ...
        if prefix == ADDON_PREFIX and message == "START" then
            -- Block everything during combat
            if UnitAffectingCombat("player") then return end
            ns:StartKaraoke(false)
        end
    end
end)

function ns:StartKaraoke(playSound)
    if self.isActive then return end
    self.isActive = true
    if playSound then
        local ok, _, handle = pcall(PlaySoundFile, self.SOUND_FILE_ID, "Master")
        if ok then self.soundHandle = handle end
    end
    self:CreateUI()
    self:StartAnimation()
end

function ns:StopKaraoke()
    self.isActive = false
    if self.soundHandle then
        StopSound(self.soundHandle)
        self.soundHandle = nil
    end
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
            print("|cFFFFFF00DollyAndDot|r chat |cFF00FF00ENABLED|r — lyrics will be sent to " .. (ns:GetChatChannel() or "SAY"))
        else
            print("|cFFFFFF00DollyAndDot|r chat |cFFFF0000DISABLED|r")
        end
    else
        if UnitAffectingCombat("player") then
            print("|cFFFFFF00DollyAndDot|r can't start during combat!")
            return
        end
        ns:StartKaraoke(true)
    end
end
