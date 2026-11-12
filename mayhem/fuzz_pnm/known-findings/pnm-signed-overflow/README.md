# Fl_PNM_Image.cxx:139 signed overflow in w()*h()*d()

Reproducers (replay: `/mayhem/fuzz_pnm-standalone <file>`):
- `crash-060f7be6b3e64f36f357258c8e841396a038d463`: `16552 * 346552` overflows (the `w()*h()` product, column 31).
- `crash-3e1eb43bf5d632ec2228366ac1a80ff1ebf90f91`: `965620963 * 3` overflows (the `*d()` product, column 37).

- **Cause:** `new uchar[w() * h() * d()]` with header-controlled dimensions overflows `int`. The guard at :133 does the product in `size_t` against `Fl_Image::max_size()`, which is effectively unlimited, so it never rejects these sizes; the allocation then repeats the product in `int`.
- **Impact:** UB, and a potential heap overflow when the wrapped size is small. When it wraps negative the allocation request becomes 16 EiB: see `pnm-allocation-size-too-big` (OOM-class).
- **Fix:** compute the size in `size_t` once, bail out if it overflows or exceeds the remaining file size, and use it for the allocation.
