# Fl_Pixmap.cxx:305 delete_data() reads past the row-pointer array

Reproducer: `crash-16d404d191ef2e8f8ca65a5d5af2f3d5866949b5` (replay: `/mayhem/fuzz_anim_gif-standalone <file>`).

- **Cause:** in the animated-GIF branch of `load_gif_` (frame smaller or larger than the logical screen), the XPM is built from the composited image with `convert_to_xpm(moved_image, ScreenWidth, ScreenHeight, ...)` (line 735), which allocates `ScreenHeight+2` row pointers, but the result is registered with `data(new_data, Height + 2)` (line 736), using the *frame* height. When the frame is taller than the screen, `Fl_Pixmap::delete_data()` loops `count()` times over `data()[i]` and reads 8 bytes past the 784-byte pointer array (ASan heap-buffer-overflow READ at `Fl_Pixmap.cxx:305`, in the destructor).
- **Impact:** heap over-read, then `delete[]` of a garbage pointer, when a 1.4 KB animated GIF is destroyed. The bug is in the GIF loader's count, not in `Fl_Pixmap`.
- **Fix:** pass `ScreenHeight + 2` to `data()` in the anim branch.
