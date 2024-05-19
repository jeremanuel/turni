import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../core/config/service_locator.dart';
import '../../domain/entities/club_type.dart';
import '../core/cubit/auth/auth_cubit.dart';
import '../core/widgets/button/button_navigation.dart';
import '../core/widgets/carrousel/carrousel_horizontal.dart';
import 'cubit/home_cubit.dart';

class HomePage extends StatelessWidget {
  late final HomeCubit homeCubit;

  HomePage({super.key}) {
    homeCubit = sl<HomeCubit>();
  }

  @override
  Widget build(BuildContext context) {
    const whiteColor = Color.fromRGBO(249, 247, 254, 1);
    const backgroundColor = Color.fromRGBO(240, 239, 242, 1);

    return BlocBuilder<HomeCubit, HomeState>(
      bloc: homeCubit,
      builder: (context, state) {
        List<Widget> buttonActivities = getButttonActivities(context);

        return Scaffold(
          backgroundColor: backgroundColor,
          body: Column(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              CarrouselHorizontal(
                  children: state.isLoading ? [] : buttonActivities)
            ],
          ),
        );
      },
    );
  }

  List<Widget> getButttonActivities(BuildContext context) {
    return homeCubit.getClubTypes
        .map((clubType) => ButtonNavigation(
              text: clubType.name,
              svg: "assets/img/${clubType.logo}.svg",
              onPressed: () async {
                context.push(
                  "/session_feed",
                  extra: ClubType(
                      clubTypeId: clubType.clubTypeId, name: clubType.name),
                );
              },
            ))
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
