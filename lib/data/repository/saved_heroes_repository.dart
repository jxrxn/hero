// lib/data/repository/saved_heroes_repository.dart
import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

import '../model/hero_model.dart';
import '../remote/superhero_api_client.dart';

class SavedHero {
  const SavedHero({
    required this.id,
    required this.name,
    required this.imageUrl,
    required this.alignment,
    required this.strength,
    required this.attack,
    required this.defense,
    required this.savedAt,
    this.powerstats = const <String, dynamic>{},
  });

  final String id;
  final String name;
  final String imageUrl;
  final String alignment;

  // legacy + summary
  final int strength;

  // combat summary
  final int attack;
  final int defense;

  final DateTime? savedAt;

  // keep raw stats for future recalcs
  final Map<String, dynamic> powerstats;

  factory SavedHero.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data() ?? const <String, dynamic>{};

    int parseInt(dynamic v) {
      if (v is int) return v;
      final s = '${v ?? ''}'.trim();
      return int.tryParse(s) ?? 0;
    }

    DateTime? parseDate(dynamic v) {
      if (v is Timestamp) return v.toDate();
      return null;
    }

    Map<String, dynamic> parseMap(dynamic v) {
      if (v is Map<String, dynamic>) return v;
      if (v is Map) return v.cast<String, dynamic>();
      return const <String, dynamic>{};
    }

    return SavedHero(
      id: doc.id,
      name: '${data['name'] ?? ''}',
      imageUrl: '${data['imageUrl'] ?? ''}',
      alignment: '${data['alignment'] ?? 'neutral'}',
      strength: parseInt(data['strength']),
      attack: parseInt(data['attack']),
      defense: parseInt(data['defense']),
      savedAt: parseDate(data['savedAt']),
      powerstats: parseMap(data['powerstats']),
    );
  }
}

class SavedHeroesRepository {
  SavedHeroesRepository({
    required FirebaseAuth auth,
    required FirebaseFirestore firestore,
  })  : _auth = auth,
        _firestore = firestore;

  final FirebaseAuth _auth;
  final FirebaseFirestore _firestore;

  String? get _uid => _auth.currentUser?.uid;

  CollectionReference<Map<String, dynamic>> _col(String uid) =>
      _firestore.collection('users').doc(uid).collection('saved');

  /// Stream med alla sparade heroIds (perfekt för att markera i Search)
  Stream<Set<String>> watchSavedIds() {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value(<String>{});

      return _col(user.uid).snapshots().map((snap) {
        return snap.docs.map((d) => d.id).toSet();
      });
    });
  }

  /// Stream med hela listan (för SavedPage / Heroes/Villains-lista)
  Stream<List<SavedHero>> watchSavedHeroes() {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value(const <SavedHero>[]);

      return _col(user.uid)
          .orderBy('savedAt', descending: true)
          .snapshots()
          .map((snap) => snap.docs.map(SavedHero.fromDoc).toList());
    });
  }

  /// Stream som säger om en specifik hero är sparad
  Stream<bool> isSavedStream(String heroId) {
    return _auth.authStateChanges().switchMap((user) {
      if (user == null) return Stream.value(false);

      return _col(user.uid)
          .doc(heroId)
          .snapshots()
          .map((snap) => snap.exists);
    });
  }

  Future<void> saveHero(HeroModel hero) async {
    final uid = _uid;
    if (uid == null) return;

    await _col(uid).doc(hero.id).set(
      {
        'name': hero.name,
        'imageUrl': hero.imageUrl ?? '',
        'alignment': hero.alignment,
        'strength': hero.strength,
        'attack': hero.attack,
        'defense': hero.defense,
        'powerstats': hero.powerstats,
        'savedAt': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );
  }

  Future<void> removeHero(String heroId) async {
    final uid = _uid;
    if (uid == null) return;
    await _col(uid).doc(heroId).delete();
  }

  Future<void> toggleHero(HeroModel hero) async {
    final uid = _uid;
    if (uid == null) return;

    final ref = _col(uid).doc(hero.id);
    final snap = await ref.get();

    if (snap.exists) {
      await ref.delete();
    } else {
      await saveHero(hero);
    }
  }

  // ---------------------------------------------------------------------------
  // Starter hero
  // ---------------------------------------------------------------------------

  /// Ger nya användare en starter hero (Batman) om deras "saved" är tomt.
  ///
  /// - Kör detta EN gång efter lyckad inloggning.
  /// - Skapar inga dubletter (kollar om något redan finns).
  /// - Sväljer nät/API-fel (app ska aldrig krascha).
  Future<void> ensureStarterHero({
    required SuperheroApiClient api,
    String starterHeroId = '69', // Batman
  }) async {
    final uid = _uid;
    if (uid == null) return;

    try {
      final hasAny = await _hasAnySaved(uid);
      if (hasAny) return;

      final hero = await api.getById(starterHeroId);
      if (hero == null) return;

      await _col(uid).doc(hero.id).set(
        {
          'name': hero.name,
          'imageUrl': hero.imageUrl ?? '',
          'alignment': hero.alignment,
          'strength': hero.strength,
          'attack': hero.attack,
          'defense': hero.defense,
          'powerstats': hero.powerstats,
          'savedAt': FieldValue.serverTimestamp(),
          'starter': true, // valfritt, kan vara nice att veta i framtiden
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      // Viktigt: aldrig krascha pga starter logic.
      if (kDebugMode) {
        debugPrint('🧩 ensureStarterHero failed: $e');
      }
    }
  }

  Future<bool> _hasAnySaved(String uid) async {
    final snap = await _col(uid).limit(1).get();
    return snap.docs.isNotEmpty;
  }
}

/// Minimal “switchMap” utan rx_dart
extension _SwitchMapExt<T> on Stream<T> {
  Stream<R> switchMap<R>(Stream<R> Function(T value) mapper) {
    late StreamController<R> controller;
    StreamSubscription<T>? outerSub;
    StreamSubscription<R>? innerSub;

    controller = StreamController<R>(
      onListen: () {
        outerSub = listen(
          (value) async {
            await innerSub?.cancel();
            innerSub = mapper(value).listen(
              controller.add,
              onError: controller.addError,
              onDone: () {},
            );
          },
          onError: controller.addError,
          onDone: () async {
            await innerSub?.cancel();
            await controller.close();
          },
        );
      },
      onCancel: () async {
        await innerSub?.cancel();
        await outerSub?.cancel();
      },
    );

    return controller.stream;
  }
}