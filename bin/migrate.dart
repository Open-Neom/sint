import 'dart:convert';
import 'dart:io';

/// Automated GetX -> SINT migration and architectural audit CLI.
///
/// Usage:
/// ```bash
/// dart run sint:migrate [target_dir] [--dry-run] [--apply] [--strict] [--fail-on-warnings] [--rule=<code>] [--json]
/// ```
///
/// Defaults to `--dry-run` (safe preview) unless `--apply` is specified.
/// For read-only architectural linting in CI, you can also run `dart run sint:audit`.
void main(List<String> args) {
  runCli(args, auditOnly: false);
}

/// Shared CLI entrypoint used by both `dart run sint:migrate` and
/// `dart run sint:audit`.
void runCli(List<String> args, {required bool auditOnly}) {
  var targetPath = '.';
  var apply = false;
  var jsonOutput = false;
  var strict = false;
  var failOnWarnings = false;
  final ruleFilter = <String>{};

  for (final arg in args) {
    if (!auditOnly && arg == '--apply') {
      apply = true;
    } else if (!auditOnly && arg == '--dry-run') {
      apply = false;
    } else if (arg == '--json') {
      jsonOutput = true;
    } else if (arg == '--strict') {
      strict = true;
    } else if (arg == '--fail-on-warnings') {
      failOnWarnings = true;
    } else if (arg.startsWith('--rule=')) {
      final rules = arg.substring('--rule='.length).split(',');
      for (final r in rules) {
        final trimmed = r.trim();
        if (trimmed.isNotEmpty) ruleFilter.add(trimmed);
      }
    } else if (arg == '-h' || arg == '--help') {
      stdout.writeln(auditOnly ? _auditUsage : _migrateUsage);
      return;
    } else if (!arg.startsWith('-')) {
      targetPath = arg;
    } else {
      stderr.writeln(
        'Unknown option: $arg\n\n${auditOnly ? _auditUsage : _migrateUsage}',
      );
      exitCode = 64;
      return;
    }
  }

  final dir = Directory(targetPath);
  if (!dir.existsSync()) {
    stderr.writeln('Target directory does not exist: ${dir.path}');
    exitCode = 66;
    return;
  }

  final report = SintMigrator.run(
    dir,
    apply: auditOnly ? false : apply,
    strict: strict,
    ruleFilter: ruleFilter.isEmpty ? null : ruleFilter,
  );

  if (jsonOutput) {
    stdout.writeln(const JsonEncoder.withIndent('  ').convert(report.toJson()));
  } else {
    stdout.writeln(
      report.formatHumanReadable(
        applied: !auditOnly && apply,
        auditOnly: auditOnly,
      ),
    );
  }

  if (failOnWarnings && report.warningsCount > 0) {
    exitCode = 1;
  }
}

const _migrateUsage = '''
SINT Migration & Audit CLI (`dart run sint:migrate`)

Usage:
  dart run sint:migrate [directory] [options]

Options:
  --dry-run           Preview all migrations and audit findings without modifying files (default)
  --apply             Write all migrated pubspec.yaml and Dart files to disk
  --strict            Include Flutter 3.50 standalone UI checks (e.g. deprecated_flutter_ui_import)
  --fail-on-warnings  Exit with code 1 if any WARN-level audit findings are detected (CI mode)
  --rule=a,b          Filter audit output to specific rule code(s)
  --json              Emit machine-readable JSON report (useful for CI/CD)
  -h, --help          Show this help message
''';

const _auditUsage = '''
SINT Architectural Linter & Audit CLI (`dart run sint:audit`)

Usage:
  dart run sint:audit [directory] [options]

Options:
  --strict            Include Flutter 3.50 standalone UI checks (e.g. deprecated_flutter_ui_import)
  --fail-on-warnings  Exit with code 1 if any WARN-level audit findings are detected (CI mode)
  --rule=a,b          Filter output to specific rule code(s)
  --json              Emit machine-readable JSON report (useful for CI/CD)
  -h, --help          Show this help message

Audit Rules:
  WARN  sint_no_get_connect           Legacy GetConnect usage (excluded by SINT)
  WARN  bind_put_closure_trap         Bind.put(() => ...) registers a Function instead of instance
  WARN  sint_back_inside_modal        Sint.back() inside dialog/sheet (use Sint.pop())
  WARN  avoid_sint_put_in_build       Unconditional Sint.put() inside Widget.build()
  INFO  avoid_direct_navigator        Direct Navigator.* call (use Sint.* navigation)
  INFO  prefer_sint_find_or_null      isRegistered ? find : null or try/catch find (use Sint.findOrNull)
  INFO  prefer_sint_find_or_put       isRegistered ? find : put (use Sint.findOrPut)
  INFO  prefer_contract_binding       2-line lazyPut<S>(() => Sint.find<I>()) (use Bind.contract)
  INFO  prefer_sint_batch             3+ consecutive .value= mutations outside Sint.batch/frameBatch
  INFO  deprecated_flutter_ui_import  (--strict) Unguarded flutter/material.dart or cupertino.dart
''';

