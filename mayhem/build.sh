#!/usr/bin/env bash
#
# mayhem/build.sh — build this repo's fuzz harness(es). EDIT per repo.
#
# Runs inside the commit image (mayhem/Dockerfile) as `mayhem` in /mayhem. The base image
# (ghcr.io/savantenvs/base) already exports the build contract — use these, don't redefine:
#   CC, CXX             stock clang / clang++
#   LIB_FUZZING_ENGINE  -fsanitize=fuzzer   (link into each harness that has a LLVMFuzzer entry)
#   SANITIZER_FLAGS     -fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer
#                       (ASan + UBSan, both set to HALT — so Mayhem catches memory AND UB defects)
#   DEBUG_FLAGS         -g -gdwarf-3   (DWARF debug info — always on for fuzz/standalone builds,
#                       independent of the sanitizer off-switch; DWARF version must be < 4)
#   RUST_DEBUG_FLAGS    -C debuginfo=2 -C force-frame-pointers=yes -C llvm-args=-gdwarf-3
#                       (thread through RUSTFLAGS on every cargo-fuzz build)
#   GO_DEBUG_FLAGS      -gcflags=all=-N -l
#                       (thread through go build / go-fuzz-build so the linked ELF keeps symbols)
#   SRC                 /mayhem (the repo source)
#
# Contract: build EVERYTHING here — one runnable binary per fuzz harness, AND the project's test
# suite (so mayhem/test.sh only has to RUN it, never compile). Keep it ADDITIVE (build upstream as
# upstream documents; don't edit upstream files). IMPORTANT: build the PROJECT ITSELF with
# $SANITIZER_FLAGS and $DEBUG_FLAGS (not just the harness) so the fuzzed code is instrumented
# AND carries DWARF < 4 symbols — otherwise ASan/UBSan only see the harness, not the library
# you're trying to find bugs in, and backtraces won't resolve project source lines. Build the TEST
# suite with the project's NORMAL flags (a clean, independent build) so test.sh stays an honest
# functional oracle and won't false-fail on benign UB. Leave the test binary/runner where test.sh
# expects it.
set -euo pipefail

# clang rejects SOURCE_DATE_EPOCH='' (empty) — it must be unset or a valid integer.
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH

# Build knobs come from the ENVIRONMENT (overridable), with sane defaults — no if-statements,
# just parameter-expansion fallbacks. Default sanitizers are the base's ASan+UBSan (halting); override
# per build via the Dockerfile's `--build-arg SANITIZER_FLAGS="..."`.
# NB: SANITIZER_FLAGS uses `=` (no colon) on purpose — `=` only fills when the var is UNSET, so an
# explicit EMPTY value (`--build-arg SANITIZER_FLAGS=`) is honored and builds with NO sanitizers
# (useful when you want the program's natural crash / full backtrace, not an ASan report). The other
# knobs use `:=` (default on empty too). MAYHEM_JOBS sets build parallelism (falls back to nproc).
: "${SANITIZER_FLAGS=-fsanitize=address,undefined -fno-sanitize-recover=all -fno-omit-frame-pointer}"
# DEBUG_FLAGS carries DWARF debug info INDEPENDENTLY of the sanitizer off-switch (so an empty
# SANITIZER_FLAGS still yields DWARF symbols). DWARF MUST be < 4 (Mayhem triage can't read >=4); clang-19's
# plain `-g` emits DWARF-5, so `-gdwarf-3` is explicit. Apply $DEBUG_FLAGS to the fuzz/harness/standalone
# builds (NOT the test/oracle build). Rust/Go carry the same intent via their language flags below.
: "${DEBUG_FLAGS:=-g -gdwarf-3}"
: "${RUST_DEBUG_FLAGS:=-C debuginfo=2 -C force-frame-pointers=yes -C llvm-args=-gdwarf-3}"
: "${GO_DEBUG_FLAGS:=-gcflags=all=-N -l}"
: "${CC:=clang}" ; : "${CXX:=clang++}" ; : "${LIB_FUZZING_ENGINE:=-fsanitize=fuzzer}"
: "${MAYHEM_JOBS:=$(nproc)}"
# COVERAGE_FLAGS: empty by default → no effect on the normal oracle build. Set it via the Dockerfile's
# `--build-arg COVERAGE_FLAGS="-fprofile-instr-generate -fcoverage-mapping"` to instrument the TEST
# build for source-coverage measurement (how much of the project the test suite actually exercises —
# a quality signal for the oracle; complements the anti-reward-hack sabotage check). APPEND it to the
# test build's compile+link flags in step 3 (NOT the fuzz build); after `test.sh` runs, merge with
# `llvm-profdata` and report with `llvm-cov`. Empty value is honored (`=`, not `:=`).
: "${COVERAGE_FLAGS=}"
export SANITIZER_FLAGS DEBUG_FLAGS RUST_DEBUG_FLAGS GO_DEBUG_FLAGS CC CXX LIB_FUZZING_ENGINE MAYHEM_JOBS COVERAGE_FLAGS

cd "$SRC"

