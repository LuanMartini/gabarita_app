import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/models/enem_question_remote_model.dart';

void main() {
  Map<String, dynamic> questionJson({
    String context = 'Enunciado inteiramente textual.',
    List<dynamic>? alternatives,
    List<dynamic>? files,
  }) {
    return <String, dynamic>{
      'title': 'Questao 1 - ENEM 2024',
      'index': 1,
      'discipline': 'matematica',
      'year': 2024,
      'context': context,
      'correctAlternative': 'A',
      'files': files ?? <dynamic>[],
      'alternatives': alternatives ??
          <Map<String, dynamic>>[
            <String, dynamic>{'letter': 'A', 'text': 'Alternativa A'},
            <String, dynamic>{'letter': 'B', 'text': 'Alternativa B'},
            <String, dynamic>{'letter': 'C', 'text': 'Alternativa C'},
            <String, dynamic>{'letter': 'D', 'text': 'Alternativa D'},
            <String, dynamic>{'letter': 'E', 'text': 'Alternativa E'},
          ],
    };
  }

  test('aceita somente questao textual com alternativas completas', () {
    final question = EnemQuestionRemoteModel.fromMap(questionJson());

    expect(question.canBecomeQuestion, isTrue);
    expect(question.requiresVisualResource, isFalse);
  });

  test('rejeita questao que depende de arquivo visual ou de referencia visual',
      () {
    final withFile = EnemQuestionRemoteModel.fromMap(
      questionJson(files: <String>['question-1.png']),
    );
    final withReference = EnemQuestionRemoteModel.fromMap(
      questionJson(context: 'Observe a figura a seguir e responda.'),
    );

    expect(withFile.canBecomeQuestion, isFalse);
    expect(withReference.canBecomeQuestion, isFalse);
  });

  test('rejeita questao sem todas as cinco alternativas do ENEM', () {
    final question = EnemQuestionRemoteModel.fromMap(
      questionJson(
        alternatives: <Map<String, dynamic>>[
          <String, dynamic>{'letter': 'A', 'text': 'Alternativa A'},
          <String, dynamic>{'letter': 'B', 'text': 'Alternativa B'},
          <String, dynamic>{'letter': 'C', 'text': 'Alternativa C'},
          <String, dynamic>{'letter': 'D', 'text': 'Alternativa D'},
        ],
      ),
    );

    expect(question.canBecomeQuestion, isFalse);
  });
}
