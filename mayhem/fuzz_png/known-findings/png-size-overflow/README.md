# Fl_PNG_Image.cxx:218 signed overflow in w()*h()*d()

Reproducer: `crash-2dc12541a67e17af8d3fee44b9d1a41eaceff072` (replay: `/mayhem/fuzz_png-standalone <file>`).

It is a 680-byte PNG whose IHDR declares `190546 x 422396`, 8-bit RGB (3 channels); libpng accepts it because its default limit is 1,000,000 pixels per side. Mayhem run 3 reports it once (defect #3608024, Integer Overflow or Wraparound, first application frame in `Fl_PNG_Image::load_png_`, reached through `Fl_PNG_Image(const char*, const uchar*, int)`).

- **Cause:** `new uchar[w() * h() * d()]` multiplies header-controlled `int`s, and `190546 * 422396` does not fit in `int`. The guard on the line above, `((size_t)w()) * h() * d() > max_size()`, does the product in `size_t` but compares it with `Fl_RGB_Image::max_size()`, whose default is `~(size_t)0`, so it never rejects a large header. It is the same bug as `fuzz_pnm/known-findings/pnm-signed-overflow` (`Fl_PNM_Image.cxx:139`).
- **Impact:** UB, and a potential heap overflow. When the wrapped size is small or negative, the allocation is far smaller than the `h()` rows of `w() * d()` bytes that `png_read_rows` then writes into it (the `rows[i]` pointers use the same `int` arithmetic).
- **Fix:** compute `w() * h() * d()` in `size_t` once, reject it when it overflows or exceeds a sane limit (`Fl_RGB_Image::max_size()` has no limit unless the application sets one), and use that value for both the allocation and the row pointers.
