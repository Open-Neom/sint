# Flutter frame workload

A small macOS application compares **Obx** and **ValueListenableBuilder** on the same widget tree and integer updates. It runs ABBA order, warmup frames before each run, then checks final state, exact rebuild count and captured frame count. Frame build/raster samples are retained individually, so their p95 is a frame percentile rather than a percentile of averaged operation batches.

    cd performance
    flutter pub get
    flutter run -d macos --profile \
      --dart-define=SINT_BENCH_AUTORUN=true \
      --dart-define=SINT_BENCH_OUTPUT=/absolute/path/profile.json \
      --dart-define=SINT_BENCH_REVISION=your-commit-or-dirty-checkout-label

Use --release to repeat in release mode. Keep profile and release results separate. On completion autorun writes SINT_FRAME_BENCH_JSON and SINT_FRAME_BENCH_DONE to stdout and exits with 0 for a valid measurement, 1 for invalid counts, missing frames or failures. An output path is optional; without it the complete JSON is printed. Run without the autorun define for an interactive application.

The macOS runner keeps its application sandbox. A file path outside its container may be inaccessible: the error is included in outputFileError and the complete report is still printed to stdout. Omit SINT_BENCH_OUTPUT and capture stdout to save a report anywhere accessible to your shell.

Configuration defines:

- SINT_BENCH_FRAMES: measured frames per run, default 180.
- SINT_BENCH_WARMUP: warmup frames per run, default 60.
- SINT_BENCH_LISTENERS: independently rebuilding widgets, default 100.
- SINT_BENCH_UPDATES: state updates before each frame, default 10.
- SINT_BENCH_REVISION: checked-out revision/dirty-worktree label.
- SINT_BENCH_OUTPUT: optional absolute JSON output file.
- SINT_BENCH_AUTORUN: run automatically and exit.

Keep the application visible and the host idle. Use the same display/refresh rate, power conditions, SDK, mode, defines and hardware for a comparison. Record the exact flutter --version --machine output alongside the artifact; the app reports its Dart SDK and OS. Default rendering may differ by SDK/platform, so verify the renderer separately when comparing environments. Debug runs are always marked invalid for performance reporting.

Memory fields are **whole-process resident memory (RSS)** and include Flutter engine, raster caches, assets and JIT/AOT runtime. RSS deltas alone do not establish a Dart heap leak or allocation count. Use a heap/allocation profile if a memory regression is suspected. This application does not force garbage collection or claim allocation-free notification.

Frame timing callbacks arrive after rasterization. The workload records their vsync timestamps and filters to the measured frame interval; it waits for final timings before validating the count. A missing timing fails the measurement instead of silently publishing an incomplete percentile.

The project includes a macOS runner. Other platforms need a platform runner generated with the Flutter SDK used for that experiment and their own validation; measurements are not portable between platforms. No competitors beyond Flutter's native ValueListenableBuilder are measured.
