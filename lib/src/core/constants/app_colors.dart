import 'package:flutter/material.dart';

/// Paleta de colores centralizada para serpiente.io.
/// Diseño premium dark con acentos neon.
class AppColors {
  AppColors._();

  // ── Fondos ────────────────────────────────────────────────────────────────
  static const Color backgroundStart = Color(0xFF0B1120);
  static const Color backgroundEnd   = Color(0xFF101D38);
  static const Color surface         = Color(0xFF162035);
  static const Color cardBackground  = Color(0xFF1A2B48);

  // ── Acentos / Neon ────────────────────────────────────────────────────────
  static const Color accent     = Color(0xFF22C55E);  // verde neon
  static const Color accentSoft = Color(0xFF4ADE80);  // verde suave
  static const Color neonCyan   = Color(0xFF00F5FF);  // cyan neon
  static const Color neonOrange = Color(0xFFFF6B00);  // naranja boost
  static const Color neonRed    = Color(0xFFFF2D55);  // rojo peligro
  static const Color neonPurple = Color(0xFFA855F7);  // morado accent

  // ── Texto ─────────────────────────────────────────────────────────────────
  static const Color textPrimary   = Color(0xFFF0F4FF);
  static const Color textSecondary = Color(0xFF8BA3C7);
  static const Color textMuted     = Color(0xFF4D6A8A);

  // ── Bordes y separadores ──────────────────────────────────────────────────
  static const Color border       = Color(0xFF2C4570);
  static const Color borderAccent = Color(0xFF22C55E);

  // ── HUD del juego ─────────────────────────────────────────────────────────
  static const Color hudBackground = Color(0x99101D38);  // semi-transparente
  static const Color hudBorder     = Color(0x4422C55E);  // verde con alpha
}
