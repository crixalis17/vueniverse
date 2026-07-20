import 'package:shared_preferences/shared_preferences.dart';
import 'package:vueniverse/domain/store_kind.dart';

abstract interface class AppPreferences {
  Future<bool> getOnboardingComplete();

  Future<void> setOnboardingComplete(bool value);

  Future<StoreKind> getActiveMode();

  Future<void> setActiveMode(StoreKind value);

  Future<bool> getReducedMotion();

  Future<void> setReducedMotion(bool value);

  Future<String?> getLastNavigationDestination();

  Future<void> setLastNavigationDestination(String? value);
}

final class SharedAppPreferences implements AppPreferences {
  SharedAppPreferences(this._preferences);

  final SharedPreferences _preferences;

  static const _onboardingKey = 'onboarding_complete';
  static const _modeKey = 'active_mode';
  static const _reducedMotionKey = 'reduced_motion';
  static const _navigationKey = 'last_navigation_destination';

  @override
  Future<bool> getOnboardingComplete() async =>
      _preferences.getBool(_onboardingKey) ?? false;

  @override
  Future<void> setOnboardingComplete(bool value) =>
      _preferences.setBool(_onboardingKey, value);

  @override
  Future<StoreKind> getActiveMode() async =>
      _preferences.getString(_modeKey) == StoreKind.live.name
      ? StoreKind.live
      : StoreKind.demo;

  @override
  Future<void> setActiveMode(StoreKind value) =>
      _preferences.setString(_modeKey, value.name);

  @override
  Future<bool> getReducedMotion() async =>
      _preferences.getBool(_reducedMotionKey) ?? false;

  @override
  Future<void> setReducedMotion(bool value) =>
      _preferences.setBool(_reducedMotionKey, value);

  @override
  Future<String?> getLastNavigationDestination() async =>
      _preferences.getString(_navigationKey);

  @override
  Future<void> setLastNavigationDestination(String? value) async {
    if (value == null) {
      await _preferences.remove(_navigationKey);
    } else {
      await _preferences.setString(_navigationKey, value);
    }
  }
}
