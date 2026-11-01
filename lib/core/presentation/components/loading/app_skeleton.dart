import 'package:flutter/material.dart';
import 'package:skeletonizer/skeletonizer.dart';

export 'package:skeletonizer/skeletonizer.dart' show Skeleton, Skeletonizer, Bone, BoneMock;

/// Cargas de la app. Mientras algo carga se muestra la forma de lo que va a
/// aparecer (un esqueleto), no un spinner suelto:
///
/// - [AppSkeleton]: envuelve el layout real armado con datos de mentira
///   ([BoneMock] para textos). Los textos e íconos se dibujan como huesos y
///   las cards conservan su color.
/// - [SkeletonRows] / [SkeletonCard]: cuando no hay modelo a mano, filas o
///   una card genéricas.
/// - [LoadingView]: carga sin forma conocida (una página que se descarga).
/// - [InlineSpinner]: dentro de un botón mientras guarda.
class AppSkeleton extends StatelessWidget {
  const AppSkeleton({super.key, this.enabled = true, required this.child});

  final bool enabled;
  final Widget child;

  /// El brillo del esqueleto, derivado del seed: se ve sobre `surface*` y
  /// sobre las cards (`surfaceContainerHigh`) en los dos temas.
  static PaintingEffect effect(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ShimmerEffect(
      baseColor: scheme.onSurface.withValues(alpha: 0.08),
      highlightColor: scheme.onSurface.withValues(alpha: 0.16),
      duration: const Duration(milliseconds: 1400),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Skeletonizer(
      enabled: enabled,
      effect: effect(context),
      // Sin animación de cambio: el AnimatedSwitcher arma el esqueleto y el
      // contenido a la vez, y duplica las GlobalKey (Form, mapa, guías).
      child: child,
    );
  }
}

/// [count] filas de lista (avatar opcional, título y detalle) como esqueleto.
class SkeletonRows extends StatelessWidget {
  const SkeletonRows({super.key, this.count = 3, this.avatar = false, this.dividers = true, this.padding = const EdgeInsets.symmetric(vertical: 12)});

  final int count;
  final bool avatar;
  final bool dividers;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Skeletonizer.zone(
      effect: AppSkeleton.effect(context),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          for (var i = 0; i < count; i++)
            Container(
              padding: padding,
              decoration: dividers && i < count - 1 ? BoxDecoration(border: Border(bottom: BorderSide(color: scheme.outlineVariant))) : null,
              child: Row(
                children: [
                  if (avatar) ...[const Bone.circle(size: 36), const SizedBox(width: 12)],
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Largos distintos por fila: no parece una grilla.
                        Bone.text(words: 2 + i % 3, fontSize: 14),
                        const SizedBox(height: 6),
                        Bone.text(words: 3 + (i + 1) % 3, fontSize: 12),
                      ],
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Una card genérica mientras carga: un título y [rows] filas.
class SkeletonCard extends StatelessWidget {
  const SkeletonCard({super.key, this.rows = 3, this.margin});

  final int rows;
  final EdgeInsetsGeometry? margin;

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: margin,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Skeletonizer.zone(
          effect: AppSkeleton.effect(context),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Bone.text(words: 2, fontSize: 18),
              const SizedBox(height: 8),
              SkeletonRows(count: rows),
            ],
          ),
        ),
      ),
    );
  }
}

/// Texto de mentira para armar el layout real dentro de un [AppSkeleton]
/// (con espacios, a diferencia de `BoneMock.words`: así corta en líneas).
String skeletonText([int words = 2]) => List.filled(words, 'Moock').join(' ');

/// Carga sin forma conocida: centrada y discreta.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.message});

  final String? message;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(width: 28, height: 28, child: CircularProgressIndicator(strokeWidth: 3)),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(message!, style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// Spinner chico para un botón o un ícono que está guardando.
class InlineSpinner extends StatelessWidget {
  const InlineSpinner({super.key, this.size = 18, this.color});

  final double size;
  final Color? color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(width: size, height: size, child: CircularProgressIndicator(strokeWidth: 2, color: color));
  }
}

/// Error de una carga, con reintento. En una card va en línea; [center] es
/// para una pantalla entera que no pudo cargar.
class LoadError extends StatelessWidget {
  const LoadError({super.key, required this.message, this.onRetry, this.center = false});

  final String message;
  final VoidCallback? onRetry;
  final bool center;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (center) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline, color: scheme.error),
              const SizedBox(height: 8),
              Text(message, textAlign: TextAlign.center),
              if (onRetry != null) ...[const SizedBox(height: 12), OutlinedButton(onPressed: onRetry, child: const Text('Reintentar'))],
            ],
          ),
        ),
      );
    }
    return Row(
      children: [
        Icon(Icons.error_outline, size: 18, color: scheme.error),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: TextStyle(color: scheme.error))),
        if (onRetry != null) ...[const SizedBox(width: 8), TextButton(onPressed: onRetry, child: const Text('Reintentar'))],
      ],
    );
  }
}
