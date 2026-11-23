import 'migrate.dart';

/// Read-only SINT Architectural Linter & CI Audit CLI (`dart run sint:audit`).
///
/// Usage:
/// ```bash
/// dart run sint:audit [target_dir] [--strict] [--fail-on-warnings] [--rule=<code>] [--json]
/// ```
void main(List<String> args) {
  runCli(args, auditOnly: true);
}
