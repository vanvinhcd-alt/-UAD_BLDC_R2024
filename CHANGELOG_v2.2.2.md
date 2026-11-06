# CHANGELOG v2.2.2

## Giữ nguyên từ v2.2.0

Encoder, protocol, LOBO verification, ambiguity thresholds 2.08/7.30, one-target-bank BLDC policy, protected routing, SeedGuard, seed-referenced local health, baselines và readiness gates.

## Thay đổi

1. Thêm `cfg.safeSeedTargetN = 12`.
2. Thêm `scu_select_compact_diverse_seed.m`.
3. `scu_verify_candidate_lobo.m` vẫn tạo verified quality pool như v2.2.0, sau đó rút đúng 12 sample bằng temporal-diversity-first / quality-second selection.
4. Không kéo sample ngoài verified quality pool vào seed.
5. Self-test bổ sung invariant: target seed size và maximal temporal batch coverage.
6. Output đổi sang `results_safecl_bldc_v222` và `SAFECL_BLDC_v222_Results.*`.
7. Confirmation đổi sang `results_safecl_bldc_v222_CONFIRMATION`.

## Không thay đổi

Không thay các threshold để tối ưu trên kết quả evaluation. TrueLabel chỉ được dùng trong `development_audit` để hậu kiểm counterfactual, không dùng runtime.
