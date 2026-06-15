// ============================================================
//  app_colors.dart
//  Gabarita · Paleta de cores oficial
// ============================================================

import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // ── Cores primárias ───────────────────────────────────────
  static const Color primary = Color(0xFF4F46E5);       // Indigo vibrante
  static const Color primaryLight = Color(0xFF818CF8);  // Indigo claro
  static const Color primaryDark = Color(0xFF3730A3);   // Indigo escuro
  static const Color accent = Color(0xFF10B981);        // Verde esmeralda (acerto)

  // ── Feedback ─────────────────────────────────────────────
  static const Color success = Color(0xFF22C55E);       // Verde acerto
  static const Color successLight = Color(0xFFDCFCE7);
  static const Color error = Color(0xFFEF4444);         // Vermelho erro
  static const Color errorLight = Color(0xFFFEE2E2);
  static const Color warning = Color(0xFFF59E0B);       // Amarelo atenção
  static const Color warningLight = Color(0xFFFEF3C7);

  // ── Neutros (Light Mode) ──────────────────────────────────
  static const Color background = Color(0xFFF8F7FF);    // Fundo levemente roxo
  static const Color surface = Color(0xFFFFFFFF);
  static const Color surfaceVariant = Color(0xFFF1F0FF); // Cards
  static const Color onBackground = Color(0xFF1E1B4B);  // Texto principal
  static const Color onSurface = Color(0xFF3730A3);
  static const Color textPrimary = Color(0xFF1E1B4B);
  static const Color textSecondary = Color(0xFF6B7280);
  static const Color textHint = Color(0xFF9CA3AF);
  static const Color divider = Color(0xFFE5E7EB);

  // ── Neutros (Dark Mode) ───────────────────────────────────
  static const Color backgroundDark = Color(0xFF0F0E1A);
  static const Color surfaceDark = Color(0xFF1A1830);
  static const Color surfaceVariantDark = Color(0xFF252340);
  static const Color textPrimaryDark = Color(0xFFEDE9FE);
  static const Color textSecondaryDark = Color(0xFFA78BFA);

  // ── Matérias (cores por disciplina) ──────────────────────
  static const Color subjectPortugues = Color(0xFF3B82F6);   // Azul
  static const Color subjectMatematica = Color(0xFFEF4444);  // Vermelho
  static const Color subjectHistoria = Color(0xFFF59E0B);    // Âmbar
  static const Color subjectGeografia = Color(0xFF10B981);   // Verde
  static const Color subjectBiologia = Color(0xFF8B5CF6);    // Roxo
  static const Color subjectQuimica = Color(0xFFEC4899);     // Rosa
  static const Color subjectFisica = Color(0xFF06B6D4);      // Ciano
  static const Color subjectIngles = Color(0xFFF97316);      // Laranja

  static const List<Color> subjectColors = [
    subjectPortugues,
    subjectMatematica,
    subjectHistoria,
    subjectGeografia,
    subjectBiologia,
    subjectQuimica,
    subjectFisica,
    subjectIngles,
  ];

  // ── Gradiente principal ───────────────────────────────────
  static const LinearGradient primaryGradient = LinearGradient(
    colors: [primary, primaryLight],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
