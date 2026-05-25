# DollyAndDot Karaoke Addon - Copilot Instructions

## Project Overview

A World of Warcraft addon (Retail, Midnight 12.0.5) that recreates the "Dolly and Dot" karaoke WeakAura (wago.io/ihJP5eZK2). When **anyone** nearby uses Meerah's Jukebox toy, the addon displays karaoke-style lyrics with word-by-word yellow highlighting, yells each line in `/yell`, and animates a 3D alpaca model across the text.

## Architecture

- **Core.lua** — Addon init, event handling, lifecycle (`StartKaraoke`/`StopKaraoke`), slash commands
  - Listens to `COMBAT_LOG_EVENT_UNFILTERED` and calls `CombatLogGetCurrentEventInfo()` (not `...` — that's been empty since BFA 8.0)
  - Matches by spell name `"Meerah's Jukebox"` on `SPELL_AURA_APPLIED` / `SPELL_CAST_SUCCESS` from **any** source
  - `/dolly` starts manually, `/dolly stop` cancels

- **Lyrics.lua** — Pure data: word-by-word timing extracted from the original WeakAura
  - Each line has `startTime`, `endTime`, `yellAt` (absolute seconds from trigger)
  - Each word has `colorAt` — the exact second it turns yellow

- **UI.lua** — Frame creation, colored text rendering, alpaca model
  - Single `FontString` for lyrics, rebuilt with `|cFF` color codes when a word changes
  - `PlayerModel` frame for the 3D alpaca (`creature/alpaca/alpaca.m2`, fileId 88594) with fallback

- **Animation.lua** — `OnUpdate` loop driving the whole sequence
  - Tracks current line, updates word colors, moves alpaca left-to-right across the text
  - Yells each line via `SendChatMessage(text, "YELL")` at the scheduled time
  - Auto-stops after 11.5s total duration

## Key Conventions

- All state lives on the `DollyAndDot` namespace table (created from addon `...` args in Core.lua)
- Colon method calls throughout: `DollyAndDot:MethodName()`
- Frame refs stored in `DollyAndDot.frames` (`container`, `lyricsText`, `alpaca`)
- Word color is done via inline `|cFFFFFF00` (yellow) / `|cFFFFFFFF` (white) codes — no per-word FontStrings
- Text is only rebuilt when highlight count changes (perf optimization)

## Timing Reference (from original WeakAura)

| Line | Appears | Yelled | Ends |
|------|---------|--------|------|
| "Dolly and Dot are my best friends!" | 0.0s | 0.5s | 2.8s |
| "They pull my wagon through dunes of sand!" | 2.8s | 3.1s | 5.45s |
| "They have small teeth and they love to eat!" | 5.45s | 5.75s | 8.28s |
| "They're the best 'pacas in all the laaaand!" | 8.28s | 8.65s | 11.5s |

## Testing

1. Copy addon folder to WoW `_retail_/Interface/AddOns/DollyAndDot/`
2. `/dolly` to trigger manually (no toy needed)
3. `/dolly stop` to cancel mid-sequence
4. Watch `/yell` output in chat to verify yell timing

## Common Modifications

- **Adjust word timing**: Edit `colorAt` values in `Lyrics.lua`
- **Change yell channel**: Edit `"YELL"` in Animation.lua's `SendChatMessage` call
- **Change highlight color**: Edit `HIGHLIGHT_COLOR` in UI.lua (format: `AARRGGBB`)
- **Adjust total duration**: Change `TOTAL_DURATION` in Core.lua and last line's `endTime` in Lyrics.lua
