#include <FL/Fl_JPEG_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  Fl_JPEG_Image img("fuzz.jpg", data, (int)size);
  return mayhem_result(img);
}
