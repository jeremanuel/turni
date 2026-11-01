# turni (admin app)

Flutter admin app para clubes deportivos. Material 3, color dinámico desde un
único seed (`lib/core/config/app_theme.dart`, `Color(0xff672bea)`), dark-first
(se diseña y revisa en dark; light se genera gratis del mismo seed).

## Design system

**Antes de proponer o implementar cualquier pantalla/mockup nuevo**, leé el
Turni Design System: https://claude.ai/artifact/UxZ7ZhnDct8KgiBvkydagJ

Tiene los tokens de color exactos (derivados con el mismo algoritmo que usa
`ColorScheme.fromSeed`, no aproximados a mano), tipografía y las reglas de
implementación de abajo con más contexto de por qué existen. Si el seed
(`0xff672bea`) cambia alguna vez, ese sistema queda desactualizado y hay que
recalcularlo (no "ajustar a ojo").

## Reglas de implementación — no redescubrir estos bugs

Todas estas ya se cometieron una vez construyendo la pantalla de Ajustes del
admin (`lib/presentation/admin/club_config/`). Aplican a cualquier pantalla
nueva, no solo a esa.

- **`Card` siempre en `colorScheme.surfaceContainerHigh`** (seteado una vez en
  `cardTheme`, `app_theme.dart`). Nunca el color default de Material 3.
- **El fondo de una PANTALLA no es `colorScheme.surface`.** `surface` es solo
  para la franja de arriba (AppBar + fila de tabs). El cuerpo de la pantalla
  va en `colorScheme.surfaceContainer` — hay que setear `Scaffold.backgroundColor`
  explícito, si no hereda `surface` para todo (bug ya cometido).
- **Tablas: grilla completa, no `DataTable` nativo.** `DataTable` solo dibuja
  líneas horizontales. Usar `AdminDataTable`
  (`lib/presentation/admin/club_config/widgets/admin_data_table.dart`).
- **`Chip`: radio 8px + borde `outline`, nunca la forma pill/stadium default.**
  Ya seteado globalmente en `chipTheme` (`app_theme.dart`) — no pisarlo por
  widget salvo un caso puntual real.
- **Botones: radio 4px en AMBOS temas.** `app_theme.dart` construye light y
  dark desde la misma función por esto — un tema armado "a mano" por separado
  se desalinea (ya pasó con `OutlinedButton` en dark).
- **Nunca mostrar el ID interno de la base (la PK) en la UI.** Si una fila no
  tiene nombre/identificador legible, texto genérico ("sin identificador"),
  nunca el número de fila crudo.
- **Precios: `PriceField` + `ThousandsFormat.formatPrice`**
  (`lib/presentation/admin/club_config/widgets/price_field.dart`,
  `lib/core/utils/thousands_format.dart`). El separador de miles es solo para
  plata, no para cualquier número.
- **Horarios (HH:mm): `TimeField`**
  (`lib/presentation/admin/club_config/widgets/time_field.dart`).
- **Duración en minutos: `DurationMinutesField`**
  (`lib/presentation/admin/club_config/widgets/duration_minutes_field.dart`) —
  `helperText` en vivo tipo "1h 30m".
- **Nunca hardcodear la posición de un menú (`showMenu` con `RelativeRect`
  fijo) ni el margen de un `SnackBar`.** Usar `PopupMenuButton` (se
  autoposiciona). Si un error "no se ve" en pantalla, sospechar primero de
  `SnackbarsFunctions` (`lib/core/presentation/components/inputs/snackbars/`)
  antes de asumir que el backend no mandó el mensaje.
- **Alta/edición de una entidad: diálogo (`AlertDialog` + `Form`)**, no un
  formulario inline embebido en la card de la lista — salvo un caso ya
  confirmado explícitamente con el usuario (las franjas horarias de Tarifas sí
  quedaron con alta inline, edición por diálogo).
- **Todo nombre de cliente es un link a su ficha**, con subrayado al pasar
  el mouse: `ClientLink` (o `ClientLinksText` si el nombre va dentro de una
  frase, ej. "Con Juan y Ana"), en
  `lib/core/presentation/components/links/entity_links.dart`. Aplica a
  tablas, cards, paneles y listas; no a buscadores/selectores de cliente ni
  al texto de diálogos de confirmación. Si el dato no trae el `client_id`,
  se agrega al endpoint, no se deja el nombre como texto plano.
