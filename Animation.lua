-- Animation controller for karaoke sequence
--
-- The 3D alpaca uses creature animation 5 (Run) — set once in UI.lua at model
-- creation, loops continuously at its intrinsic cycle (~594ms). Per-frame
-- positional logic below arcs the alpaca between word centers in time with the
-- per-word colorAt highlights, with an asymmetric "hang at apex" parabolic arc
-- whose height scales with horizontal distance for visually distinct hops.

local _, ns = ...

-- Bounce-arc tuning.
local BASE_Y         = 5     -- resting Y above the lyrics text
local BOUNCE_HEIGHT  = 38    -- nominal peak hop height (px), scaled per-hop by distance
local EXIT_OFFSET    = 80    -- how far past the last word the alpaca arcs out / enters from
local APEX_AT        = 0.45  -- bias apex slightly early so the descent cues the next word
local UP_POW         = 2.4   -- ease-out on the rise
local DOWN_POW       = 2.4   -- ease-in on the fall (combined = hang at apex)
local LAST_WORD_HOLD = 0.25  -- dwell on the last word before exit-arcing (prevents clipping)
local MIN_EXIT_SPAN  = 0.15  -- skip exit arc if remaining time after dwell is shorter than this

function ns:StartAnimation()
    if self.animationFrame then
        self.animationFrame:SetScript("OnUpdate", nil)
    end

    local frame = CreateFrame("Frame")
    self.animationFrame = frame
    self.startTime = GetTime()
    self.currentLineIndex = 0
    self.lastHighlightCount = -1
    self.wordPositionCache = {}

    if self.frames.alpaca then
        self.frames.alpaca:Show()
    end

    -- Schedule chat messages via C_Timer (only if chat is enabled and in a group)
    self.chatTimers = {}
    if self.chatEnabled then
        local channel = self:GetChatChannel()
        if channel then
            for i, line in ipairs(self.LYRICS) do
                self.chatTimers[i] = C_Timer.NewTimer(line.startTime, function()
                    if ns.isActive and not UnitAffectingCombat("player") then
                        pcall(ns.SendChat, ns, line.text, channel)
                    end
                end)
            end
        end
    end

    frame:SetScript("OnUpdate", function()
        ns:OnAnimationUpdate()
    end)
end

function ns:OnAnimationUpdate()
    if not self.isActive then
        if self.animationFrame then
            self.animationFrame:SetScript("OnUpdate", nil)
        end
        return
    end

    local elapsed = GetTime() - self.startTime

    if elapsed >= self.TOTAL_DURATION then
        self:StopKaraoke()
        return
    end

    -- Determine which line we're on
    for i, line in ipairs(self.LYRICS) do
        if elapsed >= line.startTime and elapsed < line.endTime then
            if self.currentLineIndex ~= i then
                self.currentLineIndex = i
                self.lastHighlightCount = -1
            end
            break
        end
    end

    -- Update word highlights (only rebuild text when a new word turns yellow)
    if self.currentLineIndex > 0 then
        local line = self.LYRICS[self.currentLineIndex]
        local count = 0
        for _, word in ipairs(line.words) do
            if elapsed >= word.colorAt then
                count = count + 1
            end
        end
        if count ~= self.lastHighlightCount then
            self.lastHighlightCount = count
            self.frames.lyricsText:SetText(
                self:BuildColoredText(self.currentLineIndex, elapsed)
            )
        end
    end

    -- Move the alpaca across the current line
    self:UpdateAlpacaPosition(elapsed)
end

