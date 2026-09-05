import 'package:flutter_test/flutter_test.dart';
import 'package:sint_performance/main.dart';

void main() {
  testWidgets('performance app offers a bounded matched workload', (
    tester,
  ) async {
    await tester.pumpWidget(const PerformanceApp());
    expect(find.text('SINT performance lab'), findsOneWidget);
    expect(
      find.text('Run matched Obx / ValueListenableBuilder workload'),
      findsOneWidget,
    );
    expect(find.text('0'), findsNWidgets(listeners));
  });
}
