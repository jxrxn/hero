import 'dart:async';
import 'package:flutter/foundation.dart';

class GoRouterRefreshStream extends ChangeNotifier {
  GoRouterRefreshStream(List<Stream<dynamic>> streams) {
    for (final s in streams) {
      _subs.add(s.asBroadcastStream().listen((_) => notifyListeners()));
    }
  }

  final List<StreamSubscription<dynamic>> _subs = [];

  @override
  void dispose() {
    for (final sub in _subs) {
      sub.cancel();
    }
    super.dispose();
  }
}