import '../entities/attempt.dart';
import '../repositories/i_attempt_repository.dart';

class SaveAttempt {
  SaveAttempt(this._attemptRepository);

  final IAttemptRepository _attemptRepository;

  Future<int> call(Attempt attempt) async {
    // O repositório grava tentativa, totais, estatísticas e progresso em uma
    // única transação SQLite; não deixe estados parcialmente persistidos.
    return _attemptRepository.saveAttempt(attempt);
  }
}
