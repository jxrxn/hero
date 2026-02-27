import 'package:flutter/foundation.dart';

class AppState extends ChangeNotifier {
  bool onboardingComplete = false;
  bool isLoggedIn = false;

  void completeOnboarding() {
    onboardingComplete = true;
    notifyListeners();
  }

  void login() {
    isLoggedIn = true;
    notifyListeners();
  }

  void logout() {
    isLoggedIn = false;
    notifyListeners();
  }

  void resetAll() {
    onboardingComplete = false;
    isLoggedIn = false;
    notifyListeners();
  }
}