import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/datasources/local/enem_local_data_source.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carrega provas ENEM a partir de assets JSON locais', () async {
    const dataSource = EnemLocalDataSource();

    final exams = await dataSource.listExams();

    expect(exams.map((exam) => exam.year), containsAll(<int>[2025, 2009]));
  });

  test('converte questoes JSON locais para o modelo usado pelo app', () async {
    const dataSource = EnemLocalDataSource();

    final questions = await dataSource.loadQuestions(year: 2025, limit: 3);
    final firstQuestion = questions.first.toQuestion();

    expect(questions, hasLength(3));
    expect(firstQuestion.examSource, 'ENEM 2025');
    expect(
      firstQuestion.options.keys,
      containsAll(<String>['A', 'B', 'C', 'D']),
    );
    expect(firstQuestion.correctOption, isNotEmpty);
  });
}
