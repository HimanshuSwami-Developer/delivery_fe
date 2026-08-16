import 'package:fastswipe/core/router/app_router.dart';
import 'package:fastswipe/core/theme/app_theme.dart';
import 'package:fastswipe/features/auth/bloc/auth_bloc.dart';
import 'package:fastswipe/features/auth/data/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class FastSwipeApp extends StatelessWidget {
  const FastSwipeApp({super.key, required this.authRepository});

  final AuthRepository authRepository;

  @override
  Widget build(BuildContext context) {
    return RepositoryProvider.value(
      value: authRepository,
      child: BlocProvider(
        create: (context) => AuthBloc(authRepository: authRepository),
        child: Builder(
          builder: (context) {
            final router = buildAppRouter(context.read<AuthBloc>());
            return MaterialApp.router(
              debugShowCheckedModeBanner: false,
              title: 'Aapno Bazar',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              // Every screen (Basket + Basket Admin) is built entirely on
              // hardcoded light-mode colors (BasketColors/AppColors), not a
              // theme-aware palette — with no themeMode pin, MaterialApp
              // defaults to ThemeMode.system, so a phone with system dark
              // mode on switches to `AppTheme.dark`'s generic Material3
              // scheme. That scheme's near-white default text color then
              // lands on top of these screens' hardcoded white/light-grey
              // cards, which is exactly the "light, barely visible text on
              // some phones" bug. Pin to light until the UI is actually
              // built to support both.
              themeMode: ThemeMode.light,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}
