import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

// O nome "gabarita_app" deve ser o mesmo que está na primeira linha do seu pubspec.yaml
import 'package:gabarita_app/main.dart'; 

void main() {
  testWidgets('Teste inicial de renderização da tela principal', (WidgetTester tester) async {
    // Constrói o nosso app com o nome atualizado
    await tester.pumpWidget(const GabaritaApp());

    // Verifica se a saudação da Home Screen aparece na tela
    expect(find.text('Bom dia, Lucas! 👋'), findsOneWidget);
  });
}