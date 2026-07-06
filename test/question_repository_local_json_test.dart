import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/repositories/question_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('importa questoes do JSON local para o SQLite', () async {
    final repository = QuestionRepositoryImpl();

    await repository.syncEnemQuestions(year: 2025);
    final questions = await repository.getQuestionsByFilter(
      examSource: 'ENEM 2025',
      limit: 10,
    );

    expect(questions, isNotEmpty);
    expect(questions.first.examSource, 'ENEM 2025');
    expect(questions.any((question) => question.imagePath != null), isFalse);
  });
}
