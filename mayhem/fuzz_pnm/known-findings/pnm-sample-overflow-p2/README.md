# Fl_PNM_Image.cxx:154 (P2) 255 * val overflows

Reproducer: `crash-4ff77029ab0fb3a962f5de7bad73c8bd0090dda7` (replay: `/mayhem/fuzz_pnm-standalone <file>`).

- **Cause:** in the P2 (ASCII graymap) branch `val` comes from `fscanf("%d")` unchecked and `255 * val / maxval` multiplies in `int` (here `255 * -598358244`).
- **Impact:** signed-overflow UB on a 58-byte file; the stored byte is garbage. `maxval` is also used as a divisor and is never checked against `val`.
- **Fix:** clamp or reject `val` outside `0..maxval` and compute the scaling in `long long`.
- **Root cause:** same unvalidated sample as `pnm-sample-overflow-p1` and `-p3`.
