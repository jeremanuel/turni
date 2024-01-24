

import 'package:get_it/get_it.dart';
import 'package:turni/core/cubit/auth/auth_cubit.dart';
import 'package:turni/presentation/feed/cubit/feed/feed_cubit.dart';

final sl = GetIt.instance;

class ServiceLocator {
  static initializeDependencies() async {

     sl.registerSingleton<AuthCubit>(AuthCubit());
     sl.registerLazySingleton<FeedCubit>(() => FeedCubit());
     
  }
}