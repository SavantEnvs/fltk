# jpeg/jdmarker.c:508 DHT table index used before it is range-checked

Reproducer: `crash-b8e721a629bc7d529257c50780ff713bbac38a57` (replay: `/mayhem/fuzz_jpeg-standalone <file>`).

- **Cause:** in `get_dht` the table slot address `&cinfo->ac_huff_tbl_ptrs[index]` / `&cinfo->dc_huff_tbl_ptrs[index]` (lines 506-508) is formed from the file-controlled index byte *before* the `index < 0 || index >= NUM_HUFF_TBLS` check at line 511 (UBSan array-bounds: index 12 and 33 of a `JHUFF_TBL *[4]`).
- **Impact:** low. Only the address is computed out of range; the check then raises `JERR_DHT_INDEX` before it is dereferenced, so this is UB in form, not an observed memory error. It aborts under halting UBSan.
- **Fix:** move the range check above the address computation (as in upstream IJG libjpeg).
