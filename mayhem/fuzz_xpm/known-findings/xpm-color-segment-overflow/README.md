# Fl_XPM_Image.cxx:120 -ncolors*4 overflows

Reproducer: `crash-6a777f5a13ab69a183416b80345dea175b9072e0` (replay: `/mayhem/fuzz_xpm-standalone <file>`).

- **Cause:** for FLTK's compressed colormap (`ncolors < 0`) the colour-segment check computes `-ncolors*4` in `int` (here `2144822157 * 4`) from the unchecked header value.
- **Impact:** signed-overflow UB on a 965-byte file; the comparison against the line length is done with the wrapped value.
- **Fix:** validate `ncolors` (and `chars_per_pixel`) after the `sscanf` and do the multiplication in `size_t`.
- **Root cause:** same unvalidated header as `xpm-pic-segment-overflow`.
