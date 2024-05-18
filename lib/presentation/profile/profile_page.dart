import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/app_router.dart';
import '../../core/config/service_locator.dart';
import '../../core/utils/entities/coordinate.dart';
import '../../domain/entities/club_type.dart';
import '../../domain/usecases/club_type/get_types.dart';
import '../../infrastructure/api/providers/club_type_provider.dart';
import '../../infrastructure/api/repositories/club_type_repository_impl.dart';
import '../core/cubit/auth/auth_cubit.dart';
import '../core/widgets/button/button_navigation.dart';
import '../core/widgets/carrousel/carrousel_horizontal.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

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
            MaterialButton(
              elevation: 0,
              color: whiteColor,
              height: 50,
              shape: RoundedRectangleBorder(
                side: const BorderSide(
                  color: whiteColor,
                ),
                borderRadius: BorderRadius.circular(40),
              ),
              onPressed: handleLogout,
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "Cerrar sesión",
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w400,
                      color: Color.fromRGBO(159, 121, 242, 1),
                    ),
                  ),
                ],
              ),
            )
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
