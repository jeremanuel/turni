import 'package:flutter/material.dart';
import '../../../core/config/service_locator.dart';
import '../../core/cubit/auth/auth_cubit.dart';
import '../../core/input/custom_outlined_button.dart';
import '../../core/styles/text_styles.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer({super.key});

  final authCubit = sl<AuthCubit>();

  @override
  Widget build(BuildContext context) {

    return Drawer(
      child: Column(
        children: [
          buildDrawerHeader(),
          const Spacer(),
          CustomOutlinedButton(onPressed: authCubit.signOutGoogle, child: const Center(child: Text("Salir")) )
        ],
      )
    );
  }

  DrawerHeader buildDrawerHeader() {
    return DrawerHeader(
      
          child: Row(
            children: [
              SizedBox(
                height: 100,
                width: 100,
                child: CircleAvatar(
                  backgroundImage: NetworkImage(authCubit.state.userCredential!.picture ?? ""),
                ),
              ),
             const  SizedBox(
                width: 20,
              ),
              SizedBox(
                height: 80,
                width: 80,
                child: Center(child: Text(authCubit.state.userCredential!.person.name, overflow: TextOverflow.clip, style: TextStyles.h2,)))
            ],
          )
        );
  }
}
