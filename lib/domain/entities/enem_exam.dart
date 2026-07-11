class EnemExam {
  const EnemExam({
    required this.title,
    required this.year,
    required this.disciplines,
    required this.languages,
  });

  final String title;
  final int year;
  final List<EnemOption> disciplines;
  final List<EnemOption> languages;
}

class EnemOption {
  const EnemOption({
    required this.label,
    required this.value,
  });

  final String label;
  final String value;
}

class EnemQuestionSyncResult {
  const EnemQuestionSyncResult({
    required this.year,
    required this.imported,
    required this.updated,
    required this.skipped,
    required this.totalFetched,
  });

  final int year;
  final int imported;
  final int updated;
  final int skipped;
  final int totalFetched;
}

class LocalEnemBankSyncResult {
  const LocalEnemBankSyncResult({
    required this.imported,
    required this.updated,
    required this.skipped,
    required this.totalFetched,
    required this.years,
    required this.didImport,
  });

  final int imported;
  final int updated;
  final int skipped;
  final int totalFetched;
  final List<int> years;
  final bool didImport;

  int get saved => imported + updated;
}
