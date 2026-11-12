# Fl_GIF_Image.cxx:670 shift exponent too large (animated GIF path)

Reproducer: `crash-dd92d402c78151a2ee71bc9dbf9831768a7284bb` (replay: `/mayhem/fuzz_anim_gif-standalone <file>`).

- **Cause:** same line as the fuzz_gif finding: `1 << BitsPerPixel` with a file-controlled `CodeSize - 1` of 111 in this input; `Fl_Anim_GIF_Image` decodes each frame through the same loader.
- **Impact:** undefined behaviour on attacker-controlled GIF headers.
- **Fix:** bound `CodeSize` (max 12) before shifting.
