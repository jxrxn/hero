// lib/presentation/router/app_router.dart
import 'package:flutter/material.dart'; // ✅ behövs för Curves/FadeTransition/CustomTransitionPage
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../data/remote/superhero_api_client.dart';
import '../../data/repository/saved_heroes_repository.dart';
import '../../utilities/go_router_refresh_stream.dart';

import '../cubit/auth/auth_cubit.dart';
import '../cubit/onboarding/onboarding_cubit.dart';
import '../cubit/search/search_cubit.dart';
import '../cubit/saved_heroes/saved_heroes_cubit.dart';
import '../cubit/theme/theme_cubit.dart';

import '../page/details_page.dart';
import '../page/home_page.dart';
import '../page/login_page.dart';
import '../page/onboarding_page.dart';
import '../page/saved_page.dart';
import '../page/search_page.dart';
import '../page/signup_page.dart';
import '../page/profile_page.dart';

import '../widget/app_shell.dart';

GoRouter createRouter({
  required AuthCubit authCubit,
  required OnboardingCubit onboardingCubit,
  required ThemeCubit themeCubit,
}) {
  final refresh = GoRouterRefreshStream([
    authCubit.stream,
    onboardingCubit.stream,
  ]);

  CustomTransitionPage<T> fadePage<T>({
    required GoRouterState state,
    required Widget child,
    Duration duration = const Duration(milliseconds: 180),
  }) {
    return CustomTransitionPage<T>(
      key: state.pageKey,
      child: child,
      transitionDuration: duration,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        final curved = CurvedAnimation(
          parent: animation,
          curve: Curves.easeOutCubic,
        );
        return FadeTransition(opacity: curved, child: child);
      },
    );
  }

  return GoRouter(
    initialLocation: '/home',
    refreshListenable: refresh,
    redirect: (context, state) {
      final loc = state.uri.toString();

      final hydrated = onboardingCubit.state.hydrated;
      final onboardingDone = onboardingCubit.state.complete;
      final loggedIn = authCubit.state.loggedIn;

      final isOnboarding = loc.startsWith('/onboarding');
      final isLogin = loc.startsWith('/login');
      final isSignup = loc.startsWith('/signup');

      if (!hydrated) return isOnboarding ? null : '/onboarding';
      if (!onboardingDone) return isOnboarding ? null : '/onboarding';

      if (!loggedIn) {
        if (isLogin || isSignup) return null;
        return '/login';
      }

      if (isLogin || isSignup) return '/home';
      return null;
    },
    routes: [
      GoRoute(
        path: '/onboarding',
        pageBuilder: (context, state) => fadePage(
          state: state,
          child: const OnboardingPage(),
          duration: const Duration(milliseconds: 220),
        ),
      ),
      GoRoute(
        path: '/login',
        pageBuilder: (context, state) => fadePage(
          state: state,
          child: const LoginPage(),
          duration: const Duration(milliseconds: 180),
        ),
      ),
      GoRoute(
        path: '/signup',
        pageBuilder: (context, state) => fadePage(
          state: state,
          child: const SignupPage(),
          duration: const Duration(milliseconds: 180),
        ),
      ),

      // ✅ Shell med 4 tabs (måste matcha AppShell destinations index)
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // 0) Home
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/home',
                pageBuilder: (context, state) =>
                    const NoTransitionPage(child: HomePage()),
              ),
            ],
          ),

          // 1) Saved (Heroes/Villains)
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/saved',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: BlocProvider<SavedHeroesCubit>(
                    create: (context) => SavedHeroesCubit(
                      context.read<SavedHeroesRepository>(),
                    ),
                    child: const SavedPage(),
                  ),
                ),
              ),
            ],
          ),

          // 2) Search
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/search',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: BlocProvider<SearchCubit>(
                    create: (context) => SearchCubit(
                      context.read<SuperheroApiClient>(),
                      context.read<SavedHeroesRepository>(),
                    ),
                    child: const SearchPage(),
                  ),
                ),
              ),
            ],
          ),

          // 3) Settings
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/settings',
                pageBuilder: (context, state) => NoTransitionPage(
                  child: BlocProvider.value(
                    value: themeCubit,
                    child: const ProfilePage(),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),

      // Details utanför shell (ingen bottom bar)
      GoRoute(
        path: '/details/:id',
        builder: (context, state) {
          final id = state.pathParameters['id']!;
          return DetailsPage(id: id);
        },
      ),
    ],
  );
}