import 'dart:io';

import 'package:flutter_test/flutter_test.dart';

import '../../bin/migrate.dart';

void main() {
  group('SintMigrator pubspec migration', () {
    test('replaces get dependency with sint ^2.3.0', () {
      const input = '''
name: sample_app
dependencies:
  flutter:
    sdk: flutter
  get: ^4.6.6
  http: ^1.2.0
''';
      final result = SintMigrator.migratePubspec(
        input,
        filePath: 'pubspec.yaml',
      );
      expect(result.changed, isTrue);
      expect(result.replacements, 1);
      expect(result.updatedContent, contains('sint: ^2.3.0'));
      expect(result.updatedContent, isNot(contains('get: ^4.6.6')));
    });

    test('deduplicates get entry when sint is already declared', () {
      const input = '''
name: sample_app
dependencies:
  sint: ^2.2.2
  get: ^4.6.6
''';
      final result = SintMigrator.migratePubspec(
        input,
        filePath: 'pubspec.yaml',
      );
      expect(result.changed, isTrue);
      expect(result.replacements, 1);
      expect(RegExp(r'\bsint\s*:').allMatches(result.updatedContent).length, 1);
      expect(result.updatedContent, isNot(contains('get: ^4.6.6')));
    });
  });

  group('SintMigrator Dart source migration & audit', () {
    test('rewrites GetX imports & symbols while preserving comments and string literals', () {
      const input = '''
import 'package:get/get.dart';
import 'package:get/get_navigation/get_navigation.dart';

// Get.to should not be rewritten inside a comment
class CounterController extends GetxController {
  final label = 'Get.find() and GetMaterialApp inside string';
  void open() {
    Get.toNamed('/detail');
  }
}

Widget buildApp() => GetMaterialApp(
  getPages: [
    GetPage(name: '/home', page: () => const SizedBox()),
  ],
);
''';

      final result = SintMigrator.migrateDartSource(
        input,
        filePath: 'lib/main.dart',
      );

      expect(result.changed, isTrue);
      // Duplicate package:get sub-import deduplicated into one package:sint/sint.dart.
      expect(
        RegExp(r"package:sint/sint\.dart")
            .allMatches(result.updatedContent)
            .length,
        1,
      );
      expect(result.updatedContent, isNot(contains('package:get/')));
      expect(result.updatedContent, contains('extends SintController'));
      expect(result.updatedContent, contains("Sint.toNamed('/detail');"));
      expect(result.updatedContent, contains('SintMaterialApp('));
      expect(result.updatedContent, contains('sintPages: ['));
      expect(result.updatedContent, contains('SintPage('));

      // Comments and string literals must remain untouched.
      expect(
        result.updatedContent,
        contains('// Get.to should not be rewritten inside a comment'),
      );
      expect(
        result.updatedContent,
        contains("'Get.find() and GetMaterialApp inside string'"),
      );
    });

    test('emits all four smart architectural audit findings', () {
      const input = '''
import 'package:sint/sint.dart';

class ApiService extends GetConnect {}

void setup() {
  Bind.put(() => ApiService());
}

void navigate(BuildContext context) {
  Navigator.of(context).pop();
}

void openModal() {
  Sint.dialog(
    AlertDialog(
      actions: [
        TextButton(onPressed: () => Sint.back(), child: const Text('Close')),
      ],
    ),
  );
}
''';

      final result = SintMigrator.migrateDartSource(
        input,
        filePath: 'lib/audit_sample.dart',
      );

      final codes = result.findings.map((f) => f.code).toSet();
      expect(
        codes,
        containsAll([
          'sint_no_get_connect',
          'bind_put_closure_trap',
          'avoid_direct_navigator',
          'sint_back_inside_modal',
        ]),
      );
    });

    test('detects ecosystem audit rules (findOrNull, findOrPut, contract, batch, put-in-build, strict material) and respects sint-ignore', () {
      const input = '''
import 'package:flutter/material.dart';
import 'package:sint/sint.dart';

class BadWidget extends StatelessWidget {
  const BadWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final c = Sint.put(MyCtrl());
    final opt = Sint.isRegistered<OtherCtrl>()
        ? Sint.find<OtherCtrl>()
        : null;
    final lazy = Sint.isRegistered<ThirdCtrl>()
        ? Sint.find<ThirdCtrl>()
        : Sint.put(ThirdCtrl());
    return const SizedBox();
  }
}

void bindings() {
  Sint.lazyPut<AuthService>(() => Sint.find<AuthController>(), fenix: true);
}

void updateAll(RxInt a, RxInt b, RxInt c) {
  a.value = 1;
  b.value = 2;
  c.value = 3;
}

void suppressed(RxInt a, RxInt b, RxInt c) {
  // sint-ignore: prefer_sint_batch
  a.value = 1;
  b.value = 2;
  c.value = 3;
}
''';

      final defaultResult = SintMigrator.migrateDartSource(
        input,
        filePath: 'lib/ecosystem_audit.dart',
      );
      final defaultCodes = defaultResult.findings.map((f) => f.code).toList();
      expect(defaultCodes, contains('avoid_sint_put_in_build'));
      expect(defaultCodes, contains('prefer_sint_find_or_null'));
      expect(defaultCodes, contains('prefer_sint_find_or_put'));
      expect(defaultCodes, contains('prefer_contract_binding'));
      // Only the unsuppressed 3-line burst should fire `prefer_sint_batch`.
      expect(defaultCodes.where((c) => c == 'prefer_sint_batch').length, 1);
      // `deprecated_flutter_ui_import` only fires with `strict: true`.
      expect(defaultCodes, isNot(contains('deprecated_flutter_ui_import')));

      final strictResult = SintMigrator.migrateDartSource(
        input,
        filePath: 'lib/ecosystem_audit.dart',
        strict: true,
      );
      expect(
        strictResult.findings.map((f) => f.code),
        contains('deprecated_flutter_ui_import'),
      );

      final filtered = SintMigrator.migrateDartSource(
        input,
        filePath: 'lib/ecosystem_audit.dart',
        ruleFilter: {'prefer_contract_binding'},
      );
      expect(filtered.findings.length, 1);
      expect(filtered.findings.single.code, 'prefer_contract_binding');
    });

    test('avoids false positives for post-dialog Sint.back, Sint.pop+Sint.back, and onPressed Sint.put', () {
      const input = '''
import 'package:sint/sint.dart';

class SafePage extends StatelessWidget {
  const SafePage({super.key});

  Future<void> confirmExit(BuildContext context) async {
    final shouldExit = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        actions: [
          TextButton(onPressed: () => Sint.pop(true), child: const Text('Yes')),
        ],
      ),
    );
    if (shouldExit == true) {
      Sint.back(result: true);
    }
  }

  Future<void> endLiveDialog(BuildContext context) async {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        actions: [
          TextButton(
            onPressed: () async {
              Sint.pop();
              await Future<void>.delayed(Duration.zero);
              Sint.back();
            },
            child: const Text('End'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final nested = Sint.isRegistered<SelectController<T>>(tag: 'a')
        ? Sint.find<SelectController<T>>(tag: 'a')
        : Sint.put(SelectController<T>(), tag: 'a');
    return TextButton(
      onPressed: () {
        try {
          Sint.find<String>();
        } catch (_) {
          Sint.put('fallback');
        }
      },
      child: Text('\$nested'),
    );
  }
}
''';

      final res = SintMigrator.migrateDartSource(
        input,
        filePath: 'lib/safe_page.dart',
        ruleFilter: {'sint_back_inside_modal', 'avoid_sint_put_in_build'},
      );
      expect(res.findings, isEmpty);
    });
  });

  group('SintMigrator end-to-end directory runner', () {
    late Directory tempDir;

    setUp(() {
      tempDir = Directory.systemTemp.createTempSync('sint_migrate_test_');
      File('${tempDir.path}/pubspec.yaml').writeAsStringSync('''
name: demo
dependencies:
  get: ^4.6.6
''');
      Directory('${tempDir.path}/lib').createSync();
      File('${tempDir.path}/lib/app.dart').writeAsStringSync('''
import 'package:get/get.dart';
class MyCtrl extends GetxController {}
''');
    });

    tearDown(() {
      if (tempDir.existsSync()) {
        tempDir.deleteSync(recursive: true);
      }
    });

    test('--dry-run previews changes without mutating files on disk', () {
      final report = SintMigrator.run(tempDir, apply: false);
      expect(report.filesScanned, 2);
      expect(report.modifiedFiles.length, 2);
      expect(report.totalReplacements, greaterThanOrEqualTo(3));

      // Disk files must remain untouched.
      expect(
        File('${tempDir.path}/pubspec.yaml').readAsStringSync(),
        contains('get: ^4.6.6'),
      );
      expect(
        File('${tempDir.path}/lib/app.dart').readAsStringSync(),
        contains('GetxController'),
      );

      final json = report.toJson();
      expect(json['filesScanned'], 2);
      expect(json['filesChanged'], 2);
    });

    test('--apply writes migrated files and second run reports 0 changes', () {
      final first = SintMigrator.run(tempDir, apply: true);
      expect(first.modifiedFiles.length, 2);

      expect(
        File('${tempDir.path}/pubspec.yaml').readAsStringSync(),
        contains('sint: ^2.3.0'),
      );
      expect(
        File('${tempDir.path}/lib/app.dart').readAsStringSync(),
        contains('SintController'),
      );

      // Idempotent on second run.
      final second = SintMigrator.run(tempDir, apply: false);
      expect(second.modifiedFiles, isEmpty);
      expect(second.totalReplacements, 0);
    });
  });
}
