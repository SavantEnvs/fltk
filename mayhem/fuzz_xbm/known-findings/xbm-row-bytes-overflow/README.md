# Fl_XBM_Image.cxx:76 ((width+7)/8)*height overflows

Reproducer: `crash-0854ce0a92dd48dfaf0ac3981116978570c721ab` (replay: `/mayhem/fuzz_xbm-standalone <file>`).

- **Cause:** `int n = ((wh[0]+7)/8)*wh[1]` multiplies the header's `#define ..._width/_height` values in `int` (here `2 * -2101409110`); the result also becomes the `new uchar[n]` size and the read-loop bound.
- **Impact:** signed-overflow UB on a 184-byte file; when the product wraps negative the next line (:77) requests a ~16 EiB allocation, which is `xbm-allocation-size-too-big` (OOM-class).
- **Fix:** reject non-positive or oversized `wh[0]`/`wh[1]` and compute `n` in `size_t`.
- **Root cause:** same unvalidated dimensions as `xbm-allocation-size-too-big`; the two are one expression on adjacent lines.
