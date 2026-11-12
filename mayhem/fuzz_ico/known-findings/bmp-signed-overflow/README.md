# Fl_BMP_Image.cxx:344 signed overflow computing the row offset (reached through ICO)

Reproducer: `oom-aedbccc16c4e367eb06ba575d7a5e93708037b66` (replay: `/mayhem/fuzz_ico-standalone <file>`). libFuzzer reports it as oom; the standalone binary stops on UBSan.

- **Cause:** `ptr = array + y * width * dstBDepth` multiplies ints taken from the (ICO-embedded) BMP header: `1864123800 * 3` overflows `int`.
- **Impact:** UB, and a bogus pointer (out-of-bounds write) if the overflow wraps to a valid-looking offset; large allocations before it make the input an OOM.
- **Fix:** compute the offset in `size_t` and reject dimensions whose product exceeds the data available.
