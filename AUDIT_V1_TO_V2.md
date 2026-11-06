# Audit v1.1–v1.4 và quyết định tái thiết kế v2.0

## Phát hiện chính

1. v1.1 chứng minh representation và candidate adaptation có thể đạt target AUC rất cao, nhưng một global adaptive bank bị self-contamination ở stress cao.
2. v1.2 protected routing có ích, nhưng global watchdog phản ứng sau khi contamination đã vào bank.
3. v1.3/v1.4 đặt quá nhiều protection trên đường adaptation, làm candidate không commit và SafeCL gần Static.
4. Source score của normal target và anomaly candidate chồng lấn; thêm threshold source-score không giải quyết triệt để.
5. `maxAdaptiveMemory` từng ảnh hưởng cả SafeCL và baseline, làm so sánh phiên bản không hoàn toàn cùng capacity.
6. Protocol cũ audit theo SampleID; v2 nâng thành GroupID hard audit.

## Quyết định v2.0

- bỏ global adaptive bank;
- bỏ global watchdog;
- không dùng probation/dormant state machine làm cơ chế chính;
- dùng independent adaptive banks;
- immutable seed core + bounded dynamic memory;
- symmetric 2-of-3 multi-view safety;
- local health / local rollback / local suspension;
- baseline capacity cố định;
- GroupID-disjoint hard-stop;
- 5-seed development -> freeze -> 20-seed confirmation.
