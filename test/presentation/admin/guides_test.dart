import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:turni/core/utils/permissions.dart';
import 'package:turni/domain/entities/partition_vocabulary.dart';
import 'package:turni/presentation/admin/guides/admin_guides.dart';
import 'package:turni/presentation/admin/guides/guide.dart';
import 'package:turni/presentation/admin/guides/guides_dialog.dart';

import '../../helpers/logged_admin.dart';

void main() {
  setUp(registerLoggedAdmin);

  group('catálogo', () {
    test('cada guía tiene un id único, pasos y anchors', () {
      final ids = AdminGuides.all.map((g) => g.id).toList();
      expect(ids.toSet().length, ids.length);
      for (final guide in AdminGuides.all) {
        final steps = guide.steps(PartitionVocabulary.court);
        expect(steps, isNotEmpty, reason: guide.id);
        for (final step in steps) {
          expect(step.anchor, isNotNull, reason: '${guide.id}: ${step.title}');
        }
      }
    });

    test('con otro vocabulario ningún paso dice "cancha"', () {
      for (final guide in AdminGuides.all) {
        for (final step in guide.steps(PartitionVocabulary.generic)) {
          expect('${step.title} ${step.body}'.toLowerCase(), isNot(contains('cancha')), reason: '${guide.id}: ${step.title}');
        }
      }
    });

    test('un rol sin permisos solo ve las guías que no piden ninguno', () {
      registerLoggedAdmin(permissions: const []);
      final visible = AdminGuides.all.where((g) => g.isVisible).map((g) => g.id);
      expect(visible, containsAll(['panel', 'notifications']));
      expect(visible, isNot(contains('agenda')));
      expect(visible, isNot(contains('config.tariffs')));
    });

    test('con permiso de agenda aparecen las guías de turnos', () {
      registerLoggedAdmin(permissions: const [Permissions.AGENDA_VER]);
      final visible = AdminGuides.all.where((g) => g.isVisible).map((g) => g.id);
      expect(visible, contains('agenda'));
      expect(visible, isNot(contains('users.roles')));
    });
  });

  group('búsqueda', () {
    Guide guide(String title, {String section = 'Turnos', List<String> keywords = const []}) =>
        Guide(id: title, section: section, title: title, description: 'Descripción', icon: Icons.help_outline, keywords: keywords, steps: (_) => const []);

    test('sin tildes ni mayúsculas, y con todas las palabras', () {
      final g = guide('Configuración del club', keywords: ['tarifas']);
      expect(g.matches('configuracion'), isTrue);
      expect(g.matches('CLUB tarifas'), isTrue);
      expect(g.matches('club torneo'), isFalse);
      expect(g.matches('  '), isTrue);
    });

    testWidgets('el panel filtra por lo que se escribe y elige la guía tocada', (tester) async {
      Guide? picked;
      final guides = [
        guide('Cobrar un turno', keywords: ['pago']),
        guide('Crear un torneo', section: 'Torneos'),
      ];
      await tester.pumpWidget(MaterialApp(
        home: Scaffold(body: GuidesPanel(guides: guides, seen: const {'Crear un torneo'}, onPick: (g) => picked = g)),
      ));

      expect(find.text('Turnos'), findsOneWidget);
      expect(find.text('Torneos'), findsOneWidget);
      // La que ya vio lleva un tilde.
      expect(find.byIcon(Icons.check_circle_outline), findsOneWidget);

      await tester.enterText(find.byType(TextField), 'pago');
      await tester.pump();
      expect(find.text('Cobrar un turno'), findsOneWidget);
      expect(find.text('Crear un torneo'), findsNothing);

      await tester.enterText(find.byType(TextField), 'zzz');
      await tester.pump();
      expect(find.text('No encontramos guías con "zzz".'), findsOneWidget);

      await tester.enterText(find.byType(TextField), '');
      await tester.pump();
      await tester.tap(find.text('Crear un torneo'));
      expect(picked?.id, 'Crear un torneo');
    });
  });
}
