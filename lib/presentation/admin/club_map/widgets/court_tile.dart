import 'dart:math' as math;

import 'package:flutter/material.dart';

/// Líneas de juego que se dibujan según el deporte.
enum CourtLines { padel, football, tennis, volleyball, basketball, none }

/// Color y líneas de cada deporte (por `club_type_id`).
class SportStyle {
  final Color fill;
  final CourtLines lines;

  const SportStyle(this.fill, this.lines);

  static SportStyle of(int clubTypeId) {
    switch (clubTypeId) {
      case 10:
        return const SportStyle(Color(0xFF2A5FA3), CourtLines.padel);
      case 20:
        return const SportStyle(Color(0xFF2E7A47), CourtLines.football);
      case 30:
        return const SportStyle(Color(0xFFB5532F), CourtLines.tennis);
      case 40:
        return const SportStyle(Color(0xFF6F7F8F), CourtLines.none);
      case 50:
        return const SportStyle(Color(0xFF9A7413), CourtLines.volleyball);
      case 60:
        return const SportStyle(Color(0xFF7B5EA7), CourtLines.basketball);
      default:
        return const SportStyle(Color(0xFF5F6B7A), CourtLines.none);
    }
  }
}

const _coveredBorder = Color(0xFF2B2440);

/// Escala de uso (un solo tono, de claro a oscuro), en 5 tramos de 20 %.
/// Validada contra el piso del plano (#FBFAF7), que es claro en los dos
/// temas: el tramo más claro llega a 2:1.
class UsageScale {
  static const steps = [Color(0xFF86B6EF), Color(0xFF5598E7), Color(0xFF2A78D6), Color(0xFF1C5CAB), Color(0xFF0D366B)];

  /// Cancha sin turnos en el período.
  static const none = Color(0xFFB9B6AE);

  static const labels = ['0–20 %', '20–40 %', '40–60 %', '60–80 %', '80–100 %'];

  static Color colorOf(double? usage) {
    if (usage == null) return none;
    final index = (usage * steps.length).floor().clamp(0, steps.length - 1);
    return steps[index];
  }
}

/// Estado en vivo de una cancha en el mapa del club.
enum CourtLiveStatus {
  free('Libre', Color(0xFF1E8E3E)),
  occupied('Ocupada', Color(0xFFC5221F));

  final String label;
  final Color color;

  const CourtLiveStatus(this.label, this.color);
}

/// Una cancha dibujada a escala: color del deporte, líneas, rayado de techo
/// si es techada, y su nombre.
class CourtTile extends StatelessWidget {
  final String name;
  final SportStyle style;
  final bool isCover;
  final double width;
  final double height;

  /// Anillo alrededor: seleccionada (primario) o con problema (error).
  final Color? ringColor;

  /// Libre u ocupada ahora. `null`: no se muestra (ej. en el editor).
  final CourtLiveStatus? liveStatus;

  /// Vista de uso: la cancha se pinta con este color (sin líneas de juego)
  /// y muestra [usageLabel] al centro.
  final Color? usageColor;
  final String? usageLabel;

  const CourtTile({
    super.key,
    required this.name,
    required this.style,
    required this.isCover,
    required this.width,
    required this.height,
    this.ringColor,
    this.liveStatus,
    this.usageColor,
    this.usageLabel,
  });

