import 'package:flutter_test/flutter_test.dart';
import 'package:mafad_desktop/main.dart';

void main() {
  testWidgets('Mafad desktop smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MafadDesktopApp());
    expect(find.text('مفاد وان پلاس'), findsWidgets);
  });
}
