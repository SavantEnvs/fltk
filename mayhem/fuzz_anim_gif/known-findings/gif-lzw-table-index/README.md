# Fl_GIF_Image.cxx:345 Suffix[] index out of bounds

Reproducer: `crash-94862b29904cd0269f20a97cef6e4ba0612dc983` (replay: `/mayhem/fuzz_anim_gif-standalone <file>`).

- **Cause:** the LZW minimum code size is read from the file and never bounded (GIF allows at most 11/12). `ClearCode = 1 << (CodeSize-1)` makes `FreeCode` start in the millions, so the `i < FreeCode` guard at line 344 passes for any index and `Suffix[i]` at line 345 reads far outside the 4096-entry `uchar Suffix[4096]` (UBSan array-bounds; indexes seen are 7196 to 14165150). With `CodeSize <= 12`, `FreeCode` is capped at 4096 and this cannot happen.
- **Impact:** out-of-bounds stack read (and later write at `Prefix`/`Suffix[FreeCode]`) driven by header bytes.
- **Fix:** reject `CodeSize > 12` before the decode loop (same root cause as `gif-shift-exponent`, which hits the shifts at lines 270 and 670).
