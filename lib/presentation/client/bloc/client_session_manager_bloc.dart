import 'package:bloc/bloc.dart';
import '../../../core/config/service_locator.dart';
import '../../../core/utils/entities/range_date.dart';
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

  final DateTime fromNow = DateTime.now().copyWith(hour: 0, minute: 0);
  final int minDays = 7;

  ClientSessionManagerBloc()
      : super(
          ClientSessionManagerState(
            currentDate: DateTime.now(),
            sessions: [],
          ),
        ) {
    final rangeDate = RangeDate(
      from: fromNow,
      to: fromNow.add(Duration(days: minDays)).copyWith(hour: 23, minute: 59),
    );
    final location = authCubit.state.userCredential!.location!;

    on<LoadClubTypeEvent>((event, emit) {
      emit(state.copyWith(clubType: event.clubType));
    });

    on<ClientSessionLoadEvent>((event, emit) async {
      emit(state.copyWith(isFirstLoad: true, isLoadingSessions: true));

      List<Session> sessions = await getSessionsUseCase.excute(
        state.clubType!.clubTypeId,
        location,
        rangeDate,
      );

      emit(state.copyWith(
        sessions: sessions,
        isFirstLoad: false,
        isLoadingSessions: false,
      ));
    });

    on<ClientSessionChangeDateEvent>((event, emit) async {
      emit(
        state.copyWith(currentDate: event.newDate, isLoadingSessions: true),
      );

      datesCarrouselController.setDate!(event.newDate);

      List<Session> sessions = await getSessionsUseCase.excute(
        state.clubType!.clubTypeId,
        location,
        rangeDate,
      );

      emit(state.copyWith(
        sessions: sessions,
        isLoadingSessions: false,
      ));
    });
  }
}
