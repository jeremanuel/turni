# Changelog

Cambios de Admin (`turni`) por versión. Formato basado en [Keep a Changelog](https://keepachangelog.com/es-ES/1.1.0/); versiones con [semver](https://semver.org/lang/es/).

Cada PR a `develop` con un cambio visible (para usuarios, admins o la operación) agrega una línea bajo `## [Unreleased]`, al final de la sección que corresponda:

    - AAAA-MM-DD — Qué cambia, en una línea ([#123](https://github.com/jeremanuel/turni/pull/123))

Una línea por entrega, no por PR: si un PR completa una entrada que ya está, se suma su link a esa línea. Refactors, tests y docs internos no llevan entrada. `/turni:release` convierte `[Unreleased]` en la versión nueva y la resume en [RELEASES.md](RELEASES.md).

## [Unreleased]

### Agregado
- 2026-11-01 — Descanso entre series opcional por ejercicio en el editor de rutinas, y su evolución en el historial del ejercicio ([#81](https://github.com/jeremanuel/turni/pull/81)) — requiere BE #121

### Cambiado

### Corregido

## [1.3.0] - 2026-11-01

### Agregado

- 2026-11-01 — Buscador de clientes único en todos los lugares donde se elige un cliente: recientes, búsqueda con resaltado, teclado y "Crear cliente" con lo escrito ya cargado ([#79](https://github.com/jeremanuel/turni/pull/79))

### Cambiado

- 2026-11-01 — Registrar pago y pausar abono iguales al diseño; las opciones (medio de pago, chips de turnos fijos) son transparentes hasta elegirlas ([#79](https://github.com/jeremanuel/turni/pull/79))
- 2026-11-01 — Las pantallas cargan mostrando su forma en vez de un spinner (ficha del cliente, turnos fijos, abonos, torneos, Ajustes, usuarios); si la ficha no carga, ofrece reintentar ([#79](https://github.com/jeremanuel/turni/pull/79))

### Corregido

- 2026-11-01 — En el celular el teclado ya no se abre solo al entrar a una pantalla, y al cerrarlo la app se reacomoda sin dejar una franja negra ([#79](https://github.com/jeremanuel/turni/pull/79))
- 2026-11-01 — Las listas desplegables al pie de la pantalla se abren hacia arriba en vez de quedar cortadas ([#79](https://github.com/jeremanuel/turni/pull/79))

## [1.2.0] - 2026-11-01

### Agregado

- 2026-11-01 — El panel se actualiza en tiempo real: agenda, bandeja, clientes, ficha del cliente, abonos, pagos, mapa, turnos fijos, torneos y usuarios se recargan solos cuando algo cambia, con un punto de conexión sobre el avatar ([#54](https://github.com/jeremanuel/turni/pull/54))
- 2026-11-01 — Bandeja de notificaciones nueva: sale de la campana, con filtros, avisos agrupados por día, contexto de cada aviso y aceptar o rechazar solicitudes desde la lista. Cuando llega un aviso, la campana se balancea y aparece un aviso flotante ([#74](https://github.com/jeremanuel/turni/pull/74))

### Cambiado

- 2026-11-01 — Menú lateral con grupos y expandible: cerrado muestra íconos y manda a «Más» lo que no entra; abierto muestra los nombres y scrollea. El logo de Turni reemplaza la "T" ([#75](https://github.com/jeremanuel/turni/pull/75), [#74](https://github.com/jeremanuel/turni/pull/74))
- 2026-11-01 — El panel pasa a Flutter 3.47.9 y el build de Render usa la versión del repo ([#73](https://github.com/jeremanuel/turni/pull/73), [#77](https://github.com/jeremanuel/turni/pull/77))
- 2026-11-01 — Al abrir, el panel trae siempre la última versión publicada ([#76](https://github.com/jeremanuel/turni/pull/76))

## [1.1.2] - 2026-10-26

### Corregido

- 2026-10-26 — El panel vuelve a deployarse: las guías (1.1.0) usaban algo que la versión de Flutter de producción no tiene, y ni 1.1.0 ni 1.1.1 habían llegado a producción ([#72](https://github.com/jeremanuel/turni/pull/72))

## [1.1.1] - 2026-10-26

### Corregido

- 2026-10-26 — Las notificaciones web ya no llegan dobles ([#70](https://github.com/jeremanuel/turni/pull/70)) — requiere BE #113

## [1.1.0] - 2026-10-26

### Agregado

- 2026-10-26 — Guías paso a paso de todo el panel desde el signo de pregunta del menú, con buscador ([#68](https://github.com/jeremanuel/turni/pull/68))

## [1.0.0] - 2026-10-25

- Versión de base: todo lo liberado hasta el 2026-10-25. Lo anterior está resumido en [RELEASES.md](RELEASES.md).

[1.3.0]: https://github.com/jeremanuel/turni/compare/v1.2.0...v1.3.0
[1.2.0]: https://github.com/jeremanuel/turni/compare/v1.1.2...v1.2.0
[1.1.2]: https://github.com/jeremanuel/turni/compare/v1.1.1...v1.1.2
[1.1.1]: https://github.com/jeremanuel/turni/compare/v1.1.0...v1.1.1
[1.1.0]: https://github.com/jeremanuel/turni/compare/v1.0.0...v1.1.0
[1.0.0]: https://github.com/jeremanuel/turni/releases/tag/v1.0.0
