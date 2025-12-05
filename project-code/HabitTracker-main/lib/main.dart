import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'core/theme/app_theme.dart';
import 'core/di/injection_container.dart';
import 'features/auth/presentation/bloc/sign_up_cubit.dart';
import 'features/auth/presentation/bloc/auth_cubit.dart';
import 'features/habits/presentation/bloc/habits_cubit.dart';
import 'presentation/pages/main_navigation_page.dart';
import 'features/auth/presentation/pages/sign_up_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await setupDependencies();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (context) => AuthCubit()),
        BlocProvider(
          create: (context) =>
              SignUpCubit(authCubit: context.read<AuthCubit>()),
        ),
        BlocProvider(create: (context) => HabitsCubit(repository: getIt())),
      ],
      child: MaterialApp(
        title: 'HabitTracker',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: ThemeMode.light,
        home: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            if (state is AuthAuthenticated) {
              return const MainNavigationPage();
            } else if (state is AuthUnauthenticated) {
              return const SignUpPage();
            } else {
              return const Scaffold(
                body: Center(child: CircularProgressIndicator()),
              );
            }
          },
        ),
        routes: {'/auth': (context) => const SignUpPage()},
      ),
    );
  }
}
