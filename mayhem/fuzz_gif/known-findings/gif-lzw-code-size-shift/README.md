# Fl_GIF_Image.cxx:270 shift/overflow on file-controlled code size

Reproducer: `crash-d7f54ef1c63772117321bbbe76f536fc68b8f4a5` (replay: `/mayhem/fuzz_gif-standalone <file>`).

- **Cause:** `ReadMask = (1<<CodeSize) - 1` (line 270) and `ClearCode = 1 << (CodeSize-1)` shift by a file-controlled code size; at `CodeSize` 31 or 32 the shift is UB (shift exponent 32, or `-2147483648 - 1` signed overflow). Same root cause as `gif-shift-exponent` (line 670): the LZW code size is not bounded.
- **Impact:** UB on attacker-controlled GIF header; with halting UBSan the target aborts.
- **Fix:** reject `CodeSize > 12`.