/// Severity of an audit diagnostic discovered during migration or linting.
enum AuditSeverity { info, warning }

/// A single architectural audit diagnostic found in a scanned Dart file.
class AuditFinding {
  const AuditFinding({
    required this.filePath,
    required this.line,
    required this.code,
    required this.severity,
    required this.message,
  });

  final String filePath;
  final int line;
  final String code;
  final AuditSeverity severity;
  final String message;

  Map<String, Object> toJson() => {
    'file': filePath,
    'line': line,
    'code': code,
    'severity': severity.name,
    'message': message,
  };
}

/// Result of migrating/auditing a single source or manifest file.
class FileMigrationResult {
  const FileMigrationResult({
    required this.filePath,
    required this.changed,
    required this.replacements,
    required this.updatedContent,
    required this.findings,
  });

  final String filePath;
  final bool changed;
  final int replacements;
  final String updatedContent;
  final List<AuditFinding> findings;

  Map<String, Object> toJson() => {
    'file': filePath,
    'changed': changed,
    'replacements': replacements,
  };
}

/// Aggregated report returned by [SintMigrator.run].
class MigrationReport {
  const MigrationReport({
    required this.rootPath,
    required this.filesScanned,
    required this.modifiedFiles,
    required this.totalReplacements,
    required this.findings,
  });

  final String rootPath;
  final int filesScanned;
  final List<FileMigrationResult> modifiedFiles;
  final int totalReplacements;
  final List<AuditFinding> findings;

  int get warningsCount =>
      findings.where((f) => f.severity == AuditSeverity.warning).length;

  int get infosCount =>
      findings.where((f) => f.severity == AuditSeverity.info).length;

  Map<String, int> get ruleCounts {
    final map = <String, int>{};
    for (final f in findings) {
      map[f.code] = (map[f.code] ?? 0) + 1;
    }
    final sorted = map.entries.toList()
      ..sort((a, b) {
        final cmp = b.value.compareTo(a.value);
        return cmp != 0 ? cmp : a.key.compareTo(b.key);
      });
    return {for (final e in sorted) e.key: e.value};
  }

  Map<String, Object> toJson() => {
    'root': rootPath,
    'filesScanned': filesScanned,
    'filesChanged': modifiedFiles.length,
    'totalReplacements': totalReplacements,
    'warnings': warningsCount,
    'infos': infosCount,
    'ruleCounts': ruleCounts,
    'modifiedFiles': modifiedFiles.map((f) => f.toJson()).toList(),
    'findings': findings.map((f) => f.toJson()).toList(),
  };

