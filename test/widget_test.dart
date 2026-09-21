import 'package:flutter_test/flutter_test.dart';
import 'package:panama_historica/app/app.dart';

void main() {
  testWidgets('Panama Historica App smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const PanamaHistoricaApp());
    expect(find.byType(PanamaHistoricaApp), findsOneWidget);
  });
}
