# Fl_PNM_Image.cxx:149 (P1) 255 * (1-val) overflows

Reproducer: `crash-95aad19e46d64a2fef9d7d20c463ea47ff5ca2a1` (replay: `/mayhem/fuzz_pnm-standalone <file>`).

- **Cause:** in the P1 (ASCII bitmap) branch the sample `val` comes from `fscanf("%d")` with no range check, and `255 * (1-val)` is evaluated in `int` (here `val` makes the factor `-460460524`).
- **Impact:** signed-overflow UB on a 55-byte file; the result is then truncated to `uchar`, so only the pixel value is wrong, but the UB is real.
- **Fix:** reject samples outside `0..1` for P1 (`0..maxval` for P2/P3), or compute in `long long`/clamp `val` before the multiplication.
- **Root cause:** the same unvalidated sample value is behind `pnm-sample-overflow-p2` (:154) and `pnm-sample-overflow-p3` (:159, repeated on :160/:161). They are three lines of one bug, kept as separate entries because Mayhem reports a defect per line.
