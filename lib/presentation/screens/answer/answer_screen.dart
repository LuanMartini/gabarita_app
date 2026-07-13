import 'dart:async';

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

// Tela: AnswerScreen.
// Objetivo: mostrar uma questao, permitir escolher alternativa e confirmar.
// Tambem integra recursos extras:
// - acelerometro para Modo Foco;
// - cronometro local;
// - GPS para registrar local de estudo;
// - notificacao de revisao quando o aluno erra;
// - atualizacao de estatisticas e widgets.
class AnswerScreen extends StatefulWidget {
  const AnswerScreen({super.key});

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen> {
  // Bloco 1 - servicos usados nesta tela.
  // A tela combina sensor, GPS, notificacao e widgets externos.
  final AccelerometerService _accelerometerService = AccelerometerService();
  final GpsService _gpsService = GpsService();
  final StudyPlaceService _studyPlaceService = StudyPlaceService();
  final NotificationService _notificationService = NotificationService();

  // Bloco 2 - estado local do tempo de resposta
  Timer? _timer;
  int _elapsedSeconds = 0;
  bool _focusModeActive = false;

  @override
  void initState() {
    super.initState();
    // Bloco 3 - ao abrir a tela, inicia cronometro e acelerometro.
    _startTimer();
    _startFocusSensor();
  }

  @override
  void dispose() {
    // Bloco 4 - ao sair, cancela timer e libera sensor.
    _timer?.cancel();
    _accelerometerService.dispose();
    super.dispose();
  }

  // Bloco 5 - cronometro da questao.
  void _startTimer() {
    // Bloco 5.1 - incrementa a cada segundo enquanto nao esta em modo foco.
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted || _focusModeActive) return;
      setState(() {
        _elapsedSeconds++;
      });
    });
  }

  // Bloco 6 - inicia sensor do modo foco.
  Future<void> _startFocusSensor() async {
    try {
      // Bloco 6.1 - quando o celular vira para baixo, ativa overlay e pausa tempo.
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
    // Bloco 7 - escuta o QuestionsProvider para redesenhar a tela.
    // Alternativa selecionada, questao atual e progresso saem desse provider.
    return Consumer<QuestionsProvider>(
      builder: (context, provider, _) {
        // Bloco 8 - questao que sera exibida agora.
        final question = provider.currentQuestion;

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            // Widget especial: Stack.
            // Permite colocar widgets uns por cima dos outros. Aqui o conteudo
            // principal fica embaixo e o overlay de "Modo Foco" aparece por cima.
            child: Stack(
              children: [
                // Bloco 9 - conteudo principal: cabecalho, enunciado, alternativas e botao.
                Column(
                  children: [
                    // Bloco 10 - cabecalho com voltar, barra de progresso e cronometro.
                    Padding(
                      padding: const EdgeInsets.fromLTRB(8, 12, 18, 10),
                      child: Row(
                        children: [
                          // Widget especial: IconButton.
                          // Botao compacto que usa apenas um icone. Aqui volta
                          // para a tela anterior.
                          IconButton(
                            onPressed: () => Navigator.of(context).pop(),
                            icon: const Icon(
                              Icons.arrow_back,
                              color: Colors.white,
                            ),
                          ),
                          Expanded(
                            // Widget especial: LinearProgressIndicator.
                            // Mostra quanto da lista/sessao de questoes ja foi
                            // percorrido pelo aluno.
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
                          // Bloco 11 - caso nenhum item tenha sido selecionado.
                          ? const Center(
                              child: Text(
                                'Nenhuma questao selecionada.',
                                style: TextStyle(color: Colors.white),
                              ),
                            )
                          // Bloco 12 - area rolavel com enunciado e alternativas.
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
                                  // Bloco 13 - mostra prova/origem e materia.
                                  Text(
                                    '${question.examSource ?? 'ENEM'} - ${question.subject}',
                                    style: const TextStyle(
                                      color: Color(0xFF4DA3FF),
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  // Bloco 14 - caixa do enunciado da questao.
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
                                    // Widget especial: MarkdownBody.
                                    // Renderiza texto com Markdown, permitindo
                                    // negrito, listas, codigo e formulas textuais.
                                    child: MarkdownBody(
                                      // Bloco 14.1 - limpa imagens para manter uso offline.
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
                                  // Bloco 15 - lista das alternativas clicaveis.
                                  ListView(
                                    shrinkWrap: true,
                                    physics:
                                        const NeverScrollableScrollPhysics(),
                                    children: question.options.entries.map((
                                      entry,
                                    ) {
                                      // Bloco 15.1 - verifica se essa alternativa e a selecionada.
                                      final selected =
                                          provider.selectedOption == entry.key;
                                      // Widget especial: GestureDetector.
                                      // Transforma o Container inteiro da alternativa
                                      // em area clicavel, nao apenas o texto.
                                      return GestureDetector(
                                        onTap: () {
                                          // Bloco 15.2 - grava alternativa escolhida no provider.
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
                                              // Widget especial: CircleAvatar.
                                              // Aqui vira um circulo com a letra
                                              // da alternativa: A, B, C, D ou E.
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
                                                // Widget especial: MarkdownBody.
                                                // Tambem permite renderizar as
                                                // alternativas com texto rico.
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
                    // Bloco 16 - rodape fixo com botao de confirmar resposta.
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
                            // Bloco 16.1 - so confirma se existe alternativa selecionada.
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
                // Bloco 17 - overlay do Modo Foco ativado pelo acelerometro.
                if (_focusModeActive)
                  // Widget especial: Container sobreposto pelo Stack.
                  // Como fica depois da Column na lista do Stack, aparece por cima
                  // da questao e bloqueia a interacao enquanto o modo foco esta ativo.
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
    // Bloco 18 - coleta dados necessarios para salvar a tentativa.
    final userId = context.read<UserProvider>().userId;
    final sessionProvider = context.read<SessionProvider>();
    final question = provider.currentQuestion;
    final selectedOption = provider.selectedOption;

    // Bloco 19 - tenta registrar local de estudo junto com a resposta.
    final studyLocation = await _captureStudyLocation();
    final locationName = await _resolveStudyLocationName(studyLocation);

    // Bloco 20 - detecta se a resposta pertence a um simulado ativo.
    final shouldAnswerActiveSimulado =
        sessionProvider.status == SessionStatus.inProgress &&
            sessionProvider.isCurrentQuestion(question) &&
            selectedOption != null;

    if (shouldAnswerActiveSimulado && question != null) {
      // Bloco 21 - fluxo de resposta dentro de simulado.
      final isCorrect = await sessionProvider.answerCurrentQuestion(
        userId: userId,
        selectedOption: selectedOption,
        expectedQuestionId: question.id,
        timeTakenSeconds: _elapsedSeconds,
        latitude: studyLocation?.latitude,
        longitude: studyLocation?.longitude,
        locationName: locationName,
      );
      if (sessionProvider.errorMessage != null) return;

      // Bloco 22 - registra feedback no QuestionsProvider para a proxima tela.
      provider.registerAnsweredFeedback(
        question: question,
        selectedOption: selectedOption,
        isCorrect: isCorrect,
      );

      // Bloco 23 - atualiza perfil, estatisticas, widgets e notificacao.
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

    // Bloco 24 - fluxo de treino livre, fora de simulado.
    final feedback = await provider.confirmSelectedAnswer(
      userId: userId,
      timeTakenSeconds: _elapsedSeconds,
      latitude: studyLocation?.latitude,
      longitude: studyLocation?.longitude,
      locationName: locationName,
    );

    // Bloco 25 - atualiza estatisticas depois de salvar a tentativa.
    await _refreshUserStats(userId);
    if (!mounted || feedback == null) return;

    // Bloco 26 - acoes pos-resposta: revisao se errou e home widgets.
    await _afterAttemptSaved(
      userId: userId,
      questionId: feedback.question.id,
      questionTopic: feedback.question.topic,
      isCorrect: feedback.isCorrect,
    );
    if (!mounted) return;
    Navigator.of(context).pushNamed('/feedback');
  }

  // Bloco 27 - captura GPS com timeout curto para nao travar a resposta.
  Future<StudyLocation?> _captureStudyLocation() async {
    try {
      return await _gpsService.getCurrentStudyLocation(
        timeLimit: const Duration(seconds: 4),
      );
    } catch (_) {
      return null;
    }
  }

  // Bloco 28 - transforma coordenadas em nome/local agrupado.
  Future<String?> _resolveStudyLocationName(StudyLocation? location) async {
    try {
      return await _studyPlaceService.resolvePlaceName(location);
    } catch (_) {
      return null;
    }
  }

  // Bloco 29 - acoes feitas depois que a tentativa ja foi salva.
  Future<void> _afterAttemptSaved({
    required int userId,
    required int? questionId,
    required String questionTopic,
    required bool isCorrect,
  }) async {
    // Bloco 29.1 - se errou, agenda notificacao de revisao.
    if (!isCorrect && questionId != null) {
      try {
        await _notificationService.scheduleWrongQuestionReview(
          questionId: questionId,
          questionTopic: questionTopic,
        );
      } catch (_) {}
    }
    // Bloco 29.2 - atualiza widgets da tela inicial.
    try {
      await HomeWidgetService.refreshWidgets(userId: userId);
    } catch (_) {}
  }

  // Bloco 30 - recarrega perfil e estatisticas em paralelo.
  Future<void> _refreshUserStats(int userId) async {
    await Future.wait([
      context.read<UserProvider>().refresh(userId: userId),
      context.read<StatisticsProvider>().loadStatistics(userId),
    ]);
  }

  // Bloco 31 - transforma segundos em texto mm:ss.
  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }

  // Bloco 32 - remove imagens markdown porque o app usa questoes offline textuais.
  String _offlineMarkdown(String value) {
    return value.replaceAllMapped(
      RegExp(r'!\[[^\]]*\]\([^)]*\)'),
      (_) => '[Imagem indisponível no modo offline.]',
    );
  }

  // Bloco 33 - padrao visual para textos em Markdown.
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
