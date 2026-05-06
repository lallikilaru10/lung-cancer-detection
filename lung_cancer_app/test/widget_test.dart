import 'package:flutter_test/flutter_test.dart';
import 'package:lung_cancer_detector/main.dart';

void main() {
  testWidgets('App loads without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const LungCancerDetectorApp());
    expect(find.text('LungScan AI'), findsOneWidget);
  });
}
