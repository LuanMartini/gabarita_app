import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';

final Uint8List _logoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
);

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
  }

  void _navigateWhenReady(QuestionsProvider provider) {
    if (_hasNavigated || (!provider.localBankReady && provider.isSyncingEnem)) {
      return;
    }

    _hasNavigated = true;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<QuestionsProvider>(
      builder: (context, provider, _) {
        _navigateWhenReady(provider);

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    child: IntrinsicHeight(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Image.memory(
                                  _logoBytes,
                                  width: 56,
                                  height: 56,
                                  color: const Color(0xFF4DA3FF),
                                ),
                                const SizedBox(width: 14),
                                const Text(
                                  'Gabarita',
                                  style: TextStyle(
                                    color: Colors.white,
                                    fontSize: 30,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ],
                            ),
                            const Spacer(),
                            const Text(
                              'Seu treino offline para questoes, simulados e revisao inteligente.',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 34,
                                fontWeight: FontWeight.w800,
                                height: 1.08,
                              ),
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Dados locais. Foco real. Evolucao visivel.',
                              style: TextStyle(
                                color: Color(0xFFB6C2D1),
                                fontSize: 16,
                                height: 1.35,
                              ),
                            ),
                            const Spacer(),
                            Row(
                              children: [
                                Text(
                                  provider.isSyncingEnem
                                      ? 'Preparando banco local de questões'
                                      : 'Carregando ambiente de estudo',
                                  style: const TextStyle(
                                    color: Color(0xFF8EA4BE),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const Spacer(),
                                const Text(
                                  '100% offline',
                                  style: TextStyle(
                                    color: Color(0xFF4DA3FF),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ),
        );
      },
    );
  }
}
