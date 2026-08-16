import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:turni/core/config/service_locator.dart';
import 'package:turni/presentation/core/cubit/auth/auth_cubit.dart';
import 'package:turni/presentation/core/input/custom_outlined_button.dart';
import 'package:turni/presentation/core/styles/text_styles.dart';

import '../../../core/config/app_routes.dart';

class CustomDrawer extends StatelessWidget {
  CustomDrawer({super.key});

  final authCubit = sl<AuthCubit>();

  @override
  Widget build(BuildContext context) {

    return Drawer(
      child: Column(
        children: [
          buildDrawerHeader(),
          if(authCubit.isAdmin())
            ListTile(
              leading: const Icon(Icons.settings),
              title: const Text("Configuración"),
              onTap: (){
                Navigator.pop(context);
                context.push(AppRoutes.ADMIN_SETTINGS_ROUTE['path']!);
              },
            ),
          const Spacer(),
          CustomOutlinedButton(onPressed: authCubit.signOutGoogle, child: Center(child: Text("Salir")) )
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
                  backgroundImage: NetworkImage(authCubit.state.userCredential!.picture!),
                ),
              ),
             const  SizedBox(
                width: 20,
              ),
              SizedBox(
                height: 80,
                width: 80,
                child: Center(child: Text(authCubit.state.userCredential!.person!.name, overflow: TextOverflow.clip, style: TextStyles.h2,)))
            ],
          )
        );
  }
}
