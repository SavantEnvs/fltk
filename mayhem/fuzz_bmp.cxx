#include <FL/Fl_BMP_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  Fl_BMP_Image img("fuzz.bmp", data, (long)size);
  return mayhem_result(img);
}
