import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:splizz/bloc/settingsview_states.dart';
import 'package:supabase_flutter/supabase_flutter.dart';


import 'package:splizz/bloc/settingsview_bloc.dart';
import 'package:splizz/ui/widgets/uiModels.dart';
import 'package:splizz/ui/widgets/customDialog.dart';

class SettingsView extends StatelessWidget {
  late final context;
  late final SettingsViewCubit cubit;

  Future<void> showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          content: Text(
            "Are you sure you want to log out?",
            style: TextStyle(fontSize: 20),
          ),
          pop: false,
          onConfirmed: () async => cubit.confirmLogout(),
          onDismissed: () async => cubit.dismissLogout(),
        );
      },
    );
  }

  Future<void> showPrivacyPolicy() async {
    await launchUrl(
      Uri.parse("https://tmc.tiedl.rocks/splizz/dsgvo"),
      customTabsOptions: CustomTabsOptions(
        urlBarHidingEnabled: false,
        instantAppsEnabled: true,
        closeButton: CustomTabsCloseButton(position: CustomTabsCloseButtonPosition.end),
        showTitle: true,
      )
    );

    cubit.closePrivacyPolicy();
  }

  Widget themeSegment(systemTheme, darkMode) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          SwitchListTile(
            title: const Text("Use system theme"),
            value: systemTheme,
            onChanged: (_) async => cubit.updateTheme(),
          ),
          const Divider(
            thickness: 0.2,
            indent: 15,
            endIndent: 15,
          ),
          SwitchListTile(
            title: const Text("Dark Mode"),
            value: darkMode,
            tileColor: systemTheme
              ? Theme.of(context).colorScheme.surfaceContainer
              : null,
            onChanged: systemTheme
              ? null
              : (_) async => cubit.updateDarkMode()
          ),
        ],
      ),
    );
  }

  Widget infoSegment(String version) {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainer,
        border: Border.all(
          style: BorderStyle.none,
        ),
        borderRadius: BorderRadius.circular(20)),
      child: Column(
        children: [
          ListTile(
            title: Text("Version"),
            subtitle: Text(version),
          ),
          const Divider(
            thickness: 0.2,
            indent: 15,
            endIndent: 15,
          ),
          ListTile(
            title: Text("Privacy Policy"),
            trailing: Icon(Icons.open_in_browser),
            onTap: () => cubit.showPrivacyPolicy(),
          ),
        ],
      ),
    );
  }

  Widget userSegment() {
    return Container(
      margin: const EdgeInsets.all(10),
      padding: const EdgeInsets.all(5),
      decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainer,
          border: Border.all(
            style: BorderStyle.none,
          ),
          borderRadius: BorderRadius.circular(20)),
      child: Supabase.instance.client.auth.currentSession != null
        ? ListTile(
            title: const Text("Logout"),
            trailing: Icon(Icons.logout),
            onTap: () => cubit.showLogoutDialog(),
          )
        : ListTile(
            title: const Text("Login"),
            trailing: Icon(Icons.login),
            onTap: () async => cubit.login(),
          ),
    );
  }

  @override
  Widget build(BuildContext context) {
    this.context = context;
    this.cubit = context.read<SettingsViewCubit>();

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        title: const Text('Settings'),
      ),
      body: BlocConsumer<SettingsViewCubit, SettingsViewState>(
        bloc: cubit,
        listenWhen: (_, current) => current is SettingsViewListener,
        listener: (context, state) {
          switch (state.runtimeType) {
            case SettingsViewShowPrivacyPolicy:
              showPrivacyPolicy();
              break;
            case SettingsViewShowLogoutDialog:
              showLogoutDialog();
              break;
            case SettingsViewLogin:
              Navigator.pushNamedAndRemoveUntil(context, '/auth', (route) => false);
              break;
            case SettingsViewLogout:
              Navigator.pushNamedAndRemoveUntil(context, '/', (route) => false);
              break;
          }
        },
        buildWhen: (_, current) => current is SettingsViewLoaded || current is SettingsViewLoading,
        builder: (context, state) {
          return state.runtimeType == SettingsViewLoading
            ? Center(child: CircularProgressIndicator())
            : Column(
                children: [
                  themeSegment((state as SettingsViewLoaded).systemTheme, state.darkMode),
                  infoSegment(state.version),
                  userSegment(),
                ]
              );
        },
      ),
    );
  }
}
