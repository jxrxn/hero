import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/model/hero_model.dart';
import '../../../data/remote/superhero_api_client.dart';
import '../../../data/repository/saved_heroes_repository.dart';
import 'search_state.dart';

class SearchCubit extends Cubit<SearchState> {
  SearchCubit(
    this._api,
    this._savedRepo,
  ) : super(SearchState.initial()) {
    _savedIdsSub = _savedRepo.watchSavedIds().listen(
      (ids) => emit(state.copyWith(savedIds: ids)),
      onError: (_) => emit(state.copyWith(savedIds: state.savedIds)),
    );
  }

  final SuperheroApiClient _api;
  final SavedHeroesRepository _savedRepo;

  Timer? _debounce;
  static const _debounceDuration = Duration(milliseconds: 450);

  StreamSubscription<Set<String>>? _savedIdsSub;

  void onQueryChanged(String value) {
    final q = value.trim();
    emit(state.copyWith(query: value, errorMessage: null));

    _debounce?.cancel();
    _debounce = Timer(_debounceDuration, () => _search(q));
  }

  Future<void> _search(String q) async {
    if (q.isEmpty) {
      emit(state.copyWith(
        status: SearchStatus.idle,
        results: const [],
        errorMessage: null,
      ));
      return;
    }

    emit(state.copyWith(status: SearchStatus.loading, errorMessage: null));

    try {
      final hits = await _api.searchByName(q);
      emit(state.copyWith(
        status: SearchStatus.success,
        results: hits,
        errorMessage: hits.isEmpty ? 'Inga träffar.' : null,
      ));
    } on SuperheroApiException catch (e) {
      // Visa API:ts egna felmeddelande (t.ex. "invalid access token")
      if (kDebugMode) {
        debugPrint('🔎 Search failed: $e');
      }
      emit(state.copyWith(
        status: SearchStatus.failure,
        results: const [],
        errorMessage: e.message,
      ));
    } catch (e) {
      // Okänt fel (t.ex. kodbugg)
      if (kDebugMode) {
        debugPrint('🔎 Search unknown error: $e');
      }
      emit(state.copyWith(
        status: SearchStatus.failure,
        results: const [],
        errorMessage: 'Något gick fel vid sökning.',
      ));
    }
  }

  Future<void> toggleSave(HeroModel hero) async {
    final id = hero.id.trim();
    if (id.isEmpty) return;

    emit(state.copyWith(savingIds: {...state.savingIds, id}));

    try {
      final alreadySaved = state.savedIds.contains(id);
      if (alreadySaved) {
        await _savedRepo.removeHero(id);
      } else {
        await _savedRepo.saveHero(hero);
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('💾 Toggle save failed: $e');
      }
      emit(state.copyWith(errorMessage: 'Kunde inte spara just nu.'));
    } finally {
      final next = {...state.savingIds}..remove(id);
      emit(state.copyWith(savingIds: next));
    }
  }

  void clear() {
    _debounce?.cancel();
    emit(SearchState.initial().copyWith(savedIds: state.savedIds));
  }

  @override
  Future<void> close() async {
    _debounce?.cancel();
    await _savedIdsSub?.cancel();
    return super.close();
  }
}