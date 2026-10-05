import 'package:flutter/material.dart';

import '../../../../domain/entities/club_map/club_map.dart';
import 'court_tile.dart';

/// Escala (px por metro) para que el predio entre en el espacio disponible.
double planScale(int widthM, int heightM, double maxWidth, double maxHeight) {
  final byWidth = maxWidth / widthM;
  final byHeight = maxHeight / heightM;
  return byWidth < byHeight ? byWidth : byHeight;
}

/// El predio dibujado a escala, con la cuadrícula en metros, las canchas
/// ubicadas y los otros espacios (entrada, bar...). En modo edición se
/// arrastran.
class PlanCanvas extends StatefulWidget {
  final ClubMapView view;
  final int widthM;
  final int heightM;
  final List<ClubMapElement> elements;
  final List<ClubMapSpace> spaces;
  final double scale;
  final int? selectedCourtId;

  /// Posición en [spaces] del espacio seleccionado.
  final int? selectedSpaceIndex;
  final ClubMapIssues? issues;

  /// Libre u ocupada ahora, por cancha. `null`: no se muestra.
  final Map<int, CourtLiveStatus>? liveStatus;
  final ValueChanged<int>? onCourtTap;

  /// Edición: nueva posición (en metros) de una cancha arrastrada.
  final void Function(int courtId, int xM, int yM)? onCourtMoved;

  final ValueChanged<int>? onSpaceTap;

  /// Edición: nueva posición (en metros) de un espacio arrastrado.
  final void Function(int index, int xM, int yM)? onSpaceMoved;

  /// Toque en un lugar vacío del predio.
  final VoidCallback? onBackgroundTap;

  const PlanCanvas({
    super.key,
    required this.view,
    required this.widthM,
    required this.heightM,
    required this.elements,
    this.spaces = const [],
    required this.scale,
    this.selectedCourtId,
    this.selectedSpaceIndex,
    this.issues,
    this.liveStatus,
    this.onCourtTap,
    this.onCourtMoved,
    this.onSpaceTap,
    this.onSpaceMoved,
    this.onBackgroundTap,
  });

  @override
  State<PlanCanvas> createState() => _PlanCanvasState();
}

class _PlanCanvasState extends State<PlanCanvas> {
  int? _draggingId;
  int? _draggingSpace;
  Offset _dragStartM = Offset.zero;
  Offset _dragDeltaPx = Offset.zero;

  bool get _editable => widget.onCourtMoved != null;

  @override
  Widget build(BuildContext context) {
    final scale = widget.scale;
    final colors = Theme.of(context).colorScheme;

    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: widget.onBackgroundTap,
      child: SizedBox(
        width: widget.widthM * scale,
        height: widget.heightM * scale,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            Positioned.fill(
              child: CustomPaint(
                painter: PlanGridPainter(scale: scale, minorLines: _editable),
              ),
            ),
            // Los espacios van debajo de las canchas.
            for (var i = 0; i < widget.spaces.length; i++) _buildSpace(i, scale, colors),
            for (final element in _ordered()) _buildCourt(element, scale, colors),
          ],
        ),
      ),
    );
  }

  /// La cancha que se arrastra va arriba de las demás.
  List<ClubMapElement> _ordered() {
    final list = [...widget.elements];
    list.sort((a, b) {
      int rank(ClubMapElement e) => e.courtId == _draggingId ? 2 : (e.courtId == widget.selectedCourtId ? 1 : 0);
      return rank(a).compareTo(rank(b));
    });
    return list;
  }

  Widget _buildCourt(ClubMapElement element, double scale, ColorScheme colors) {
    final found = widget.view.findCourt(element.courtId);
    if (found == null) return const SizedBox.shrink();

    final fp = courtFootprint(widget.view.courtSizeOf(element.courtId), element.rotated);
    final hasIssue = widget.issues?.hasIssue(element.courtId) ?? false;
    final selected = widget.selectedCourtId == element.courtId;

    final tile = CourtTile(
      name: found.court.name,
      style: SportStyle.of(found.partition.clubTypeId),
      isCover: found.court.isCover,
      width: fp.w * scale,
      height: fp.h * scale,
      ringColor: hasIssue ? colors.error : (selected ? colors.primary : null),
      liveStatus: widget.liveStatus?[element.courtId],
    );

    final status = widget.liveStatus?[element.courtId];
    final label = [
      found.partition.sport,
      found.court.name,
      found.court.isCover ? 'techada' : 'descubierta',
      if (status != null) status.label.toLowerCase(),
    ].join(', ');

    return Positioned(
      left: element.xM * scale,
      top: element.yM * scale,
      child: Semantics(
        button: true,
        selected: selected,
        label: label,
        child: MouseRegion(
          cursor: _editable ? (_draggingId == element.courtId ? SystemMouseCursors.grabbing : SystemMouseCursors.grab) : SystemMouseCursors.click,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onCourtTap == null ? null : () => widget.onCourtTap!(element.courtId),
            onPanStart: _editable
                ? (_) {
                    widget.onCourtTap?.call(element.courtId);
                    setState(() {
                      _draggingId = element.courtId;
                      _dragStartM = Offset(element.xM.toDouble(), element.yM.toDouble());
                      _dragDeltaPx = Offset.zero;
                    });
                  }
                : null,
            onPanUpdate: _editable
                ? (details) {
                    _dragDeltaPx += details.delta;
                    final target = _dragStartM + _dragDeltaPx / scale;
                    final pos = clampToPlot(target.dx, target.dy, fp.w, fp.h, widget.widthM, widget.heightM);
                    if (pos.x != element.xM || pos.y != element.yM) {
                      widget.onCourtMoved!(element.courtId, pos.x, pos.y);
                    }
                  }
                : null,
            onPanEnd: _editable ? (_) => setState(() => _draggingId = null) : null,
            onPanCancel: _editable ? () => setState(() => _draggingId = null) : null,
            child: tile,
          ),
        ),
      ),
    );
  }

  Widget _buildSpace(int index, double scale, ColorScheme colors) {
    final space = widget.spaces[index];
    final hasIssue = widget.issues?.spaceHasIssue(index) ?? false;
    final selected = widget.selectedSpaceIndex == index;
    final name = widget.view.spaceName(space);
    final editable = widget.onSpaceMoved != null;

    return Positioned(
      left: space.xM * scale,
      top: space.yM * scale,
      child: Semantics(
        button: widget.onSpaceTap != null,
        selected: selected,
        label: '$name, ${space.widthM} × ${space.heightM} m',
        child: MouseRegion(
          cursor: editable ? (_draggingSpace == index ? SystemMouseCursors.grabbing : SystemMouseCursors.grab) : SystemMouseCursors.basic,
          child: GestureDetector(
            behavior: HitTestBehavior.opaque,
            onTap: widget.onSpaceTap == null ? null : () => widget.onSpaceTap!(index),
            onPanStart: editable
                ? (_) {
                    widget.onSpaceTap?.call(index);
                    setState(() {
                      _draggingSpace = index;
                      _dragStartM = Offset(space.xM.toDouble(), space.yM.toDouble());
                      _dragDeltaPx = Offset.zero;
                    });
                  }
                : null,
            onPanUpdate: editable
                ? (details) {
                    _dragDeltaPx += details.delta;
                    final target = _dragStartM + _dragDeltaPx / scale;
                    final current = widget.spaces[index];
                    final pos = clampToPlot(target.dx, target.dy, current.widthM.toDouble(), current.heightM.toDouble(), widget.widthM, widget.heightM);
                    if (pos.x != current.xM || pos.y != current.yM) widget.onSpaceMoved!(index, pos.x, pos.y);
                  }
                : null,
            onPanEnd: editable ? (_) => setState(() => _draggingSpace = null) : null,
            onPanCancel: editable ? () => setState(() => _draggingSpace = null) : null,
            child: SpaceTile(
              type: space.type,
              name: name,
              width: space.widthM * scale,
              height: space.heightM * scale,
              ringColor: hasIssue ? colors.error : (selected ? colors.primary : null),
            ),
          ),
        ),
      ),
    );
  }
}

