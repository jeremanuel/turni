import 'package:bloc/bloc.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/entities/range_date.dart';
import '../../../core/utils/types/util_dates.dart';
import '../../../domain/entities/session.dart';
import '../../../domain/usecases/session/get_sessions.dart';
import '../../../infrastructure/api/providers/client/client_session_provider.dart';
import '../../../infrastructure/api/repositories/client/client_session_repository_impl.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../../core/dates_carrousel/dates_carrousel.dart';
import '../home_manager_screen/home/cubit/home_cubit.dart';
import 'client_session_manager_event.dart';
import 'client_session_manager_state.dart';

class ClientSessionManagerBloc
    extends Bloc<ClientSessionManagerEvent, ClientSessionManagerState> {
  final homeCubit = sl<HomeCubit>();
  final authCubit = sl<AuthCubit>();
  final getSessionsUseCase = GetClientSessions(
      ClientSessionRepositoryImplementation(
          sessionProvider: ClientSessionProvider()));

  final DatesCarrouselController datesCarrouselController =
      DatesCarrouselController();

  final DateTime fromNow =
      DateTime.now().copyWith(second: 0, millisecond: 0, microsecond: 0);
  final int batchIntervalDays = 7;

  ClientSessionManagerBloc()
      : super(
          ClientSessionManagerState(
            currentDate: DateTime.now(),
            sessions: [],
          ),
        ) {
    final location = authCubit.state.userCredential!.location!;
    final to = fromNow
        .add(Duration(days: batchIntervalDays))
        .copyWith(hour: 23, minute: 59);
    final rangeDate = RangeDate(
      from: fromNow,
      to: to,
    );

    on<LoadClubTypeEvent>((event, emit) {
      emit(state.copyWith(clubType: event.clubType));
    });

    on<ClientSessionLoadEvent>((event, emit) async {
      emit(state.copyWith(
        isFirstLoad: true,
        isLoadingSessions: true,
      ));

      List<Session> sessions = await getSessionsUseCase.excute(
        state.clubType!.clubTypeId,
        location,
        rangeDate,
      );

      List<Session> filter = sessions
          .where((Session session) =>
              UtilDates.isSameDate(session.startTime, state.currentDate))
          .toList();

      emit(state.copyWith(
        isFirstLoad: false,
        isLoadingSessions: false,
        sessions: sessions,
        filteredSessions: filter,
        rangeDate: rangeDate,
      ));
    });

    on<ClientSessionChangeDateEvent>((event, emit) async {
      datesCarrouselController
          .setDate!(event.newDate.copyWith(hour: 0, minute: 0));

      if (state.rangeDate!.isBetween(event.newDate) ||
          state.rangeDate!.isSameDate(event.newDate)) {
        List<Session> filter = state.sessions
            .where((Session session) =>
                UtilDates.isSameDate(session.startTime, event.newDate))
            .toList();

        emit(state.copyWith(
          filteredSessions: filter,
        ));
        return;
      }

      DateTime auxFrom =
          state.rangeDate!.from!.add(Duration(days: batchIntervalDays + 1));
      DateTime toAux =
          state.rangeDate!.to!.add(Duration(days: batchIntervalDays + 1));
      RangeDate auxRangeDate = RangeDate(from: auxFrom, to: toAux);

      emit(
        state.copyWith(
          currentDate: event.newDate,
          isLoadingSessions: true,
          rangeDate: RangeDate(from: state.rangeDate!.from!, to: toAux),
        ),
      );

      List<Session> sessions = await getSessionsUseCase.excute(
        state.clubType!.clubTypeId,
        location,
        auxRangeDate,
      );

      List<Session> filter = sessions
          .where((Session session) =>
              UtilDates.isSameDate(session.startTime, event.newDate))
          .toList();

      print(sessions.length);
      print(filter.length);

      final newSessions = [...state.sessions, ...sessions];

      emit(state.copyWith(
        isLoadingSessions: false,
        sessions: newSessions,
        filteredSessions: filter,
      ));
    });
  }
}
