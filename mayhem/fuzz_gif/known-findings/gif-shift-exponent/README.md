# Fl_GIF_Image.cxx:670 shift exponent too large

Reproducer: `crash-7c18ee61b519bbf10b1473081dbd5a9c8cba22cb` (replay: `/mayhem/fuzz_gif-standalone <file>`).

- **Cause:** the "broken GIF" workaround computes `1 << BitsPerPixel` with `BitsPerPixel = CodeSize - 1`, where `CodeSize` is read from the file and can be well above 31, so the shift exponent exceeds the width of `int` (UBSan `shift-exponent`).
- **Impact:** undefined behaviour on attacker-controlled GIF headers; with halting UBSan the target aborts.
- **Fix:** bound `BitsPerPixel` before shifting, e.g. reject `CodeSize > 12` (GIF's maximum LZW code size).
