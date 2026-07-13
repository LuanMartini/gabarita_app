import '../entities/attempt.dart';
import '../repositories/i_attempt_repository.dart';

// Bloco 1 - caso de uso para salvar uma resposta do usuario.
// Uma "tentativa" registra qual questao foi respondida, qual alternativa foi
// marcada, se acertou e quanto tempo levou.
class SaveAttempt {
  // Bloco 2 - recebe a interface do repositorio de tentativas.
  SaveAttempt(this._attemptRepository);

  final IAttemptRepository _attemptRepository;

  // Bloco 3 - grava a tentativa.
  // O repositorio tambem atualiza estatisticas, progresso e ofensiva.
  Future<int> call(Attempt attempt) async {
    // Bloco 4 - a implementacao grava tudo em uma transacao SQLite.
    // Assim nao existe estado pela metade: ou salva tentativa + stats, ou falha.
    return _attemptRepository.saveAttempt(attempt);
  }
}
