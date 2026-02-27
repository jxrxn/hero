import 'package:equatable/equatable.dart';

import '../../../data/model/hero_model.dart';

enum SearchStatus { idle, loading, success, failure }

class SearchState extends Equatable {
  const SearchState({
    required this.query,
    required this.status,
    required this.results,
    required this.savedIds,
    required this.savingIds,
    this.errorMessage,
  });

  final String query;
  final SearchStatus status;
  final List<HeroModel> results;

  /// Hero IDs som finns sparade i Firestore
  final Set<String> savedIds;

  /// IDs som just nu håller på att sparas/tas bort (för att disable:a UI)
  final Set<String> savingIds;

  final String? errorMessage;

  factory SearchState.initial() => const SearchState(
        query: '',
        status: SearchStatus.idle,
        results: <HeroModel>[],
        savedIds: <String>{},
        savingIds: <String>{},
        errorMessage: null,
      );

  bool isSaved(String heroId) => savedIds.contains(heroId);
  bool isSaving(String heroId) => savingIds.contains(heroId);

  SearchState copyWith({
    String? query,
    SearchStatus? status,
    List<HeroModel>? results,
    Set<String>? savedIds,
    Set<String>? savingIds,
    String? errorMessage,
  }) {
    return SearchState(
      query: query ?? this.query,
      status: status ?? this.status,
      results: results ?? this.results,
      savedIds: savedIds ?? this.savedIds,
      savingIds: savingIds ?? this.savingIds,
      errorMessage: errorMessage,
    );
  }

  @override
  List<Object?> get props => [query, status, results, savedIds, savingIds, errorMessage];
}