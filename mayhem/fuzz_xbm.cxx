#include <FL/Fl_XBM_Image.H>
#include "fuzz_common.h"

extern "C" int LLVMFuzzerTestOneInput(const uint8_t *data, size_t size) {
  char path[4096];
  if (!mayhem_write_tmp(data, size, ".xbm", path, sizeof path)) return -1;
  int rc;
  {
    Fl_XBM_Image img(path);
    rc = mayhem_result(img);
  }
  unlink(path);
  return rc;
}
