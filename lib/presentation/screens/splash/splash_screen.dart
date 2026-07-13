import 'dart:convert';
import 'dart:typed_data';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/questions_provider.dart';

// Logo minimo em base64.
// Esta imagem e um PNG 1x1 usado como base para exibir um simbolo colorido.
final Uint8List _logoBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mP8/x8AAwMCAO+/p9sAAAAASUVORK5CYII=',
);

// Tela: SplashScreen.
// Objetivo: mostrar a primeira tela enquanto o app prepara o banco local
// e depois navegar automaticamente para a tela principal.
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Evita navegar duas vezes se o Provider redesenhar a splash varias vezes.
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
  }

  void _navigateWhenReady(QuestionsProvider provider) {
    // Se ja navegou, nao faz nada.
    // Se o banco ainda esta sincronizando, espera mais um rebuild.
    if (_hasNavigated || (!provider.localBankReady && provider.isSyncingEnem)) {
      return;
    }

    // Marca como navegado antes de chamar Navigator para evitar duplicidade.
    _hasNavigated = true;

    // Navegacao e agendada para depois do frame atual.
    // Isso evita chamar Navigator no meio do build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        // pushReplacementNamed troca a Splash pela tela principal.
        // Assim o botao voltar nao retorna para a Splash.
        Navigator.of(context).pushReplacementNamed('/main');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    // Consumer observa o estado do banco local pelo QuestionsProvider.
    return Consumer<QuestionsProvider>(
      builder: (context, provider, _) {
        // A cada rebuild, verifica se ja pode sair da splash.
        _navigateWhenReady(provider);

        return Scaffold(
          backgroundColor: Colors.black,
          body: SafeArea(
            // Widget especial: LayoutBuilder.
            // Entrega as medidas disponiveis da tela. Aqui usamos a altura maxima
            // para montar uma Splash que ocupa a tela toda sem overflow.
            child: LayoutBuilder(
              builder: (context, constraints) {
                // Widget especial: SingleChildScrollView.
                // Se a tela for muito baixa, permite rolar o conteudo da splash.
                return SingleChildScrollView(
                  // Widget especial: ConstrainedBox.
                  // Forca altura minima igual a altura da tela para o layout
                  // continuar ocupando tudo mesmo com pouco conteudo.
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight,
                    ),
                    // Widget especial: IntrinsicHeight.
                    // Faz a Column calcular altura interna para os Spacers
                    // distribuirem os blocos verticalmente.
                    child: IntrinsicHeight(
                      child: Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(28),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                // Widget especial: Image.memory.
                                // Mostra uma imagem a partir de bytes em memoria.
                                // Aqui o logo esta embutido em base64.
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
                            // Widget especial: Spacer.
                            // Ocupa o espaco vazio disponivel e empurra os textos
                            // para ficarem visualmente distribuidos na tela.
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
                            // Outro Spacer para equilibrar o rodape da splash.
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
