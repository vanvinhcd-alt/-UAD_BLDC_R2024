# Audit v2.2.2 -> v2.2.3

## Kết luận nguyên nhân

v2.2.2 không thất bại vì compact seed, ambiguity thresholds, LOBO, routing hay dynamic update. Controlled 10–30% đã cải thiện và dynamic memory vẫn sạch. Regression chỉ xuất hiện ở Natural seed 342/442 vì ambiguity gate bị coupling với calibrated-seed readiness.

Trong v2.2.2, `scu_ambiguity_risk()` chỉ chạy khi LOBO verifier trả `Pass`. Compact 12-sample seed khiến hai run Natural phải chờ thêm 1–2 batch trước khi fit/cal đủ. Trong thời gian đó candidate geometry thay đổi và Mic-DeltaBIC vượt khỏi vùng low-confidence.

## Bằng chứng tái lập

Ở v2.2.0, cùng protocol/thresholds:
- seed 342, batch 7: R_acc=2.428571, Mic-DeltaBIC=6.570919 -> abstain.
- seed 442, batch 7: R_acc=2.285714, Mic-DeltaBIC=6.418919 -> abstain.

Ở v2.2.2:
- seed 342: batch 7/8 `InsufficientCalibratedCore`; đến batch 9 mới Pass, Mic-DeltaBIC=18.817902 -> commit, final memory contamination=33.33%.
- seed 442: batch 7 `InsufficientCalibratedCore`; đến batch 8 mới Pass, Mic-DeltaBIC=17.558963 -> commit, final memory contamination=14.29%.

Tức cùng risk signature đã tồn tại trước khi bank-quality verifier đủ điều kiện tạo seed. Đây là ordering/coupling bug.

## Controlled false-abstention audit

Trên v2.2.2 5-seed development, maximum observed candidate accumulation rate trước commit ở controlled 0–30% là 1.75 < 2.08. Vì runtime gate dùng AND condition với Mic-DeltaBIC < 7.30, việc screen sớm không làm controlled runs vượt gate chỉ do thay đổi ordering.

## Sửa đổi

v2.2.3 gọi `scu_ambiguity_risk()` trên mọi grown+ready candidate trước LOBO. Nếu high ambiguity: lock bank birth + clear candidate + protected-source fallback. Nếu không: tiếp tục LOBO/compact seed y nguyên v2.2.2.

Không thay threshold. Không thay compact seed. Không thay readiness gate.

## Tính độc lập chức năng

- Ambiguity screening trả lời: `Có an toàn để tiếp tục học normal bank hay không?`
- LOBO/calibrated seed trả lời: `Candidate có đủ chất lượng để tạo bank hay chưa?`

v2.2.3 tách hai câu hỏi này thay vì bắt câu hỏi safety phải chờ câu hỏi bank-quality.
