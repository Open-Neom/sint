@Tags(['benchmark'])
library;

import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';
import 'bench_harness.dart';

RouteParser buildParser(int count, {required bool sharedPrefix}) => RouteParser(
      routes: [
        SintPage(name: '/', page: () => const SizedBox()),
        for (var i = 0; i < count; i++)
          SintPage(
              name: sharedPrefix ? '/api/item$i/:id' : '/item$i/:id',
              page: () => const SizedBox()),
      ],
    );

void main() {
  for (final count in [10, 100, 1000]) {
    for (final shared in [false, true]) {
      final shape = shared ? 'shared' : 'unique';
      for (final miss in [false, true]) {
        test('Route $shape prefix, $count entries, miss=$miss', () async {
          final parser = buildParser(count, sharedPrefix: shared);
          final stem = shared ? '/api' : '';
          final path =
              miss ? '$stem/item_missing/42' : '$stem/item${count - 1}/42';
          final settings = PageSettings(Uri.parse('$path?tab=summary'));
          final preflight =
              parser.matchRoute('$path?tab=summary', arguments: settings);
          expect(preflight.route?.name, miss ? isNull : path);
          if (!miss) expect(settings.pathParams['id'], '42');
          var valid = 0;
          final result =
              await runBench('route.hot.$shape.entries=$count.miss=$miss', () {
            final decoded =
                parser.matchRoute('$path?tab=summary', arguments: settings);
            if (miss
                ? decoded.route == null
                : decoded.route?.name == path &&
                    settings.pathParams['id'] == '42' &&
                    settings.params['tab'] == 'summary') {
              valid++;
            }
          }, iterations: 100);
          expect(valid, result.totalOperations);
          printBenchTable(
              'Parser match including URI/parameter decoding (${count + 1} actual routes)',
              [result]);
        });
      }
    }
  }

  test('Index construction plus first lookup is reported separately', () async {
    var valid = 0;
    final result =
        await runBench('route.cold.construct_and_first_match.entries=100', () {
      final parser = buildParser(100, sharedPrefix: true);
      if (parser.matchRoute('/api/item99/42').route?.name == '/api/item99/42') {
        valid++;
      }
    }, iterations: 10, warmup: 10);
    expect(valid, result.totalOperations);
    printBenchTable(
        'Route/page construction, index build and first lookup', [result]);
  });
}
