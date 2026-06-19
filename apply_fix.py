#!/usr/bin/env python3
"""
apply_fix.py  -  CombatStatsDisplay nightly damage-tracking fix (1-byte patch)

What it does:
  Reads the mod DLL, verifies it is the exact build this patch was made for,
  flips ONE byte (offset 0x5BC6: 0x33 -> 0x32), and writes a patched COPY.
  The original file is never modified.

  That byte is a single IL branch opcode inside DamageHook.Patch8Arg:
      0x33 = bne.un.s   -> "skip this method unless it has exactly 8 parameters"
      0x32 = blt.s      -> "skip this method only if it has fewer than 8 parameters"
  i.e. it makes the mod also accept Elin nightly's 9-parameter Card.DamageHP,
  which is what restores damage-dealt / damage-taken tracking.

Usage:
  python apply_fix.py [path-to-CombatStatsDisplay.dll] [output.dll]
  (defaults: ./CombatStatsDisplay.dll  ->  ./CombatStatsDisplay.patched.dll)

Standard library only. No network access, no third-party packages.
"""
import sys, os, hashlib

OFFSET      = 0x5BC6
OLD_BYTE    = 0x33   # IL  bne.un.s   (param-count check:  != 8  -> skip method)
NEW_BYTE    = 0x32   # IL  blt.s      (param-count check:  <  8  -> skip method)
ORIG_SHA256 = "709fc81bd3bdf5d4b7647b75bd687a51e20f530f1b1c8ab1db250c55840822ec"

src = sys.argv[1] if len(sys.argv) > 1 else "CombatStatsDisplay.dll"
dst = sys.argv[2] if len(sys.argv) > 2 else "CombatStatsDisplay.patched.dll"

data = bytearray(open(src, "rb").read())

# 1) Make sure this is the exact mod build the patch targets (fails safe otherwise).
got = hashlib.sha256(data).hexdigest()
if got != ORIG_SHA256:
    sys.exit("Refusing to patch: SHA-256 does not match the supported build.\n"
             f"  expected {ORIG_SHA256}\n"
             f"  got      {got}\n"
             "Your CombatStatsDisplay version differs from the one this patch was made for.")

# 2) Double-check the exact byte before touching it.
if data[OFFSET] != OLD_BYTE:
    sys.exit(f"Refusing to patch: byte at {hex(OFFSET)} is {hex(data[OFFSET])}, expected {hex(OLD_BYTE)}.")

# 3) Flip the one byte and write a NEW file (the original is left untouched).
data[OFFSET] = NEW_BYTE
with open(dst, "wb") as f:
    f.write(data)

print(f"OK - patched 1 byte at {hex(OFFSET)}: {hex(OLD_BYTE)} -> {hex(NEW_BYTE)}")
print(f"Wrote: {os.path.abspath(dst)}")
print(f"Patched SHA-256: {hashlib.sha256(data).hexdigest()}")
