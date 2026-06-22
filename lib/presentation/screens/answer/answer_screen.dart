import 'dart:async';

import 'package:flutter/material.dart';

import '../../../services/hardware/accelerometer_service.dart';

class AnswerScreen extends StatefulWidget {
  const AnswerScreen({super.key});

  @override
  State<AnswerScreen> createState() => _AnswerScreenState();
}

class _AnswerScreenState extends State<AnswerScreen> {
  final AccelerometerService _accelerometerService = AccelerometerService();
  final List<_AnswerOption> _options = const [
    _AnswerOption(letter: 'A', text: 'Movimento Abolicionista'),
    _AnswerOption(letter: 'B', text: 'Inconfidencia Mineira'),
    _AnswerOption(letter: 'C', text: 'Revolucao Farroupilha'),
    _AnswerOption(letter: 'D', text: 'Guerra do Paraguai'),
  ];

  Timer? _timer;
  String? _selectedOption;
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
    await _accelerometerService.startListening(
      onChanged: (isFocusMode) {
        if (!mounted) return;
        setState(() {
          _focusModeActive = isFocusMode;
        });
      },
      onError: (_, __) {},
    );
  }

  @override
  Widget build(BuildContext context) {
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
                      const Expanded(
                        child: LinearProgressIndicator(
                          value: 0.35,
                          minHeight: 8,
                          borderRadius: BorderRadius.all(Radius.circular(8)),
                          backgroundColor: Color(0xFF223044),
                          valueColor: AlwaysStoppedAnimation<Color>(
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
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
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
                          child: const Text(
                            'Qual foi o principal movimento historico responsavel pela abolicao da escravatura no Brasil?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 21,
                              height: 1.3,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 18),
                        ListView.builder(
                          shrinkWrap: true,
                          physics: const NeverScrollableScrollPhysics(),
                          itemCount: _options.length,
                          itemBuilder: (context, index) {
                            final option = _options[index];
                            final selected = _selectedOption == option.letter;

                            return GestureDetector(
                              onTap: () {
                                setState(() {
                                  _selectedOption = option.letter;
                                });
                              },
                              child: Container(
                                margin: const EdgeInsets.only(bottom: 12),
                                padding: const EdgeInsets.all(14),
                                decoration: BoxDecoration(
                                  color: selected
                                      ? const Color(0xFF12395C)
                                      : const Color(0xFF0E131B),
                                  borderRadius: BorderRadius.circular(8),
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
                                        option.letter,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.w800,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 14),
                                    Expanded(
                                      child: Text(
                                        option.text,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 15,
                                          height: 1.3,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
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
                    onPressed: _selectedOption == null
                        ? null
                        : () => Navigator.of(context).pushNamed('/feedback'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4DA3FF),
                      disabledBackgroundColor: const Color(0xFF26364A),
                      foregroundColor: Colors.white,
                      minimumSize: const Size(double.infinity, 52),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    child: const Text('Confirmar Resposta'),
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
  }

  String get _formattedTime {
    final minutes = (_elapsedSeconds ~/ 60).toString().padLeft(2, '0');
    final seconds = (_elapsedSeconds % 60).toString().padLeft(2, '0');
    return '$minutes:$seconds';
  }
}

class _AnswerOption {
  const _AnswerOption({
    required this.letter,
    required this.text,
  });

  final String letter;
  final String text;
}
