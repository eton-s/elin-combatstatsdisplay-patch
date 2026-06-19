<#
  apply_fix.ps1  -  CombatStatsDisplay nightly damage-tracking fix (1-byte patch)

  PowerShell version of apply_fix.py, for Windows machines without Python.

  What it does:
    Reads the mod DLL, verifies it is the exact build this patch was made for,
    flips ONE byte (offset 0x5BC6: 0x33 -> 0x32), and writes a patched COPY.
    The original file is never modified.

    0x33 = IL 'bne.un.s'  -> "skip a DamageHP unless it has exactly 8 parameters"
    0x32 = IL 'blt.s'     -> "skip a DamageHP only if it has fewer than 8 parameters"
    i.e. it makes the mod accept Elin nightly's 9-parameter Card.DamageHP.

  Usage:
    powershell -ExecutionPolicy Bypass -File apply_fix.ps1 [pathToDll] [outDll]
    (defaults: .\CombatStatsDisplay.dll  ->  .\CombatStatsDisplay.patched.dll)

  No network access, no modules, no admin rights. Standard .NET methods only.
#>
[CmdletBinding()]
param(
  [string]$Src = "CombatStatsDisplay.dll",
  [string]$Dst = "CombatStatsDisplay.patched.dll"
)
$ErrorActionPreference = 'Stop'

$OFFSET      = 0x5BC6
$OLD_BYTE    = [byte]0x33   # IL bne.un.s  (param-count check:  != 8  -> skip)
$NEW_BYTE    = [byte]0x32   # IL blt.s     (param-count check:  <  8  -> skip)
$ORIG_SHA256 = "709fc81bd3bdf5d4b7647b75bd687a51e20f530f1b1c8ab1db250c55840822ec"

$bytes = [System.IO.File]::ReadAllBytes($Src)

# 1) Make sure this is the exact mod build the patch targets (fails safe otherwise).
$hash = [System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes)
$got  = -join ($hash | ForEach-Object { $_.ToString('x2') })
if ($got -ne $ORIG_SHA256) {
  Write-Host "Refusing to patch: SHA-256 does not match the supported build." -ForegroundColor Red
  Write-Host "  expected $ORIG_SHA256"
  Write-Host "  got      $got"
  exit 1
}

# 2) Double-check the exact byte before touching it.
if ($bytes[$OFFSET] -ne $OLD_BYTE) {
  Write-Host ("Refusing to patch: byte at 0x{0:X4} is 0x{1:X2}, expected 0x{2:X2}." -f $OFFSET, $bytes[$OFFSET], $OLD_BYTE) -ForegroundColor Red
  exit 1
}

# 3) Flip the one byte and write a NEW file (the original is left untouched).
$bytes[$OFFSET] = $NEW_BYTE
[System.IO.File]::WriteAllBytes($Dst, $bytes)

$newHex = -join ([System.Security.Cryptography.SHA256]::Create().ComputeHash($bytes) | ForEach-Object { $_.ToString('x2') })
Write-Host ("OK - patched 1 byte at 0x{0:X4}: 0x{1:X2} -> 0x{2:X2}" -f $OFFSET, $OLD_BYTE, $NEW_BYTE)
Write-Host ("Wrote: {0}" -f (Resolve-Path $Dst).Path)
Write-Host ("Patched SHA-256: {0}" -f $newHex)