  @override
  Widget build(BuildContext context) {
    final borderWidth = isCover ? 3.0 : 2.0;
    final showBadge = width >= 64 && height >= 44;
    final showName = width >= 44 && height >= 28;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: usageColor ?? style.fill,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: isCover ? _coveredBorder : Colors.white, width: borderWidth),
        boxShadow: [
          if (ringColor != null) ...[
            BoxShadow(color: Theme.of(context).colorScheme.surface, spreadRadius: 3),
            BoxShadow(color: ringColor!, spreadRadius: 6),
          ] else if (isCover)
            const BoxShadow(color: Color(0x40000000), blurRadius: 3, offset: Offset(0, 1)),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(2),
        child: Stack(
          children: [
            if (usageColor == null) Positioned.fill(child: CustomPaint(painter: CourtLinesPainter(style.lines))),
            if (isCover) const Positioned.fill(child: CustomPaint(painter: RoofStripesPainter())),
            // El % va arriba del rayado de techada.
            if (usageLabel != null)
              Center(
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(4)),
                  child: Text(usageLabel!, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: Color(0xFF1D1B20))),
                ),
              ),
            if (showBadge) Positioned(left: 4, top: 4, child: _Badge(isCover: isCover)),
            if (liveStatus != null) Positioned(right: 4, top: 4, child: _LiveStatusBadge(status: liveStatus!, compact: width < 150)),
            if (showName)
              Positioned(
                left: 2,
                right: 2,
                bottom: 6,
                child: Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(color: const Color(0xFF1D1B20), borderRadius: BorderRadius.circular(4)),
                    child: Text(
                      name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w500),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final bool isCover;

  const _Badge({required this.isCover});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(4, 2, 6, 2),
      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(isCover ? Icons.roofing : Icons.wb_sunny_outlined, size: 12, color: const Color(0xFF1D1B20)),
          const SizedBox(width: 3),
          Text(
            isCover ? 'Techada' : 'Descubierta',
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: Color(0xFF1D1B20)),
          ),
        ],
      ),
    );
  }
}

/// Espacio del predio que no es una cancha (entrada, bar...): gris claro,
/// con el ícono del tipo y su nombre si entra.
class SpaceTile extends StatelessWidget {
  final String type;
  final String name;
  final double width;
  final double height;

  /// Anillo alrededor: seleccionado (primario) o con problema (error).
  final Color? ringColor;

  const SpaceTile({super.key, required this.type, required this.name, required this.width, required this.height, this.ringColor});

  static IconData iconOf(String type) {
    switch (type) {
      case 'ENTRANCE':
        return Icons.door_front_door_outlined;
      case 'LOCKER_ROOM':
        return Icons.checkroom;
      case 'BATHROOM':
        return Icons.wc;
      case 'BAR':
        return Icons.local_cafe_outlined;
      case 'PARKING':
        return Icons.local_parking;
      case 'STREET':
        return Icons.add_road;
      default:
        return Icons.crop_square;
    }
  }

  @override
  Widget build(BuildContext context) {
    const ink = Color(0xFF49454F);
    final showName = width >= 56 && height >= 34;
    final showIcon = width >= 18 && height >= 18;

    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        // La calle es una referencia de afuera: gris asfalto, para que no se
        // confunda con un espacio del club.
        color: type == 'STREET' ? const Color(0xFFCFCFCF) : const Color(0xFFE9E5DD),
        borderRadius: BorderRadius.circular(3),
        border: Border.all(color: type == 'STREET' ? const Color(0xFF8E8E8E) : const Color(0xFF9C968A), width: 1.5),
        boxShadow: [
          if (ringColor != null) ...[
            BoxShadow(color: Theme.of(context).colorScheme.surface, spreadRadius: 3),
            BoxShadow(color: ringColor!, spreadRadius: 6),
          ],
        ],
      ),
      child: !showIcon
          ? null
          : Center(
              child: Padding(
                padding: const EdgeInsets.all(2),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(iconOf(type), size: 16, color: ink),
                    if (showName)
                      Text(
                        name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500, color: ink),
                      ),
                  ],
                ),
              ),
            ),
    );
  }
}

/// Libre / Ocupada arriba a la derecha. En canchas chicas, solo el punto.
class _LiveStatusBadge extends StatelessWidget {
  final CourtLiveStatus status;
  final bool compact;

  const _LiveStatusBadge({required this.status, required this.compact});

