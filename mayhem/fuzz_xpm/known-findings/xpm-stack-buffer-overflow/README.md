# Fl_XPM_Image.cxx:69 stack-buffer-overflow in the line buffer

Reproducer: `crash-099c609e770e3020b33cfa2e836ddfe1dffd5f7a` (replay: `/mayhem/fuzz_xpm-standalone <file>`).

- **Cause:** the loop `while (*q != '"' && myp < buffer+MAXSIZE)` bounds `myp` but advances `q` (including `*++q` after a backslash) without bounding it, so an over-long or backslash-terminated line reads past the `buffer[MAXSIZE+20]` stack array.
- **Impact:** stack out-of-bounds read of attacker-controlled XPM files (ASan abort).
- **Fix:** bound `q` by `buffer+MAXSIZE` too, and check for NUL after the backslash.