-- Measure the x-offset (from the lyrics text's center) of each word's center.
-- Cached per line since GetStringWidth on every frame would be wasteful.
function ns:GetWordPositions(lineIndex)
    local cache = self.wordPositionCache
    if cache[lineIndex] then return cache[lineIndex] end

    local line = self.LYRICS[lineIndex]
    local lyricsText = self.frames.lyricsText

    local measurer = self.frames.alpacaMeasurer
    if not measurer then
        measurer = self.frames.container:CreateFontString(nil, "OVERLAY")
        local font, size, flags = lyricsText:GetFont()
        measurer:SetFont(font, size, flags)
        measurer:Hide()
        self.frames.alpacaMeasurer = measurer
    end

    -- Derive separator width by measuring "a<SEP>a" minus "aa".
    -- Must match the separator used in BuildColoredText for the alpaca to land on words.
    local sep = ns.WORD_SEPARATOR or " "
    measurer:SetText("a" .. sep .. "a")
    local twoWithSep = measurer:GetStringWidth()
    measurer:SetText("aa")
    local twoNoSep = measurer:GetStringWidth()
    local spaceWidth = twoWithSep - twoNoSep

    local widths = {}
    local total = 0
    for i, word in ipairs(line.words) do
        measurer:SetText(word.text)
        widths[i] = measurer:GetStringWidth()
        total = total + widths[i]
    end
    if #line.words > 1 then
        total = total + spaceWidth * (#line.words - 1)
    end

    local positions = {}
    local cursor = -total / 2
    for i, w in ipairs(widths) do
        positions[i] = cursor + w / 2
        cursor = cursor + w + spaceWidth
    end

    cache[lineIndex] = positions
    return positions
end

-- Asymmetric arc: 0 -> 1 -> 0 with extra hang at apex, peak biased to APEX_AT.
local function arcHeight(p)
    if p < APEX_AT then
        local up = p / APEX_AT
        return 1 - (1 - up) ^ UP_POW
    else
        local down = (p - APEX_AT) / (1 - APEX_AT)
        return 1 - down ^ DOWN_POW
    end
end

-- Long horizontal gaps get taller arcs so each hop reads as distinct.
local function heightScale(distancePx)
    local scale = 0.55 + distancePx / 170
    if scale < 0.55 then scale = 0.55 end
    if scale > 1.6 then scale = 1.6 end
    return scale
end

function ns:UpdateAlpacaPosition(elapsed)
    if not self.frames.alpaca or not self.frames.lyricsText then return end

    local lineIndex = self.currentLineIndex
    if lineIndex == 0 then return end

    local line = self.LYRICS[lineIndex]
    local positions = self:GetWordPositions(lineIndex)

    -- Find the latest word that has turned yellow at this elapsed time.
    local currentIdx = 0
    for i, word in ipairs(line.words) do
        if elapsed >= word.colorAt then
            currentIdx = i
        else
            break
        end
    end

    local nWords = #line.words
    local offsetX, offsetY

    if currentIdx == 0 then
        -- Entry: descend from upper-left onto word 1.
        local firstColorAt = line.words[1].colorAt
        local span = firstColorAt - line.startTime
        local progress = span > 0 and (elapsed - line.startTime) / span or 1
        progress = math.max(0, math.min(1, progress))
        local startX = positions[1] - EXIT_OFFSET
        offsetX = startX + (positions[1] - startX) * progress
        offsetY = BASE_Y + BOUNCE_HEIGHT * heightScale(EXIT_OFFSET) * ((1 - progress) ^ DOWN_POW)
    elseif currentIdx < nWords then
        -- Mid-line: full hop from current word to next.
        local current = line.words[currentIdx]
        local nextWord = line.words[currentIdx + 1]
        local span = nextWord.colorAt - current.colorAt
        local progress = span > 0 and (elapsed - current.colorAt) / span or 1
        progress = math.max(0, math.min(1, progress))
        local fromX = positions[currentIdx]
        local toX   = positions[currentIdx + 1]
        offsetX = fromX + (toX - fromX) * progress
        offsetY = BASE_Y + BOUNCE_HEIGHT * heightScale(math.abs(toX - fromX)) * arcHeight(progress)
    else
        -- After the last word: dwell briefly, then arc UP to apex so the next line's
        -- entry (which starts at apex height and descends) feels like one continuous bounce.
        -- For the final line of the song, just park.
        local lastColorAt = line.words[nWords].colorAt
        local hasNextLine = lineIndex < #self.LYRICS
        local exitStart = lastColorAt + LAST_WORD_HOLD
        local exitSpan = line.endTime - exitStart

        if (not hasNextLine) or exitSpan < MIN_EXIT_SPAN or elapsed < exitStart then
            offsetX = positions[nWords]
            offsetY = BASE_Y
        else
            local progress = (elapsed - exitStart) / exitSpan
            progress = math.max(0, math.min(1, progress))
            offsetX = positions[nWords] + EXIT_OFFSET * progress
            offsetY = BASE_Y + BOUNCE_HEIGHT * heightScale(EXIT_OFFSET) * (1 - (1 - progress) ^ UP_POW)
        end
    end

    self.frames.alpaca:ClearAllPoints()
    self.frames.alpaca:SetPoint("BOTTOM", self.frames.lyricsText, "TOP", offsetX, offsetY)
end
