// lib/data/remote/superhero_api_client.dart
import 'dart:async';
import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;

import '../model/hero_model.dart';

class SuperheroApiException implements Exception {
  const SuperheroApiException(this.message, {this.statusCode, this.uri});

  final String message;
  final int? statusCode;
  final Uri? uri;

  @override
  String toString() {
    final sc = statusCode == null ? '' : ' (HTTP $statusCode)';
    final u = uri == null ? '' : ' • $uri';
    return 'SuperheroApiException$sc: $message$u';
  }
}

class SuperheroApiClient {
  SuperheroApiClient({
    String? tokenOverride,
    http.Client? client,
    Duration timeout = const Duration(seconds: 8),
  })  : _tokenOverride = tokenOverride?.trim(),
        _client = client ?? http.Client(),
        _timeout = timeout;

  // ✅ Base enligt docs
  static const _base = 'https://superheroapi.com/api';

  final String? _tokenOverride;
  final http.Client _client;
  final Duration _timeout;

  /// Läs token "late" så dotenv hinner laddas även om clienten skapades tidigt.
  String get _token {
    final t = (_tokenOverride ?? dotenv.env['SUPERHERO_TOKEN'] ?? '').trim();
    return t;
  }

  bool get hasToken => _token.isNotEmpty;

  SuperheroApiException _missingTokenError() => const SuperheroApiException(
        'SUPERHERO_TOKEN saknas. Lägg den i .env i projektroten och starta om appen.',
      );

  Future<List<HeroModel>> searchByName(String rawQuery) async {
    final q = rawQuery.trim();
    if (q.isEmpty) return const <HeroModel>[];
    if (!hasToken) throw _missingTokenError();

    List<String> variants(String s) {
      final base = s.trim().toLowerCase();
      const suffixes = ['man', 'woman', 'boy', 'girl', 'men', 'women'];

      final v = <String>{
        base,
        base.replaceAll('-', ' '),
        base.replaceAll(' ', '-'),
        base.replaceAll(RegExp(r'[\s\-]+'), ''),
      };

      for (final suf in suffixes) {
        if (base.endsWith(suf) && base.length > suf.length) {
          final stem = base.substring(0, base.length - suf.length);
          final stemTrim = stem.replaceAll(RegExp(r'[\s\-]+$'), '');
          if (stemTrim.isNotEmpty) {
            v.add('$stemTrim-$suf');
            v.add('$stemTrim $suf');
          }
        }
      }

      return v.toList();
    }

    Future<List<HeroModel>> tryOnce(String term) async {
      final uri =
          Uri.parse('$_base/$_token/search/${Uri.encodeComponent(term)}');

      http.Response res;
      try {
        res = await _client.get(uri).timeout(_timeout);
      } on TimeoutException {
        throw SuperheroApiException('Timeout mot SuperheroAPI.', uri: uri);
      } on http.ClientException catch (e) {
        throw SuperheroApiException(
          'HTTP-klientfel: ${e.message} (på web är detta ofta CORS).',
          uri: uri,
        );
      } catch (e) {
        throw SuperheroApiException('Nätverksfel: $e', uri: uri);
      }

      if (res.statusCode != 200) {
        final snippet = res.body.length > 200 ? res.body.substring(0, 200) : res.body;
        throw SuperheroApiException(
          'Fel från API. Body: $snippet',
          statusCode: res.statusCode,
          uri: uri,
        );
      }

      dynamic decoded;
      try {
        decoded = jsonDecode(res.body);
      } on FormatException {
        final snippet = res.body.length > 200 ? res.body.substring(0, 200) : res.body;
        throw SuperheroApiException(
          'Kunde inte tolka JSON (fick troligen HTML/redirect). Body: $snippet',
          uri: uri,
        );
      }

      if (decoded is! Map<String, dynamic>) {
        throw SuperheroApiException('Oväntat JSON-format (inte en Map).', uri: uri);
      }

      final response = decoded['response']?.toString();
      if (response != 'success') {
        final err = decoded['error']?.toString() ?? 'Okänt API-fel.';
        throw SuperheroApiException(err, uri: uri);
      }

      final results = decoded['results'];
      if (results is! List) return const <HeroModel>[];

      final mapped = results
          .whereType<Map>()
          .map((e) => e.cast<String, dynamic>())
          .toList();

      return mapped.map(HeroModel.fromJson).toList();
    }

    final tried = <String>{};
    SuperheroApiException? lastError;

    for (final term in variants(q)) {
      if (!tried.add(term)) continue;
      try {
        final hits = await tryOnce(term);
        if (hits.isNotEmpty) return hits;
      } on SuperheroApiException catch (e) {
        lastError = e;
      }
    }

    if (lastError != null) throw lastError;
    return const <HeroModel>[];
  }

  Future<HeroModel?> getById(String id) async {
    final clean = id.trim();
    if (clean.isEmpty) return null;
    if (!hasToken) throw _missingTokenError();

    final uri = Uri.parse('$_base/$_token/$clean');
    if (kDebugMode) debugPrint('🌐 GET $uri');

    http.Response res;
    try {
      res = await _client.get(uri).timeout(_timeout);
    } on TimeoutException {
      throw SuperheroApiException('Timeout mot SuperheroAPI.', uri: uri);
    } on http.ClientException catch (e) {
      throw SuperheroApiException(
        'HTTP-klientfel: ${e.message} (på web är detta ofta CORS).',
        uri: uri,
      );
    } catch (e) {
      throw SuperheroApiException('Nätverksfel: $e', uri: uri);
    }

    if (res.statusCode != 200) {
      throw SuperheroApiException(
        'HTTP-fel vid getById.',
        statusCode: res.statusCode,
        uri: uri,
      );
    }

    final decoded = jsonDecode(res.body);
    if (decoded is! Map<String, dynamic>) {
      throw SuperheroApiException('Oväntat JSON-format (inte en Map).', uri: uri);
    }

    if (decoded['response']?.toString() == 'error') return null;
    return HeroModel.fromJson(decoded);
  }

  void dispose() => _client.close();
}