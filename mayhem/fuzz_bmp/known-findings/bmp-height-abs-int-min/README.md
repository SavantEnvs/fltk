# Fl_BMP_Image.cxx:227 height = abs(temp) overflows for INT_MIN

Reproducer: `crash-c6698d32153adf9e5969145c764613e72ff22c96` (replay: `/mayhem/fuzz_bmp-standalone <file>`).

- **Cause:** the BITMAPINFOHEADER height is a signed 32-bit value; a negative height means top-down rows, and the code takes `height = abs(temp)`. For `temp = INT_MIN` the negation is not representable.
- **Impact:** signed-overflow UB on a 146-byte file; `abs(INT_MIN)` returns `INT_MIN`, so `height` stays negative.
- **Fix:** reject `temp == INT_MIN` (or any height beyond a sane limit) before calling `abs`.
- **Root cause:** independent of the other BMP bugs (:212, :258, :259, :325), which are in different header fields.
