# Fl_BMP_Image.cxx:258 int overflow in the mask-size computation

Reproducer: `crash-eb10a286b7cdbcd7fa4ce625097b3aad64ae7e98` (replay: `/mayhem/fuzz_bmp-standalone <file>`).

- **Cause:** for an uncompressed 8+ bit BMP, `maskSize = (((width*Bpp+3)&~3)*height) + (((((width+7)/8)+3)&~3)*height)` (line 258) multiplies header-controlled `width`, `Bpp` and `height` in `int`; the two products overflow independently (UBSan reports columns 30 and 41 as separate defects, e.g. `1572864 * 1536`, `1209563391 * 3907`). Same code is reached from `fuzz_ico`.
- **Impact:** signed-overflow UB on attacker-controlled dimensions (a 111-byte file); the wrapped `maskSize` is then compared to `2*dataSize` to decide whether an AND mask is present, so overflow can flip that decision.
- **Fix:** compute `maskSize` in `int64_t`/`size_t`, and reject dimensions whose product cannot fit the file size.
