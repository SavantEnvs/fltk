# Fl_XPM_Image.cxx:119 W*chars_per_pixel overflows

Reproducer: `crash-1f9b435e71bee135474161090e822cf6f9c4d9bb` (replay: `/mayhem/fuzz_xpm-standalone <file>`).

- **Cause:** the first XPM line is parsed with `sscanf("%d%d%d%d")` into `W, H, ncolors, chars_per_pixel` without any range check; the picture-segment check on every following line computes `W*chars_per_pixel` in `int` (here `32 * -1174308552`).
- **Impact:** signed-overflow UB on a 1738-byte file; the overflowed value decides whether a pixel line is accepted, so the validation itself is unreliable.
- **Fix:** reject non-positive or oversized `W`, `H`, `ncolors`, `chars_per_pixel` right after the `sscanf`, and compute the products in `size_t`.
- **Root cause:** the same unvalidated header as `xpm-color-segment-overflow` (:120).