  @override
  Widget build(BuildContext context) {
    final dot = Container(
      width: 10,
      height: 10,
      decoration: BoxDecoration(color: status.color, shape: BoxShape.circle),
    );

    return Tooltip(
      message: status.label,
      child: Container(
        padding: compact ? const EdgeInsets.all(3) : const EdgeInsets.fromLTRB(5, 2, 7, 2),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.94), borderRadius: BorderRadius.circular(999)),
        child: compact
            ? dot
            : Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  dot,
                  const SizedBox(width: 4),
                  Text(
                    status.label,
                    style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: Color(0xFF1D1B20)),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Rayado diagonal que marca una cancha techada.
class RoofStripesPainter extends CustomPainter {
  const RoofStripesPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = const Color(0x3D100C28)
      ..strokeWidth = 6;
    for (double d = -size.height; d < size.width; d += 14) {
      canvas.drawLine(Offset(d, size.height), Offset(d + size.height, 0), paint);
    }
  }

  @override
  bool shouldRepaint(covariant RoofStripesPainter oldDelegate) => false;
}

/// Líneas de juego. Se dibujan con el largo en horizontal y se giran si la
/// cancha está vertical.
class CourtLinesPainter extends CustomPainter {
  final CourtLines lines;

  const CourtLinesPainter(this.lines);

  @override
  void paint(Canvas canvas, Size size) {
    if (lines == CourtLines.none) return;

    final vertical = size.height > size.width;
    final len = vertical ? size.height : size.width;
    final wid = vertical ? size.width : size.height;

    canvas.save();
    if (vertical) {
      canvas.translate(size.width, 0);
      canvas.rotate(math.pi / 2);
    }

    final line = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = 2
      ..style = PaintingStyle.stroke;
    final net = Paint()
      ..color = Colors.white.withValues(alpha: 0.88)
      ..strokeWidth = 4;

    void across(double x, [Paint? p]) => canvas.drawLine(Offset(x, 0), Offset(x, wid), p ?? line);

    switch (lines) {
      case CourtLines.padel:
        final s1 = len * 0.1525, s2 = len - s1;
        across(len / 2, net);
        across(s1);
        across(s2);
        canvas.drawLine(Offset(s1, wid / 2), Offset(s2, wid / 2), line);
      case CourtLines.tennis:
        final alley = wid * 0.125, sv1 = len * 0.231, sv2 = len - sv1;
        across(len / 2, net);
        canvas.drawLine(Offset(0, alley), Offset(len, alley), line);
        canvas.drawLine(Offset(0, wid - alley), Offset(len, wid - alley), line);
        canvas.drawLine(Offset(sv1, alley), Offset(sv1, wid - alley), line);
        canvas.drawLine(Offset(sv2, alley), Offset(sv2, wid - alley), line);
        canvas.drawLine(Offset(sv1, wid / 2), Offset(sv2, wid / 2), line);
      case CourtLines.football:
        final areaL = len * 0.12, areaW = wid * 0.44;
        across(len / 2);
        canvas.drawCircle(Offset(len / 2, wid / 2), wid * 0.18, line);
        canvas.drawRect(Rect.fromLTWH(0, (wid - areaW) / 2, areaL, areaW), line);
        canvas.drawRect(Rect.fromLTWH(len - areaL, (wid - areaW) / 2, areaL, areaW), line);
      case CourtLines.volleyball:
        across(len / 2, net);
        across(len / 2 - len / 6);
        across(len / 2 + len / 6);
      case CourtLines.basketball:
        final keyL = len * 0.2, keyW = wid * 0.33;
        across(len / 2);
        canvas.drawCircle(Offset(len / 2, wid / 2), wid * 0.12, line);
        canvas.drawRect(Rect.fromLTWH(0, (wid - keyW) / 2, keyL, keyW), line);
        canvas.drawRect(Rect.fromLTWH(len - keyL, (wid - keyW) / 2, keyL, keyW), line);
        final r = wid * 0.45;
        canvas.drawArc(Rect.fromCircle(center: Offset(len * 0.056, wid / 2), radius: r), -math.pi / 2, math.pi, false, line);
        canvas.drawArc(Rect.fromCircle(center: Offset(len - len * 0.056, wid / 2), radius: r), math.pi / 2, math.pi, false, line);
      case CourtLines.none:
        break;
    }

    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CourtLinesPainter oldDelegate) => oldDelegate.lines != lines;
}