/// Cuadrícula del predio: líneas cada 5 m y, en edición, cada 1 m.
class PlanGridPainter extends CustomPainter {
  final double scale;
  final bool minorLines;

  const PlanGridPainter({required this.scale, required this.minorLines});

  @override
  void paint(Canvas canvas, Size size) {
    canvas.drawRect(Offset.zero & size, Paint()..color = const Color(0xFFFBFAF7));

    void grid(double stepM, Color color) {
      final paint = Paint()
        ..color = color
        ..strokeWidth = 1;
      final step = stepM * scale;
      for (double x = 0; x <= size.width + 0.5; x += step) {
        canvas.drawLine(Offset(x, 0), Offset(x, size.height), paint);
      }
      for (double y = 0; y <= size.height + 0.5; y += step) {
        canvas.drawLine(Offset(0, y), Offset(size.width, y), paint);
      }
    }

    // Con menos de 6 px por metro la cuadrícula de 1 m es puro ruido.
    if (minorLines && scale >= 6) grid(1, const Color(0xFFF2EFF4));
    grid(5, const Color(0xFFE7E3EC));

    canvas.drawRect(
      Offset.zero & size,
      Paint()
        ..color = const Color(0xFFCAC4D0)
        ..style = PaintingStyle.stroke,
    );
  }

  @override
  bool shouldRepaint(covariant PlanGridPainter oldDelegate) => oldDelegate.scale != scale || oldDelegate.minorLines != minorLines;
}

/// Regla de 10 m y el tamaño del predio, para debajo del plano.
class PlanScaleLegend extends StatelessWidget {
  final double scale;
  final int widthM;
  final int heightM;

  const PlanScaleLegend({super.key, required this.scale, required this.widthM, required this.heightM});

  @override
  Widget build(BuildContext context) {
    final textStyle = Theme.of(context).textTheme.bodySmall?.copyWith(color: Theme.of(context).colorScheme.onSurfaceVariant);
    final preset = ClubMapSizePreset.match(widthM, heightM);
    final name = preset != null ? 'Predio ${preset.name.toLowerCase()}' : 'Predio';

    return Wrap(
      spacing: 16,
      runSpacing: 4,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 10 * scale,
              height: 6,
              decoration: BoxDecoration(
                border: Border(
                  left: BorderSide(color: textStyle?.color ?? Colors.black54, width: 2),
                  right: BorderSide(color: textStyle?.color ?? Colors.black54, width: 2),
                  bottom: BorderSide(color: textStyle?.color ?? Colors.black54, width: 2),
                ),
              ),
            ),
            const SizedBox(width: 6),
            Text('10 m', style: textStyle),
          ],
        ),
        Text('$name: $widthM × $heightM m (${formatThousands(widthM * heightM)} m²)', style: textStyle),
      ],
    );
  }
}

String formatThousands(int value) {
  final digits = value.toString();
  final buffer = StringBuffer();
  for (var i = 0; i < digits.length; i++) {
    if (i > 0 && (digits.length - i) % 3 == 0) buffer.write('.');
    buffer.write(digits[i]);
  }
  return buffer.toString();
}
