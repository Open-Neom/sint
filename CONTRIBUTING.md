# Contributing to SINT

Thank you for your interest in contributing to **SINT (State · Injection · Navigation · Translation)**! We welcome code contributions, real-world GetX migration feedback, benchmarks, bug reports, and documentation translations from the Flutter community.

---

## Core Design Principles

Before opening a pull request, please keep SINT's architectural guardrails in mind:

1. **Strict 4-Pillar Scope (`S · I · N · T`):** State Management, Dependency Injection, Navigation, and Translation/Localization. SINT intentionally excludes HTTP clients (`GetConnect`), storage layers, and unrelated utilities so the core stays lean, auditable, and fast.
2. **Zero Codegen (`0 build_runner`):** APIs should remain clean, idiomatic Dart without requiring generated `.g.dart` or `.freezed.dart` files.
3. **Web / Wasm & Standalone Design System Safety:** Dependency lookups must remain reified `Type`-keyed (never `runtimeType.toString()`), and core layers stay decoupled from legacy `package:flutter/material.dart` / `cupertino.dart` imports where `package:flutter/widgets.dart` suffices.
4. **`2.x` Backwards Compatibility:** Existing `@Deprecated` `Get*` aliases and `SintMaterialApp` / `SintCupertinoApp` compatibility bridges remain intact throughout `2.x`. New features should not break existing callers.
5. **High-Frequency Performance:** Hot paths (`Obx`, `ObxSelect`, `Computed`, `Sint.batch`, `Sint.frameBatch`, `FrameThrottledRx`, Prefix-Trie router, `.tr`) should avoid unnecessary allocations, `StreamController`s, or `Timer`s.

---

## Local Development Setup

```bash
git clone https://github.com/Open-Neom/sint.git
cd sint
flutter pub get
```

### Running Checks Before Submitting a PR

Please make sure all checks pass locally with zero warnings/errors:

```bash
# Format Dart files
dart format .

# Static analysis (strict lints enabled in analysis_options.yaml)
dart analyze

# Full unit & widget test suite
flutter test

# High-frequency telemetry benchmark
flutter test test/benchmarks/high_frequency_benchmark_test.dart
```

If you modify `bin/migrate.dart` or `bin/audit.dart`, also verify the pure-Dart CLIs against sample fixtures or a real Flutter project with `--dry-run` and `--json`.

---

## High-Impact Ways to Contribute

Look for open tickets labeled **`good first issue`** or **`help wanted`** in [GitHub Issues](https://github.com/Open-Neom/sint/issues), or jump into any of these areas:

- **Core & Reactive Engine (`lib/`):** Performance improvements, reactive worker parity (`SintService` / `SintController`), edge-case fixes, and regression tests.
- **Migration & Audit CLIs (`bin/migrate.dart`, `bin/audit.dart`):** Testing drop-in migrations on real GetX production apps, reporting edge cases, and adding safe automated rewrites + unit tests.
- **Large Codebase Migration Guides (`docs/`):** Practical guides for migrating real-world apps (`GetConnect` → `dio`/`http`, `GetStorage`, `GetPlatform`, phased rollouts).
- **Documentation Translations (`documentation/`):** Keeping regional docs up to date with `2.3.0+` (for example `documentation/pt_BR/`, matching `en_US` and `es_ES`).
- **Benchmarks (`test/benchmarks/`, `tool/`):** Reproducible AOT and frame-timing comparisons against `ValueNotifier`, Riverpod, and BLoC.

---

## Pull Request Workflow

1. **Fork** the repository and create a focused branch from `main`:
   ```bash
   git checkout -b feat/short-description
   # or: fix/short-description, docs/pt-br-2.3.0
   ```
2. **Keep PRs focused:** One feature, fix, or doc update per PR makes review fast.
3. **Add tests:** Every bug fix or feature in `lib/` or `bin/` should include unit/widget tests in `test/`.
4. **Commit style:** We use Conventional Commits (`feat:`, `fix:`, `docs:`, `perf:`, `test:`, `chore:`).
5. **Open the PR:** Reference the related issue (e.g., `Closes #2`), summarize what changed, and include `flutter test` / `dart analyze` output.

---

## Questions & Roadmap

- Check [`ROADMAP.md`](ROADMAP.md) for upcoming milestones (`2.4.0` DevTools Extension, `sint_lints`, Web/Wasm stress showcase, AOT benchmark matrix).
- Start a thread in [GitHub Discussions](https://github.com/Open-Neom/sint/discussions) or open an issue anytime — we respond quickly and appreciate every contribution!
