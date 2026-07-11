import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/repositories/question_repository_impl.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  sqfliteFfiInit();
  databaseFactory = databaseFactoryFfi;

  test('mistura anos e prioriza questoes ainda nao exibidas', () async {
    final repository = QuestionRepositoryImpl();
    for (final year in <int>[2023, 2024, 2025]) {
      await repository.syncEnemQuestions(year: year);
    }

    final firstSimulado = await repository.getSimuladoQuestions(quantity: 9);
    final secondSimulado = await repository.getSimuladoQuestions(quantity: 9);

    expect(firstSimulado, hasLength(9));
    expect(firstSimulado.map((question) => question.id).toSet(), hasLength(9));
    expect(firstSimulado.map((question) => question.year).toSet().length,
        greaterThanOrEqualTo(3));
    expect(secondSimulado, hasLength(9));
    expect(
      secondSimulado
          .map((question) => question.id)
          .toSet()
          .intersection(firstSimulado.map((question) => question.id).toSet()),
      isEmpty,
    );
  });
}
