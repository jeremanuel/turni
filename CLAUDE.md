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
- **Una sola jerarquía de navegación lateral por pantalla.** No agregar un
  segundo `NavigationRail`/menú dentro de una sección interna.

## Dev local

- SDK fijado por FVM — correr todo con `./.fvm/flutter_sdk/bin/flutter ...` o
  `fvm flutter ...`, nunca el `flutter` global del PATH (puede ser otra
  versión y romper hot reload/restart de una sesión ya corriendo).
- Backend en `../turni_mono_be` vía `docker compose` (`turni_mono_be-api-1` en
  `:3001`, Postgres en `:5433`).
