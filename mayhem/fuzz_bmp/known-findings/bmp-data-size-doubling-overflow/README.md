# Fl_BMP_Image.cxx:259 int overflow in 2*dataSize

Reproducer: `crash-f6488f41f1eaea7cee3e4b19ae4e0d06ee81465f` (replay: `/mayhem/fuzz_bmp-standalone <file>`).

- **Cause:** `if (maskSize == 2*dataSize)` (line 259) doubles `dataSize` in `int` (`2 * 1107308544`, `2 * -1942224848`, ...); `dataSize` is the header's image-size field (or a value derived from it) and is not bounded by the file length. The same line is reached from ICO.
- **Impact:** signed-overflow UB on a 1.1 KB file.
- **Fix:** compare in 64-bit (`(int64_t)maskSize == 2*(int64_t)dataSize`) or reject `dataSize` above the remaining file size first.
