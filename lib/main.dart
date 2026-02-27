// lib/main.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'data/analytics/firebase_analytics_service.dart';
import 'data/local/consent_storage.dart';
import 'data/remote/superhero_api_client.dart';
import 'data/repository/auth_repository_impl.dart';
import 'data/repository/saved_heroes_repository.dart';
import 'firebase_options.dart';
import 'presentation/cubit/auth/auth_cubit.dart';
import 'presentation/cubit/auth/auth_state.dart';
import 'presentation/cubit/counter/counter_cubit.dart';
import 'presentation/cubit/onboarding/onboarding_cubit.dart';
import 'presentation/cubit/saved_heroes/saved_heroes_cubit.dart';
import 'presentation/cubit/theme/theme_cubit.dart';
import 'presentation/cubit/theme/theme_state.dart';
import 'presentation/theme/team_colors.dart';
import 'presentation/router/app_router.dart';


Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

    // ✅ 1. Ladda .env FÖRST
  await dotenv.load(fileName: ".env");

  // ✅ 2. Init Firebase
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final app = Firebase.app();
  debugPrint('🔥 Firebase projectId: ${app.options.projectId}');
  debugPrint('🔥 Firebase appId: ${app.options.appId}');

  // ✅ 3. Läs consent tidigt
  final prefs = await SharedPreferences.getInstance();
  final consentStorage = ConsentStorage(prefs);
  final consent = await consentStorage.read();

  // ---- Analytics: respektera val ----
  await FirebaseAnalytics.instance
      .setAnalyticsCollectionEnabled(consent.analyticsEnabled);

  // ---- Crashlytics: respektera val + koppla global felhantering ----
  if (!kIsWeb) {
    await FirebaseCrashlytics.instance
        .setCrashlyticsCollectionEnabled(consent.crashlyticsEnabled);

    if (consent.crashlyticsEnabled) {
      FlutterError.onError =
          FirebaseCrashlytics.instance.recordFlutterFatalError;

      PlatformDispatcher.instance.onError = (error, stack) {
        FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
        return true;
      };
    }
  }

  // ✅ 4. Starta appen – precis som du hade innan
  runApp(
    HeroApp(
      consentStorage: consentStorage,
      prefs: prefs,
    ),
  );
}


class HeroApp extends StatefulWidget {
  const HeroApp({
    super.key,
    required this.consentStorage,
    required this.prefs,
  });

  final ConsentStorage consentStorage;
  final SharedPreferences prefs;

  @override
  State<HeroApp> createState() => _HeroAppState();
}

class _HeroAppState extends State<HeroApp> {
  late final AuthCubit _authCubit;
  late final OnboardingCubit _onboardingCubit;
  late final ThemeCubit _themeCubit;
  late final SuperheroApiClient _apiClient;
  late final SavedHeroesRepository _savedHeroesRepo;

  @override
  void initState() {
    super.initState();

    // --- API client ---
    _apiClient = SuperheroApiClient();

    // --- Repos / services ---
    final authRepo = AuthRepositoryImpl(FirebaseAuth.instance);
    final analyticsService = FirebaseAnalyticsService(FirebaseAnalytics.instance);

    // Saved heroes repo (behövs för starter hero)
    _savedHeroesRepo = SavedHeroesRepository(
      auth: FirebaseAuth.instance,
      firestore: FirebaseFirestore.instance,
    );

    // AuthCubit med starter-hero injection
    _authCubit = AuthCubit(
      authRepo,
      analyticsService,
      savedHeroesRepository: _savedHeroesRepo,
      apiClient: _apiClient,
    );

    _onboardingCubit = OnboardingCubit(
      consentStorage: widget.consentStorage,
      analytics: FirebaseAnalytics.instance,
      crashlytics: FirebaseCrashlytics.instance,
    );

    // ThemeCubit: läser/sparar ThemeMode i SharedPreferences
    _themeCubit = ThemeCubit(widget.prefs);

    // hydrate() är async -> kör utan await
    unawaited(_onboardingCubit.hydrate());
    unawaited(_themeCubit.hydrate());
    }

  @override
  void dispose() {
    _apiClient.dispose();
    _authCubit.close();
    _onboardingCubit.close();
    _themeCubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final router = createRouter(
      authCubit: _authCubit,
      onboardingCubit: _onboardingCubit,
      themeCubit: _themeCubit,
    );

    return MultiRepositoryProvider(
      providers: [
        RepositoryProvider<SuperheroApiClient>.value(value: _apiClient),
        RepositoryProvider<SavedHeroesRepository>(
          create: (_) => SavedHeroesRepository(
            auth: FirebaseAuth.instance,
            firestore: FirebaseFirestore.instance,
          ),
        ),
      ],
      child: MultiBlocProvider(
        providers: [
          BlocProvider<AuthCubit>.value(value: _authCubit),
          BlocProvider<OnboardingCubit>.value(value: _onboardingCubit),
          BlocProvider<ThemeCubit>.value(value: _themeCubit),
          BlocProvider<CounterCubit>(create: (_) => CounterCubit()),
          BlocProvider<SavedHeroesCubit>(
            create: (ctx) => SavedHeroesCubit(
              ctx.read<SavedHeroesRepository>(),
            ),
          ),
        ],
        child: BlocBuilder<ThemeCubit, ThemeState>(
          builder: (context, themeState) {
            // ✅ Bygg schemes med en tydlig villain-red via error:
            final lightScheme = ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.light,
            ).copyWith(
              error: const Color(0xFFC62828), // riktigt röd
              onError: Colors.white,
              errorContainer: const Color(0xFFFFDAD6),
              onErrorContainer: const Color(0xFF410002),
            );

            final darkScheme = ColorScheme.fromSeed(
              seedColor: Colors.green,
              brightness: Brightness.dark,
            ).copyWith(
              error: const Color(0xFFEF5350), // röd som syns i dark mode
              onError: const Color(0xFF1B0000),
              errorContainer: const Color(0xFF93000A),
              onErrorContainer: const Color(0xFFFFDAD6),
            );

            return MaterialApp.router(
              routerConfig: router,

              // ✅ ThemeMode: system/light/dark (styrt av settings)
              themeMode: themeState.mode,

              // ✅ Material 3 med explicita colorSchemes
              theme: ThemeData(
                useMaterial3: true,
                colorScheme: lightScheme,
                extensions: <ThemeExtension<dynamic>>[
                  TeamColors(
                    heroes: lightScheme.primary,
                    villains: lightScheme.error,
                    neutral: lightScheme.tertiary,
                  ),
                ],
              ),
              darkTheme: ThemeData(
                useMaterial3: true,
                colorScheme: darkScheme,
                extensions: <ThemeExtension<dynamic>>[
                  TeamColors(
                    heroes: darkScheme.primary,
                    villains: darkScheme.error,
                    neutral: darkScheme.tertiary,
                  ),
                ],
              ),

              // Global snackbar hook (för AuthCubit.message)
              builder: (context, child) {
                return BlocListener<AuthCubit, AuthState>(
                  listenWhen: (prev, curr) =>
                      prev.message != curr.message && curr.message != null,
                  listener: (context, state) {
                    final msg = state.message;
                    if (msg == null) return;

                    ScaffoldMessenger.of(context)
                      ..hideCurrentSnackBar()
                      ..showSnackBar(
                        SnackBar(
                          content: Text(msg),
                          behavior: SnackBarBehavior.floating,
                          margin: const EdgeInsets.all(16),
                        ),
                      );

                    context.read<AuthCubit>().clearMessage();
                  },
                  child: child!,
                );
              },
            );
          },
        ),
      ),
    );
  }
}