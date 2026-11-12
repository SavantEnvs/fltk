#include <FL/Fl_ICO_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  Fl_ICO_Image img("fuzz.ico", -1, data, size);
  return mayhem_result(img);
}
