import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:splizz/bloc/main_bloc.dart';
import 'package:splizz/bloc/settingsview_states.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'package:splizz/data/database.dart';

class SettingsViewCubit extends Cubit<SettingsViewState> {
  final ThemeCubit themeCubit;

  SettingsViewCubit(this.themeCubit)
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

  void updateTheme(platformBrightness) async {
    final newState = (state as SettingsViewLoaded).copyWith(
      systemTheme: !(state as SettingsViewLoaded).systemTheme
    );

    await newState.sharedPreferences.setBool('systemTheme', newState.systemTheme);
    this.themeCubit.toggleSystemTheme(newState.systemTheme, platformBrightness);
    emit(newState);
  }

  void updateDarkMode(platformBrightness) async {
    final newState = (state as SettingsViewLoaded).copyWith(
      darkMode: !(state as SettingsViewLoaded).darkMode
    );

    await newState.sharedPreferences.setBool('darkMode', newState.darkMode);
    this.themeCubit.toggleDarkMode(newState.darkMode, platformBrightness);
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