  String formatHumanReadable({required bool applied, bool auditOnly = false}) {
    final buf = StringBuffer()
      ..writeln('═══════════════════════════════════════════════════════')
      ..writeln(
        auditOnly
            ? '  SINT 2.3 Architectural Audit Report'
            : '  SINT 2.3 Migration & Audit Report',
      )
      ..writeln('═══════════════════════════════════════════════════════')
      ..writeln('Target directory : $rootPath')
      ..writeln('Files scanned    : $filesScanned');

    if (!auditOnly) {
      buf
        ..writeln(
          'Files ${applied ? 'updated' : 'to update'}   : ${modifiedFiles.length}',
        )
        ..writeln('Replacements     : $totalReplacements');
    }
    buf.writeln(
      'Audit findings   : ${findings.length} '
      '($warningsCount warnings, $infosCount info)',
    );

    if (!auditOnly && modifiedFiles.isNotEmpty) {
      buf.writeln('\n--- File Changes ---');
      for (final file in modifiedFiles) {
        buf.writeln(
          '  ${applied ? '[UPDATED]' : '[WOULD UPDATE]'} ${file.filePath} '
          '(${file.replacements} replacements)',
        );
      }
    }

    if (findings.isNotEmpty) {
      buf.writeln('\n--- Summary by Rule ---');
      for (final entry in ruleCounts.entries) {
        buf.writeln('  ${entry.key.padRight(30)} : ${entry.value}');
      }

      buf.writeln('\n--- Architectural Audit Findings ---');
      for (final f in findings) {
        final badge = f.severity == AuditSeverity.warning ? 'WARN' : 'INFO';
        buf.writeln(
          '  [$badge] ${f.filePath}:${f.line} (${f.code}) — ${f.message}',
        );
      }
    }

    if (auditOnly) {
      if (findings.isEmpty) {
        buf.writeln('\nClean audit! Zero SINT architectural findings.');
      }
    } else if (!applied && modifiedFiles.isNotEmpty) {
      buf.writeln(
        '\nDry run complete. Re-run with `--apply` to write changes to disk.',
      );
    } else if (applied) {
      buf.writeln(
        '\nMigration applied. Run `flutter pub get && flutter analyze && flutter test` to verify.',
      );
    } else {
      buf.writeln('\nCodebase is already free of legacy GetX imports/symbols.');
    }
    return buf.toString();
  }
}

/// Core GetX -> SINT source migrator and architectural auditor.
class SintMigrator {
  static const String sintVersionConstraint = '^2.3.0';

  static const Set<String> _ignoredDirs = {
    '.dart_tool',
    '.git',
    '.idea',
    '.symlinks',
    'build',
    'Pods',
    'node_modules',
  };

  static final RegExp _getImportPattern = RegExp(
    r'''^(\s*import\s+['"])package:get/[^'"]+(['"][^;]*;\s*)$''',
  );

  static final RegExp _deprecatedFlutterUiImportPattern = RegExp(
    r'''^\s*import\s+['"]package:flutter/(material|cupertino)\.dart['"]''',
  );

  static final RegExp _pubspecGetDepPattern = RegExp(
    r'^(\s*)get\s*:\s*[^\n#]+(.*)$',
    multiLine: true,
  );

  static final List<(RegExp, String)> _codeSymbolRules = [
    (RegExp(r'\bGetMaterialApp\b'), 'SintMaterialApp'),
    (RegExp(r'\bGetCupertinoApp\b'), 'SintCupertinoApp'),
    (RegExp(r'\bGetxController\b'), 'SintController'),
    (RegExp(r'\bGetxService\b'), 'SintService'),
    (RegExp(r'\bGetPageRoute\b'), 'SintPageRoute'),
    (RegExp(r'\bGetPage\b'), 'SintPage'),
    (RegExp(r'\bGetMiddleware\b'), 'SintMiddleware'),
    (RegExp(r'\bGetView\b'), 'SintView'),
    (RegExp(r'\bGetBuilder\b'), 'SintBuilder'),
    (RegExp(r'\bGetRouterOutlet\b'), 'SintRouterOutlet'),
    (RegExp(r'\bGetSnackBar\b'), 'SintSnackBar'),
    (RegExp(r'\bGetObserver\b'), 'SintObserver'),
    (RegExp(r'\bgetPages\s*:'), 'sintPages:'),
    (RegExp(r'\bGet\.'), 'Sint.'),
  ];

