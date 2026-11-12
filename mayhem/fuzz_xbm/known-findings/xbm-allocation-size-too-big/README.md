# Fl_XBM_Image.cxx:77 allocation size from header width/height

Reproducer: `crash-fbc1a45e2f93a584de0e8743a7ebd3a9b2ffcab1` (replay: `/mayhem/fuzz_xbm-standalone <file>`).

- **Cause:** `n = ((wh[0]+7)/8)*wh[1]` is computed in `int` from the `#define ..._width/_height` values and passed to `new uchar[n]`; a negative/overflowed value becomes a ~16 EiB request.
- **Impact:** ASan allocation-size-too-big abort on a small file.
- **Fix:** reject non-positive or oversized dimensions and compute `n` in `size_t`.
