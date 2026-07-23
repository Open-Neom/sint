# SINT Route Matching Benchmarks — Baseline v1.4.0

Captured **before** the 1.5.0 navigation overhaul, against the 1.4.0 codebase
(flat-list + regex-per-route matching, O(segments × routes)).

- Machine: macOS (darwin-arm64), Flutter SDK `~/development/flutter` (Dart 3.12.2), `flutter test` (VM, JIT).
- Methodology: `bench_harness.dart` — warmup 2,000 ops, 7 rounds × 1,000 ops, median/p95 µs/op.
- Command: `flutter test test/benchmarks/route_benchmark_test.dart`
- Setup: N pairs of routes (`/route{i}` literal + `/user{i}/:id` param), matching the LAST registered route (worst case for a flat scan).

| Benchmark                    | median µs/op | p95 µs/op | min µs/op | max µs/op |
|------------------------------|-------------:|----------:|----------:|----------:|
| literal match, last of 10    |       4.4390 |    8.5620 |    4.1330 |    8.5620 |
| param match, last of 10      |       7.3280 |    8.4670 |    6.9210 |    8.4670 |
| miss (unknown), 10           |       4.5190 |    4.7550 |    4.3100 |    4.7550 |
| literal match, last of 100   |      14.0920 |   14.3340 |   13.8650 |   14.3340 |
| param match, last of 100     |      25.7190 |   26.4550 |   25.5310 |   26.4550 |
| miss (unknown), 100          |      31.5970 |   31.8170 |   31.3330 |   31.8170 |
