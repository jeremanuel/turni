import 'package:bloc/bloc.dart';

import '../../../../../core/config/service_locator.dart';
import '../../../../../domain/entities/club_type.dart';
import '../../../../../domain/usecases/club_type/get_types.dart';
import '../../../../../infrastructure/api/providers/club_type_provider.dart';
import '../../../../../infrastructure/api/repositories/club_type_repository_impl.dart';
import '../../../../core/cubit/auth/auth_cubit.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  final AuthCubit authCubit = sl<AuthCubit>();

  HomeCubit() : super(HomeInitial()) {
    getRangedClubTypes();
  }

  List<ClubType> get getClubTypes => state.clubTypes;

  getRangedClubTypes() async {
    List<ClubType> clubTypes = await GetTypes(
      ClubTypeRepositoryImplementation(clubTypeProvider: ClubTypeProvider()),
    ).excute(authCubit.state.userCredential!.location!);

    emit(HomeLoaded(clubTypes));
  }
}
