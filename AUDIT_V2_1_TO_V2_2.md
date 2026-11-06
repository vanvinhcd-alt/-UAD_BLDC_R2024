# Audit v2.1 -> v2.2

## Evidence retained

1. `SafeCL_MB_SingleBank` v2.1 đạt mạnh ở controlled stress:
   - 10% AUC ~0.911, Target AUC ~0.862, memory ~2.3%.
   - 20% AUC ~0.922, memory ~5.8%.
   - 30% AUC ~0.921, memory ~7.3%.
2. Secondary banks in v2.1 were often fault banks; Bank 2 contamination rose to roughly 49/74/84% at 10/20/30%.
3. Natural candidate before Bank 1 was close to 50:50 normal/fault, so source score, LOBO consistency, density and multi-view consistency alone could not establish normality.
4. `RUN_V22_AMBIGUITY_DIAGNOSTIC` found development separation using two label-free signals:
   - candidate accumulation rate: controlled max 1.875, Natural min 2.286;
   - Mic DeltaBIC: controlled min 8.024, Natural max 6.586.

## Design consequences

- Keep encoder, LOBO and protected routing unchanged.
- Lock BLDC main study to one verified target bank.
- Add safe abstention only after LOBO PASS, before Bank 1 birth.
- Do not interpret Mic clusters as normal/fault; DeltaBIC is an uncertainty signal only.
- Add immutable SeedModel so OperationalModel cannot self-authorize dynamic drift.
- Replace sensor-disagreement local health with seed-vs-operational model drift.

## Runtime-information boundary

Learner may use only scores, latent features, batch counter, candidate IDs/batches and frozen configuration. `TrueLabel`, nominal contamination, domain transition timing, and evaluation labels are audit-only.
