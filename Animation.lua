-- Animation controller for karaoke sequence

local _, ns = ...

function ns:StartAnimation()
    if self.animationFrame then
        self.animationFrame:SetScript("OnUpdate", nil)
    end

    local frame = CreateFrame("Frame")
    self.animationFrame = frame
    self.startTime = GetTime()
    self.currentLineIndex = 0
    self.lastHighlightCount = -1

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

    -- Auto-stop if player enters combat mid-song
    if UnitAffectingCombat("player") then
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

function ns:UpdateAlpacaPosition(elapsed)
    if not self.frames.alpaca or not self.frames.lyricsText then return end

    local lineIndex = self.currentLineIndex
    if lineIndex == 0 then return end

    local line = self.LYRICS[lineIndex]
    local progress = (elapsed - line.startTime) / (line.endTime - line.startTime)
    progress = math.max(0, math.min(1, progress))

    -- Move alpaca from left edge to right edge of the lyrics text
    local textWidth = self.frames.lyricsText:GetStringWidth()
    if textWidth == 0 then textWidth = 600 end

    local offsetX = -textWidth / 2 + (progress * textWidth)

    self.frames.alpaca:ClearAllPoints()
    self.frames.alpaca:SetPoint("BOTTOM", self.frames.lyricsText, "TOP", offsetX, 5)
end
