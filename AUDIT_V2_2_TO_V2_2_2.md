# Audit v2.2.0 -> v2.2.2

## Kết luận audit

v2.2.0 đã giải quyết kiến trúc chính: clean/controlled mean performance đạt, Natural SafeAbstain 5/5, controlled false abstention 0/30, và dynamic memory contamination = 0% ở controlled 0–30%. Hai development failures còn lại đến từ seed-level robustness.

Vì vậy v2.2.2 chỉ sửa immutable seed construction.

## Vì sao không chọn 12 mẫu từ toàn reservoir

Một rule temporal-diversity trực tiếp trên toàn candidate reservoir có thể kéo một sample low-quality chỉ để phủ thêm batch. Audit seed 42 ở 10% cho thấy điều này có thể chọn anomaly ở một batch mới. Do đó v2.2.2 giữ nguyên quality pool của v2.2 trước khi tối ưu temporal diversity.

## Rule được chọn

1. LOBO pass / quality calculation: giữ nguyên.
2. Verified quality pool: top 85% như v2.2.0.
3. Seed = 12 samples trong pool:
   - best-quality representative của các batch khác nhau trước;
   - fill còn lại theo quality.

## Hậu kiểm 5-seed v2.2.0

- 10%: seed anomalies 2 -> 0 tổng cộng trên 5 seed.
- 20%: seed anomalies 5 -> 2.
- 30%: seed anomalies 6 -> 4.
- Clean: không thay đổi seed contamination.
- Max compact-seed contamination: 0% (10%), 8.33% (20%), 8.33% (30%).

Nếu dynamic memory giữ 0% contamination như run gốc, projected max final memory contamination là 0%, 6.67%, 6.67% ở 10/20/30%.

Các con số này là retrospective audit có nhãn EVAL_ONLY; chúng chỉ biện minh cho việc chạy v2.2.2, không thay thế FULL result.
