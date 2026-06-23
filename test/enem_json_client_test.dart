import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/datasources/local/enem_json_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('carrega provas ENEM a partir de assets JSON locais', () async {
    final client = EnemJsonClient();

    final exams = await client.listExams();

    expect(exams.map((exam) => exam.year), containsAll(<int>[2023, 2022]));
  });

  test('converte questoes JSON locais para o modelo usado pelo app', () async {
    final client = EnemJsonClient();

    final questions = await client.fetchQuestions(year: 2023, maxQuestions: 3);
    final firstQuestion = questions.first.toQuestion();

    expect(questions, hasLength(3));
    expect(firstQuestion.examSource, 'ENEM 2023');
    expect(
        firstQuestion.options.keys, containsAll(<String>['A', 'B', 'C', 'D']));
    expect(firstQuestion.correctOption, isNotEmpty);
  });
}
