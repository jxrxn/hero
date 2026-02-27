// lib/presentation/cubit/saved_heroes/saved_heroes_cubit.dart
import 'dart:async';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../data/model/hero_model.dart';
import '../../../data/repository/saved_heroes_repository.dart';

class SavedHeroesState extends Equatable {
  const SavedHeroesState({
    required this.savedIds,
    required this.savedHeroes,
  });

  final Set<String> savedIds;
  final List<SavedHero> savedHeroes;

  factory SavedHeroesState.initial() => const SavedHeroesState(
        savedIds: <String>{},
        savedHeroes: <SavedHero>[],
      );

  SavedHeroesState copyWith({
    Set<String>? savedIds,
    List<SavedHero>? savedHeroes,
  }) {
    return SavedHeroesState(
      savedIds: savedIds ?? this.savedIds,
      savedHeroes: savedHeroes ?? this.savedHeroes,
    );
  }

  @override
  List<Object> get props => [savedIds, savedHeroes];
}

class SavedHeroesCubit extends Cubit<SavedHeroesState> {
  SavedHeroesCubit(this._repo) : super(SavedHeroesState.initial()) {
    _subIds = _repo.watchSavedIds().listen((ids) {
      emit(state.copyWith(savedIds: ids));
    });

    _subHeroes = _repo.watchSavedHeroes().listen((list) {
      emit(state.copyWith(savedHeroes: list));
    });
  }

  final SavedHeroesRepository _repo;
  StreamSubscription? _subIds;
  StreamSubscription? _subHeroes;

  bool isSaved(String heroId) => state.savedIds.contains(heroId);

  Future<void> toggle(HeroModel hero) => _repo.toggleHero(hero);

  Future<void> removeById(String heroId) => _repo.removeHero(heroId);

  @override
  Future<void> close() async {
    await _subIds?.cancel();
    await _subHeroes?.cancel();
    return super.close();
  }
}