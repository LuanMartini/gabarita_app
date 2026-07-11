import 'dart:async';
import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';
import '../../providers/session_provider.dart';
import '../../providers/statistics_provider.dart';
import '../../providers/user_provider.dart';
import '../../../services/hardware/accelerometer_service.dart';
import '../../../services/hardware/gps_service.dart';
import '../../../services/hardware/study_place_service.dart';
import '../../../services/notifications/notification_service.dart';
import '../../../services/widgets/home_widget_service.dart';

class AnswerScreen extends StatefulWidget {
  const AnswerScreen({super.key});

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen> {
  final AccelerometerService _accelerometerService = AccelerometerService();
  final GpsService _gpsService = GpsService();
  final StudyPlaceService _studyPlaceService = StudyPlaceService();
  final NotificationService _notificationService = NotificationService();

  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _focusModeActive = false;

  @override
  void initState() {
    super.initState();
    _startTimer();
    _startFocusSensor();
  }

  @override
  void dispose() {
    _timer?.cancel();
    _accelerometerService.dispose();
    super.dispose();
  }

  void _startTimer() {
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _focusModeActive) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  Future<void> _startFocusSensor() async {
    try {
      await _accelerometerService.startListening(
        onChanged: (isFocusMode) {
          if (!mounted) return;
          setState(() {
            _focusModeActive = isFocusMode;
          });
        },
        onError: (_, __) {},
      );
    } catch (_) {
      // O sensor é um recurso opcional e não pode interromper o treino.
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuestionsProvider>(
      builder: (context, provider, _) {
        final question = provider.currentQuestion;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: Stack(
              children: [
                Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 18, 10),
                      child: Row(
                        children: [
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            child: LinearProgressIndicator(
                              value: provider.progress,
                              minHeight: 8,
                              borderRadius: const BorderRadius.all(
                                Radius.circular(8),
                              ),
                              backgroundColor: const Color(0xFF223044),
                              valueColor: const AlwaysStoppedAnimation<Color>(
                                Color(0xFF4DA3FF),
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(
                            _formattedTime,
                            style: const TextStyle(
                              color: Color(0xFFB6C2D1),
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Expanded(
                      child: question == null
                          ? const Center(
                              child: Text(
                                'Nenhuma questao selecionada.',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          : SingleChildScrollView(
                              padding: const EdgeInsets.fromLTRB(
                                18,
                                12,
                                18,
                                18,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    '${question.examSource ?? 'ENEM'} - ${question.subject}',
                                    style: const TextStyle(
                                      color: Color(0xFF4DA3FF),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  if (_hasQuestionImage(
                                    question.imagePath,
                                  )) ...[
                                    const SizedBox(height: 12),
                                    ClipRRect(
                                      borderRadius: BorderRadius.circular(8),
                                      child: Image.file(
                                        File(question.imagePath!),
                                        width: double.infinity,
                                        fit: BoxFit.cover,
                                      ),
                                    ),
                                  ],
                                  const SizedBox(height: 12),
                                  Container(
                                    width: double.infinity,
                                    padding: const EdgeInsets.all(20),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFF101822),
                                      borderRadius: BorderRadius.circular(8),
                                      border: Border.all(
                                        color: const Color(0xFF243449),
                                      ),
                                    ),
                                    child: MarkdownBody(
                                      data: _offlineMarkdown(question.text),
                                      selectable: true,
                                      styleSheet: _markdownStyle(
                                        context,
                                        fontSize: 18,
                                        textColor: Colors.white,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                  ),
                                  const SizedBox(height: 18),
                                  ListView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: question.options.entries.map((
                                      entry,
                                    ) {
                                      final selected =
                                          provider.selectedOption == entry.key;
                                      return GestureDetector(
                                        onTap: () {
                                          provider.selectAlternative(entry.key);
                                        },
                                        child: Container(
                                          margin: const EdgeInsets.only(
                                            bottom: 12,
                                          ),
                                          padding: const EdgeInsets.all(14),
                                          decoration: BoxDecoration(
                                            color: selected
                                                ? const Color(0xFF12395C)
                                                : const Color(0xFF0E131B),
                                            borderRadius: BorderRadius.circular(
                                              8,
                                            ),
                                            border: Border.all(
                                              color: selected
                                                  ? const Color(0xFF4DA3FF)
                                                  : const Color(0xFF213047),
                                            ),
                                          ),
                                          child: Row(
                                            children: [
                                              CircleAvatar(
                                                radius: 18,
                                                backgroundColor: selected
                                                    ? const Color(0xFF4DA3FF)
                                                    : const Color(0xFF1A2535),
                                                child: Text(
                                                  entry.key,
                                                  style: const TextStyle(
                                                    color: Colors.white,
                                                    fontWeight: FontWeight.w800,
                                                  ),
                                                ),
                                              ),
                                              const SizedBox(width: 14),
                                              Expanded(
                                                child: MarkdownBody(
                                                  data: entry.value.isEmpty
                                                      ? 'Alternativa sem texto'
                                                      : _offlineMarkdown(
                                                          entry.value,
                                                        ),
                                                  styleSheet: _markdownStyle(
                                                    context,
                                                    fontSize: 15,
                                                    textColor: Colors.white,
                                                  ),
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      );
                                    }).toList(),
                                  ),
                                ],
                              ),
                            ),
                    ),
                    Container(
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                      decoration: const BoxDecoration(
                        color: Colors.black,
                        border: Border(
                          top: BorderSide(color: Color(0xFF213047)),
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: provider.canConfirmAnswer
                            ? () => _confirmAnswer(provider)
                            : null,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF4DA3FF),
                          disabledBackgroundColor: const Color(0xFF26364A),
                          foregroundColor: Colors.white,
                          minimumSize: const Size(double.infinity, 52),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        child: Text(
                          provider.isSavingAnswer
                              ? 'Salvando...'
                              : 'Confirmar Resposta',
                        ),
                      ),
                    ),
                  ],
                ),
                if (_focusModeActive)
                  Container(
                    color: Colors.black.withValues(alpha: 0.82),
                    child: Center(
                      child: Container(
                        margin: const EdgeInsets.all(24),
                        padding: const EdgeInsets.all(22),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0E131B),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: const Color(0xFF4DA3FF)),
                        ),
                        child: const Text(
                          'Modo Foco Ativo\nCronometro pausado',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            height: 1.25,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Future<void> _confirmAnswer(QuestionsProvider provider) async {
    final userId = context.read<UserProvider>().userId;
    final sessionProvider = context.read<SessionProvider>();
    final question = provider.currentQuestion;
    final selectedOption = provider.selectedOption;
    final studyLocation = await _captureStudyLocation();
    final locationName = await _resolveStudyLocationName(studyLocation);

    if (sessionProvider.status == SessionStatus.inProgress &&
        question != null &&
        selectedOption != null) {
      final isCorrect = await sessionProvider.answerCurrentQuestion(
        userId: userId,
        selectedOption: selectedOption,
        timeTakenSeconds: _elapsedSeconds,
        latitude: studyLocation?.latitude,
        longitude: studyLocation?.longitude,
        locationName: locationName,
      );
      if (sessionProvider.errorMessage != null) return;
      provider.registerAnsweredFeedback(
        question: question,
        selectedOption: selectedOption,
        isCorrect: isCorrect,
      );
      await _refreshUserStats(userId);
      await _afterAttemptSaved(
        userId: userId,
        questionId: question.id,
        questionTopic: question.topic,
        isCorrect: isCorrect,
      );
      if (!mounted) return;
      Navigator.of(context).pushNamed('/feedback');
      return;
    }

    final feedback = await provider.confirmSelectedAnswer(
      userId: userId,
      timeTakenSeconds: _elapsedSeconds,
      latitude: studyLocation?.latitude,
      longitude: studyLocation?.longitude,
      locationName: locationName,
    );
    await _refreshUserStats(userId);
    if (!mounted || feedback == null) return;
    await _afterAttemptSaved(
      userId: userId,
      questionId: feedback.question.id,
      questionTopic: feedback.question.topic,
      isCorrect: feedback.isCorrect,
    );
    if (!mounted) return;
    Navigator.of(context).pushNamed('/feedback');
  }

  Future<StudyLocation?> _captureStudyLocation() async {
    try {
      return await _gpsService.getCurrentStudyLocation(
        timeLimit: const Duration(seconds: 4),
      );
    } catch (_) {
      return null;
    }
  }

  Future<String?> _resolveStudyLocationName(StudyLocation? location) async {
    try {
      return await _studyPlaceService.resolvePlaceName(location);
    } catch (_) {
      return null;
    }
  }

  Future<void> _afterAttemptSaved({
    required int userId,
    required int? questionId,
    required String questionTopic,
    required bool isCorrect,
  }) async {
    if (!isCorrect && questionId != null) {
      try {
        await _notificationService.scheduleWrongQuestionReview(
          questionId: questionId,
          questionTopic: questionTopic,
        );
      } catch (_) {}
    }
    try {
      await HomeWidgetService.refreshWidgets(userId: userId);
    } catch (_) {}
  }

  Future<void> _refreshUserStats(int userId) async {
    await Future.wait([
      context.read<UserProvider>().refresh(userId: userId),
      context.read<StatisticsProvider>().loadStatistics(userId),
    ]);
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  bool _hasQuestionImage(String? imagePath) {
    return imagePath != null &&
        imagePath.isNotEmpty &&
        File(imagePath).existsSync();
  }

  String _offlineMarkdown(String value) {
    return value.replaceAllMapped(
      RegExp(r'!\[[^\]]*\]\([^)]*\)'),
      (_) => '[Imagem indisponível no modo offline.]',
    );
  }

  MarkdownStyleSheet _markdownStyle(
    BuildContext context, {
    required double fontSize,
    required Color textColor,
    FontWeight fontWeight = FontWeight.w400,
  }) {
    final baseStyle = TextStyle(
      color: textColor,
      fontSize: fontSize,
      height: 1.35,
      fontWeight: fontWeight,
    );

    return MarkdownStyleSheet.fromTheme(Theme.of(context)).copyWith(
      p: baseStyle,
      strong: baseStyle.copyWith(fontWeight: FontWeight.w800),
      em: baseStyle.copyWith(fontStyle: FontStyle.italic),
      code: baseStyle.copyWith(
        color: const Color(0xFFE0ECFF),
        backgroundColor: const Color(0xFF182338),
        fontFamily: 'monospace',
      ),
      blockquote: baseStyle.copyWith(color: const Color(0xFFB6C2D1)),
      listBullet: baseStyle,
    );
  }
}
