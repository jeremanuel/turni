import 'package:bloc/bloc.dart';
import 'package:meta/meta.dart';

import '../../../core/utils/entities/coordinate.dart';
import '../../../domain/entities/club_type.dart';
import '../../../domain/usecases/club_type/get_types.dart';
import '../../../infrastructure/api/providers/club_type_provider.dart';
import '../../../infrastructure/api/repositories/club_type_repository_impl.dart';

part 'home_state.dart';

class HomeCubit extends Cubit<HomeState> {
  HomeCubit() : super(HomeInitial()) {
    getRangedClubTypes();
  }

  List<ClubType> get getClubTypes => state.clubTypes;

  getRangedClubTypes() async {
    List<ClubType> clubTypes = await GetTypes(
      ClubTypeRepositoryImplementation(clubTypeProvider: ClubTypeProvider()),
    ).excute(Coordinate(latitud: -37.320132, longitud: -59.122182));

    emit(HomeLoaded(clubTypes));
  }
}
