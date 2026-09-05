# SINT benchmark workloads

These tests measure **means of synchronous operation batches**, in microseconds per operation. Median, median absolute deviation (MAD), minimum, maximum and every sample in execution order are retained. There is deliberately no "operation p95": seven averaged batches cannot measure that quantity.

Every timed scenario checks delivered notifications, identity, final values, decoded routes/parameters, lifecycle counts or checksums outside the timer. Timed callback bodies and result checksums add work; comparisons must use the same harness, never historical empty-listener numbers.

## Run

From the package root:

    flutter pub get
    dart run tool/benchmark_runner.dart --full --output=build/benchmarks/candidate.json

The runner uses one Flutter-test worker, no coverage and the checked-out package. It records Flutter/engine/Dart revisions, host identifier, OS, CPU count, Git revision/dirty state, harness content hashes, flags, calibration parameters and ordered samples. The JSON is valid only when all tests pass and all expected scenario records exist. Keep the adjacent .log file.

Default smoke budget: at least 2000 warmup operations (specific expensive workloads use a smaller count), at least 15 ms warmup, calibrated batches targeting 5 ms, seven measured rounds. With --full: at least 200 ms warmup, 40 ms target per batch, 21 rounds. Calibration may double iteration counts; those operations are included in correctness accounting but not samples. A safety cap prevents unbounded batch sizes. Time-based warmup reduces initialization noise; it does not prove JIT stabilization. Inspect sample order and repeat runs to identify drift.

These are Flutter-test **VM JIT** measurements, not release/AOT, UI frame timings or per-event asynchronous latency.

## Workload matrix

- Rx addListener and native ValueNotifier synchronous delivery with 0/1/10/100 listeners, identical integer updates and nonempty counter callbacks.
- Controller update, repeated equal Rx assignment, typed/tagged hot DI.
- Route tables with 10/100/1000 registered entries plus root: unique first segments and shared /api prefix, last hit and miss within the same shape; URI/query/path parameters are verified. Cold page construction + index + first lookup is separate. Parser miss does not include unknown-route navigation.
- Put/find/delete with synchronous lifecycle counters; genuine lazy dependency chains of depths 1/10 with fenix disposal; hot lookup among 1/10 independent tags, correctly labelled as registry size.
- Equal/changed replacement of lists of 10/1000 elements, checking exact notification counts.
- Translation lookup and two parameter substitutions with a consumed/verified result.
- Route disposal with 1000/4000/16000 linked controllers, registration outside the timer, exact close/removal checks and disposal time divided by dependency count.
- Rx.listen versus native asynchronous broadcast Streams, 1000/30000 events, identical delivery/checksum assertions. Time includes enqueue through final callback, excluding subscription setup/cleanup; it is not pure enqueue time.

The DI lifecycle fixture intentionally overrides initialization without scheduling onReady; it measures synchronous lifecycle. UI frame scheduling belongs in the separate Flutter application.

Destructive route-disposal and asynchronous-delivery scenarios use bounded, prepared batches: one warmup batch plus seven rounds by default, three warmups plus 21 rounds with --full. Each batch prepares a fresh fixture, times only disposal or complete event delivery, verifies results and cleans up. They intentionally do not apply adaptive iteration doubling; setup cost and asynchronous allocation make an unbounded calibration inappropriate. Their configuration is recorded distinctly in JSON.

## Controlled before/after comparison

Use two isolated checkouts on the **same idle machine**, the same exact Flutter SDK, build mode and benchmark source files. Resolve dependencies before measurement; do not run coverage, compilers or another benchmark concurrently. Copy the new harness/workload files into the baseline checkout so both run the same work. If a baseline fails a correctness assertion, no performance comparison for that scenario is valid.

Run baseline/candidate in alternating order (ABBA), retain each report and inspect repeatability. Do not treat results from separate hosted CI workers as paired historical samples.

    dart run tool/compare_benchmarks.dart before.json after.json --budget=0.05
    dart run tool/compare_benchmarks.dart before.json after.json --budget=0.05 --fail-on-regression

The 5% above is an **example of a project-selected budget**, not a universal threshold. Budget selection is required. The conservative comparison envelope is the larger of the user budget and noiseMultiplier × (MAD_before + MAD_after) / median_before (default multiplier 3, adjustable). This is a noise heuristic, not a confidence interval, and does not correct systematic drift. Results below the envelope are labelled within_budget_or_noise, not "equivalent". The tool refuses incomplete reports, different environments/harnesses, changed scenario sets or incompatible workload configuration.

CI separates correctness/coverage from full serial performance, saves raw JSON/logs and enforces correctness in every workload. An automatic timing gate across unrelated hosted runners is not configured: no calibrated historical baseline exists. The explicit comparator supports a gate for paired measurements on controlled hosts.

## Flutter frame measurements

See [the Flutter performance application](../../performance/README.md) for a runnable macOS profile/release application. It measures actual frame build/raster samples, rebuild counts and process RSS with an equivalent Obx/ValueListenableBuilder workload, in ABBA order.

The BASELINE_1.3.1.md and BASELINE_1.4.0.md files are historical records from a different harness; do not compare their numbers directly with schema-2 measurements. Workers, widget lifecycle churn and competitors such as BLoC remain additional workloads; no BLoC speedup claim is implied by this suite.