  static final RegExp _getConnectPattern = RegExp(r'\bGetConnect\b');
  static final RegExp _navigatorPattern = RegExp(r'\bNavigator\s*\.');
  static final RegExp _bindPutClosurePattern = RegExp(
    r'\bBind\.put\s*(?:<(?:[^<>]|<[^>]*>)+>)?\s*\(\s*\([^)]*\)\s*=>',
  );
  static final RegExp _modalContextPattern = RegExp(
    r'\b(AlertDialog|SimpleDialog|showDialog|showModalBottomSheet|Sint\.dialog|Sint\.bottomSheet)\b',
  );
  static final RegExp _fireAndForgetDialogPattern = RegExp(
    r'\b(showDialog|Sint\.dialog|Sint\.bottomSheet|showModalBottomSheet)\s*(?:<(?:[^<>]|<[^>]*>)+>)?\s*\(',
  );
  static final RegExp _sintBackPattern = RegExp(r'\bSint\.back\s*\(');
  static final RegExp _sintPopPattern = RegExp(r'\bSint\.pop\s*\(');
  static final RegExp _buildMethodPattern = RegExp(
    r'\bWidget\s+build\s*\(\s*BuildContext\b',
  );
  static final RegExp _sintPutCallPattern = RegExp(
    r'\bSint\.put(?:<(?:[^<>]|<[^>]*>)+>)?\s*\(',
  );
  static final RegExp _isRegisteredPattern = RegExp(
    r'\bSint\.isRegistered(?:<(?:[^<>]|<[^>]*>)+>)?\s*\(',
  );
  static final RegExp _tryOpenPattern = RegExp(r'\btry\s*\{');
  static final RegExp _sintFindCallPattern = RegExp(
    r'\bSint\.find(?:<(?:[^<>]|<[^>]*>)+>)?\s*\(',
  );
  static final RegExp _isRegisteredFindNullWindowPattern = RegExp(
    r'\bSint\.isRegistered\s*<((?:[^<>]|<[^>]*>)+)>\s*\([^)]*\)\s*\?\s*Sint\.find\s*<\1>\s*\([^)]*\)\s*:\s*null\b',
  );
  static final RegExp _isRegisteredFindPutWindowPattern = RegExp(
    r'\bSint\.isRegistered\s*<((?:[^<>]|<[^>]*>)+)>\s*\([^)]*\)\s*\?\s*Sint\.find\s*<\1>\s*\([^)]*\)\s*:\s*Sint\.put(?:<\1>)?\s*\(',
  );
  static final RegExp _contractBridgeWindowPattern = RegExp(
    r'\b(?:Sint|Bind)\.lazyPut\s*<(?:[^<>]|<[^>]*>)+>\s*\(\s*\(\s*\)\s*=>\s*Sint\.find\s*<(?:[^<>]|<[^>]*>)+>\s*\(',
  );
  static final RegExp _batchOpenPattern = RegExp(
    r'\bSint\.(?:frameBatch|batch)\s*\(',
  );
  static final RegExp _rxValueAssignPattern = RegExp(
    r'^\s*(?:[a-zA-Z_][a-zA-Z0-9_]*\.)*[a-zA-Z_][a-zA-Z0-9_]*\.value\s*=(?!=)',
  );

  /// Scans [root] and migrates/audits `pubspec.yaml` and `.dart` files.
  static MigrationReport run(
    Directory root, {
    bool apply = false,
    bool strict = false,
    Set<String>? ruleFilter,
  }) {
    final files = _collectFiles(root);
    final modified = <FileMigrationResult>[];
    final findings = <AuditFinding>[];
    var totalReplacements = 0;

    for (final file in files) {
      final rel = _relativePath(root.path, file.path);
      final original = file.readAsStringSync();
      final FileMigrationResult result;

      if (file.path.endsWith('pubspec.yaml')) {
        result = migratePubspec(original, filePath: rel);
      } else {
        result = migrateDartSource(
          original,
          filePath: rel,
          strict: strict,
          ruleFilter: ruleFilter,
        );
      }

      findings.addAll(result.findings);
      if (result.changed) {
        modified.add(result);
        totalReplacements += result.replacements;
        if (apply) {
          file.writeAsStringSync(result.updatedContent);
        }
      }
    }

    return MigrationReport(
      rootPath: root.path,
      filesScanned: files.length,
      modifiedFiles: modified,
      totalReplacements: totalReplacements,
      findings: findings,
    );
  }

  /// Migrates `get:` dependency entries inside a `pubspec.yaml` string.
  static FileMigrationResult migratePubspec(
    String content, {
    required String filePath,
  }) {
    var replacements = 0;
    final lines = content.split('\n');
    final out = <String>[];
    var inDependencies = false;
    var hasSintAlready = RegExp(
      r'^\s+sint\s*:',
      multiLine: true,
    ).hasMatch(content);

    for (final line in lines) {
      final trimmed = line.trim();
      if (RegExp(r'^[a-zA-Z0-9_]+\s*:').hasMatch(line)) {
        inDependencies =
            trimmed.startsWith('dependencies:') ||
            trimmed.startsWith('dev_dependencies:') ||
            trimmed.startsWith('dependency_overrides:');
      }
      if (inDependencies && _pubspecGetDepPattern.hasMatch(line)) {
        replacements++;
        if (hasSintAlready) {
          continue;
        }
        hasSintAlready = true;
        final replaced = line.replaceFirstMapped(
          _pubspecGetDepPattern,
          (m) => '${m.group(1)}sint: $sintVersionConstraint${m.group(2) ?? ''}',
        );
        out.add(replaced);
      } else {
        out.add(line);
      }
    }

    final updated = out.join('\n');
    return FileMigrationResult(
      filePath: filePath,
      changed: updated != content,
      replacements: replacements,
      updatedContent: updated,
      findings: const [],
    );
  }

