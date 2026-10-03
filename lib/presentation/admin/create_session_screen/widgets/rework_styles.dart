import 'package:flutter/material.dart';

/// Paleta y medidas EXACTAS del diseño aprobado
/// (https://claude.ai/artifact/LCe4zJBahnR9ANFQmjGjvu) — a propósito no usa
/// `Theme.of(context).colorScheme` (que generaría tonos M3 distintos, más
/// claros/oscuros según el algoritmo HCT): el pedido fue 1:1 con el mockup,
/// no "inspirado en". Si el diseño cambia, actualizar solo este archivo.
class RW {
  RW._();

  // ---- superficies ----
  static const page = Color(0xFF0F0D13);
  static const rail = Color(0xFF1D1B20);
  static const card = Color(0xFF1D1B20);
  static const panel = Color(0xFF272530);
  static const surface = Color(0xFF141218);
  static const surfaceHigh = Color(0xFF322F3A);
  static const divider = Color(0xFF2B2930);
  static const outlineVariant = Color(0xFF49454E);

  // ---- texto ----
  static const onSurface = Color(0xFFE6E0E9);
  static const onSurfaceVariant = Color(0xFFCAC4CF);
  static const muted = Color(0xFF938F99);
  static const mutedMore = Color(0xFF78747E);
  static const mutedLocked = Color(0xFF625F6B);

  // ---- acento primario (lavanda) ----
  static const primary = Color(0xFFCFBCFF);
  static const onPrimary = Color(0xFF37008A);
  static const primaryContainer = Color(0xFF4F2DA7);
  static const onPrimaryContainer = Color(0xFFEADDFF);

  // ---- acentos por duración (timeline paso 1 "Horarios") ----
  static const accent30min = Color(0xFF8C6FD1);
  static const accent60min = primary;
  static const accent90min = Color(0xFFF3C969);

  // ---- acento "agregado en esta cancha" (paso 2 "Canchas") ----
  static const accentExtra = Color(0xFF5FD3A2);

  // ---- error / incidencias ----
  static const error = Color(0xFFFFB4AB);
  static const errorContainer = Color(0xFF4A3B1F);
  static const onErrorContainer = Color(0xFFF3C969);

  // ---- tipografía (tamaños, no familia — la app no fija una custom) ----
  static const tTitle = TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: onSurface);
  static const tSubtitle = TextStyle(fontSize: 12, color: muted);
  static const tPanelTitle = TextStyle(fontSize: 14, fontWeight: FontWeight.w700, color: onSurface);
  static const tPanelSubtitle = TextStyle(fontSize: 12, color: muted);
  static const tLabel = TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: onSurfaceVariant);
  static const tBody = TextStyle(fontSize: 12, color: onSurfaceVariant);
  static const tSmall = TextStyle(fontSize: 11, color: mutedMore);
  static const tChip = TextStyle(fontSize: 12, color: onSurfaceVariant);
  static const tStepLabel = TextStyle(fontSize: 13, color: onSurfaceVariant);
  static const tButton = TextStyle(fontSize: 13, fontWeight: FontWeight.w600);

  // ---- medidas ----
  static const double railWidth = 84;
  static const double cardRadius = 20;
  static const double panelRadius = 16;
  static const double surfaceRadius = 14;
  static const double columnRadius = 12;
  static const double blockRadius = 8;
  static const double blockRadiusSmall = 6;
  static const double buttonRadius = 4;
  static const double chipRadius = 999;
  static const double rowHeight = 52; // alto de cada hora en el timeline
  static const double hoursColumnWidth = 40;
  static const double rightPanelWidth = 400;
  static const double courtColumnWidth = 150;
  static const int firstHour = 8;
  static const int lastHour = 22; // exclusivo

  static Color accentForDuration(int minutes) {
    if (minutes <= 30) return accent30min;
    if (minutes <= 60) return accent60min;
    return accent90min;
  }
}
