import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/main.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;
  SharedPreferences.setMockInitialValues(<String, Object>{});

  testWidgets('renderiza o splash inicial', (WidgetTester tester) async {
    await tester.pumpWidget(const GabaritaApp());

    expect(find.text('Gabarita'), findsOneWidget);
  });
}
