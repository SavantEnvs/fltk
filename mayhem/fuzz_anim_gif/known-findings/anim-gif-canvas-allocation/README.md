# Fl_Anim_GIF_Image.cxx:310 and :379 canvas-sized allocations (OOM-class) and the :310 int overflow

Reproducers: `crash-f5c528e35cb971c9a164c1471b68a0cd7cbb5921` (replay: `/mayhem/fuzz_anim_gif <file>`, OOM) and `crash-dec11c6fa43004edd0820811bf79c0f4632b1d8e` (replay: `/mayhem/fuzz_anim_gif-standalone <file>`, overflow).

The replay must use the libFuzzer binary (2 GiB RSS limit); `/mayhem/fuzz_anim_gif-standalone` has no limit and finishes normally.

One root cause, two allocation sites and an overflow in the size computation: the canvas size comes straight from the 16-bit logical-screen width and height in the GIF header, and `Fl_Anim_GIF_Image::FrameInfo::on_frame_data` allocates buffers of `canvas_w * canvas_h * 4` bytes from it.

- **`:310`** (Mayhem run 3, defect #3607984, Memory Allocation with Excessive Size Value): on the first frame, `offscreen = new uchar[canvas_w * canvas_h * 4]` (followed by a `memset` of the same size). The reproducer declares `65535 x 3329`, about 872 MB, and replaying it with the libFuzzer binary fails here with `out-of-memory (used: 2192Mb; limit: 2048Mb)`.
- **`:379`** (Mayhem runs 2 and 5, run 5 defect #3607115): with `optimize_mem` off, every frame allocates and copies another `canvas_w * canvas_h * 4` buffer (`:379-380`) on top of the offscreen canvas, so a file with a few frames needs several GB. This reproducer fails at `:310` first, so it does not exercise `:379`; I have no separate input for that site.
- **`:310:36`** (Mayhem run 4, defect #3608688, Integer Overflow or Wraparound): the size expression `canvas_w * canvas_h * 4` is evaluated in `int`, so a canvas such as `65440 x 63391` overflows it (UBSan: `signed integer overflow: 65440 * 63391 cannot be represented in type 'int'`). The reproducer is an 885-byte file that declares exactly that and aborts on the multiplication before the allocation. Without UBSan the wrapped `int` is converted to `size_t` for `new[]` and the `memset`, so the allocation size is wrong (a huge request when it wraps negative); I did not trace further than the multiplication.
- **Impact:** the allocation sites are memory amplification rather than a memory-safety bug (libFuzzer: `out-of-memory`, CWE-789, OOM-class); the overflow is signed-integer UB. Without an RSS limit a 1169-byte file only succeeds on a machine with enough memory.
- **Fix:** compute the size in `size_t`, cap the canvas size (or the total decoded bytes) and fail the load when it would exceed it; share the offscreen buffer instead of copying it per frame.
