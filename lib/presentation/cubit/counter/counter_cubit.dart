import 'package:flutter/foundation.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

class CounterCubit extends Cubit<int> {
  CounterCubit() : super(0);

  void increment(String source) {
    final next = state + 1;
    debugPrint('[CounterCubit] increment from $source → $next');
    emit(next);
  }

  void decrement(String source) {
    final next = state - 1;
    debugPrint('[CounterCubit] decrement from $source → $next');
    emit(next);
  }
}