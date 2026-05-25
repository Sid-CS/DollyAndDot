# DollyAndDot

A World of Warcraft addon (Retail, Midnight 12.0.5) that recreates the classic "Dolly and Dot" karaoke WeakAura. When anyone nearby uses **Meerah's Jukebox** toy, the addon displays karaoke-style lyrics with word-by-word yellow highlighting and animates a 3D jumping alpaca across the text.

## Install

### Addon Manager
Install via [CurseForge](https://www.curseforge.com/wow/addons/dollyand dot) or [Wago](https://addons.wago.io).

### Manual
1. Download the latest release from [GitHub Releases](https://github.com/Sid-CS/DollyAndDot/releases)
2. Extract the `DollyAndDot` folder into `World of Warcraft/_retail_/Interface/AddOns/`
3. Restart WoW or `/reload`

## Features

- **Karaoke-style lyrics** — word-by-word yellow highlighting synced to the Dolly and Dot song
- **Jumping alpaca** — 3D alpaca model bounces across the lyrics text
- **Auto-trigger** — detects when anyone nearby uses Meerah's Jukebox toy (spell ID 288851)
- **Party/Raid chat** — optionally sends lyrics to your group chat so everyone can sing along
- **Fantasy font** — Morpheus font for that old-school WoW quest feel

## Slash Commands

| Command | Action |
|---------|--------|
| `/dolly` | Start karaoke manually (no toy needed) |
| `/dolly stop` | Cancel mid-sequence |
| `/dolly chat` | Toggle party/raid chat output |

## Chat Output

When chat is enabled (default: on), lyrics are sent to your current group channel:
- **Instance Chat** (LFG/LFR) → **Raid** → **Party**
- If you're solo, no messages are sent
- Uses the modern `C_ChatInfo.SendChatMessage` API

## Credits

Inspired by the original [Dolly and Dot WeakAura](https://wago.io/ihJP5eZK2) by the WoW community.

## License

[MIT](LICENSE)
