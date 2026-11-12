#!/usr/bin/env bash
#
# mayhem/test.sh — known-answer oracle for the FLTK image decoders (probe built by mayhem/build.sh).
# exit 0 = pass. EDIT per repo. PATCH-grade oracle: after an agent patches the source, the grader
# rebuilds (build.sh) then runs this. DELETE this file if the repo has no meaningful tests.
#
# IMPORTANT:
#  * Must assert BEHAVIOR/OUTPUT, not just exit status. The oracle has to check asserted values /
#    golden-output diffs / known-answer results — so a PATCH that "fixes" a bug by making the program
#    exit(0) (or any no-op) FAILS here. Running inputs and checking only "exit 0 / didn't crash" is
#    NOT a functional test (it's trivially reward-hackable) — use the project's real assertion suite.
#  * Do NOT build here — mayhem/build.sh already compiled the test suite (with the project's normal
#    flags). This script only RUNS the pre-built tests and reports counts. If the test runner is
#    missing, that's a build.sh bug — fail loudly rather than silently rebuilding.
#  * REQUIRED OUTPUT — a CTRF (https://ctrf.io) summary so Mayhem/the PATCH grader reads the counts:
#      - writes a CTRF JSON report to ${CTRF_REPORT:-$SRC/ctrf-report.json}, and
#      - prints a one-line `CTRF {...}` marker to stdout (same JSON, compact).
#    Only `results.summary` (with tests/passed/failed/pending/skipped/other) is required.
#    Use the emit_ctrf helper below; it computes tests = passed+failed+skipped and sets the exit
#    code (0 iff failed==0). Map your framework's output to passed/failed/skipped.
set -uo pipefail
[ -n "${SOURCE_DATE_EPOCH:-}" ] || unset SOURCE_DATE_EPOCH
: "${MAYHEM_JOBS:=$(nproc)}"   # build parallelism; env-overridable, falls back to nproc (use -j"$MAYHEM_JOBS")
cd "$SRC"

# emit_ctrf <tool> <passed> <failed> [skipped] [pending] [other]
# Writes a CTRF report (file + stdout `CTRF {...}` marker) and returns non-zero iff failed>0.
emit_ctrf() {
  local tool="$1" passed="$2" failed="$3" skipped="${4:-0}" pending="${5:-0}" other="${6:-0}"
  local tests=$(( passed + failed + skipped + pending + other ))
  cat > "${CTRF_REPORT:-$SRC/ctrf-report.json}" <<JSON
{
  "results": {
    "tool": { "name": "$tool" },
    "summary": {
      "tests": $tests,
      "passed": $passed,
      "failed": $failed,
      "pending": $pending,
      "skipped": $skipped,
      "other": $other
    }
  }
}
JSON
  printf 'CTRF {"results":{"tool":{"name":"%s"},"summary":{"tests":%d,"passed":%d,"failed":%d,"pending":%d,"skipped":%d,"other":%d}}}\n' \
    "$tool" "$tests" "$passed" "$failed" "$pending" "$skipped" "$other"
  [ "$failed" -eq 0 ]
}

# fltk_kat (built by mayhem/build.sh with the project's normal flags, dynamically linked) decodes a file with
# the real FLTK loader chosen by extension and prints geometry + pixel bytes. Each fixture below is checked
# against its exact known output; a loader that is stubbed out, returns early or decodes wrongly fails.
KAT="$SRC/mayhem/build-oracle/fltk_kat"
passed=0 failed=0

if [ ! -x "$KAT" ]; then
  echo "FAIL: $KAT missing (mayhem/build.sh should have built it)" >&2
  emit_ctrf "fltk-kat" 0 1 0
  exit 1
fi
if command -v file >/dev/null 2>&1 && ! file -L "$KAT" | grep -q 'dynamically linked'; then
  echo "FAIL: $KAT is not dynamically linked" >&2
  emit_ctrf "fltk-kat" 0 1 0
  exit 1
fi

check() {  # check <fixture> <expected stdout>
  local f="$1" want="$2" got
  got="$("$KAT" "$SRC/$f" 2>/dev/null)"
  if [ "$got" = "$want" ]; then
    passed=$((passed + 1))
  else
    failed=$((failed + 1))
    echo "FAIL: $f: got '$got', want '$want'" >&2
  fi
}

check mayhem/fuzz_pnm/testsuite/p3.ppm  '2x2x3 ff000000ff000000ffffff00 1275'
check mayhem/fuzz_pnm/testsuite/p6.ppm  '3x2x3 ff000000ff000000ff0a141e 1215'
check mayhem/fuzz_pnm/testsuite/p5.pgm  '4x2x1 00326496c8dcf0ff 1215'
check mayhem/fuzz_pnm/testsuite/p1.pbm  '6x4x1 00ff00ff00ffff00ff00ff00 3060'
check mayhem/fuzz_pnm/testsuite/p4.pbm  '9x3x1 00ff00ff00ff00ff00ff00ff 2295'
check mayhem/fuzz_bmp/testsuite/bmp24.bmp '8x6x3 005e002d5e3c5a5e78875eb4 13044'
check mayhem/fuzz_bmp/testsuite/bmp8.bmp  '7x4x3 03fc1504fb1c05fa2306f92a 8022'
check mayhem/fuzz_bmp/testsuite/bmp1.bmp  '16x6x3 000000000000ffffff000000 30600'
check test/images/tiny.png              '33x12x3 2255aa2255aa2255aa2255aa 188224'
check mayhem/fuzz_png/testsuite/Fl_Value_Input.png '140x50x2 8fff8fff8fff8fff8fff8fff 3282753'
check fltk-options/icons/fltk-options-32.gif '32x32 header="32 32 -22 1"'
check mayhem/fuzz_anim_gif/testsuite/fltk_animated2.gif '229x70 frames=8'
check fltk.xpm                          '229x70 header="229 70 152 2"'
check src/up.xbm                        '16x16 00007800'
check test/pixmaps/checker.svg          '400x400'
check test/sudoku.ico                   '32x32x3 000000000000000000000000 322830'
check documentation/images/fl_color_chooser.jpg '215x200x3 cae6dacde4dcd2e1dcd8dede 21974270'

# A corrupt file must be rejected, not decoded.
printf 'BM\x00\x00' > "${TMPDIR:-/tmp}/kat_bad.bmp"
if "$KAT" "${TMPDIR:-/tmp}/kat_bad.bmp" >/dev/null 2>&1; then
  failed=$((failed + 1)); echo "FAIL: truncated BMP was accepted" >&2
else
  passed=$((passed + 1))
fi
rm -f "${TMPDIR:-/tmp}/kat_bad.bmp"

emit_ctrf "fltk-kat" "$passed" "$failed" 0
