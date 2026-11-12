# Fl_GIF_Image.cxx:690 Width*Height int overflow

Reproducer: `crash-cda6ec10c553cd89494aa8a0664a7459682d67aa` (replay: `/mayhem/fuzz_anim_gif-standalone <file>`).

- **Cause:** `new uchar[Width*Height]` (line 690) and the matching `Width*Height` / `ScreenWidth*ScreenHeight` products multiply two 16-bit values (up to 65535 each) in `int`, overflowing it.
- **Impact:** UB, and a wrapped value can size the image buffer smaller than the decoder writes.
- **Fix:** compute the sizes in `size_t` and reject images whose area exceeds a sane limit.
