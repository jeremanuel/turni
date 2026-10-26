import 'package:flutter/material.dart';

import '../../../core/config/router/app_routes.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/presentation/components/onboarding/onboarding_tour.dart';
import '../../../core/utils/admin_features.dart';
import '../../../core/utils/permissions.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import 'guide.dart';

/// Catálogo de guías del admin, en el orden en que se muestran en el centro
/// de ayuda (el signo de pregunta del menú).
///
/// Cada paso resalta un `TourAnchor` por nombre (`agenda.grid`,
/// `client.payments`...): los nombres están en las pantallas, buscando el
/// texto entre comillas. Los pasos `optional` dependen de los datos o del
/// rol; el resto tiene que aparecer siempre (lo controla el e2e
/// `integration_test/guides_flow.dart` contra el seed de dev).
class AdminGuides {
  AdminGuides._();

  static const _clubConfig = '/admin/settings';

  static List<Guide> get all => [
        // -------------------------------------------------------------------
        // Primeros pasos
        // -------------------------------------------------------------------
        Guide(
          id: 'panel',
          section: 'Primeros pasos',
          title: 'Recorrido por el panel',
          description: 'Dónde está cada sección del menú, los avisos y esta ayuda.',
          icon: Icons.explore_outlined,
          keywords: const ['menu', 'navegar', 'inicio', 'secciones'],
          steps: (v) => const [
            OnboardingStep(anchor: 'nav.turnos', optional: true, title: 'Turnos', body: 'La agenda del día: reservás, cobrás y aprobás solicitudes. Es la pantalla que más vas a usar.'),
            OnboardingStep(anchor: 'nav.clientes', optional: true, title: 'Clientes', body: 'Todos tus clientes con su ficha: datos, turnos, pagos y notas.'),
            OnboardingStep(anchor: 'nav.pagos', optional: true, title: 'Pagos', body: 'Lo que se cobró, por día y por medio de pago, con los totales del período.'),
            OnboardingStep(anchor: 'nav.mapa', optional: true, title: 'Mapa', body: 'El plano del establecimiento: qué está ocupado ahora y cuánto se usa cada espacio.'),
            OnboardingStep(anchor: 'nav.torneos', optional: true, title: 'Torneos', body: 'Armá torneos, seguí las inscripciones, sorteá el cuadro y cargá resultados.'),
            OnboardingStep(anchor: 'nav.configuracion', optional: true, title: 'Configuración', body: 'Datos del establecimiento, servicios, tarifas, productos, solicitudes y cobros online.'),
            OnboardingStep(anchor: 'nav.usuarios', optional: true, title: 'Usuarios', body: 'Quiénes entran al panel y qué puede hacer cada rol.'),
            OnboardingStep(anchor: 'nav.more', optional: true, title: 'Más', body: 'En el celular, las secciones que no entran en la barra están acá.'),
            OnboardingStep(anchor: 'nav.notifications', optional: true, title: 'Avisos', body: 'Reservas nuevas, pagos y solicitudes que llegan mientras trabajás.'),
            OnboardingStep(anchor: 'nav.help', title: 'Guías', body: 'Cuando tengas una duda, tocá el signo de pregunta y buscá la guía de lo que querés hacer.'),
          ],
        ),
        Guide(
          id: 'config.club',
          section: 'Primeros pasos',
          title: 'Configurar el establecimiento',
          description: 'Nombre, dirección y ubicación en el mapa, y qué cargar después.',
          icon: Icons.storefront_outlined,
          keywords: const ['alta', 'empezar', 'direccion', 'ubicacion', 'nombre', 'club', 'bienvenida'],
          permissions: const [Permissions.CONFIGURACION_VER],
          route: _clubConfig,
          steps: (v) => clubSetupSteps(),
        ),

        // -------------------------------------------------------------------
        // Turnos
        // -------------------------------------------------------------------
        Guide(
          id: 'agenda',
          section: 'Turnos',
          title: 'Cómo leer la agenda',
          description: 'Cambiar de día y de servicio, qué significa cada color y el resumen del día.',
          icon: Icons.calendar_month_outlined,
          keywords: const ['turnos', 'calendario', 'dia', 'fecha', 'colores', 'ocupacion', 'buscar'],
          permissions: const [Permissions.AGENDA_VER],
          route: AppRoutes.SESSION_MANAGER_ROUTE.path,
          steps: (v) => [
            const OnboardingStep(anchor: 'agenda.day', title: 'El día que estás viendo', body: 'Pasá al día anterior o al siguiente, volvé a hoy o tocá la fecha para elegir otra en el calendario.'),
            OnboardingStep(anchor: 'agenda.services', title: 'Servicios', body: 'Cada servicio tiene su agenda. Elegí cuál ver; ${v.space.definitePlural} de ese servicio son las columnas.'),
            const OnboardingStep(anchor: 'agenda.legend', optional: true, title: 'Qué significa cada color', body: 'Reservado, turno fijo, libre, fijo cancelado ese día y solicitudes por aprobar.'),
            OnboardingStep(anchor: 'agenda.grid', title: 'La agenda', body: 'Una columna por ${v.space.lower} y una fila por hora. Tocá cualquier turno para ver su detalle, reservarlo o cobrarlo.'),
            const OnboardingStep(anchor: 'agenda.summary', optional: true, title: 'Resumen del día', body: 'Cuántos turnos hay reservados, libres y por aprobar, la ocupación y cuánto se cobró de lo reservado.'),
            const OnboardingStep(anchor: 'agenda.pending', optional: true, title: 'Solicitudes por aprobar', body: 'Los clientes que pidieron un turno desde la app. Aceptalas o rechazalas desde acá.'),
            const OnboardingStep(anchor: 'agenda.search', title: 'Buscar', body: 'Encontrá un cliente o un turno sin recorrer la agenda.'),
            const OnboardingStep(anchor: 'agenda.bulk', optional: true, title: 'Gestión masiva', body: 'Cargar muchos turnos de una vez, editarlos por reglas y administrar los turnos fijos.'),
          ],
        ),
        Guide(
          id: 'agenda.reserve',
          section: 'Turnos',
          title: 'Reservar un turno libre',
          description: 'Elegir el turno, buscar o crear al cliente y confirmar la reserva.',
          icon: Icons.event_available_outlined,
          keywords: const ['reserva', 'cliente nuevo', 'libre', 'agendar', 'anotar'],
          permissions: const [Permissions.AGENDA_RESERVAR],
          route: AppRoutes.SESSION_MANAGER_ROUTE.path,
          steps: (v) => [
            const OnboardingStep(anchor: 'agenda.card.free', title: 'Un turno libre', body: 'Los turnos libres tienen el borde punteado. Tocalo para reservarlo.'),
            OnboardingStep(anchor: 'session.header', before: activate('agenda.card.free'), title: 'El turno elegido', body: 'Horario, día, servicio y ${v.space.lower}. Con la cruz volvés al resumen del día.'),
            const OnboardingStep(anchor: 'session.free.price', title: 'Precio', body: 'Sale de las tarifas por horario de la configuración.'),
            const OnboardingStep(anchor: 'session.free.client', title: 'Para quién', body: 'Buscá al cliente por nombre, teléfono o email, o elegí uno de los recientes.'),
            const OnboardingStep(anchor: 'session.free.newClient', title: '¿Es nuevo?', body: 'Crealo acá mismo con sus datos básicos: queda reservado en el mismo paso.'),
            const OnboardingStep(anchor: 'session.free.reserve', title: 'Reservar', body: 'Con el cliente elegido, confirmá. El turno pasa a reservado en la agenda.'),
          ],
        ),
        Guide(
          id: 'agenda.charge',
          section: 'Turnos',
          title: 'Cobrar un turno y sumar adicionales',
          description: 'La cuenta del turno, cobrar todo o una parte, adicionales, notas y la actividad.',
          icon: Icons.point_of_sale_outlined,
          keywords: const ['cobrar', 'pago', 'seña', 'adicional', 'producto', 'consumo', 'cuenta', 'cancelar reserva', 'notas'],
          permissions: const [Permissions.AGENDA_VER],
          route: AppRoutes.SESSION_MANAGER_ROUTE.path,
          steps: (v) => [
            const OnboardingStep(anchor: 'agenda.card.booked', title: 'Un turno reservado', body: 'Los reservados muestran al cliente y una barra con cuánto se pagó. Tocalo para abrir su detalle.'),
            OnboardingStep(anchor: 'session.client', before: activate('agenda.card.booked'), title: 'El cliente', body: 'Su nombre lleva a la ficha, con todos sus turnos y pagos.'),
            const OnboardingStep(anchor: 'session.fixed', optional: true, title: 'Turno fijo', body: 'Si es parte de un turno fijo, desde acá cancelás solo este día o vas a la lista de turnos fijos.'),
            const OnboardingStep(anchor: 'session.account', title: 'La cuenta', body: 'El turno más los adicionales, menos lo que ya se pagó. Abajo queda el saldo.'),
            const OnboardingStep(anchor: 'session.addExtra', optional: true, title: 'Adicionales', body: 'Sumá bebidas, alquileres o lo que se haya consumido. Los productos se cargan en la configuración.'),
            const OnboardingStep(anchor: 'session.charge', optional: true, title: 'Cobrar', body: 'Cobrá todo, la mitad o una parte por persona, con el medio de pago que corresponda.'),
            const OnboardingStep(anchor: 'session.notes', title: 'Notas', body: 'Lo que quieras recordar de este turno. Lo ven los demás administradores.'),
            const OnboardingStep(anchor: 'session.activity', title: 'Actividad', body: 'Quién creó, reservó o cobró el turno y cuándo.'),
            const OnboardingStep(anchor: 'session.notifications', optional: true, title: 'Avisos enviados', body: 'Los mensajes que le llegaron al cliente por este turno.'),
            const OnboardingStep(anchor: 'session.footer', optional: true, title: 'Cancelar o eliminar', body: 'Cancelar la reserva deja el turno libre otra vez; eliminarlo lo saca de la agenda.'),
          ],
        ),
        Guide(
          id: 'agenda.requests',
          section: 'Turnos',
          title: 'Aprobar solicitudes de turno',
          description: 'Los turnos que los clientes piden desde la app y esperan tu respuesta.',
          icon: Icons.mark_email_unread_outlined,
          keywords: const ['solicitud', 'pedido', 'aprobar', 'aceptar', 'rechazar', 'pendiente', 'app'],
          permissions: const [Permissions.AGENDA_SOLICITUDES, Permissions.AGENDA_VER],
          route: AppRoutes.SESSION_MANAGER_ROUTE.path,
          steps: (v) => [
            const OnboardingStep(anchor: 'agenda.summary.pending', optional: true, title: 'Por aprobar', body: 'Cuántas solicitudes hay en el día que estás viendo.'),
            const OnboardingStep(anchor: 'agenda.pending', optional: true, title: 'La lista', body: 'Cada solicitud con el cliente, el horario y cuándo vence. Aceptala con la tilde o rechazala con la cruz.'),
            const OnboardingStep(anchor: 'agenda.card.pending', optional: true, title: 'En la agenda', body: 'Las solicitudes también aparecen en la agenda con otro color. Tocala para ver el detalle.'),
            OnboardingStep(anchor: 'session.pending', optional: true, before: activate('agenda.card.pending'), title: 'Aceptar o rechazar', body: 'Al aceptarla, el turno queda reservado y le avisamos al cliente.'),
            const OnboardingStep(anchor: 'agenda.day', title: 'Revisá otros días', body: 'Si hoy no hay solicitudes, pasá a los próximos días: las solicitudes se ven en el día del turno.'),
            OnboardingStep(
              anchor: 'clubConfig.tab.requests',
              before: goTo(_clubConfig),
              title: 'Vencimiento y seña',
              body: 'En Configuración › Solicitudes de turno definís cuánto tiempo tiene una solicitud para que la respondas y si se pide seña.',
            ),
          ],
        ),
        Guide(
          id: 'bulk.add',
          section: 'Turnos',
          title: 'Cargar turnos en bloque',
          description: 'Una plantilla de horarios repetida en varios días y espacios.',
          icon: Icons.add_to_photos_outlined,
          keywords: const ['agregar turnos', 'plantilla', 'masivo', 'cargar', 'crear turnos', 'horarios', 'semana'],
          permissions: const [Permissions.AGENDA_CREAR],
          route: '${AppRoutes.BULK_SESSIONS_ROUTE.path}?tab=add',
          steps: (v) => [
            OnboardingStep(anchor: 'bulk.tabs', before: activate('bulk.tab.add'), title: 'Gestión masiva', body: 'Tres herramientas: editar o eliminar por reglas, agregar turnos y los turnos fijos.'),
            const OnboardingStep(anchor: 'addSessions.steps', title: 'Cuatro pasos', body: 'Horarios, dónde, qué fechas y confirmar. Podés volver a cualquier paso antes de crear.'),
            const OnboardingStep(anchor: 'addSessions.wizard', title: 'Armá la plantilla', body: 'Definí los turnos de un día tipo (o usá la carga rápida de mañana o tarde) y después elegí los servicios y las fechas.'),
            OnboardingStep(anchor: 'addSessions.preview', title: 'Vista previa', body: 'Cómo queda el día y cómo se reparte en ${v.space.definitePlural}. Tocá una hora libre para agregar un turno o uno existente para editarlo.'),
          ],
        ),
        Guide(
          id: 'bulk.edit',
          section: 'Turnos',
          title: 'Editar o eliminar muchos turnos',
          description: 'Cambiar precio, duración u horario de los turnos que cumplan unas reglas.',
          icon: Icons.edit_calendar_outlined,
          keywords: const ['masivo', 'precio', 'duracion', 'horario', 'eliminar turnos', 'reglas', 'aumento'],
          permissions: const [Permissions.AGENDA_GESTION_MASIVA],
          route: '${AppRoutes.BULK_SESSIONS_ROUTE.path}?tab=edit',
          steps: (v) => [
            OnboardingStep(anchor: 'bulkEdit.rules', before: activate('bulk.tab.edit'), title: '1. ¿Qué turnos?', body: 'Servicio, espacios, fechas, días y horarios: se toman los turnos que cumplan todas las reglas.'),
            const OnboardingStep(anchor: 'bulkEdit.action', title: '2. ¿Qué hacer?', body: 'Cambiar el precio, la duración o el horario, o eliminarlos.'),
            const OnboardingStep(anchor: 'bulkEdit.preview', title: 'Vista previa', body: 'Antes de aplicar ves cuántos turnos cambian y cómo quedan. Los reservados se pueden dejar afuera.'),
            const OnboardingStep(anchor: 'bulkEdit.apply', title: 'Aplicar', body: 'Nada cambia hasta que confirmás acá.'),
          ],
        ),
        Guide(
          id: 'fixed',
          section: 'Turnos',
          title: 'Turnos fijos',
          description: 'Clientes que vienen el mismo día y horario todas las semanas.',
          icon: Icons.event_repeat,
          keywords: const ['fijo', 'semanal', 'recurrente', 'abono', 'todas las semanas'],
          permissions: const [Permissions.TURNOS_FIJOS_VER],
          route: '${AppRoutes.BULK_SESSIONS_ROUTE.path}?tab=fixed',
          steps: (v) => [
            OnboardingStep(anchor: 'fixed.stats', before: activate('bulk.tab.fixed'), title: 'De un vistazo', body: 'Cuántos turnos fijos hay, cuántas horas por semana ocupan y si alguno choca con otro turno.'),
            const OnboardingStep(anchor: 'fixed.search', title: 'Buscar', body: 'Filtrá por cliente o por servicio.'),
            const OnboardingStep(anchor: 'fixed.view', title: 'Semana o lista', body: 'La semana muestra cada día en una columna; la lista, todos juntos.'),
            const OnboardingStep(anchor: 'fixed.board', title: 'Los turnos fijos', body: 'Desde el menú de cada uno editás sus integrantes o lo cancelás (un día o para siempre).'),
            const OnboardingStep(anchor: 'fixed.new', optional: true, title: 'Nuevo turno fijo', body: 'Elegí al titular, el día, la hora y el espacio: se crea un turno por semana.'),
          ],
        ),

        // -------------------------------------------------------------------
        // Clientes
        // -------------------------------------------------------------------
        Guide(
          id: 'clients',
          section: 'Clientes',
          title: 'Buscar y dar de alta clientes',
          description: 'El listado, el buscador y cómo cargar un cliente nuevo.',
          icon: Icons.groups_outlined,
          keywords: const ['cliente', 'buscar', 'alta', 'nuevo cliente', 'listado', 'telefono', 'email'],
          permissions: const [Permissions.CLIENTES_VER],
          route: AppRoutes.CLIENTS_LIST_ROUTE.path,
          steps: (v) => const [
            OnboardingStep(anchor: 'clients.search', title: 'Buscar', body: 'Por nombre, teléfono, email o etiqueta. Enter o la lupa para buscar.'),
            OnboardingStep(anchor: 'clients.list', title: 'El listado', body: 'Tocá el nombre de un cliente para abrir su ficha.'),
            OnboardingStep(anchor: 'clients.pay', optional: true, title: 'Registrar un pago', body: 'Cobrale algo al cliente sin entrar a su ficha.'),
            OnboardingStep(anchor: 'clients.new', optional: true, title: 'Nuevo cliente', body: 'Cargá nombre, teléfono y email. Después le podés reservar turnos, cobrarle y ponerle etiquetas.'),
          ],
        ),
        Guide(
          id: 'client.profile',
          section: 'Clientes',
          title: 'La ficha del cliente',
          description: 'Datos, próximos turnos, pagos, etiquetas, notas y los avisos que recibió.',
          icon: Icons.badge_outlined,
          keywords: const ['ficha', 'perfil', 'historial', 'etiquetas', 'notas', 'whatsapp', 'deuda', 'saldo'],
          permissions: const [Permissions.CLIENTES_VER],
          route: AppRoutes.CLIENTS_LIST_ROUTE.path,
          stayOn: RegExp(r'^/client/\d+$'),
          steps: (v) => [
            const OnboardingStep(anchor: 'clients.row', optional: true, title: 'Abrí un cliente', body: 'Vamos a recorrer la ficha de este cliente.'),
            OnboardingStep(anchor: 'client.header', before: reveal('client.header', via: 'clients.row'), title: 'Datos y acciones', body: 'Contacto y etiquetas. Escribile por WhatsApp, editá sus datos, registrá un pago o reservale un turno.'),
            const OnboardingStep(anchor: 'client.kpis', title: 'Números del cliente', body: 'Cuántos turnos tuvo, cuánto gastó y si tiene saldo pendiente.'),
            const OnboardingStep(anchor: 'client.fixed', title: 'Turnos fijos', body: 'Los horarios que tiene todas las semanas.'),
            const OnboardingStep(anchor: 'client.routine', optional: true, title: 'Rutina', body: 'La rutina de entrenamiento que le armaste y lo que te comentó de cada ejercicio.'),
            const OnboardingStep(anchor: 'client.membership', optional: true, title: 'Abono', body: 'El abono del gimnasio, su cuota y el próximo vencimiento.'),
            const OnboardingStep(anchor: 'client.upcoming', title: 'Próximos turnos', body: 'Tocá uno para abrirlo en la agenda.'),
            const OnboardingStep(anchor: 'client.payments', title: 'Pagos', body: 'Todo lo que pagó, con el detalle de cada pago.'),
            const OnboardingStep(anchor: 'client.categories', optional: true, title: 'Categorías', body: 'Su categoría en cada deporte que el establecimiento categoriza (para los torneos).'),
            const OnboardingStep(anchor: 'client.labels', title: 'Etiquetas', body: 'Agrupá clientes (ej. "Profesor", "Moroso") y buscalos por etiqueta en el listado.'),
            const OnboardingStep(anchor: 'client.notes', title: 'Notas', body: 'Lo que quieras recordar del cliente.'),
            const OnboardingStep(anchor: 'client.activity', title: 'Actividad', body: 'Lo último que pasó con el cliente.'),
            const OnboardingStep(anchor: 'client.notifications', optional: true, title: 'Avisos', body: 'Los mensajes que le mandamos: recordatorios, confirmaciones y pagos.'),
          ],
        ),
        Guide(
          id: 'client.routine',
          section: 'Clientes',
          title: 'Armar una rutina',
          description: 'Grupos, ejercicios, series y repeticiones para un cliente del gimnasio.',
          icon: Icons.fitness_center,
          keywords: const ['rutina', 'gimnasio', 'ejercicios', 'entrenamiento', 'series', 'repeticiones'],
          permissions: const [Permissions.CLIENTES_EDITAR],
          isAvailable: () => AdminFeatures.routines,
          route: AppRoutes.CLIENTS_LIST_ROUTE.path,
          stayOn: RegExp(r'^/client/\d+$'),
          steps: (v) => [
            const OnboardingStep(anchor: 'clients.row', optional: true, title: 'Abrí un cliente', body: 'Las rutinas se arman desde la ficha del cliente.'),
            // La card de rutina solo aparece si el cliente es del gimnasio: los pasos del editor dependen de eso.
            OnboardingStep(anchor: 'client.routine', optional: true, before: reveal('client.routine', via: 'clients.row'), title: 'Rutina del cliente', body: 'Acá ves la rutina activa. Con "Nueva rutina" abrís el editor.'),
            OnboardingStep(anchor: 'routine.start', optional: true, before: activate('client.routine'), title: 'Cómo empezar', body: 'Copiá la rutina actual, usá otra de base o creala vacía eligiendo cuántos grupos tiene.'),
            const OnboardingStep(anchor: 'routine.groups', optional: true, title: 'Grupos y ejercicios', body: 'Armá la rutina por grupos (ej. "Día 1", "Tren superior") y sumá ejercicios del catálogo.'),
            const OnboardingStep(anchor: 'routine.copy', optional: true, title: 'Copiar de otra', body: 'Partí de una rutina que ya armaste para otro cliente.'),
            const OnboardingStep(anchor: 'routine.save', optional: true, title: 'Guardar', body: 'El cliente la ve en la app y te puede dejar comentarios de cada ejercicio.'),
          ],
        ),

        // -------------------------------------------------------------------
        // Pagos
        // -------------------------------------------------------------------
        Guide(
          id: 'payments',
          section: 'Pagos',
          title: 'Pagos registrados',
          description: 'Filtrar por fecha, concepto y medio de pago, y ver los totales.',
          icon: Icons.payments_outlined,
          keywords: const ['pagos', 'caja', 'cobros', 'totales', 'efectivo', 'transferencia', 'mercado pago', 'registrar pago'],
          permissions: const [Permissions.PAGOS_VER],
          route: AppRoutes.PAYMENTS_LIST.path,
          steps: (v) => [
            OnboardingStep(anchor: 'payments.filters', before: activate('payments.tab.registered'), title: 'Filtros', body: 'El período, qué se pagó (turnos, productos, abonos), el medio de pago y el cliente.'),
            const OnboardingStep(anchor: 'payments.register', optional: true, title: 'Registrar un pago', body: 'Cargá un pago que se hizo fuera de la agenda.'),
            const OnboardingStep(anchor: 'payments.totals', optional: true, title: 'Totales', body: 'Lo cobrado en el período, separado por medio de pago.'),
            const OnboardingStep(anchor: 'payments.list', optional: true, title: 'Los pagos, día por día', body: 'Hora, cliente, concepto, medio, monto y quién lo registró.'),
          ],
        ),
        Guide(
          id: 'payments.memberships',
          section: 'Pagos',
          title: 'Estado de las cuotas',
          description: 'Quién está al día, quién debe y cómo avisarles.',
          icon: Icons.card_membership_outlined,
          keywords: const ['cuotas', 'abonos', 'vencidas', 'deuda', 'gimnasio', 'recordatorio', 'avisar'],
          permissions: const [Permissions.PAGOS_VER],
          isAvailable: () => AdminFeatures.memberships,
          route: AppRoutes.PAYMENTS_LIST.path,
          steps: (v) => [
            OnboardingStep(anchor: 'board.kpis', before: activate('payments.tab.board'), title: 'Cómo están las cuotas', body: 'Cuántos abonos hay al día, por vencer y vencidos.'),
            const OnboardingStep(anchor: 'board.filters', title: 'Filtros', body: 'Elegí qué estado y qué abono ver. "Avisar a todos" les manda un recordatorio a los que deben.'),
            const OnboardingStep(anchor: 'board.list', optional: true, title: 'Cada abono', body: 'Registrá el pago de la cuota, avisale al cliente o retomá un abono pausado.'),
          ],
        ),

        // -------------------------------------------------------------------
        // Mapa
        // -------------------------------------------------------------------
        Guide(
          id: 'map',
          section: 'Mapa',
          title: 'El mapa del establecimiento',
          description: 'El plano, qué está ocupado ahora y cuánto se usa cada espacio.',
          icon: Icons.map_outlined,
          keywords: const ['plano', 'ocupacion', 'uso', 'mapa', 'ubicacion'],
          permissions: const [Permissions.MAPA_VER],
          route: AppRoutes.CLUB_MAP_ROUTE.path,
          steps: (v) => [
            const OnboardingStep(anchor: 'map.empty', optional: true, title: 'Todavía no hay plano', body: 'Diseñalo una vez: ubicás cada espacio y queda para siempre.'),
            const OnboardingStep(anchor: 'map.modes', optional: true, title: 'Ahora o uso', body: '"Ocupación ahora" pinta lo que está en uso en este momento; el uso muestra cuántas horas se reservó cada uno.'),
            OnboardingStep(anchor: 'map.plan', optional: true, title: 'El plano', body: 'Tocá ${v.space.indefinite} para ver su turno actual, el próximo y sus datos.'),
            const OnboardingStep(anchor: 'map.detail', optional: true, title: 'El detalle', body: 'Desde acá abrís el turno en la agenda.'),
            const OnboardingStep(anchor: 'map.edit', optional: true, title: 'Editar el plano', body: 'Mové, rotá o sumá espacios cuando cambie algo en el establecimiento.'),
          ],
        ),

        // -------------------------------------------------------------------
        // Torneos
        // -------------------------------------------------------------------
        Guide(
          id: 'tournaments',
          section: 'Torneos',
          title: 'Torneos, ranking y categorías',
          description: 'El listado de torneos, el ranking del club y qué deportes categoriza.',
          icon: Icons.emoji_events_outlined,
          keywords: const ['torneo', 'ranking', 'categorias', 'listado', 'estado'],
          permissions: const [Permissions.TORNEOS_VER],
          route: AppRoutes.TOURNAMENTS_ROUTE.path,
          steps: (v) => [
            OnboardingStep(anchor: 'tournaments.filters', before: activate('tournaments.tab.list'), title: 'Por estado', body: 'Borrador, inscripción abierta, cerrada, en juego y terminados.'),
            const OnboardingStep(anchor: 'tournaments.table', optional: true, title: 'Los torneos', body: 'Tocá uno para ver sus equipos, el cuadro y los partidos.'),
            const OnboardingStep(anchor: 'tournaments.new', optional: true, title: 'Nuevo torneo', body: 'Armá uno nuevo: formato, categoría, inscripción y cobro de la entrada.'),
            OnboardingStep(anchor: 'ranking.filters', before: activate('tournaments.tab.ranking'), title: 'Ranking', body: 'Los puntos de cada jugador por deporte, categoría y rama, del club o de toda la ciudad.'),
            const OnboardingStep(anchor: 'ranking.suggestions', optional: true, title: 'Sugerencias de categoría', body: 'Jugadores que, por sus títulos y los votos de sus rivales, podrían cambiar de categoría.'),
            OnboardingStep(anchor: 'categories.sports', optional: true, before: activate('tournaments.tab.categories'), title: 'Deportes que categoriza el club', body: 'Si lo activás, le asignás tu propia categoría a cada jugador y el deporte tiene ranking.'),
            const OnboardingStep(anchor: 'categories.city', optional: true, title: 'Ciudad', body: 'Agrupa el ranking con los demás establecimientos de la misma ciudad.'),
          ],
        ),
        Guide(
          id: 'tournament.new',
          section: 'Torneos',
          title: 'Crear un torneo',
          description: 'Datos, categoría, formato, partidos, inscripción y premios.',
          icon: Icons.add_circle_outline,
          keywords: const ['torneo nuevo', 'crear torneo', 'formato', 'zonas', 'eliminacion', 'inscripcion', 'entrada', 'premios'],
          permissions: const [Permissions.TORNEOS_EDITAR],
          route: AppRoutes.TOURNAMENT_NEW_ROUTE.path,
          steps: (v) => [
            const OnboardingStep(anchor: 'tournamentForm.general', title: 'Datos generales', body: 'Nombre, deporte, modalidad y fechas.'),
            const OnboardingStep(anchor: 'tournamentForm.category', title: 'Categoría', body: 'Qué categoría juega, cuáles más bajas se admiten, la rama y si suma al ranking.'),
            const OnboardingStep(anchor: 'tournamentForm.format', title: 'Formato', body: 'Zonas y eliminación, eliminación directa o liga; cuántos clasifican y cómo se sortea.'),
            OnboardingStep(anchor: 'tournamentForm.matches', title: 'Partidos', body: 'Cómo se cuenta el resultado, cuánto dura cada partido y en qué ${v.space.lowerPlural} se juega.'),
            const OnboardingStep(anchor: 'tournamentForm.entry', title: 'Inscripción y pagos', body: 'Cupo de equipos, cierre de la inscripción y si se cobra entrada.'),
            const OnboardingStep(anchor: 'tournamentForm.prizes', optional: true, title: 'Premios', body: 'Texto libre: se muestra tal cual en la app.'),
            const OnboardingStep(anchor: 'tournamentForm.results', optional: true, title: 'Resultados', body: 'Los equipos cargan el resultado desde la app; definí qué pasa si solo uno lo carga.'),
            const OnboardingStep(anchor: 'tournamentForm.save', title: 'Guardar o publicar', body: 'Un borrador no lo ve nadie. Al publicarlo se abre la inscripción en la app.'),
          ],
        ),
        Guide(
          id: 'tournament.detail',
          section: 'Torneos',
          title: 'Gestionar un torneo',
          description: 'Equipos, pagos de la entrada, el cuadro, los partidos y cada etapa.',
          icon: Icons.account_tree_outlined,
          keywords: const ['torneo', 'equipos', 'cuadro', 'partidos', 'resultados', 'sorteo', 'inscriptos', 'publicar'],
          permissions: const [Permissions.TORNEOS_VER],
          route: AppRoutes.TOURNAMENTS_ROUTE.path,
          stayOn: RegExp(r'^/tournaments/\d+$'),
          steps: (v) => [
            OnboardingStep(anchor: 'tournaments.row', optional: true, before: activate('tournaments.tab.list'), title: 'Abrí un torneo', body: 'Vamos a recorrer este torneo.'),
            OnboardingStep(anchor: 'tournament.header', before: activate('tournaments.row'), title: 'Estado y datos', body: 'En qué etapa está, las fechas, la categoría y la entrada.'),
            const OnboardingStep(anchor: 'tournament.progress', title: 'Etapas', body: 'Borrador → inscripción → cerrado → en juego → terminado.'),
            const OnboardingStep(anchor: 'tournament.actions', optional: true, title: 'El próximo paso', body: 'Publicar, cerrar la inscripción, sortear o programar los partidos, según la etapa. En el menú: editar, avisar pagos pendientes, finalizar o cancelar.'),
            OnboardingStep(anchor: 'tournament.tab.entries', title: 'Equipos', body: 'Los inscriptos, si pagaron la entrada y la lista de espera.'),
            const OnboardingStep(anchor: 'tournament.tab.bracket', optional: true, title: 'Cuadro', body: 'Las zonas y el cuadro de eliminación, con los resultados.'),
            const OnboardingStep(anchor: 'tournament.tab.matches', optional: true, title: 'Partidos', body: 'Programá cada partido, cargá o corregí resultados y resolvé los que quedaron en disputa.'),
          ],
        ),
        Guide(
          id: 'tournament.schedule',
          section: 'Torneos',
          title: 'Programar los partidos',
          description: 'Días y horarios de juego, reglas de descanso, vista previa y publicar.',
          icon: Icons.edit_calendar_outlined,
          keywords: const ['programacion', 'cronograma', 'horarios', 'fixture', 'partidos', 'publicar'],
          permissions: const [Permissions.TORNEOS_EDITAR],
          route: AppRoutes.TOURNAMENTS_ROUTE.path,
          stayOn: RegExp(r'^/tournaments/\d+/schedule$'),
          steps: (v) => [
            OnboardingStep(anchor: 'tournaments.row.playing', optional: true, before: activate('tournaments.tab.list'), title: 'Un torneo en juego', body: 'La programación se arma después del sorteo.'),
            OnboardingStep(anchor: 'tournament.schedule', optional: true, before: activate('tournaments.row.playing'), title: 'Programación', body: 'Abre el armado del cronograma.'),
            OnboardingStep(anchor: 'schedule.when', before: activate('tournament.schedule'), title: 'Cuándo se juega', body: 'Agregá los días y los horarios disponibles para cada fase.'),
            const OnboardingStep(anchor: 'schedule.rules', title: 'Reglas', body: 'El descanso mínimo entre partidos y cuántos puede jugar un equipo por día.'),
            const OnboardingStep(anchor: 'schedule.generate', optional: true, title: 'Vista previa', body: 'Turni reparte los partidos. Si alguno no entra, te muestra por qué y lo podés ubicar a mano.'),
            const OnboardingStep(anchor: 'schedule.preview', title: 'El cronograma', body: 'Cada partido en su día, horario y espacio. Revisalo antes de publicar.'),
            const OnboardingStep(anchor: 'schedule.publish', title: 'Publicar', body: 'Los partidos quedan en la agenda y los equipos los ven en la app.'),
          ],
        ),

        // -------------------------------------------------------------------
        // Configuración
        // -------------------------------------------------------------------
        Guide(
          id: 'config.partitions',
          section: 'Configuración',
          title: 'Servicios y espacios',
          description: 'Qué ofrece el establecimiento y en qué espacios se dan los turnos.',
          icon: Icons.grid_view_outlined,
          keywords: const ['servicio', 'deporte', 'espacios', 'alta', 'dar de baja', 'activo', 'techada'],
          permissions: const [Permissions.CONFIGURACION_VER],
          route: _clubConfig,
          steps: (v) => [
            OnboardingStep(anchor: 'partitions.list', before: reveal('partitions.list', via: 'clubConfig.tab.partitions'), title: 'Tus servicios', body: 'Cada servicio con sus ${v.space.lowerPlural}. El interruptor lo da de baja sin borrar los turnos que ya tiene.'),
            OnboardingStep(anchor: 'partitions.card', optional: true, title: 'Un servicio', body: 'Agregá, editá o desactivá ${v.space.lowerPlural}.'),
            const OnboardingStep(anchor: 'partitions.new', optional: true, title: 'Nuevo servicio', body: 'Elegí el tipo (pádel, gimnasio, peluquería...) y, si querés, ponele un nombre propio.'),
          ],
        ),
        Guide(
          id: 'config.tariffs',
          section: 'Configuración',
          title: 'Tarifas por horario',
          description: 'Cuánto sale cada turno según el servicio, el día y la hora.',
          icon: Icons.attach_money,
          keywords: const ['precio', 'tarifa', 'franja', 'horario pico', 'fin de semana', 'valor'],
          permissions: const [Permissions.CONFIGURACION_VER],
          route: _clubConfig,
          steps: (v) => [
            OnboardingStep(anchor: 'tariffs.services', before: reveal('tariffs.services', via: 'clubConfig.tab.tariffs'), title: 'Servicio', body: 'Las tarifas son por servicio: elegí cuál configurar.'),
            const OnboardingStep(anchor: 'tariffs.new', optional: true, waitFor: Duration(seconds: 4), title: 'Nueva tarifa', body: 'Una tarifa agrupa espacios que salen lo mismo.'),
            OnboardingStep(anchor: 'tariffs.card', optional: true, title: 'Una tarifa', body: 'Sus ${v.space.lowerPlural} y sus franjas horarias: cada franja tiene días, horario y precio.'),
          ],
        ),
        Guide(
          id: 'config.products',
          section: 'Configuración',
          title: 'Productos y adicionales',
          description: 'Lo que se vende o alquila en el turno: bebidas, paletas, toallas.',
          icon: Icons.shopping_bag_outlined,
          keywords: const ['productos', 'adicionales', 'bebidas', 'alquiler', 'categorias', 'kiosco', 'buffet'],
          permissions: const [Permissions.CONFIGURACION_VER],
          route: _clubConfig,
          steps: (v) => [
            OnboardingStep(anchor: 'products.list', before: reveal('products.list', via: 'clubConfig.tab.products'), title: 'Productos', body: 'Lo que se suma a la cuenta de un turno. Filtralos por categoría.'),
            const OnboardingStep(anchor: 'products.new', optional: true, title: 'Agregar un producto', body: 'Nombre, precio y categoría.'),
            const OnboardingStep(anchor: 'products.categories', title: 'Categorías', body: 'Ordená los productos (ej. "Bebidas", "Alquileres") para encontrarlos rápido al cobrar.'),
          ],
        ),
        Guide(
          id: 'config.requests',
          section: 'Configuración',
          title: 'Solicitudes de turno',
          description: 'Cuánto dura una solicitud, hasta cuándo se puede cancelar y la seña.',
          icon: Icons.schedule_outlined,
          keywords: const ['solicitud', 'vencimiento', 'cancelacion', 'seña', 'anticipo', 'app'],
          permissions: const [Permissions.CONFIGURACION_VER],
          route: _clubConfig,
          steps: (v) => [
            OnboardingStep(anchor: 'requests.settings', before: reveal('requests.settings', via: 'clubConfig.tab.requests'), title: 'Reglas de las solicitudes', body: 'Cuánto tiempo tenés para responder una solicitud, hasta cuándo el cliente puede cancelar y si tiene que dejar seña.'),
            const OnboardingStep(anchor: 'requests.save', optional: true, title: 'Guardar', body: 'Los cambios valen para las solicitudes nuevas.'),
          ],
        ),
        Guide(
          id: 'config.payments',
          section: 'Configuración',
          title: 'Cobros online',
          description: 'Vincular la cuenta de Mercado Pago para cobrar señas y turnos desde la app.',
          icon: Icons.credit_card,
          keywords: const ['mercado pago', 'online', 'seña', 'cobrar', 'vincular', 'cuenta'],
          permissions: const [Permissions.CONFIGURACION_VER],
          route: _clubConfig,
          steps: (v) => [
            OnboardingStep(anchor: 'payments.mercadoPago', before: reveal('payments.mercadoPago', via: 'clubConfig.tab.payments'), title: 'Mercado Pago', body: 'Vinculá la cuenta del establecimiento: la plata de las señas y los turnos pagados en la app va directo ahí.'),
          ],
        ),
        Guide(
          id: 'config.memberships',
          section: 'Configuración',
          title: 'Abonos del gimnasio',
          description: 'Los abonos que vendés, cuándo vence la cuota y los recordatorios.',
          icon: Icons.card_membership_outlined,
          keywords: const ['abono', 'cuota', 'gimnasio', 'plan', 'mensual', 'recordatorio', 'vencimiento'],
          permissions: const [Permissions.CONFIGURACION_VER],
          isAvailable: () => AdminFeatures.memberships,
          route: _clubConfig,
          steps: (v) => [
            OnboardingStep(anchor: 'plans.list', before: reveal('plans.list', via: 'clubConfig.tab.memberships'), title: 'Abonos por servicio', body: 'Cada abono dice cuántos días por semana puede venir el cliente y cuánto sale.'),
            const OnboardingStep(anchor: 'plans.new', optional: true, title: 'Nuevo abono', body: 'Precio, días por semana y si la cuota vence el mismo día para todos o a un mes de que empezó cada cliente.'),
            const OnboardingStep(anchor: 'plans.reminders', optional: true, title: 'Recordatorios automáticos', body: 'Le avisamos al cliente el día que vence la cuota y cuando pasa a vencida.'),
          ],
        ),

        // -------------------------------------------------------------------
        // Usuarios
        // -------------------------------------------------------------------
        Guide(
          id: 'users.admins',
          section: 'Usuarios',
          title: 'Invitar administradores',
          description: 'Sumar a alguien al panel con un rol, cambiarlo o deshabilitarlo.',
          icon: Icons.manage_accounts_outlined,
          keywords: const ['usuario', 'administrador', 'invitar', 'empleado', 'acceso', 'link'],
          permissions: const [Permissions.ADMINISTRADORES_VER],
          route: AppRoutes.USERS_ROUTE.path,
          steps: (v) => [
            OnboardingStep(anchor: 'admins.invite', optional: true, before: activate('users.tab.admins'), title: 'Invitar', body: 'Elegí el rol y compartí el link: quien lo abra entra con su cuenta de Google.'),
            const OnboardingStep(anchor: 'admins.table', title: 'Administradores', body: 'Quiénes entran al panel, con qué rol y si están activos. Desde el menú de cada uno le cambiás el rol o lo deshabilitás.'),
            const OnboardingStep(anchor: 'admins.invitations', optional: true, title: 'Invitaciones pendientes', body: 'Cada link sirve una sola vez. Copialo de nuevo o anulalo.'),
          ],
        ),
        Guide(
          id: 'users.roles',
          section: 'Usuarios',
          title: 'Roles y permisos',
          description: 'Qué pantallas ve cada administrador y qué puede hacer en ellas.',
          icon: Icons.admin_panel_settings_outlined,
          keywords: const ['rol', 'permisos', 'acceso', 'recepcion', 'empleado'],
          permissions: const [Permissions.ROLES_VER],
          route: AppRoutes.USERS_ROUTE.path,
          steps: (v) => [
            OnboardingStep(anchor: 'roles.table', before: activate('users.tab.roles'), title: 'Roles', body: 'Cada rol con sus permisos y cuántos administradores lo tienen. El super administrador puede todo.'),
            const OnboardingStep(anchor: 'roles.new', optional: true, title: 'Nuevo rol', body: 'Ej. "Recepción": ve la agenda y cobra, pero no toca la configuración.'),
          ],
        ),

        // -------------------------------------------------------------------
        // Avisos
        // -------------------------------------------------------------------
        Guide(
          id: 'notifications',
          section: 'Avisos',
          title: 'Notificaciones',
          description: 'Los avisos de reservas, solicitudes y pagos que llegan al panel.',
          icon: Icons.notifications_outlined,
          keywords: const ['avisos', 'campanita', 'notificaciones', 'alertas', 'leido'],
          steps: (v) => [
            const OnboardingStep(anchor: 'nav.notifications', title: 'La campanita', body: 'El número son los avisos sin leer.'),
            OnboardingStep(anchor: 'notifications.panel', before: activate('nav.notifications'), title: 'Los avisos', body: 'Reservas nuevas, solicitudes, cancelaciones y pagos. Tocá uno para ir al turno o al cliente.'),
            const OnboardingStep(anchor: 'notifications.readAll', optional: true, title: 'Marcar todo como leído', body: 'Para empezar de cero.'),
          ],
        ),

        // -------------------------------------------------------------------
        // Turni (operadores de la plataforma)
        // -------------------------------------------------------------------
        Guide(
          id: 'platform.clubs',
          section: 'Turni',
          title: 'Dar de alta un establecimiento',
          description: 'Crear un club nuevo con su dueño y mandarle cómo entrar.',
          icon: Icons.add_business_outlined,
          keywords: const ['alta', 'club nuevo', 'establecimiento', 'dueño', 'operador', 'plataforma'],
          isAvailable: () => sl<AuthCubit>().isPlatformOperator(),
          route: AppRoutes.PLATFORM_CLUBS_ROUTE.path,
          steps: (v) => const [
            OnboardingStep(anchor: 'platform.form', title: 'Datos del alta', body: 'Nombre del establecimiento y email de Google del dueño: entra como super administrador.'),
            OnboardingStep(anchor: 'platform.submit', title: 'Dar de alta', body: 'Después te armamos el mail con el link para que entre.'),
          ],
        ),
      ];

