#include <FL/Fl_SVG_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  // Fl_SVG_Image's contract: length 0 means "unknown, NUL-terminated string" (it strdup()s the buffer),
  // so an empty input is not a valid call; any non-zero length is bounds-protected.
  if (size == 0) return -1;
  Fl_SVG_Image img("fuzz.svg", data, size);
  return mayhem_result(img);
}
