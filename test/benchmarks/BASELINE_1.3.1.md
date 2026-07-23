# SINT P0 Hot-Path Benchmarks — Baseline v1.3.1

Captured **before** any 1.4.0 optimization, against the unmodified 1.3.1 codebase.

- Machine: macOS (darwin-arm64), Flutter SDK `~/development/flutter` (Dart 3.12.2), `flutter test` (VM, JIT).
- Methodology: `bench_harness.dart` — warmup 2,000 ops, 7 rounds × 20,000 ops, median/p95 µs/op.
- Command: `flutter test test/benchmarks/p0_benchmark_test.dart`
- Verified state at capture: `flutter test` 234/234 pass; `dart analyze` 0 errors / 25 pre-existing issues.

| Benchmark                                  | median µs/op | p95 µs/op | min µs/op | max µs/op |
|--------------------------------------------|-------------:|----------:|----------:|----------:|
| S1. pure notification (RxInt, 1 listener)  |       0.0193 |    0.0679 |    0.0169 |    0.0679 |
| S2. fan-out (0 listeners)                  |       0.0132 |    0.0167 |    0.0109 |    0.0167 |
| S2. fan-out (1 listener)                   |       0.0188 |    0.0215 |    0.0164 |    0.0215 |
| S2. fan-out (10 listeners)                 |       0.0682 |    0.0702 |    0.0665 |    0.0702 |
| S2. fan-out (100 listeners)                |       0.6452 |    0.6470 |    0.6353 |    0.6470 |
| S3. no-listeners (empty path)              |       0.0149 |    0.1336 |    0.0103 |    0.1336 |
| I1. Sint.find (tagged)                     |       0.5555 |    0.6059 |    0.5424 |    0.6059 |
| S4. SintController.update() (1 listener)   |       0.0158 |    0.0754 |    0.0115 |    0.0754 |
