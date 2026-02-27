import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/remote/superhero_api_client.dart';
import '../../../data/repository/saved_heroes_repository.dart';
import '../../../domain/analytics/analytics_service.dart';
import '../../../domain/repository/auth_repository.dart';
import 'auth_state.dart';

class AuthCubit extends Cubit<AuthState> {
  AuthCubit(
    this._repo,
    this._analytics, {
    required SavedHeroesRepository savedHeroesRepository,
    required SuperheroApiClient apiClient,
  })  : _savedRepo = savedHeroesRepository,
        _api = apiClient,
        super(const AuthState(loggedIn: false)) {
    _sub = _repo.authStateChanges().listen(_onAuthChanged);
  }

  final AuthRepository _repo;
  final AnalyticsService _analytics;
  final SavedHeroesRepository _savedRepo;
  final SuperheroApiClient _api;

  StreamSubscription<User?>? _sub;

  bool _starterEnsuredThisSession = false;

  void _onAuthChanged(User? user) {
    final nextLoggedIn = user != null;
    if (state.loggedIn == nextLoggedIn) return;

    emit(state.copyWith(loggedIn: nextLoggedIn));

    if (user != null) {
      _ensureStarterHeroOncePerSession();
    } else {
      _starterEnsuredThisSession = false;
    }
  }

  void _ensureStarterHeroOncePerSession() {
    if (_starterEnsuredThisSession) return;
    _starterEnsuredThisSession = true;

    // fire-and-forget: får aldrig blocka UI eller krascha appen
    // ignore: unawaited_futures
    _savedRepo.ensureStarterHero(api: _api).catchError((e) {
      if (kDebugMode) debugPrint('🧩 ensureStarterHero error: $e');
    });
  }

  void clearMessage() {
    if (state.message != null || state.status != AuthStatus.idle) {
      emit(state.copyWith(status: AuthStatus.idle, message: null));
    }
  }

  String _loginErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'invalid-credential':
      case 'wrong-password':
        return 'Fel lösenord eller email.';
      case 'user-not-found':
        return 'Ingen användare med den emailen.';
      case 'invalid-email':
        return 'Ogiltig email-adress.';
      case 'user-disabled':
        return 'Kontot är inaktiverat.';
      case 'too-many-requests':
        return 'För många försök. Vänta en stund och prova igen.';
      case 'network-request-failed':
        return 'Nätverksfel. Kontrollera internetanslutningen.';
      default:
        return 'Login misslyckades. (${e.code})';
    }
  }

  String _signupErrorMessage(FirebaseAuthException e) {
    switch (e.code) {
      case 'email-already-in-use':
        return 'Det finns redan ett konto med den emailen.';
      case 'weak-password':
        return 'Lösenordet är för svagt.';
      case 'invalid-email':
        return 'Ogiltig email-adress.';
      case 'operation-not-allowed':
        return 'Signup är inte aktiverat i Firebase-projektet.';
      case 'network-request-failed':
        return 'Nätverksfel. Kontrollera internetanslutningen.';
      default:
        return 'Kunde inte skapa konto. (${e.code})';
    }
  }

  Future<void> login(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      await _repo.signIn(email, password);
      emit(state.copyWith(status: AuthStatus.success, message: 'Inloggad!'));
      _safeAnalytics(() => _analytics.logLogin(success: true));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        message: _loginErrorMessage(e),
      ));
      _safeAnalytics(() => _analytics.logLogin(success: false));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.failure, message: 'Login misslyckades.'));
      _safeAnalytics(() => _analytics.logLogin(success: false));
    }
  }

  Future<void> signUp(String email, String password) async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      await _repo.signUp(email, password);
      emit(state.copyWith(status: AuthStatus.success, message: 'Konto skapat!'));
      _safeAnalytics(() => _analytics.logSignUp(success: true));
    } on FirebaseAuthException catch (e) {
      emit(state.copyWith(
        status: AuthStatus.failure,
        message: _signupErrorMessage(e),
      ));
      _safeAnalytics(() => _analytics.logSignUp(success: false));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.failure, message: 'Kunde inte skapa konto.'));
      _safeAnalytics(() => _analytics.logSignUp(success: false));
    }
  }

  Future<void> logout() async {
    emit(state.copyWith(status: AuthStatus.loading, message: null));
    try {
      await _repo.signOut();
      emit(state.copyWith(status: AuthStatus.success, message: 'Utloggad.'));
      _safeAnalytics(() => _analytics.logLogout(success: true));
    } catch (_) {
      emit(state.copyWith(status: AuthStatus.failure, message: 'Logout misslyckades.'));
      _safeAnalytics(() => _analytics.logLogout(success: false));
    }
  }

  void _safeAnalytics(Future<void> Function() fn) {
    // ignore: unawaited_futures
    fn().catchError((_) {});
  }

  @override
  Future<void> close() async {
    await _sub?.cancel();
    return super.close();
  }
}