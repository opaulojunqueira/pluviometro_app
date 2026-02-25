import 'package:shared_preferences/shared_preferences.dart';

class PreferencesService {
  static final PreferencesService instance = PreferencesService._init();
  static SharedPreferences? _prefs;

  PreferencesService._init();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  SharedPreferences get prefs {
    if (_prefs == null) {
      throw Exception('PreferencesService not initialized. Call init() first.');
    }
    return _prefs!;
  }

  // Onboarding completed
  bool get isOnboardingCompleted =>
      prefs.getBool('onboarding_completed') ?? false;
  Future<void> setOnboardingCompleted(bool value) async {
    await prefs.setBool('onboarding_completed', value);
  }

  // User setup completed (either logged in or skipped login)
  bool get isUserSetupCompleted =>
      prefs.getBool('user_setup_completed') ?? false;
  Future<void> setUserSetupCompleted(bool value) async {
    await prefs.setBool('user_setup_completed', value);
  }

  // Is logged in
  bool get isLoggedIn => prefs.getBool('is_logged_in') ?? false;
  Future<void> setLoggedIn(bool value) async {
    await prefs.setBool('is_logged_in', value);
  }

  // User name
  String get userName => prefs.getString('user_name') ?? '';
  Future<void> setUserName(String value) async {
    await prefs.setString('user_name', value);
  }

  // User email
  String get userEmail => prefs.getString('user_email') ?? '';
  Future<void> setUserEmail(String value) async {
    await prefs.setString('user_email', value);
  }

  // User city
  String get userCity => prefs.getString('user_city') ?? '';
  Future<void> setUserCity(String value) async {
    await prefs.setString('user_city', value);
  }

  // Property name
  String get propertyName => prefs.getString('property_name') ?? '';
  Future<void> setPropertyName(String value) async {
    await prefs.setString('property_name', value);
  }

  // Notifications
  bool get notificationsEnabled =>
      prefs.getBool('notifications_enabled') ?? false;
  Future<void> setNotificationsEnabled(bool value) async {
    await prefs.setBool('notifications_enabled', value);
  }

  // Clear all preferences (logout)
  Future<void> clearUserData() async {
    await prefs.setBool('is_logged_in', false);
    await prefs.setBool('user_setup_completed', false);
    await prefs.remove('user_name');
    await prefs.remove('user_email');
    await prefs.remove('user_city');
    await prefs.remove('property_name');
  }

  // Full reset (including onboarding)
  Future<void> fullReset() async {
    await prefs.clear();
  }
}
