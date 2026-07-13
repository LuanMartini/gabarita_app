import 'dart:convert';
import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/data/models/enem_question_remote_model.dart';

void main() {
  test('questoes importaveis do ENEM corrigem certo e errado pelo gabarito',
      () async {
    final files = Directory('assets/data/enem')
        .listSync()
        .whereType<File>()
        .where((file) => file.path.endsWith('.json'))
        .toList(growable: false);

    var validAnswerKeyCount = 0;
    var importableQuestionCount = 0;

    for (final file in files) {
      final decoded = jsonDecode(await file.readAsString());
      final questions = decoded is Map<String, dynamic>
          ? decoded['questions']
          : const <dynamic>[];

      if (questions is! List) continue;

      for (final rawQuestion in questions) {
        if (rawQuestion is! Map<String, dynamic>) continue;

        final model = EnemQuestionRemoteModel.fromMap(rawQuestion);
        final correct = model.correctAlternative;
        final hasValidAnswerKey = RegExp(r'^[A-E]$').hasMatch(correct);

        if (hasValidAnswerKey) {
          validAnswerKeyCount++;
          final correctAlternatives = model.alternatives
              .where((alternative) => alternative.isCorrect)
              .map((alternative) => alternative.letter)
              .toList(growable: false);

          expect(
            correctAlternatives,
            <String>[correct],
            reason:
                '${file.path} questao ${model.index}: isCorrect deve bater com $correct.',
          );
        }

        if (!model.canBecomeQuestion) continue;

        importableQuestionCount++;
        final question = model.toQuestion();

        expect(
          question.isCorrectAnswer(correct),
          isTrue,
          reason:
              '${file.path} questao ${model.index}: alternativa oficial deveria ser correta.',
        );

        for (final option
            in question.options.keys.where((key) => key != correct)) {
          expect(
            question.isCorrectAnswer(option),
            isFalse,
            reason:
                '${file.path} questao ${model.index}: alternativa $option deveria ser incorreta.',
          );
        }
      }
    }

    expect(validAnswerKeyCount, greaterThan(3000));
    expect(importableQuestionCount, greaterThan(0));
  });
}
