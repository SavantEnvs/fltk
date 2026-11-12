# Fl_SVG_Image.cxx:293-294 int(width + 0.5) / int(height + 0.5) on an unbounded float (CWE-197)

Reproducer: `crash-3a5540b06d68c4d5aff7a963456b9719a164e812` (replay: `/mayhem/fuzz_svg-standalone <file>`). Mayhem run 3 reports both lines: `:293` for the width and `:294` for the height; the reproducer trips `:294`.

- **Cause:** `nsvgParse` returns the document size as `float`, taken from the `width`/`height` attributes with no upper bound (here `height="4009999985,..."` parses to `4.01e+09`). `w(int(svg_image->width + 0.5))` (`:293`) and `h(int(svg_image->height + 0.5))` (`:294`) convert that to `int` without a range check.
- **Impact:** float-to-int conversion UB (UBSan `float-cast-overflow`) on a 1377-byte file; the image then gets an arbitrary `h()`.
- **Fix:** clamp or reject `width`/`height` outside `1..INT_MAX` (or a sane maximum) before the cast.
