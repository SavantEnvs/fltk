// Shared helper for the FLTK image-loader harnesses: loaders that only take a file name get the
// fuzz input through a private temp file under $TMPDIR (the image dir is read-only under Mayhem).
#ifndef MAYHEM_FUZZ_COMMON_H
#define MAYHEM_FUZZ_COMMON_H
#include <stdint.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <unistd.h>
#include <FL/Fl_Image.H>

// Writes data to a fresh temp file named <TMPDIR>/fltk-XXXXXX<suffix>; returns false if it cannot.
static inline bool mayhem_write_tmp(const uint8_t *data, size_t size, const char *suffix, char *path, size_t pathlen) {
  const char *dir = getenv("TMPDIR");
  if (!dir || !*dir) dir = "/tmp";
  size_t slen = strlen(suffix);
  int n = snprintf(path, pathlen, "%s/fltk-XXXXXX%s", dir, suffix);
  if (n <= 0 || (size_t)n >= pathlen) return false;
  int fd = mkstemps(path, (int)slen);
  if (fd < 0) return false;
  size_t off = 0;
  while (off < size) {
    ssize_t w = write(fd, data + off, size - off);
    if (w <= 0) break;
    off += (size_t)w;
  }
  close(fd);
  if (off != size) { unlink(path); return false; }
  return true;
}

// A loader that refused the input leaves the image in a failed state; libFuzzer must not keep it.
static inline int mayhem_result(const Fl_Image &img) { return img.fail() ? -1 : 0; }
#endif
