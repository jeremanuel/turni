# Guías del admin (signo de pregunta)

El signo de pregunta del menú (rail en escritorio, hoja «Más» en el celular, barra de las pantallas de primer nivel) abre un buscador de guías. Cada guía es un recorrido paso a paso (`OnboardingTour`) que resalta partes de la pantalla y puede pasar por varias pantallas.

## Piezas

| Archivo | Qué tiene |
|---|---|
| `lib/core/presentation/components/onboarding/tour_anchor.dart` | `TourAnchor`: marca un widget con un nombre (`agenda.grid`, `clients.row`). `onActivate` deja a la vista lo que representa: abrir esa tab (`TourAnchor.selectTab`), ese turno, esa ficha. |
| `lib/core/presentation/components/onboarding/onboarding_tour.dart` | El recorrido: overlay en el Navigator raíz, espera a que aparezca cada target, lo lleva a la vista y devuelve un `OnboardingResult` (pasos mostrados, salteados y si llegó a «Listo»). |
| `lib/presentation/admin/guides/guide.dart` | `Guide`: título, descripción, sección, palabras clave, permisos, ruta donde arranca y los pasos. Helpers para el `before` de un paso: `activate`, `reveal`, `goTo`. |
| `lib/presentation/admin/guides/admin_guides.dart` | El catálogo (`AdminGuides.all`). También los pasos del recorrido de bienvenida de Configuración (`clubSetupSteps`). |
| `lib/presentation/admin/guides/guides_dialog.dart` | El botón, el diálogo y el buscador. |

## Agregar una guía

1. Marcá con `TourAnchor` lo que la guía va a resaltar. Nombre con el prefijo de la pantalla (`tariffs.new`). Si hay varios con el mismo nombre (una fila por cliente), usa el primero visible.
2. Si un paso necesita abrir algo (una tab, un turno, una ficha), poné el `onActivate` en el anchor que lo abre y pedilo desde el paso con `before: activate('<anchor>')`. Si eso ya puede estar abierto (ej. en el celular la sección tapa la lista), usá `reveal('<lo que quiero ver>', via: '<lo que lo abre>')`.
3. Sumá la `Guide` en `AdminGuides.all`, en su sección. Textos con el vocabulario del club (`v.space.lowerPlural`), nunca «cancha» fijo: lo chequea `test/presentation/admin/guides_test.dart`.
4. Marcá `optional: true` los pasos que dependen de los datos (solicitudes del día, un torneo en juego, permisos de edición). Los obligatorios tienen que aparecer siempre.
5. Corré el e2e de las guías contra el seed de dev:

   ```bash
   flutter test test/e2e/guides_flow_test.dart \
     --dart-define=DEV_ADMIN_TOKEN=<token de npm run seed:dev> [--dart-define=GUIDE=<id>,<id>]
   ```

   Recorre cada guía visible hasta «Listo» y falla si un paso obligatorio no apareció. También informa los overflows de layout que encuentra en el camino.

## Detalles que ya costaron

- Un `TabBarView` deja armada la página de al lado fuera de pantalla, y `KeepAlive` mantiene montadas las tabs que no se ven: `TourAnchors` no las cuenta como visibles.
- `onActivate` puede devolver el `Future` de un `push`: se espera como mucho 600 ms, no hasta que se cierre la ruta.
- La ruta actual de una guía es `router.state.uri` (la de arriba de todo, incluida la abierta con `push`), no `currentConfiguration.uri`.
- Cambiar de ruta con otro `?tab=` no cambia la tab de una pantalla ya abierta: elegí la tab con su anchor.
