# Fl_GIF_Image.cxx:734 negative-size memcpy for out-of-screen frame

Reproducer: `crash-b348b6527a15acfc27278e6b86c3c7fdf95f1802` (replay: `/mayhem/fuzz_anim_gif-standalone <file>`).

- **Cause:** in the animated-GIF path, a frame that lies outside the logical screen makes `xmax - xstart` negative in the compositing loop, and the `memcpy(dst, src, xmax-xstart)` at line 734 converts it to a huge `size_t` (ASan negative-size-param).
- **Impact:** memcpy with a huge length (crash / memory corruption) from a 5 KB GIF.
- **Fix:** skip frames or rows where `xmax <= xstart` (or `ymax <= ystart`) before copying.
