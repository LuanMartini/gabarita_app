import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/services/hardware/gps_service.dart';
import 'package:gabarita_app/services/hardware/study_place_service.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('agrupa coordenadas proximas no mesmo local de estudo', () async {
    final service = StudyPlaceService();

    final first = await service.resolvePlaceName(
      const StudyLocation(latitude: -23.55052, longitude: -46.63331),
    );
    final nearby = await service.resolvePlaceName(
      const StudyLocation(latitude: -23.5507, longitude: -46.6334),
    );

    expect(first, isNotNull);
    expect(nearby, first);
  });

  test('cria novo nome para coordenadas distantes', () async {
    final service = StudyPlaceService();

    await service.resolvePlaceName(
      const StudyLocation(latitude: -23.55052, longitude: -46.63331),
    );
    final distant = await service.resolvePlaceName(
      const StudyLocation(latitude: -23.56141, longitude: -46.65588),
    );

    expect(distant, isNotNull);
  });
}
