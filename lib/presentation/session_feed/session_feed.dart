import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../core/config/service_locator.dart';
import '../../core/utils/entities/range_date.dart';
import '../../domain/entities/club_type.dart';
import '../../domain/entities/session.dart';
import '../../domain/entities/template_message.dart';
import '../core/cubit/auth/auth_cubit.dart';
import '../core/dates_carrousel/dates_carrousel.dart';
import 'cubit/session_cubit.dart';

extension StringExtension on String {
  String capitalize() {
    return "${this[0].toUpperCase()}${this.substring(1).toLowerCase()}";
  }
}

class SessionFeedPage extends StatelessWidget {
  final ClubType clubType;
  late final SessionCubit sessionCubit;
  final AuthCubit authCubit = sl<AuthCubit>();
  final DatesCarrouselController datesCarrouselController =
      DatesCarrouselController();

  final DateTime fromNow = DateTime.now().copyWith(hour: 0, minute: 0);
  final int minDays = 7;

  SessionFeedPage({super.key, required this.clubType}) {
    sessionCubit = sl<SessionCubit>();

    sessionCubit.loadSessions(
        clubType,
        authCubit.state.userCredential!.location!,
        RangeDate(
          from: fromNow,
          to: fromNow
              .add(Duration(days: minDays))
              .copyWith(hour: 23, minute: 59),
        ));
  }

  void launchWppMessage(Session session) {
    final user = authCubit.state.userCredential;
    final message = user!.templateMessage!;
    final templateMessage = TemplateMessage(link: message);

    templateMessage.populateLinkFromSession([session, user.client!.person]);

    launchUrl(templateMessage.getPopulatedLink());
  }

  @override
  Widget build(BuildContext context) {
    const backgroundColor = Color.fromRGBO(159, 121, 242, 1);
    const gap = SizedBox(height: 22);
    final maxHeight = MediaQuery.of(context).size.height;
    final maxWidth = MediaQuery.of(context).size.width;

    return BlocBuilder<SessionCubit, SessionState>(
        bloc: sessionCubit,
        builder: (context, state) {
          return Scaffold(
              backgroundColor: backgroundColor,
              body: Stack(
                alignment: Alignment.center,
                children: [
                  Positioned(
                    top: -325,
                    height: 650,
                    width: 650,
                    child: OverflowBox(
                      maxHeight: 650,
                      maxWidth: 650,
                      child: Container(
                        height: 1200,
                        width: 1200,
                        decoration: const BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                            tileMode: TileMode.repeated,
                            stops: [0.52, 1],
                            colors: [
                              Color.fromRGBO(120, 67, 235, 0.6),
                              Color.fromRGBO(240, 239, 242, 0.6)
                            ],
                          ),
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    child: Container(
                      height: maxHeight * .7, //.9 en su version expanded
                      width: maxWidth * .8, //1
                      padding: const EdgeInsets.all(22),
                      decoration: const BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.only(
                            topLeft: Radius.circular(50),
                            topRight: Radius.circular(50),
                          )),
                      child: Column(
                        children: [
                          const SizedBox(height: 12),
                          Container(
                            width: 46,
                            height: 3,
                            decoration: BoxDecoration(
                              color: const Color.fromRGBO(203, 178, 255, 1),
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          gap,
                          const Text(
                            "Turnos disponibles",
                            style: TextStyle(
                                color: Color.fromRGBO(159, 121, 242, 1),
                                fontSize: 24,
                                fontWeight: FontWeight.w600),
                          ),
                          gap,
                          Expanded(
                            child: ListView(
                              addRepaintBoundaries: false,
                              children: getListItemView(state),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    top: maxHeight * 0.05,
                    left: 0,
                    child: Container(
                      height: maxHeight * .3,
                      width: maxWidth,
                      alignment: Alignment.topLeft,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 40),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                IconButton(
                                    iconSize: 28,
                                    onPressed: () => context.pop(),
                                    icon: const Icon(
                                      Icons.arrow_back,
                                      color: Colors.white,
                                    )),
                                Text(
                                  "${DateFormat('MMMM yyyy').format(fromNow).capitalize()} - ${clubType.name}",
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 24,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          SizedBox(
                            height: maxHeight * .1,
                            width: maxWidth,
                            child: DatesCarrousel(
                              containerWidth: maxWidth,
                              datesCarrouselController:
                                  datesCarrouselController,
                              onSelect: (date) {
                                print(date);
                              },
                            ),
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ));
        });
  }

  List<Widget> getListItemView(SessionState state) {
    if (state.isLoading) return [const Text('Loading')];

    getBackgroundColor(int index) => index % 2 == 0
        ? Color.fromRGBO(159, 121, 242, 1)
        : Color.fromRGBO(103, 43, 234, 1);

    return state.sessions.asMap().entries.map((entry) {
      int index = entry.key;
      Session session = entry.value;
      return GestureDetector(
        onTap: () => launchWppMessage(session),
        child: Container(
          decoration: BoxDecoration(
            color: getBackgroundColor(index),
            borderRadius: const BorderRadius.all(Radius.circular(15)),
          ),
          margin: const EdgeInsets.only(bottom: 22),
          padding: const EdgeInsets.symmetric(horizontal: 56, vertical: 14),
          child: Column(
            children: [
              Text(
                '${DateFormat('hh:mm').format(session.startTime)} - ${DateFormat('hh:mm').format(session.startTime.add(Duration(minutes: session.duration)))}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Text(
                '${session.clubName}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      );
    }).toList();
  }
}
