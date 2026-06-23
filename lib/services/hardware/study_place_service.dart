import 'dart:convert';

import 'package:geolocator/geolocator.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'gps_service.dart';

class StudyPlaceService {
  static const String _placesKey = 'study_places';
  static const double _clusterRadiusMeters = 180;
  static const List<String> _defaultNames = [
    'Casa',
    'Biblioteca',
    'Campus',
    'Sala de estudos',
    'Curso',
  ];

  Future<String?> resolvePlaceName(StudyLocation? location) async {
    if (location == null) return null;

    final prefs = await SharedPreferences.getInstance();
    final places = _readPlaces(prefs);
    final existingIndex = places.indexWhere(
      (place) =>
          _distanceMeters(place.latitude, place.longitude, location) <=
          _clusterRadiusMeters,
    );

    if (existingIndex >= 0) {
      final place = places[existingIndex];
      places[existingIndex] = place.copyWith(lastSeenAt: DateTime.now());
      await _writePlaces(prefs, places);
      return place.name;
    }

    final nextPlace = _StudyPlace(
      name: _defaultNameFor(places.length),
      latitude: location.latitude,
      longitude: location.longitude,
      createdAt: DateTime.now(),
      lastSeenAt: DateTime.now(),
    );
    places.add(nextPlace);
    await _writePlaces(prefs, places);
    return nextPlace.name;
  }

  List<_StudyPlace> _readPlaces(SharedPreferences prefs) {
    final raw = prefs.getString(_placesKey);
    if (raw == null || raw.isEmpty) return <_StudyPlace>[];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return <_StudyPlace>[];
      return decoded
          .whereType<Map<String, dynamic>>()
          .map(_StudyPlace.fromMap)
          .toList();
    } catch (_) {
      return <_StudyPlace>[];
    }
  }

  Future<void> _writePlaces(
    SharedPreferences prefs,
    List<_StudyPlace> places,
  ) {
    return prefs.setString(
      _placesKey,
      jsonEncode(places.map((place) => place.toMap()).toList()),
    );
  }

  String _defaultNameFor(int index) {
    if (index < _defaultNames.length) return _defaultNames[index];
    return 'Local ${index + 1}';
  }

  double _distanceMeters(
    double latitude,
    double longitude,
    StudyLocation location,
  ) {
    return Geolocator.distanceBetween(
      latitude,
      longitude,
      location.latitude,
      location.longitude,
    );
  }
}

class _StudyPlace {
  const _StudyPlace({
    required this.name,
    required this.latitude,
    required this.longitude,
    required this.createdAt,
    required this.lastSeenAt,
  });

  factory _StudyPlace.fromMap(Map<String, dynamic> map) {
    return _StudyPlace(
      name: map['name']?.toString() ?? 'Local',
      latitude: _asDouble(map['latitude']),
      longitude: _asDouble(map['longitude']),
      createdAt: DateTime.tryParse(map['created_at']?.toString() ?? '') ??
          DateTime.now(),
      lastSeenAt: DateTime.tryParse(map['last_seen_at']?.toString() ?? '') ??
          DateTime.now(),
    );
  }

  final String name;
  final double latitude;
  final double longitude;
  final DateTime createdAt;
  final DateTime lastSeenAt;

  _StudyPlace copyWith({
    DateTime? lastSeenAt,
  }) {
    return _StudyPlace(
      name: name,
      latitude: latitude,
      longitude: longitude,
      createdAt: createdAt,
      lastSeenAt: lastSeenAt ?? this.lastSeenAt,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'latitude': latitude,
      'longitude': longitude,
      'created_at': createdAt.toIso8601String(),
      'last_seen_at': lastSeenAt.toIso8601String(),
    };
  }
}

double _asDouble(Object? value) {
  if (value == null) return 0;
  if (value is double) return value;
  if (value is num) return value.toDouble();
  return double.tryParse(value.toString()) ?? 0;
}
