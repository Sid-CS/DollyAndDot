# Changelog

## v1.0.2
- `!dolly` chat trigger — anyone with the addon who sees `!dolly` in say/yell/party/raid/instance/whisper starts karaoke and plays the song
- Manual `/dolly` (and `!dolly`) now plays the Dolly and Dot audio via the in-game FileDataID (3169894) — no toy required
- `/dolly stop` now also stops the audio

## v1.0.1
- Added group sync via addon messages — when anyone in your group uses Meerah's Jukebox, all addon users start karaoke together
- Fixed taint errors from party member spell detection in Midnight 12.0.5
- Player-only spell detection (untainted) with addon broadcast to group
- Everyone with the addon sings lyrics in party/raid chat simultaneously

## v1.0.0
- Initial release
- Word-by-word yellow highlighting with timing from original WeakAura
- Jumping alpaca 3D model (displayInfo 88594, animation sequence 5)
- Morpheus fantasy font
- Toy detection via UNIT_SPELLCAST_SUCCEEDED (Meerah's Jukebox, spell ID 288851)
- Party/raid chat output via C_ChatInfo.SendChatMessage
- Slash commands: `/dolly`, `/dolly stop`, `/dolly chat`
