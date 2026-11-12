# Fl_GIF_Image.cxx:461 per-row allocations in convert_to_xpm (OOM-class)

Reproducer: `crash-22e198928faede768f20674a1cd75c08fd5e2695` (replay: `/mayhem/fuzz_anim_gif <file>`, the libFuzzer binary).

The replay must use the libFuzzer binary (2 GiB RSS limit); `/mayhem/fuzz_anim_gif-standalone` has no limit and finishes normally.

- **Cause:** `convert_to_xpm` allocates one `new char[Width+1]` per image row (`:461`, `Height` rows). The screen size comes straight from the 16-bit logical-screen header, so a 1169-byte file declaring `65535 x 3329` makes it allocate 3329 rows of about 64 KiB (218 MB) on top of the other buffers it already holds. The reproducer's frame (172 x 48992) differs from the screen size, so the `:736` call passes the `ScreenWidth x ScreenHeight` buffer to it.
- **How it is reported:** libFuzzer's OOM report lists the live allocation contexts. In the replay above it prints `872664060 byte(s) in 1 allocation(s)` at `Fl_Anim_GIF_Image.cxx:310:17` (the canvas, see `../anim-gif-canvas-allocation/`) and `218169344 byte(s) in 3329 allocation(s)` at `Fl_GIF_Image.cxx:461:21`. Mayhem (run 4 only, defect #3608703; run 5 does not report it) reports the second context; the same input is the crasher for both. Total RSS at the limit is 2192 MB, and the input passes with `-rss_limit_mb=2500`.
- **Impact:** memory amplification, not a memory-safety bug (libFuzzer `out-of-memory`, CWE-789). The same header-derived size also drives the canvas allocation, so they add up.
- **Fix:** cap the screen size (or total decoded bytes) and fail the load above it; store the XPM rows without a per-row allocation, or only after the size has been validated.
