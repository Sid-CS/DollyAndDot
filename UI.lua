-- UI frame creation and management

local _, ns = ...

local FONT = "Fonts\\MORPHEUS.TTF"  -- ornate fantasy font (quest title style)
local FONT_SIZE = 36
local HIGHLIGHT_COLOR = "FFFFFF00"  -- yellow
local NORMAL_COLOR = "FFFFFFFF"     -- white

-- Extra spacing between words so the karaoke-ball hop has room to feel exaggerated.
-- Used by both BuildColoredText (render) and GetWordPositions (alpaca placement).
ns.WORD_SEPARATOR = "   "  -- 3 spaces

function ns:CreateUI()
    if self.frames.container then
        self:ResetUI()
        self.frames.container:Show()
        return
    end

    -- Container frame centered above screen center (yOffset 119 from original WA)
    local container = CreateFrame("Frame", "DollyAndDotFrame", UIParent)
    container:SetSize(1200, 100)
    container:SetPoint("CENTER", UIParent, "CENTER", 0, 119)
    container:SetFrameStrata("HIGH")
    container:SetFrameLevel(100)
    self.frames.container = container

    -- Single FontString for lyrics — we build colored text with inline |cFF codes
    local text = container:CreateFontString(nil, "OVERLAY")
    text:SetFont(FONT, FONT_SIZE, "OUTLINE")
    text:SetPoint("CENTER", container, "CENTER", 0, 0)
    text:SetJustifyH("CENTER")
    text:SetWidth(1200)
    text:SetWordWrap(false)
    self.frames.lyricsText = text

    -- Alpaca 3D model
    self:CreateAlpacaModel(container)

    container:Show()
end

local ALPACA_DISPLAY_ID = 88594  -- original WeakAura value (Dot)
local ALPACA_ANIM       = 5      -- 5 = Run on creature models; intrinsic cycle ~594ms
local ALPACA_SIZE       = 120

function ns:CreateAlpacaModel(parent)
    local alpaca = CreateFrame("PlayerModel", nil, parent)
    alpaca:SetSize(ALPACA_SIZE, ALPACA_SIZE)
    alpaca:SetFrameLevel(parent:GetFrameLevel() + 1)
    alpaca:SetKeepModelOnHide(true)

    -- Must show before setting model (M33kAuras pattern)
    alpaca:Show()
    local ok = pcall(alpaca.SetDisplayInfo, alpaca, ALPACA_DISPLAY_ID)
    if not ok then
        pcall(alpaca.SetModel, alpaca, 2139079)
    end
    pcall(alpaca.ClearTransform, alpaca)
    pcall(alpaca.SetPosition, alpaca, 0, 0, 0)
    pcall(alpaca.SetFacing, alpaca, math.rad(90))  -- face right
    pcall(alpaca.SetAnimation, alpaca, ALPACA_ANIM)
    alpaca:Hide()

    self.frames.alpaca = alpaca
end

function ns:ResetUI()
    if self.frames.lyricsText then
        self.frames.lyricsText:SetText("")
    end
    if self.frames.alpaca then
        self.frames.alpaca:Hide()
    end
end

function ns:BuildColoredText(lineIndex, elapsed)
    local line = self.LYRICS[lineIndex]
    local parts = {}
    for _, word in ipairs(line.words) do
        if elapsed >= word.colorAt then
            parts[#parts + 1] = "|c" .. HIGHLIGHT_COLOR .. word.text .. "|r"
        else
            parts[#parts + 1] = "|c" .. NORMAL_COLOR .. word.text .. "|r"
        end
    end
    return table.concat(parts, ns.WORD_SEPARATOR)
end
