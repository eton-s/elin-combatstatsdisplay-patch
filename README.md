# elin-combatstatsdisplay-patch

A one-byte patch that restores damage tracking in the **[CombatStatsDisplay](https://steamcommunity.com/sharedfiles/filedetails/?id=3555582126)** mod for **[Elin](https://store.steampowered.com/app/2135150/Elin/)**.

## Problem

CombatStatsDisplay loads and runs, but **damage dealt and damage taken stay at 0** — while healing and buff/debuff tracking still work.

The cause: an Elin update added a parameter to the game's `Card.DamageHP` method. The mod locates that method by its parameter **count**, requiring exactly **8** parameters. The updated method has one more, so the mod never hooks it and no damage is recorded.

## Fix

Flip a single byte in the mod's DLL so the parameter-count check accepts the new signature — it changes the test from "exactly 8 parameters" to "8 or more". The eight parameter-type checks that follow are unchanged, so it still matches the correct method.

|                | |
|----------------|--------------------------------------------------------------------|
| Target         | `CombatStatsDisplay.dll` (Steam Workshop id `3555582126`)          |
| Change         | offset `0x5BC6`: `0x33` → `0x32`  (IL `bne.un.s` → `blt.s`)        |
| Input SHA-256  | `709fc81bd3bdf5d4b7647b75bd687a51e20f530f1b1c8ab1db250c55840822ec` |
| Output SHA-256 | `1f9a386f060619ee8a800dec748bd0e97406687a9f2e908d077dd8960dc1c8b9` |

## Usage

> Uses Windows PowerShell (built into Windows) — nothing to install.

1. **Find the mod DLL.** With CombatStatsDisplay subscribed, it's at:
   ```
   <SteamLibrary>\steamapps\workshop\content\2135150\3555582126\CombatStatsDisplay.dll
   ```
2. **Run the patcher.** It writes `CombatStatsDisplay.patched.dll` in the current folder; your original is left untouched:
   ```powershell
   powershell -ExecutionPolicy Bypass -File apply_fix.ps1 "C:\path\to\CombatStatsDisplay.dll"
   ```
   The script verifies the file's SHA-256 and the exact byte before changing anything, so it can't patch the wrong file.
3. **Load it as a local copy** (so Steam won't overwrite it on the next update):
   - Copy the Workshop folder `3555582126` into `…\steamapps\common\Elin\Package\` and rename it, e.g. `CombatStatsDisplay_patched`.
   - Replace the DLL in that copy with your `CombatStatsDisplay.patched.dll`.
   - In that copy's `package.xml`, change `<id>` and `<title>` to something distinct (e.g. add `_patched`) so it shows up as its own entry.
4. **Switch versions in-game.** Launch Elin → Mods. **Disable** the Workshop "CombatStatsDisplay" and **enable** your patched copy. They share one plugin id, so only one may be active at a time.
5. Restart, load your save, and confirm damage now counts.

## Manual alternative (any hex editor)

Open `CombatStatsDisplay.dll`, go to offset `0x5BC6`, change the byte `0x33` to `0x32`, and save.

## Notes

- **Unofficial.** This patches *your own* copy of the mod; it does not redistribute the mod. CombatStatsDisplay is created by NS.
- **Version-specific.** The hashes and offset above match the current Workshop build. If the mod is updated, `apply_fix.ps1` will refuse to run (the SHA-256 won't match) rather than patch the wrong bytes — the offset would need to be re-derived for the new build.
