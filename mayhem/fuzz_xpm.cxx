#include <FL/Fl_XPM_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  char path[4096];
  if (!mayhem_write_tmp(data, size, ".xpm", path, sizeof path)) return -1;
  int rc;
  {
    Fl_XPM_Image img(path);
    rc = mayhem_result(img);
  }
  unlink(path);
  return rc;
}
