import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sint/sint.dart';

class _KeepFoo extends SintController {}

class _KeepFooBar extends SintController {}

class _WidgetController extends SintController {
  int closes = 0;
  int readies = 0;
  @override
  void onReady() {
    readies++;
  }

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

Widget _navigationApp() => SintMaterialApp(
      initialRoute: '/',
      sintPages: [
        SintPage(name: '/', page: () => const Scaffold(body: Text('home'))),
        SintPage(
            name: '/other', page: () => const Scaffold(body: Text('other'))),
      ],
    );

void main() {
  setUp(() {
    Sint.reset();
    RouterReportManager.dispose();
    Sint.smartManagement = SmartManagement.full;
  });
  tearDown(() => Sint.reset());

  testWidgets('toInitial keeps exact types, including colliding legacy handles',
      (tester) async {
    await tester.pumpWidget(_navigationApp());
    await tester.pumpAndSettle();
    Sint.toNamed('/other');
    await tester.pumpAndSettle();
    final retained = Sint.put<_KeepFoo>(_KeepFoo());
    final taggedRetained = Sint.put<_KeepFoo>(_KeepFoo(), tag: 'Bar');
    final removed = Sint.put<_KeepFooBar>(_KeepFooBar());
    expect(
        InjectionExtension.registeredKeys
            .any((key) => key.startsWith('@sint/')),
        isTrue);

    await Sint.toInitial(keep: {_KeepFoo});
    await tester.pumpAndSettle();

    expect(Sint.currentRoute, '/');
    expect(find.text('home'), findsOneWidget);
    expect(removed.isClosed, isTrue);
    expect(Sint.isRegistered<_KeepFooBar>(), isFalse);
    expect(Sint.find<_KeepFoo>(), same(retained));
    expect(Sint.find<_KeepFoo>(tag: 'Bar'), same(taggedRetained));
    expect(retained.isClosed, isFalse);
    expect(taggedRetained.isClosed, isFalse);
  });

  testWidgets('onReady does not run after a controller was deleted',
      (tester) async {
    final controller = Sint.put<_WidgetController>(_WidgetController());
    Sint.delete<_WidgetController>();
    await tester.pumpWidget(const SizedBox());
    expect(controller.closes, 1);
    expect(controller.readies, 0);
  });

  testWidgets('toInitial keep also survives disposal of an owning SintBuilder',
      (tester) async {
    final retained = _KeepFoo();
    await tester.pumpWidget(SintMaterialApp(initialRoute: '/', sintPages: [
      SintPage(name: '/', page: () => const Scaffold(body: Text('home'))),
      SintPage(
          name: '/owned',
          page: () => SintBuilder<_KeepFoo>(
                init: retained,
                builder: (_) => const Scaffold(body: Text('owned')),
              )),
    ]));
    await tester.pumpAndSettle();
    Sint.toNamed('/owned');
    await tester.pumpAndSettle();
    expect(Sint.find<_KeepFoo>(), same(retained));
    await Sint.toInitial(keep: {_KeepFoo});
    await tester.pumpAndSettle();
    expect(Sint.currentRoute, '/');
    expect(Sint.find<_KeepFoo>(), same(retained));
    expect(retained.isClosed, isFalse);
    expect(Sint.getInstanceInfo<_KeepFoo>().isPermanent, isFalse);
    expect(Sint.delete<_KeepFoo>(), isTrue);
    expect(retained.isClosed, isTrue);
  });

  testWidgets('local Bind controller closes when its owning widget unmounts',
      (tester) async {
    final controller = _WidgetController();
    await tester.pumpWidget(Bind<_WidgetController>.builder(
      global: false,
      init: () => controller,
      child: Builder(builder: (context) {
        expect(Bind.of<_WidgetController>(context), same(controller));
        return const SizedBox();
      }),
    ));
    expect(controller.initialized, isTrue);
    await tester.pumpWidget(const SizedBox());
    expect(controller.closes, 1);
    expect(controller.isClosed, isTrue);
  });

  testWidgets('local Bind never deletes an unrelated global instance',
      (tester) async {
    final global = Sint.put<_WidgetController>(_WidgetController());
    final local = _WidgetController();
    await tester.pumpWidget(SintBuilder<_WidgetController>(
      global: false,
      init: local,
      builder: (_) => const SizedBox(),
    ));
    await tester.pumpWidget(const SizedBox());
    expect(local.closes, 1);
    expect(global.closes, 0);
    expect(Sint.find<_WidgetController>(), same(global));
  });

  testWidgets('an old owning Binder cannot delete a replacement generation',
      (tester) async {
    final old = _WidgetController();
    await tester.pumpWidget(SintBuilder<_WidgetController>(
      init: old,
      builder: (_) => const SizedBox(),
    ));
    final replacement = _WidgetController();
    Sint.replace<_WidgetController>(replacement);
    await tester.pumpWidget(const SizedBox());
    expect(old.closes, 1);
    expect(replacement.closes, 0);
    expect(Sint.find<_WidgetController>(), same(replacement));
  });

  test('Bind facade replaces fenix registrations and preserves permanent flags',
      () {
    TestWidgetsFlutterBinding.ensureInitialized();
    Bind.lazyPut<_WidgetController>(() => _WidgetController(), fenix: true);
    final first = Bind.find<_WidgetController>();
    final second = _WidgetController();
    Bind.replace<_WidgetController>(second);
    expect(first.closes, 1);
    expect(Bind.find<_WidgetController>(), same(second));
    Sint.delete<_WidgetController>();
    Bind.put<_WidgetController>(_WidgetController(), permanent: true);
    final permanentReplacement = _WidgetController();
    Bind.replace<_WidgetController>(permanentReplacement);
    expect(Sint.getInstanceInfo<_WidgetController>().isPermanent, isTrue);
    expect(Bind.find<_WidgetController>(), same(permanentReplacement));
  });

  test('Bind lazyReplace overrides fenix and defers the replacement builder',
      () {
    TestWidgetsFlutterBinding.ensureInitialized();
    Bind.lazyPut<_WidgetController>(() => _WidgetController(), fenix: true);
    final first = Bind.find<_WidgetController>();
    var builds = 0;
    Bind.lazyReplace<_WidgetController>(() {
      builds++;
      return _WidgetController();
    }, fenix: true);
    expect(first.closes, 1);
    expect(builds, 0);
    final second = Bind.find<_WidgetController>();
    expect(identical(first, second), isFalse);
    expect(builds, 1);
    Sint.delete<_WidgetController>();
    Bind.find<_WidgetController>();
    expect(builds, 2);
  });
}
