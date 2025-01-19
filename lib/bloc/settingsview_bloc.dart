import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'package:splizz/Helper/database.dart';

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

class SettingsViewCubit extends Cubit<SettingsViewState> {
  SettingsViewCubit()
    : super(SettingsViewLoading()) {
      fetchData();
    }

  void fetchData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    PackageInfo packageInfo = await PackageInfo.fromPlatform();

    final newState = SettingsViewLoaded(
      sharedPreferences: prefs,
      version: packageInfo.version,
      systemTheme: prefs.getBool('systemTheme') ?? true,
      darkMode: prefs.getBool('darkMode') ?? false,
    );

    emit(newState);
  }

  void updateTheme() async {
    final newState = (state as SettingsViewLoaded).copyWith(
      systemTheme: !(state as SettingsViewLoaded).systemTheme
    );

    await newState.sharedPreferences.setBool('systemTheme', newState.systemTheme);

    emit(newState);
  }

  void updateDarkMode() async {
    final newState = (state as SettingsViewLoaded).copyWith(
      darkMode: !(state as SettingsViewLoaded).darkMode
    );

    await newState.sharedPreferences.setBool('darkMode', newState.darkMode);

    emit(newState);
  }

  Future<void> login() async {
    await (state as SettingsViewLoaded).sharedPreferences.setBool('offline', false);

    emit(SettingsViewLogin());
  }

  void showLogoutDialog() {
    final newState = SettingsViewLogoutDialog.from(state as SettingsViewLoaded);

    emit(SettingsViewShowLogoutDialog());

    emit(newState);
  }

  Future<void> confirmLogout() async {
    await (state as SettingsViewLogoutDialog).sharedPreferences.setBool('offline', false);
    await Supabase.instance.client.auth.signOut();
    await DatabaseHelper.instance.deleteDatabase();

    emit(SettingsViewLogout());
  }

  void dismissLogout() {
    final newState = SettingsViewLoaded.fromLogoutDialog(state as SettingsViewLogoutDialog);

    emit(newState);
  }

  void showPrivacyPolicy() {
    final newState = SettingsViewPrivacyPolicy.from(state as SettingsViewLoaded);

    emit(SettingsViewShowPrivacyPolicy());

    emit(newState);
  }

  void closePrivacyPolicy() {
    final newState = SettingsViewLoaded.fromPrivacyPolicy(state as SettingsViewPrivacyPolicy);

    emit(newState);
  }
}