- **Todo turno que aparezca en la ficha del cliente abre ese turno en la
  agenda** (`openSession` / `HoverLink`, misma regla de hover). La ruta del
  turno (`SESSION_MANAGER_RESERVE_ROUTE`) centra la agenda en él vía
  `Agenda.focusSession`.
- **Nunca hardcodear "cancha", "jugadores" ni "deporte" en un texto.** El
  vocabulario es por modalidad (`club_partition`): una puede tener canchas y
  jugadores, otra salas y alumnos, otra profesionales y clientes. Usar
  `PartitionVocabulary` (`lib/domain/entities/partition_vocabulary.dart`):
  `PartitionVocabulary.of(partition)` para un texto de una modalidad
  (`.space.nuevo` → "Nueva cancha" / "Nuevo profesional", `.space.label(2)`,
  `.participant.count(4)`), `PartitionVocabulary.common(partitions)` para uno
  que mezcla varias ("Todas las canchas" si todas se llaman igual, si no
  "Todos los espacios"), y `physicalPartition.spaceLabel()` para "Cancha 2".
  Las funciones propias de un rubro (plano, cubierta, cupo) se muestran según
  `.features`. Palabras de nivel club, fijas y genéricas: Establecimiento,
  Cliente, Turno, Turno fijo, Servicio.
  El título de un servicio es `clubPartition.displayName` (su nombre propio
  o el de su tipo), nunca `physicalPartitionName`: ese es el nombre de sus
  espacios ("Sala", "Box").
- **Fechas: nunca el calendario por defecto de Material (`showDatePicker`).**
  Siempre el calendario propio que se despliega como dropdown debajo del
  campo: `DateDropdownField`
  (`lib/core/presentation/components/inputs/date_picker/date_dropdown_field.dart`)
  para una fecha, `IntervalCalendarPanel` dentro de un `DropdownWidget` para
  un rango. El campo va con fondo transparente y borde `outline`, como los
  demás campos.
- **Opciones elegibles (medio de pago, cuotas, motivo, filtros): transparentes
  sin elegir, nunca con fondo oscuro.** Usar `OptionChip`
  (`lib/core/presentation/components/inputs/option_chip.dart`): transparente
  con borde `outline` y `secondaryContainer` cuando está elegida. Los chips de
  Material heredan lo mismo del `chipTheme` (su `color`, no solo
  `backgroundColor`: en Material 3 sin `color` pintan un fondo oscuro).
- **Contenedores lado a lado para elegir una opción (tarjetas de "¿Qué
  paga?", planes, etc.): siempre del mismo alto.** Una `Row` dentro de
  `IntrinsicHeight` con `crossAxisAlignment: CrossAxisAlignment.stretch`,
  nunca anchos fijos en un `Wrap` (cada una queda del alto de su texto).
- **Labels de un formulario de diseño: arriba del campo y alineados a la
  izquierda** (`bodySmall`, `onSurfaceVariant`), no el label flotante dentro
  del borde, salvo que el diseño lo muestre así. Nunca un título de sección
  centrado.
- **Una sola jerarquía de navegación lateral por pantalla.** No agregar un
  segundo `NavigationRail`/menú dentro de una sección interna.

## Dev local

- SDK fijado por FVM — correr todo con `./.fvm/flutter_sdk/bin/flutter ...` o
  `fvm flutter ...`, nunca el `flutter` global del PATH (puede ser otra
  versión y romper hot reload/restart de una sesión ya corriendo).
- La versión de Flutter es la de `.fvmrc` (hoy 3.47.9) y es **la misma con la
  que compila Render**: el build de producción es `scripts/render_build.sh`,
  que instala esa versión. Para subir de versión: cambiar `.fvmrc`,
  `fvm use <versión>` local, `flutter pub upgrade`, `build_runner`, analyze,
  test y `flutter build web --release`.
- Cada deploy genera un número de versión (`AAAAMMDDhhmmss`) que el script
  compila en la app (`--dart-define=VERSION`) y escribe en `.env.production`.
  Al abrir, la app web lo compara con el del servidor y recarga si hay uno
  nuevo (`AppVersion.ensureLatest`). Sin `VERSION` (local) no hace nada.
- `flutter analyze` excluye `*.freezed.dart` / `*.g.dart`: un generado
  incompatible con el SDK solo aparece al compilar (`flutter test` / build).
  Por eso el `sdk:` mínimo del pubspec sigue en 3.8: con 3.13 el lenguaje
  rechaza el `final` en parámetros que genera freezed 3.
- Backend en `../turni_mono_be` vía `docker compose` (`turni_mono_be-api-1` en
  `:3001`, Postgres en `:5433`).
