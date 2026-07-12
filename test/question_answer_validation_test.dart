import 'package:flutter_test/flutter_test.dart';
import 'package:gabarita_app/domain/entities/question.dart';

void main() {
  final question = Question(
    text: 'Enunciado',
    subject: 'Matematica',
    topic: 'Topico',
    optionA: 'A',
    optionB: 'B',
    optionC: 'C',
    optionD: 'D',
    correctOption: ' b ',
  );

  test('normaliza a alternativa antes de corrigir a resposta', () {
    expect(question.isCorrectAnswer(' B '), isTrue);
    expect(question.isCorrectAnswer('a'), isFalse);
    expect(question.normalizedCorrectOption, 'B');
    expect(question.correctAlternativeIndex, 1);
  });
}
