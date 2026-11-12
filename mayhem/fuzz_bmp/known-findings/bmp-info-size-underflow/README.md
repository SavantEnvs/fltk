# Fl_BMP_Image.cxx:212 repcount = info_size - 12 overflows

Reproducer: `crash-5a71ca684b9d0404a593de08c50c6b067a81535a` (replay: `/mayhem/fuzz_bmp-standalone <file>`).

- **Cause:** `info_size` is read as a signed 32-bit value from the header; the OS/2 branch (`info_size < 40`, taken for any negative size) does `repcount = info_size - 12` (line 212), which for `info_size = INT_MIN` is `-2147483648 - 12`.
- **Impact:** signed-overflow UB on an 86-byte file; `repcount` is later used to skip remaining header bytes.
- **Fix:** treat `info_size < 12` as an invalid header (the smallest valid one is 12 bytes) before computing `repcount`.
