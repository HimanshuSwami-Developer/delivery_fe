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
              title: 'FastSwipe',
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              routerConfig: router,
            );
          },
        ),
      ),
    );
  }
}
