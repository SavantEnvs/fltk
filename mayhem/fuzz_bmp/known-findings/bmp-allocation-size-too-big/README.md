# Fl_BMP_Image.cxx:325 allocation size from header width/height

Reproducer: `crash-75a15ad46f6b3ab7b12a040e31fc40c67b96fa5a` (replay: `/mayhem/fuzz_bmp-standalone <file>`).

- **Cause:** `new uchar[w()*h()*d()]` is sized straight from the BMP header's width/height without a sanity limit (`operator new[]` requests 0x90df2d7a6011c374 bytes). The same product also overflows `int` at Fl_BMP_Image.cxx:344 (see fuzz_ico).
- **Impact:** ASan allocation-size-too-big abort (a real embedder gets `std::bad_alloc`/huge allocation) on a 127-byte file.
- **Fix:** validate width/height against the file size (or a cap) and compute the size in `size_t`.
