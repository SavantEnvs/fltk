# Fl_PNM_Image.cxx:139 new uchar[w()*h()*d()] with a wrapped size (OOM-class)

Reproducer: `crash-be4fbbdb77b098fec720b2d0cc335e68c6a79737` (replay: `/mayhem/fuzz_pnm-standalone <file>`).

- **Cause:** the guard at :133 computes `(size_t)w() * h() * d()` and compares it with `Fl_Image::max_size()`, which is effectively unlimited by default; the allocation at :139 then repeats the product in `int`. When that wraps to a negative value, `new uchar[n]` receives `0xffffffffffffffff` bytes.
- **Impact:** ASan `allocation-size-too-big` (CWE-789, OOM-class) on a 57-byte file. It is the allocation-side symptom of `pnm-signed-overflow` (same line, same expression).
- **Fix:** compute the size once in `size_t`, reject it when it exceeds a sane limit or the remaining file size, and use that value for `new`.
