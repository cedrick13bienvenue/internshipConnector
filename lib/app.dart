import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/data/repositories/auth_repository.dart';
import 'features/auth/presentation/cubit/auth_cubit.dart';
import 'features/opportunities/data/repositories/opportunity_repository.dart';
import 'features/opportunities/presentation/cubit/opportunity_cubit.dart';
import 'features/applications/data/repositories/application_repository.dart';
import 'features/applications/presentation/cubit/application_cubit.dart';
import 'features/startups/data/repositories/startup_repository.dart';
import 'features/startups/presentation/cubit/startup_cubit.dart';
import 'core/router/app_router.dart';

class App extends StatefulWidget {
  const App({super.key});

  @override
  State<App> createState() => _AppState();
}

class _AppState extends State<App> {
  late final AuthCubit _authCubit;

  @override
  void initState() {
    super.initState();
    _authCubit = AuthCubit(AuthRepository());
  }

  @override
  void dispose() {
    _authCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider.value(value: _authCubit),
        BlocProvider(create: (_) => OpportunityCubit(OpportunityRepository())),
        BlocProvider(create: (_) => ApplicationCubit(ApplicationRepository())),
        BlocProvider(create: (_) => StartupCubit(StartupRepository())),
      ],
      child: Builder(
        builder: (context) {
          final router = buildRouter(_authCubit);
          return MaterialApp.router(
            title: 'ALU Connect',
            theme: AppTheme.lightTheme,
            routerConfig: router,
            debugShowCheckedModeBanner: false,
          );
        },
      ),
    );
  }
}
