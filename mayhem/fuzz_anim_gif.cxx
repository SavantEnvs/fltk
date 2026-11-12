#include <FL/Fl_Anim_GIF_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  // DONT_START: decode every frame but never register an animation timer with the (absent) event loop.
  Fl_Anim_GIF_Image img("fuzz.gif", data, size, nullptr, Fl_Anim_GIF_Image::DONT_START);
  return img.valid() ? 0 : -1;
}
