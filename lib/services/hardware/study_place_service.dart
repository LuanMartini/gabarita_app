import '../../data/datasources/local/database_helper.dart';
import 'gps_service.dart';

/// Agrupa coordenadas próximas e mantém os nomes dos locais no SQLite.
class StudyPlaceService {
  StudyPlaceService([DatabaseHelper? dbHelper])
      : _dbHelper = dbHelper ?? DatabaseHelper.instance;

  static const double _clusterRadiusMeters = 180;
  static const List<String> _defaultNames = [
    'Casa',
    'Biblioteca',
    'Campus',
    'Sala de estudos',
    'Curso',
  ];

  final DatabaseHelper _dbHelper;

  Future<String?> resolvePlaceName(StudyLocation? location) async {
    if (location == null) return null;
    return _dbHelper.resolveStudyPlaceName(
      latitude: location.latitude,
      longitude: location.longitude,
      clusterRadiusMeters: _clusterRadiusMeters,
      defaultNames: _defaultNames,
    );
  }
}
