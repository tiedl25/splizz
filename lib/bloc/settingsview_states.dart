import 'package:shared_preferences/shared_preferences.dart';

abstract class SettingsViewState {
  SettingsViewState();
}

abstract class SettingsViewListener extends SettingsViewState {}

class SettingsViewShowPrivacyPolicy extends SettingsViewListener {}

class SettingsViewShowLogoutDialog extends SettingsViewListener {}

class SettingsViewLogin extends SettingsViewListener {}

class SettingsViewLogout extends SettingsViewListener {}



class SettingsViewLoading extends SettingsViewState {}

class SettingsViewLoaded extends SettingsViewState {
  final SharedPreferences sharedPreferences;
  final String version;
  final bool systemTheme;
  final bool darkMode;

  SettingsViewLoaded({required this.sharedPreferences, required this.version, required this.systemTheme, required this.darkMode});

  SettingsViewLoaded copyWith({SharedPreferences? sharedPreferences, String? version, bool? systemTheme, bool? darkMode}) {
    return SettingsViewLoaded(
      sharedPreferences: sharedPreferences ?? this.sharedPreferences,
      version: version ?? this.version,
      systemTheme: systemTheme ?? this.systemTheme,
      darkMode: darkMode ?? this.darkMode
    );
  }

  factory SettingsViewLoaded.fromLogoutDialog(SettingsViewLogoutDialog state) {
    return SettingsViewLoaded(
      sharedPreferences: state.sharedPreferences,
      version: state.version,
      systemTheme: state.systemTheme,
      darkMode: state.darkMode
    );
  }

  factory SettingsViewLoaded.fromPrivacyPolicy(SettingsViewPrivacyPolicy state) {
    return SettingsViewLoaded(
      sharedPreferences: state.sharedPreferences,
      version: state.version,
      systemTheme: state.systemTheme,
      darkMode: state.darkMode
    );
  }
}

class SettingsViewLogoutDialog extends SettingsViewLoaded {
  SettingsViewLogoutDialog({required super.sharedPreferences, required super.version, required super.systemTheme, required super.darkMode});

  factory SettingsViewLogoutDialog.from(SettingsViewLoaded state) {
    return SettingsViewLogoutDialog(
      sharedPreferences: state.sharedPreferences,
      version: state.version,
      systemTheme: state.systemTheme,
      darkMode: state.darkMode
    );
  }
}

class SettingsViewPrivacyPolicy extends SettingsViewLoaded {
  SettingsViewPrivacyPolicy({required super.sharedPreferences, required super.version, required super.systemTheme, required super.darkMode});

  factory SettingsViewPrivacyPolicy.from(SettingsViewLoaded state) {
    return SettingsViewPrivacyPolicy(
      sharedPreferences: state.sharedPreferences,
      version: state.version,
      systemTheme: state.systemTheme,
      darkMode: state.darkMode
    );
  }
}