  /// Migrates GetX imports and symbols in a single Dart source string while
  /// preserving comments/string literals and collecting architectural findings.
  static FileMigrationResult migrateDartSource(
    String content, {
    required String filePath,
    bool strict = false,
    Set<String>? ruleFilter,
  }) {
    final lines = content.split('\n');
    final out = <String>[];
    final findings = <AuditFinding>[];
    var replacements = 0;
    var hasSintImport = RegExp(
      r'''^\s*import\s+['"]package:sint/sint\.dart['"];\s*$''',
      multiLine: true,
    ).hasMatch(content);
    final fileIgnoresDeprecated = RegExp(
      r'ignore_for_file:[^\n]*deprecated_member_use',
    ).hasMatch(content);

    var fireAndForgetDialogWindow = 0;
    int? fireAndForgetDialogMethodDepth;
    var recentSintPopWindow = 0;
    var recentTryWindow = 0;
    var recentIsRegisteredWindow = 0;
    var braceDepth = 0;
    var parenDepth = 0;
    int? modalCallBaseParenDepth;
    int? buildMethodBaseDepth;
    int? batchBaseDepth;
    var consecutiveRxAssigns = 0;
    var rxBurstStartLine = 0;
    var rxBurstReported = false;
    String? activeTripleQuote;

    final recentCodeLines = <String>[];

    bool isSuppressed(int lineIndex, String code) {
      final current = lines[lineIndex];
      final prev = lineIndex > 0 ? lines[lineIndex - 1] : '';
      return current.contains('sint-ignore: $code') ||
          prev.contains('sint-ignore: $code');
    }

    void addFinding({
      required int lineIndex,
      required int lineNum,
      required String code,
      required AuditSeverity severity,
      required String message,
    }) {
      if (ruleFilter != null && !ruleFilter.contains(code)) return;
      if (isSuppressed(lineIndex, code)) return;
      findings.add(
        AuditFinding(
          filePath: filePath,
          line: lineNum,
          code: code,
          severity: severity,
          message: message,
        ),
      );
    }

    for (var i = 0; i < lines.length; i++) {
      final lineNum = i + 1;
      var line = lines[i];

      // Skip lines inside multiline string literals (`'''` / `"""`).
      if (activeTripleQuote != null) {
        if (line.contains(activeTripleQuote)) {
          activeTripleQuote = null;
        }
        out.add(line);
        continue;
      }
      final openedTriple = _unclosedTripleQuote(line);
      if (openedTriple != null) {
        activeTripleQuote = openedTriple;
        out.add(line);
        continue;
      }

      // 1. Rewrite `package:get/...` imports and deduplicate.
      final importMatch = _getImportPattern.firstMatch(line);
      if (importMatch != null) {
        replacements++;
        if (hasSintImport) {
          continue;
        }
        hasSintImport = true;
        line =
            '${importMatch.group(1)}package:sint/sint.dart${importMatch.group(2)}';
        out.add(line);
        continue;
      }

      // Optional --strict check for Flutter 3.50 standalone UI readiness.
      if (strict &&
          !fileIgnoresDeprecated &&
          _deprecatedFlutterUiImportPattern.hasMatch(line)) {
        final prev = i > 0 ? lines[i - 1] : '';
        final guarded =
            prev.contains('ignore:') && prev.contains('deprecated_member_use');
        if (!guarded) {
          addFinding(
            lineIndex: i,
            lineNum: lineNum,
            code: 'deprecated_flutter_ui_import',
            severity: AuditSeverity.info,
            message: 'Flutter 3.50+ deprecates `package:flutter/(material|cupertino).dart`. Prefer `package:flutter/widgets.dart`, `package:material_ui/material_ui.dart`, or `package:cupertino_ui/cupertino_ui.dart`.',
          );
        }
      }

      // 2. Rewrite code segments outside string literals and `//` comments.
      final rewritten = _rewriteCodeOutsideStringsAndComments(line);
      if (rewritten.$2 > 0) {
        replacements += rewritten.$2;
        line = rewritten.$1;
      }

      // 3. Collect architectural audit findings on non-comment code.
      final codeOnly = _stripLineCommentAndStrings(line);
      final trimmedCode = codeOnly.trim();

      // Track recent 3-line normalized snippet for multi-line patterns.
      recentCodeLines.add(trimmedCode);
      if (recentCodeLines.length > 3) {
        recentCodeLines.removeAt(0);
      }
      final windowText = recentCodeLines.join(' ');

      if (_getConnectPattern.hasMatch(codeOnly)) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'sint_no_get_connect',
          severity: AuditSeverity.warning,
          message: 'SINT excludes HTTP/socket clients by design. Replace GetConnect with `package:http` or `package:dio` in your data layer.',
        );
      }

