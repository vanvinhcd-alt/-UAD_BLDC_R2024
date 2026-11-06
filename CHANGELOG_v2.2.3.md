# CHANGELOG v2.2.3

1. Added `cfg.ambiguityEarlyScreenEnabled = true`.
2. Moved Rapid-Unresolved-Novelty screening before LOBO/calibrated-seed verification.
3. Kept ambiguity thresholds fixed at 2.08 / 7.30.
4. Kept compact temporally-diverse 12-sample seed unchanged.
5. Added self-test that forces LOBO insufficiency and requires early SafeAbstain to occur first.
6. Output renamed to `results_safecl_bldc_v223` and `SAFECL_BLDC_v223_Results.*`.
7. Confirmation output renamed to `results_safecl_bldc_v223_CONFIRMATION`.
8. Added development audits documenting Natural ordering regression and controlled accumulation-rate margin.