  /// Pasos del recorrido de bienvenida de Configuración (también los usa
  /// `ClubConfigTour`, que lo ofrece solo al dueño de un club recién creado).
  static List<OnboardingStep> clubSetupSteps() => [
        OnboardingStep(
          anchor: 'clubInfo.name',
          before: reveal('clubInfo.name', via: 'clubConfig.tab.info'),
          title: 'Te damos la bienvenida a Turni',
          body: 'Empecemos por los datos de tu establecimiento. Este nombre es el que ven tus clientes al buscarte.',
        ),
        const OnboardingStep(
          anchor: 'clubInfo.address',
          title: 'Dirección',
          body: 'Escribila y tocá la lupa: te la ubicamos en el mapa.',
        ),
        const OnboardingStep(
          anchor: 'clubInfo.map',
          title: 'Ubicación en el mapa',
          body: 'Tocá el mapa justo donde está el establecimiento y después "Confirmar ubicación". '
              'Con esto te encuentran los clientes que buscan cerca.',
        ),
        const OnboardingStep(
          anchor: 'clubInfo.save',
          title: 'Guardá los cambios',
          body: 'Nada se guarda hasta que tocás "Guardar cambios".',
        ),
        const OnboardingStep(
          anchor: 'clubConfig.tab.partitions',
          optional: true,
          title: 'Servicios y espacios',
          body: 'Después cargá lo que ofrecés (ej. pádel, una sala, un profesional) y sus espacios. '
              'Sin servicios todavía no se pueden tomar turnos.',
        ),
        const OnboardingStep(
          anchor: 'clubConfig.tab.tariffs',
          optional: true,
          title: 'Tarifas por horario',
          body: 'Definí cuánto sale cada turno según el día y la hora.',
        ),
        const OnboardingStep(
          anchor: 'clubConfig.tab.payments',
          optional: true,
          title: 'Cobros online',
          body: 'Si querés cobrar señas o turnos online, vinculá tu cuenta de Mercado Pago. '
              'Podés volver a ver este recorrido desde el signo de pregunta del menú.',
        ),
      ];
}
