// lib/data/model/hero_model.dart
//
// Robust HeroModel för SuperheroAPI + Firestore.
// - Kräver INGA extra sub-modeller (powerstats/biography/etc lagras som Map).
// - fromJson tolererar saknade/konstiga fält utan att krascha.
// - toJson ger en “ren” Map som passar både Firestore och lokalt.
// - Har computed getters för PowerStats + Attack/Defense (via CombatCalculator).

import '../../core/combat/combat_calculator.dart';

class HeroModel {
  const HeroModel({
    required this.id,
    required this.name,
    this.imageUrl,
    this.powerstats = const {},
    this.appearance = const {},
    this.biography = const {},
    this.work = const {},
  });

  final String id;
  final String name;

  /// SuperheroAPI: image.url
  final String? imageUrl;

  /// SuperheroAPI: powerstats / appearance / biography / work
  /// Vi håller dem som Map String, dynamic för att slippa 5 extra filer just nu.
  final Map<String, dynamic> powerstats;
  final Map<String, dynamic> appearance;
  final Map<String, dynamic> biography;
  final Map<String, dynamic> work;

  // ---------- Parsing helpers ----------

  static Map<String, dynamic> _map(dynamic v) {
    if (v is Map<String, dynamic>) return v;
    if (v is Map) return v.cast<String, dynamic>();
    return <String, dynamic>{};
  }

  static String _str(dynamic v) => (v == null) ? '' : '$v';

  static int _int(dynamic v) {
    if (v == null) return 0;
    if (v is int) return v;
    final s = '$v'.trim().toLowerCase();
    if (s.isEmpty || s == 'null' || s == '-' || s == 'unknown') return 0;
    return int.tryParse(s) ?? 0;
  }

  static int safeStat(dynamic v, {int max = 999}) {
  if (v == null) return 0;
  final s = v.toString().trim().toLowerCase();
  if (s.isEmpty || s == 'null' || s == '-' || s == 'unknown') return 0;

  final parsed = int.tryParse(s);
  if (parsed == null) return 0;

  return parsed.clamp(0, max);
}

  /// SuperheroAPI format (men funkar även för Firestore om du sparat samma shape)
  factory HeroModel.fromJson(Map<String, dynamic> json) {
    final image = _map(json['image']);
    return HeroModel(
      id: _str(json['id']),
      name: _str(json['name']),
      imageUrl: _str(image['url']).isEmpty ? null : _str(image['url']),
      powerstats: _map(json['powerstats']),
      appearance: _map(json['appearance']),
      biography: _map(json['biography']),
      work: _map(json['work']),
    );
  }

  /// Firestore kan ibland ge `id` som dokument-id istället för fält:
  factory HeroModel.fromFirestore({
    required String docId,
    required Map<String, dynamic> data,
  }) {
    final dataId = _str(data['id']);
    return HeroModel.fromJson({
      ...data,
      'id': dataId.isNotEmpty ? dataId : docId,
    });
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'id': id,
      'name': name,
      if (imageUrl != null) 'image': {'url': imageUrl},
      'powerstats': powerstats,
      'appearance': appearance,
      'biography': biography,
      'work': work,
    };
  }

  // ---------- Convenience getters ----------

  int get strength => _int(powerstats['strength']);

  int get speed => _int(powerstats['speed']);
  int get power => _int(powerstats['power']);
  int get combat => _int(powerstats['combat']);
  int get intelligence => _int(powerstats['intelligence']);
  int get durability => _int(powerstats['durability']);

  /// Typed stats för kalkylatorn
  PowerStats get stats => PowerStats.fromJson(powerstats);

  /// Attack/Defense (räknas alltid från nuvarande powerstats)
  CombatRating get rating => CombatCalculator.calculate(stats);

  int get attack => rating.attack;
  int get defense => rating.defense;

  String get fullName {
    final v = biography['full-name'] ?? biography['fullName'];
    final s = _str(v).trim();
    return s.isEmpty ? 'Okänt' : s;
  }

  String get alignment => (biography['alignment'] ?? '').toString();

  String get alignmentNormalized {
    final raw = _str(biography['alignment']).toLowerCase().trim();
    if (raw.isEmpty) return 'neutral';
    if (raw.contains('good')) return 'good';
    if (raw.contains('bad') || raw.contains('evil')) return 'bad';
    return 'neutral';
  }

  HeroModel copyWith({
    String? id,
    String? name,
    String? imageUrl,
    Map<String, dynamic>? powerstats,
    Map<String, dynamic>? appearance,
    Map<String, dynamic>? biography,
    Map<String, dynamic>? work,
  }) {
    return HeroModel(
      id: id ?? this.id,
      name: name ?? this.name,
      imageUrl: imageUrl ?? this.imageUrl,
      powerstats: powerstats ?? this.powerstats,
      appearance: appearance ?? this.appearance,
      biography: biography ?? this.biography,
      work: work ?? this.work,
    );
  }

  @override
  String toString() => 'HeroModel($name, id=$id)';
}