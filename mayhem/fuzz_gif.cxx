#include <FL/Fl_GIF_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  Fl_GIF_Image img("fuzz.gif", data, size);
  return mayhem_result(img);
}
