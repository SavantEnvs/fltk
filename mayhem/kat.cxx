// Known-answer probe for mayhem/test.sh: decodes one image file with the real FLTK loader selected
// by the file extension and prints the decoded geometry plus pixel bytes (or the pixmap header). Built with the project's
// normal flags (no sanitizers); dynamically linked so the sabotage shim neuters it.
#include <stdio.h>
#include <string.h>
#include <strings.h>
#include <FL/Fl_Anim_GIF_Image.H>
#include <FL/Fl_BMP_Image.H>
#include <FL/Fl_GIF_Image.H>
#include <FL/Fl_ICO_Image.H>
#include <FL/Fl_JPEG_Image.H>
#include <FL/Fl_PNG_Image.H>
#include <FL/Fl_PNM_Image.H>
#include <FL/Fl_SVG_Image.H>
#include <FL/Fl_XBM_Image.H>
#include <FL/Fl_XPM_Image.H>

static void dump_rgb(Fl_RGB_Image *img) {
  const unsigned char *p = img->array;
  size_t n = (size_t)img->data_w() * img->data_h() * img->d();
  unsigned long sum = 0;
  for (size_t i = 0; i < n; i++) sum += p[i];
  printf("%dx%dx%d ", img->data_w(), img->data_h(), img->d());
  for (size_t i = 0; i < n && i < 12; i++) printf("%02x", p[i]);
  printf(" %lu\n", sum);
}

int main(int argc, char **argv) {
  if (argc != 2) { fprintf(stderr, "usage: %s FILE\n", argv[0]); return 2; }
  const char *f = argv[1];
  const char *ext = strrchr(f, '.');
  if (!ext) return 2;
  if (!strcasecmp(ext, ".gif") && strstr(f, "anim")) {
    Fl_Anim_GIF_Image img(f, (Fl_Widget *)nullptr, Fl_Anim_GIF_Image::DONT_START);
    if (!img.valid()) return 1;
    printf("%dx%d frames=%d\n", img.w(), img.h(), img.frames());
    return 0;
  }
  if (!strcasecmp(ext, ".svg")) {
    Fl_SVG_Image img(f);
    if (img.fail()) return 1;
    printf("%dx%d\n", img.w(), img.h());
    return 0;
  }
  Fl_RGB_Image *rgb = nullptr;
  if (!strcasecmp(ext, ".bmp")) rgb = new Fl_BMP_Image(f);
  else if (!strcasecmp(ext, ".png")) rgb = new Fl_PNG_Image(f);
  else if (!strcasecmp(ext, ".jpg")) rgb = new Fl_JPEG_Image(f);
  else if (!strcasecmp(ext, ".ico")) rgb = new Fl_ICO_Image(f);
  else if (!strcasecmp(ext, ".ppm") || !strcasecmp(ext, ".pgm") || !strcasecmp(ext, ".pbm")) rgb = new Fl_PNM_Image(f);
  if (rgb) {
    if (rgb->fail()) return 1;
    dump_rgb(rgb);
    return 0;
  }
  if (!strcasecmp(ext, ".gif")) {
    Fl_GIF_Image img(f);
    if (img.fail()) return 1;
    printf("%dx%d header=\"%s\"\n", img.w(), img.h(), img.data()[0]);
    return 0;
  }
  if (!strcasecmp(ext, ".xpm")) {
    Fl_XPM_Image img(f);
    if (img.fail()) return 1;
    printf("%dx%d header=\"%s\"\n", img.w(), img.h(), img.data()[0]);
    return 0;
  }
  if (!strcasecmp(ext, ".xbm")) {
    Fl_XBM_Image img(f);
    if (img.fail()) return 1;
    printf("%dx%d %02x%02x%02x%02x\n", img.w(), img.h(), img.array[0], img.array[1], img.array[2], img.array[3]);
    return 0;
  }
  return 2;
}
