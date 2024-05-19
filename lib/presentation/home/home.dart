import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
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

  final backgroundColor = Color.fromRGBO(240, 239, 242, 1);
  final TextEditingController _textController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<HomeCubit, HomeState>(
      bloc: homeCubit,
      builder: (context, state) {
        return Scaffold(
          backgroundColor: backgroundColor,
          body: Container(
            alignment: Alignment.center,
            padding: const EdgeInsets.symmetric(vertical: 42, horizontal: 32),
            child: Column(children: [
              buildHeader(),
              const SizedBox(height: 42),
              buildSearchBox(),
              const SizedBox(height: 42),
              buildBody(context, state),
            ]),
          ),
        );
      },
    );
  }

  Widget buildHeader() {
    const textColor = Color.fromRGBO(103, 43, 234, 1);

    return const Row(
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              "¡Hola Chiri Rodríguez!",
              style: TextStyle(
                  color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
            ),
            Text(
              "¿Cómo estás hoy?",
              style: TextStyle(
                  color: textColor,
                  fontWeight: FontWeight.normal,
                  fontSize: 13),
            ),
          ],
        ),
        Spacer(),
        CircleAvatar(
          radius: 30,
          backgroundImage: AssetImage('assets/img/test.png'),
        )
      ],
    );
  }

  Widget buildSearchBox() {
    const backgroundColor = Color.fromRGBO(203, 178, 255, 1);
    const textColor = Color.fromRGBO(240, 239, 242, 1);
    const textStyle =
        TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 11);

    return CupertinoSearchTextField(
      backgroundColor: backgroundColor,
      padding: const EdgeInsets.all(8),
      itemColor: textColor,
      itemSize: 14,
      prefixInsets: const EdgeInsetsDirectional.fromSTEB(6, 4, 0, 3),
      suffixInsets: const EdgeInsetsDirectional.fromSTEB(0, 4, 5, 2),
      placeholder: "Buscar actividad...",
      placeholderStyle: textStyle,
      style: textStyle,
      controller: _textController,
    );
  }

  Widget buildBody(BuildContext context, HomeState state) {
    List<Widget> buttonActivities = getButttonActivities(context);

    return CarrouselHorizontal(
        children: state.isLoading ? [] : buttonActivities);
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
