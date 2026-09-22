import 'package:flutter/widgets.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart' as material;
import 'package:sint/sint.dart';

class _SheetController extends SintController {
  int closes = 0;

  @override
  void onClose() {
    closes++;
    super.onClose();
  }
}

void main() {
  tearDown(Sint.reset);

  for (final design in [SintDesign.material, SintDesign.cupertino]) {
    for (final persistent in [true, false]) {
      testWidgets('$design sheet preserves content height and avoids keyboard '
          '(persistent: $persistent)', (tester) async {
        tester.view.physicalSize = const Size(800, 600);
        tester.view.devicePixelRatio = 1;
        addTearDown(tester.view.resetPhysicalSize);
        addTearDown(tester.view.resetDevicePixelRatio);
        addTearDown(tester.view.resetViewInsets);

        await tester.pumpWidget(
          SintApp(
            design: design,
            enableLegacyCompatibility: false,
            sintPages: [SintPage(name: '/', page: () => const SizedBox())],
          ),
        );
        await tester.pumpAndSettle();
        final controller = _SheetController();
        const contentKey = Key('sheet-content');
        final result = Sint.bottomSheet<String>(
          SintBuilder<_SheetController>(
            init: controller,
            builder: (_) => const SizedBox(
              key: contentKey,
              height: 80,
              child: Text('Sheet content'),
            ),
          ),
          persistent: persistent,
        );
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(Sint.isBottomSheetOpen, isTrue);
        expect(find.byType(material.BottomSheet), findsOneWidget);
        expect(tester.getSize(find.byType(material.BottomSheet)).height, 80);
        expect(tester.getBottomLeft(find.byKey(contentKey)).dy, 600);

        tester.view.viewInsets = const FakeViewPadding(bottom: 300);
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
        expect(tester.getSize(find.byType(material.BottomSheet)).height, 80);
        expect(tester.getBottomLeft(find.byKey(contentKey)).dy, 300);

        Sint.closeBottomSheet(result: 'closed');
        await tester.pumpAndSettle();
        expect(await result, 'closed');
        expect(find.byKey(contentKey), findsNothing);
        expect(Sint.isBottomSheetOpen, isFalse);
        expect(controller.closes, 1);
        await tester.pumpWidget(const SizedBox());
      });
    }
  }
}
