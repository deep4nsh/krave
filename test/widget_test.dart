import 'package:flutter_test/flutter_test.dart';
import 'package:krave/main.dart';

void main() {
  testWidgets('KraveApp builds', (tester) async {
    await tester.pumpWidget(const KraveApp());
    // If it pumped without throwing, that's a pass for a smoke test.
    expect(find.byType(KraveApp), findsOneWidget);
  });
}
