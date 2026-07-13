import '../entities/question.dart';
import '../repositories/i_question_repository.dart';

// Bloco 1 - caso de uso para buscar questoes filtradas.
// A tela manda busca, disciplina, ano, favoritos etc.; este caso de uso
// encaminha para o contrato do repositorio.
class GetQuestionsByFilter {
  // Bloco 2 - recebe a interface, nao a implementacao concreta.
  GetQuestionsByFilter(this._questionRepository);

  final IQuestionRepository _questionRepository;

  // Bloco 3 - call centraliza os parametros de filtro usados pela UI.
  Future<List<Question>> call({
    String? subject,
    String? vestibular,
    List<String>? subjects,
    List<int>? difficulties,
    String? examSource,
    bool favoritesOnly = false,
    String? searchText,
    int? limit,
  }) {
    // Bloco 4 - delega a busca ao repositorio.
    // A regra de onde buscar e como montar SQL nao fica no Provider.
    return _questionRepository.getQuestionsByFilter(
      subject: subject,
      vestibular: vestibular,
      subjects: subjects,
      difficulties: difficulties,
      examSource: examSource,
      favoritesOnly: favoritesOnly,
      searchText: searchText,
      limit: limit,
    );
  }
}
