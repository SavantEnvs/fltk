# Fl_GIF_Image.cxx:270 shift/overflow on file-controlled code size

Reproducer: `crash-34867ff3b0dd996f24a176f9e4b26722adcf391c` (replay: `/mayhem/fuzz_anim_gif-standalone <file>`).

- **Cause:** `ReadMask = (1<<CodeSize) - 1` (line 270) and `ClearCode = 1 << (CodeSize-1)` shift by a file-controlled code size; at `CodeSize` 31 or 32 the shift is UB (shift exponent 32, or `-2147483648 - 1` signed overflow). Same root cause as `gif-shift-exponent` (line 670): the LZW code size is not bounded.
- **Impact:** UB on attacker-controlled GIF header; with halting UBSan the target aborts.
- **Fix:** reject `CodeSize > 12`.
