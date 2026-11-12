#include <FL/Fl_PNG_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  Fl_PNG_Image img("fuzz.png", data, (int)size);
  return mayhem_result(img);
}
