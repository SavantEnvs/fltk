# Fl_PNM_Image.cxx:159 (P3) 255 * val overflows

Reproducer: `crash-8b8d8550cd791cab8d36f90360514f3f14f8054f` (replay: `/mayhem/fuzz_pnm-standalone <file>`).

- **Cause:** in the P3 (ASCII pixmap) branch each of the three channels does `255 * val / maxval` on an unchecked `fscanf("%d")` value (here `255 * 1195816985`); lines 160 and 161 have the identical expression.
- **Impact:** signed-overflow UB on a 26-byte file.
- **Fix:** clamp or reject `val` outside `0..maxval` and compute the scaling in `long long`.
- **Root cause:** same unvalidated sample as `pnm-sample-overflow-p1` and `-p2`.
