# Fl_GIF_Image.cxx:676 CMap out-of-bounds write in the transparent-index fix-up

Reproducer: `crash-be3b0a527c35cba75e5e4c50498798e91adba156` (replay: `/mayhem/fuzz_gif-standalone <file>`).

- **Cause:** the "broken GIF" workaround at lines 669-671 does `BitsPerPixel = CodeSize - 1; if (1 << BitsPerPixel <= 256) ColorMapSize = 1 << BitsPerPixel;`. With a file-controlled code size of 32, `1 << 31` is `INT_MIN` (not flagged by UBSan in C++), which passes `<= 256`, so `ColorMapSize` becomes hugely negative. The Issue #271 fix-up then loops `for (k = ColorMapSize; k <= transparent_pixel; k++) CMap.Red[k] = ...` (line 676) from about -2^31 over the 256-entry `CMap` arrays; the faulting address in the reproducer is a wild stack address. Same root cause as `gif-shift-exponent`: the LZW code size is not bounded.
- **Impact:** out-of-bounds stack write on a 1.8 KB GIF whose Graphic Control Extension marks a transparent colour.
- **Fix:** reject `CodeSize > 12` (GIF's maximum) before the workaround, and/or clamp `ColorMapSize` to 2..256.