# FLTK is built as static libs with its BUNDLED zlib/libpng/libjpeg so the decoders being fuzzed are
# instrumented too (the system libs would be uninstrumented). X11 is only linked, never opened: the
# loaders need no display. Build trees live under mayhem/ (ignored by mayhem/.gitignore) so the
# `git clean -ffdX` the patch grader runs removes them.
CMAKE_COMMON=(-G Ninja -DCMAKE_BUILD_TYPE=None -DCMAKE_C_COMPILER="$CC" -DCMAKE_CXX_COMPILER="$CXX"
  -DFLTK_BUILD_SHARED_LIBS=OFF -DFLTK_BACKEND_WAYLAND=OFF -DFLTK_BUILD_GL=OFF -DFLTK_BUILD_FLUID=OFF
  -DFLTK_BUILD_FLTK_OPTIONS=OFF -DFLTK_BUILD_TEST=OFF -DFLTK_BUILD_EXAMPLES=OFF
  -DFLTK_USE_SYSTEM_LIBJPEG=OFF -DFLTK_USE_SYSTEM_LIBPNG=OFF -DFLTK_USE_SYSTEM_ZLIB=OFF
  -DFLTK_OPTION_SVG=ON -DFLTK_USE_PANGO=OFF -DFLTK_OPTION_CAIRO_WINDOW=OFF)

# 1) Sanitized + SanCov-instrumented library (the fuzzed code), DWARF 3.
#    -fsanitize=fuzzer-no-link goes on unconditionally: without it the library has no coverage
#    instrumentation and the targets record 0 edges in Mayhem.
FUZZ_FLAGS="-O1 $SANITIZER_FLAGS -fsanitize=fuzzer-no-link $DEBUG_FLAGS"
#    -fno-sanitize=shift-base on the C sources only (bundled libjpeg/libpng/zlib): libjpeg's Huffman
#    bit-buffer refill (jdhuff.c) deliberately shifts bits off a signed long, which halting UBSan aborts
#    on for every valid JPEG. ASan and every other UBSan check stay on, and FLTK's own C++ is untouched.
#    Fresh trees on every run: re-configuring FLTK over a populated CMake cache fails on the cached
#    OPENGL_INCLUDE_DIR-NOTFOUND of the (disabled) fltk_gl target, so the build is not re-runnable otherwise.
rm -rf mayhem/build-fuzz mayhem/build-oracle
cmake -S . -B mayhem/build-fuzz "${CMAKE_COMMON[@]}" -DCMAKE_C_FLAGS="$FUZZ_FLAGS -fno-sanitize=shift-base" -DCMAKE_CXX_FLAGS="$FUZZ_FLAGS"
cmake --build mayhem/build-fuzz -j"$MAYHEM_JOBS"

# 2) Harnesses: each links twice (libFuzzer engine, and the run-once standalone reproducer).
BD="$SRC/mayhem/build-fuzz"
INC=(-I"$SRC" -I"$BD")
LIBS=("$BD/lib/libfltk_images.a" "$BD/lib/libfltk.a" "$BD/lib/libfltk_png.a" "$BD/lib/libfltk_jpeg.a" "$BD/lib/libfltk_z.a"
      -lXft -lXrender -lXcursor -lXfixes -lXinerama -lXext -lX11 -lfontconfig -lfreetype -ldl -lm -lpthread)
HFLAGS="-O1 $SANITIZER_FLAGS $DEBUG_FLAGS -std=c++17"
$CXX $SANITIZER_FLAGS $DEBUG_FLAGS -c "$SRC/mayhem/lsan_off.cc" -o /tmp/lsan_off.o
$CC $SANITIZER_FLAGS $DEBUG_FLAGS -c "$STANDALONE_FUZZ_MAIN" -o /tmp/standalone_main.o

TARGETS="fuzz_gif fuzz_anim_gif fuzz_bmp fuzz_png fuzz_jpeg fuzz_svg fuzz_ico fuzz_pnm fuzz_xpm fuzz_xbm"
for t in $TARGETS; do
  $CXX $HFLAGS "${INC[@]}" $LIB_FUZZING_ENGINE "$SRC/mayhem/$t.cxx" /tmp/lsan_off.o "${LIBS[@]}" -o "$SRC/$t"
  $CXX $HFLAGS "${INC[@]}" "$SRC/mayhem/$t.cxx" /tmp/standalone_main.o /tmp/lsan_off.o "${LIBS[@]}" -o "$SRC/$t-standalone"
done

# 3) Oracle: the project's NORMAL flags (no sanitizers, no -gdwarf-3), a separate tree, plus a small
#    known-answer probe (dynamically linked, so the sabotage shim neuters it) that test.sh runs.
cmake -S . -B mayhem/build-oracle "${CMAKE_COMMON[@]}" -DCMAKE_C_FLAGS="-O2 $COVERAGE_FLAGS" -DCMAKE_CXX_FLAGS="-O2 $COVERAGE_FLAGS"
cmake --build mayhem/build-oracle -j"$MAYHEM_JOBS"
OD="$SRC/mayhem/build-oracle"
$CXX -O2 -std=c++17 $COVERAGE_FLAGS -I"$SRC" -I"$OD" "$SRC/mayhem/kat.cxx" \
  "$OD/lib/libfltk_images.a" "$OD/lib/libfltk.a" "$OD/lib/libfltk_png.a" "$OD/lib/libfltk_jpeg.a" "$OD/lib/libfltk_z.a" \
  -lXft -lXrender -lXcursor -lXfixes -lXinerama -lXext -lX11 -lfontconfig -lfreetype -ldl -lm -lpthread \
  -o "$SRC/mayhem/build-oracle/fltk_kat"
