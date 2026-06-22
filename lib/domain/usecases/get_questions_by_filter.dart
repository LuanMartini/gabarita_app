import '../entities/question.dart';
import '../repositories/i_question_repository.dart';

class GetQuestionsByFilter {
  GetQuestionsByFilter(this._questionRepository);

  final IQuestionRepository _questionRepository;

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
