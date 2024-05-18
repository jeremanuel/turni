import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/service_locator.dart';
import '../../core/utils/entities/coordinate.dart';
import '../../domain/entities/club_type.dart';
import '../../domain/usecases/club_type/get_types.dart';
import '../../infrastructure/api/providers/club_type_provider.dart';
import '../../infrastructure/api/repositories/club_type_repository_impl.dart';
import '../core/cubit/auth/auth_cubit.dart';
import '../core/widgets/button/button_navigation.dart';
import '../core/widgets/carrousel/carrousel_horizontal.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    const whiteColor = Color.fromRGBO(249, 247, 254, 1);
    const backgroundColor = Color.fromRGBO(240, 239, 242, 1);

    return Scaffold(
      appBar: AppBar(),
      backgroundColor: backgroundColor,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            CarrouselHorizontal(children: [
              ButtonNavigation(
                  text: "Tenis",
                  svg: "assets/img/tennis.svg",
                  onPressed: () async {
                    context.push(
                      "/session_feed",
                      extra: ClubType(club_type_id: 1, name: "Tenis"),
                    );
                  }),
              ButtonNavigation(text: "Fútbol", svg: "assets/img/football.svg"),
              ButtonNavigation(text: "Yoga", svg: "assets/img/yoga.svg"),
              ButtonNavigation(text: "Voley", svg: "assets/img/voleyball.svg"),
              ButtonNavigation(text: "Padel", svg: "assets/img/padel.svg"),
              ButtonNavigation(
                  text: "Basquet", svg: "assets/img/basketball.svg"),
              ButtonNavigation(text: "Tenis", svg: "assets/img/tennis.svg"),
              ButtonNavigation(text: "Tenis", svg: "assets/img/tennis.svg"),
              ButtonNavigation(text: "Tenis", svg: "assets/img/tennis.svg"),
              ButtonNavigation(text: "Tenis", svg: "assets/img/tennis.svg"),
              ButtonNavigation(text: "Tenis", svg: "assets/img/tennis.svg"),
              ButtonNavigation(text: "Tenis", svg: "assets/img/tennis.svg"),
            ])
          ],
        ),
      ),
    );
  }

  Future<List<Widget>> getButttonActivities() async {
    List<ClubType> clubTypes = await GetTypes(
      ClubTypeRepositoryImplementation(clubTypeProvider: ClubTypeProvider()),
    ).excute(Coordinate(latitud: "-37.320132", longitud: "-59.122182"));

    return clubTypes
        .map((clubType) =>
            ButtonNavigation(text: clubType.name, svg: "assets/img/tenis.svg"))
        .toList();
  }

  void handleLogout() async {
    try {
      sl<AuthCubit>().signOutGoogle();
    } catch (error) {
      sl<AuthCubit>().emitError(error.toString());
    }
  }
}
