import '../../domain/entities/enem_exam.dart';

class EnemExamModel extends EnemExam {
  const EnemExamModel({
    required super.title,
    required super.year,
    required super.disciplines,
    required super.languages,
  });

  factory EnemExamModel.fromMap(Map<String, dynamic> map) {
    return EnemExamModel(
      title: map['title']?.toString() ?? 'ENEM',
      year: _asInt(map['year']) ?? 0,
      disciplines: _readOptions(map['disciplines']),
      languages: _readOptions(map['languages']),
    );
  }
}

class EnemOptionModel extends EnemOption {
  const EnemOptionModel({
    required super.label,
    required super.value,
  });

  factory EnemOptionModel.fromMap(Map<String, dynamic> map) {
    return EnemOptionModel(
      label: map['label']?.toString() ?? '',
      value: map['value']?.toString() ?? '',
    );
  }
}

List<EnemOptionModel> _readOptions(Object? value) {
  if (value is! List) return const <EnemOptionModel>[];
  return value
      .whereType<Map<String, dynamic>>()
      .map(EnemOptionModel.fromMap)
      .where((option) => option.value.isNotEmpty)
      .toList(growable: false);
}

int? _asInt(Object? value) {
  if (value == null) return null;
  if (value is int) return value;
  if (value is num) return value.toInt();
  return int.tryParse(value.toString());
}
