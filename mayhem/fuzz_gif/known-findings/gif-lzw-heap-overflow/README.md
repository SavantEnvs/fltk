# Fl_GIF_Image.cxx:357 heap-buffer-overflow in lzw_decode

Reproducer: `crash-7017f44095a683fcf896c7f7f89510227f8a57e6` (replay: `/mayhem/fuzz_gif-standalone <file>`).

- **Cause:** `Fl_GIF_Image::lzw_decode` writes one byte past the `Width*Height` image buffer allocated in `load_gif_` (`Fl_GIF_Image.cxx:690`): ASan reports a 1-byte WRITE at `Fl_GIF_Image.cxx:357` (`*p++ = *--tp`), 0 bytes after a 1-byte region. We have not traced which row-wrap path (`p`/`YC`/`eol` handling at lines 358-370) lets the pointer escape the buffer; the `YC` "cheap bug fix when excess data" wrap is the suspect.
- **Impact:** heap buffer overflow (write) on a 484-byte attacker-controlled GIF.
- **Fix:** bound the write by the buffer end (`p < Image + Width*Height`) rather than relying on the per-row `eol` reset.
