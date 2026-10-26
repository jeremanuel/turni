# Releases

Cada versión de Admin que llegó a producción, contada en general: qué features entraron y para quién. El detalle, con los PRs, está en [CHANGELOG.md](CHANGELOG.md). Lo actualiza `/turni:release`; la más nueva va arriba.

## 2026-10-26 — Reservar desde el detalle · v1.1.1

Junto con BE 1.1.1 y Client 1.3.0.

Las notificaciones del panel en la web llegan una sola vez: antes, cada aviso podía aparecer duplicado.

- **Arreglos:** notificaciones web sin duplicar.

## 2026-10-26 — Guías paso a paso · v1.1.0

El panel suma ayuda paso a paso: desde el signo de pregunta del menú, el admin busca cómo hacer algo (cobrar un turno, armar un torneo, cargar tarifas) y una guía lo acompaña sobre la pantalla real, resaltando cada parte y abriendo lo que haga falta.

- **Guías desde el signo de pregunta:** 29 guías, una por pantalla o tarea del panel (agenda, cobros, turnos fijos, clientes, pagos, mapa, torneos, configuración, usuarios y avisos), con buscador. Las que no aplican al establecimiento o a los permisos del admin no aparecen.
- **Recorrido de bienvenida:** el de Configuración para un club recién creado usa las mismas guías.

## 2026-10-25 — Versión de base · v1.0.0

Desde acá arranca el versionado: v1.0.0 es lo que estaba en producción el 2026-10-25. Antes, las releases eran PRs a `master` sin número:

- 2026-10-25 — [Release: bandeja e historial de avisos](https://github.com/jeremanuel/turni/pull/66)
- 2026-10-22 — [Release: fix del deploy del admin (Flutter 3.35)](https://github.com/jeremanuel/turni/pull/63)
- 2026-10-22 — [Release: gimnasio (rutinas, micro-progresos, abonos y pagos)](https://github.com/jeremanuel/turni/pull/61)
- 2026-10-20 — [Release: invitación al dueño del club](https://github.com/jeremanuel/turni/pull/59)
- 2026-10-20 — [release: alta de clubes y operadores de plataforma](https://github.com/jeremanuel/turni/pull/57)
- 2026-10-17 — [release: admin usable desde el celular](https://github.com/jeremanuel/turni/pull/52)
- 2026-10-17 — [hotfix: branding de la app web e indicador wasm/js en la versión](https://github.com/jeremanuel/turni/pull/49)

Antes de octubre de 2026 los cambios entraban a `master` con PRs de feature; están en el historial de git.
