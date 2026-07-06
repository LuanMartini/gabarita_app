import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/datasources/local/enem_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carrega banco ENEM local de 2009 a 2025 sem imagens', () async {
    const dataSource = EnemLocalDataSource();

    final exams = await dataSource.listExams();
    final years = exams.map((exam) => exam.year).toSet();
    final questions2025 = await dataSource.loadQuestions(
      year: 2025,
      limit: 0,
    );

    expect(years.contains(2009), isTrue);
    expect(years.contains(2025), isTrue);
    expect(questions2025, isNotEmpty);
    expect(
      questions2025.any((question) {
        final values = <String>[
          question.context ?? '',
          for (final alternative in question.alternatives) alternative.text,
        ];
        return values.any((value) {
          final normalized = value.toLowerCase();
          return normalized.contains('![') ||
              normalized.contains('raw.githubusercontent') ||
              normalized.contains('/questions/') && normalized.contains('.jpg');
        });
      }),
      isFalse,
    );
  });
}
