# Fl_JPEG_Image: header-declared dimensions make decode take >30s

Reproducer: `timeout-da37f90ae8959b0ec45c1ea935c1748bcc8f5623` (1971 bytes; libFuzzer `-timeout=5` reports it, the standalone binary takes >30 s).

- **Cause:** the input makes the decode run for tens of seconds in a 1971-byte file (probably large header-declared dimensions; not root-caused further), and `Fl_JPEG_Image` applies no cap on decoded size.
- **Impact:** denial of service via a small JPEG.
- **Fix:** reject images above a pixel-count cap after reading the header (`cinfo.image_width * cinfo.image_height`) and before decompressing.