      if (_navigatorPattern.hasMatch(codeOnly)) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'avoid_direct_navigator',
          severity: AuditSeverity.info,
          message: 'Direct Flutter Navigator call detected. Prefer `Sint.to` / `Sint.toNamed` / `Sint.back` / `Sint.maybePop` (or `Sint.pop` inside dialogs/sheets).',
        );
      }

      if (_bindPutClosurePattern.hasMatch(codeOnly)) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'bind_put_closure_trap',
          severity: AuditSeverity.warning,
          message: 'Passing a closure to `Bind.put(() => ...)` registers a Function instead of the controller instance. Use `Bind.put(MyController())` or `Bind.lazyPut(() => MyController())`.',
        );
      }

      if (modalCallBaseParenDepth == null &&
          _modalContextPattern.hasMatch(codeOnly)) {
        modalCallBaseParenDepth = parenDepth;
      }

      if (_fireAndForgetDialogPattern.hasMatch(codeOnly) &&
          !codeOnly.contains('await ') &&
          !codeOnly.contains('return ')) {
        fireAndForgetDialogWindow = 18;
        fireAndForgetDialogMethodDepth = braceDepth > 0 ? braceDepth - 1 : 0;
      } else if (fireAndForgetDialogWindow > 0) {
        fireAndForgetDialogWindow--;
      }

      if (_sintPopPattern.hasMatch(codeOnly)) {
        recentSintPopWindow = 5;
      } else if (recentSintPopWindow > 0) {
        recentSintPopWindow--;
      }

      final insideModalScope =
          modalCallBaseParenDepth != null || fireAndForgetDialogWindow > 0;
      if (insideModalScope &&
          recentSintPopWindow == 0 &&
          _sintBackPattern.hasMatch(codeOnly)) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'sint_back_inside_modal',
          severity: AuditSeverity.warning,
          message: '`Sint.back()` pops page routes, not modal overlays. Inside a dialog or bottomSheet, use `Sint.pop([result])` instead.',
        );
      }

      // Multi-line `Sint.isRegistered<T>() ? Sint.find<T>() : null`
      if (trimmedCode.contains(': null') &&
          _isRegisteredFindNullWindowPattern.hasMatch(windowText)) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'prefer_sint_find_or_null',
          severity: AuditSeverity.info,
          message: 'Replace `Sint.isRegistered<T>() ? Sint.find<T>() : null` with single-lookup `Sint.findOrNull<T>()`.',
        );
      }

      // `try { Sint.find<T>() } catch`
      if (_tryOpenPattern.hasMatch(codeOnly)) {
        recentTryWindow = 3;
      } else if (recentTryWindow > 0) {
        recentTryWindow--;
      }
      if (recentTryWindow > 0 && _sintFindCallPattern.hasMatch(codeOnly)) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'prefer_sint_find_or_null',
          severity: AuditSeverity.info,
          message: 'Avoid wrapping `Sint.find<T>()` in `try/catch` for optional lookups. Use `Sint.findOrNull<T>()` instead.',
        );
        recentTryWindow = 0;
      }

      // Multi-line `Sint.isRegistered<T>() ? Sint.find<T>() : Sint.put(...)`
      final matchedFindOrPut =
          _sintPutCallPattern.hasMatch(codeOnly) &&
          _isRegisteredFindPutWindowPattern.hasMatch(windowText);
      if (matchedFindOrPut) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'prefer_sint_find_or_put',
          severity: AuditSeverity.info,
          message: 'Replace `Sint.isRegistered<T>() ? Sint.find<T>() : Sint.put(...)` with atomic `Sint.findOrPut<T>(() => ...)`.',
        );
      }

      // Track `Sint.isRegistered` guard window for `avoid_sint_put_in_build`.
      if (_isRegisteredPattern.hasMatch(codeOnly)) {
        recentIsRegisteredWindow = 4;
      } else if (recentIsRegisteredWindow > 0) {
        recentIsRegisteredWindow--;
      }

      // Track `Widget build(BuildContext ...)` scope via brace depth.
      if (buildMethodBaseDepth == null &&
          _buildMethodPattern.hasMatch(codeOnly)) {
        buildMethodBaseDepth = braceDepth;
      }

      if (buildMethodBaseDepth != null &&
          braceDepth == buildMethodBaseDepth + 1 &&
          !matchedFindOrPut &&
          recentIsRegisteredWindow == 0 &&
          _sintPutCallPattern.hasMatch(codeOnly)) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'avoid_sint_put_in_build',
          severity: AuditSeverity.warning,
          message: 'Unconditional `Sint.put()` inside `Widget.build()` runs on every rebuild. Move registration to `SintPage(binds: [...])`, `SintBuilder(init: ...)`, or use `Sint.findOrPut(() => ...)`.',
        );
      }

      // 2-line contract bridge: `lazyPut<Interface>(() => Sint.find<Impl>())`
      if (trimmedCode.contains('Sint.find<') &&
          _contractBridgeWindowPattern.hasMatch(windowText)) {
        addFinding(
          lineIndex: i,
          lineNum: lineNum,
          code: 'prefer_contract_binding',
          severity: AuditSeverity.info,
          message: 'Replace 2-line `lazyPut<Contract>(() => Sint.find<Impl>())` bridges with a single `Bind.contract<Contract, Impl>(...)` or `Sint.putContract<Contract, Impl>(...)`.',
        );
      }

      // Track `Sint.batch` / `Sint.frameBatch` scope & 3+ consecutive `.value =` mutations.
      if (batchBaseDepth == null && _batchOpenPattern.hasMatch(codeOnly)) {
        batchBaseDepth = braceDepth;
      }

      if (batchBaseDepth == null && _rxValueAssignPattern.hasMatch(codeOnly)) {
        if (consecutiveRxAssigns == 0) {
          rxBurstStartLine = lineNum;
          rxBurstReported = false;
        }
        consecutiveRxAssigns++;
        if (consecutiveRxAssigns >= 3 && !rxBurstReported) {
          rxBurstReported = true;
          addFinding(
            lineIndex: rxBurstStartLine - 1,
            lineNum: rxBurstStartLine,
            code: 'prefer_sint_batch',
            severity: AuditSeverity.info,
            message: '3+ consecutive `.value =` reactive mutations outside a batch trigger redundant rebuilds. Group them in `Sint.batch(() { ... })` (or `Sint.frameBatch` for high-frequency streams).',
          );
        }
      } else if (trimmedCode.isNotEmpty) {
        consecutiveRxAssigns = 0;
        rxBurstReported = false;
      }

      // Advance brace & paren depth after auditing current line.
      braceDepth += _braceDelta(codeOnly);
      if (braceDepth < 0) braceDepth = 0;
      parenDepth += _parenDelta(codeOnly);
      if (parenDepth < 0) parenDepth = 0;
      if (modalCallBaseParenDepth != null &&
          codeOnly.contains(')') &&
          parenDepth <= modalCallBaseParenDepth) {
        modalCallBaseParenDepth = null;
      }
      if (fireAndForgetDialogMethodDepth != null &&
          codeOnly.contains('}') &&
          braceDepth < fireAndForgetDialogMethodDepth) {
        fireAndForgetDialogWindow = 0;
        fireAndForgetDialogMethodDepth = null;
      }
      if (buildMethodBaseDepth != null &&
          codeOnly.contains('}') &&
          braceDepth <= buildMethodBaseDepth) {
        buildMethodBaseDepth = null;
      }
      if (batchBaseDepth != null &&
          codeOnly.contains('}') &&
          braceDepth <= batchBaseDepth) {
        batchBaseDepth = null;
      }

      out.add(line);
    }

    final updated = out.join('\n');
    return FileMigrationResult(
      filePath: filePath,
      changed: updated != content,
      replacements: replacements,
      updatedContent: updated,
      findings: findings,
    );
  }

  static String? _unclosedTripleQuote(String line) {
    var i = 0;
    while (i < line.length) {
      final ch = line[i];
      if (ch == '/' && i + 1 < line.length && line[i + 1] == '/') {
        return null;
      }
      if (i + 2 < line.length &&
          ((ch == "'" && line[i + 1] == "'" && line[i + 2] == "'") ||
              (ch == '"' && line[i + 1] == '"' && line[i + 2] == '"'))) {
        final delim = ch * 3;
        final closeIndex = line.indexOf(delim, i + 3);
        if (closeIndex == -1) return delim;
        i = closeIndex + 3;
        continue;
      }
      if (ch == "'" || ch == '"') {
        final quote = ch;
        i++;
        while (i < line.length) {
          if (line[i] == r'\' && i + 1 < line.length) {
            i += 2;
            continue;
          }
          if (line[i] == quote) {
            i++;
            break;
          }
          i++;
        }
        continue;
      }
      i++;
    }
    return null;
  }

  static int _braceDelta(String code) {
    var delta = 0;
    for (var i = 0; i < code.length; i++) {
      final ch = code.codeUnitAt(i);
      if (ch == 0x7B) {
        delta++;
      } else if (ch == 0x7D) {
        delta--;
      }
    }
    return delta;
  }

  static int _parenDelta(String code) {
    var delta = 0;
    for (var i = 0; i < code.length; i++) {
      final ch = code.codeUnitAt(i);
      if (ch == 0x28) {
        delta++;
      } else if (ch == 0x29) {
        delta--;
      }
    }
    return delta;
  }

  static (String, int) _rewriteCodeOutsideStringsAndComments(String line) {
    final buf = StringBuffer();
    var count = 0;
    var i = 0;
    var codeStart = 0;

    void flushCode(int end) {
      if (end <= codeStart) return;
      var segment = line.substring(codeStart, end);
      for (final (pattern, replacement) in _codeSymbolRules) {
        segment = segment.replaceAllMapped(pattern, (m) {
          count++;
          return replacement;
        });
      }
      buf.write(segment);
    }

    while (i < line.length) {
      final ch = line[i];
      if (ch == '/' && i + 1 < line.length && line[i + 1] == '/') {
        flushCode(i);
        buf.write(line.substring(i));
        return (buf.toString(), count);
      }
      if (ch == "'" || ch == '"') {
        flushCode(i);
        final quote = ch;
        final strStart = i;
        i++;
        while (i < line.length) {
          if (line[i] == r'\' && i + 1 < line.length) {
            i += 2;
            continue;
          }
          if (line[i] == quote) {
            i++;
            break;
          }
          i++;
        }
        buf.write(line.substring(strStart, i));
        codeStart = i;
        continue;
      }
      i++;
    }

    flushCode(line.length);
    return (buf.toString(), count);
  }

  static String _stripLineCommentAndStrings(String line) {
    final buf = StringBuffer();
    var i = 0;
    while (i < line.length) {
      final ch = line[i];
      if (ch == '/' && i + 1 < line.length && line[i + 1] == '/') {
        break;
      }
      if (ch == "'" || ch == '"') {
        final quote = ch;
        i++;
        while (i < line.length) {
          if (line[i] == r'\' && i + 1 < line.length) {
            i += 2;
            continue;
          }
          if (line[i] == quote) {
            i++;
            break;
          }
          i++;
        }
        buf.write(' ');
        continue;
      }
      buf.write(ch);
      i++;
    }
    return buf.toString();
  }

  static List<File> _collectFiles(Directory root) {
    final result = <File>[];
    void walk(Directory dir) {
      final entries = dir.listSync(followLinks: false)
        ..sort((a, b) => a.path.compareTo(b.path));
      for (final entity in entries) {
        final name = entity.uri.pathSegments
            .where((s) => s.isNotEmpty)
            .lastOrNull;
        if (entity is Directory) {
          if (name != null && _ignoredDirs.contains(name)) continue;
          walk(entity);
        } else if (entity is File) {
          if (name == 'pubspec.yaml' ||
              (name != null && name.endsWith('.dart'))) {
            result.add(entity);
          }
        }
      }
    }

    walk(root);
    return result;
  }

  static String _relativePath(String rootPath, String fullPath) {
    final normalizedRoot = rootPath.endsWith(Platform.pathSeparator)
        ? rootPath
        : '$rootPath${Platform.pathSeparator}';
    if (fullPath.startsWith(normalizedRoot)) {
      return fullPath.substring(normalizedRoot.length);
    }
    return fullPath;
  }
}
