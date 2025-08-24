import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_custom_tabs/flutter_custom_tabs.dart';
import 'package:splizz/bloc/settingsview_states.dart';
import 'package:splizz/resources/strings.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'package:splizz/bloc/settingsview_bloc.dart';
import 'package:splizz/ui/widgets/customDialog.dart';
import 'package:webview_flutter/webview_flutter.dart';

class SettingsView extends StatelessWidget {
  late final context;
  late final SettingsViewCubit cubit;

  Future<void> showLogoutDialog() async {
    return showDialog<void>(
      context: context,
      builder: (BuildContext context) {
        return CustomDialog(
          content: Text(
            logoutDialogTitle,
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

  Future<void> showPrivacyPolicyWebView() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text(privacyPolicy),
            ),
            body: WebViewWidget(
                gestureRecognizers: Set()
                  ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
                controller: WebViewController()
                  ..loadRequest(Uri.parse("https://tmc.tiedl.rocks/splizz/dsgvo"))
                  ..setJavaScriptMode(JavaScriptMode.unrestricted),
              ),
          );
        },
      ),
    );

    cubit.closePrivacyPolicy();
  }

  Future<void> showBuyMeACoffee() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text(buyMeACoffee),
            ),
            body: WebViewWidget(
                gestureRecognizers: Set()
                  ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
                controller: WebViewController()
                  ..loadRequest(Uri.parse("https://buymeacoffee.com/tiedl"))
                  ..setJavaScriptMode(JavaScriptMode.unrestricted),
              ),
          );
        },
      ),
    );
  }

  Future<void> showPaypal() async {
    await Navigator.push(
      context,
      MaterialPageRoute<void>(
        builder: (BuildContext context) {
          return Scaffold(
            backgroundColor: Theme.of(context).colorScheme.surface,
            appBar: AppBar(
              title: Text(paypal),
            ),
            body: WebViewWidget(
                gestureRecognizers: Set()
                  ..add(Factory<VerticalDragGestureRecognizer>(
                  () => VerticalDragGestureRecognizer())),
                controller: WebViewController()
                  ..loadRequest(Uri.parse("https://paypal.me/tiedl25"))
                  ..setJavaScriptMode(JavaScriptMode.unrestricted),
              ),
          );
        },
      ),
    );
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
            title: Text(useSystemTheme),
            value: systemTheme,
            onChanged: (_) async => cubit.updateTheme(MediaQuery.of(context).platformBrightness),
          ),
          const Divider(
            thickness: 0.2,
            indent: 15,
            endIndent: 15,
          ),
          SwitchListTile(
            title: Text(darkModeText),
            value: darkMode,
            tileColor: systemTheme
              ? Theme.of(context).colorScheme.surfaceContainer
              : null,
            onChanged: systemTheme
              ? null
              : (_) async => cubit.updateDarkMode(MediaQuery.of(context).platformBrightness)
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
            title: Text(versionText),
            subtitle: Text(version),
          ),
          const Divider(
            thickness: 0.2,
            indent: 15,
            endIndent: 15,
          ),
          ListTile(
            title: Text(privacyPolicy),
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
            title: Text(logout),
            trailing: Icon(Icons.logout),
            onTap: () => cubit.showLogoutDialog(),
          )
        : ListTile(
            title: Text(login),
            trailing: Icon(Icons.login),
            onTap: () async => cubit.login(),
          ),
    );
  }

  Widget donationSegment() {
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
            title: Text(buyMeACoffee),
            trailing: Icon(Icons.coffee),
            onTap: () => showBuyMeACoffee(),
          ),
          const Divider(
            thickness: 0.2,
            indent: 15,
            endIndent: 15,
          ),
          ListTile(
            title: Text(paypal2),
            trailing: Icon(Icons.paypal),
            onTap: () => showPaypal(),
          )
        ],
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
        title: Text(settingsViewTitle),
        systemOverlayStyle: SystemUiOverlayStyle(
            systemNavigationBarColor: Colors.transparent, // Navigation bar
        ),
      ),
      body: BlocConsumer<SettingsViewCubit, SettingsViewState>(
        bloc: cubit,
        listenWhen: (_, current) => current is SettingsViewListener,
        listener: (context, state) {
          switch (state.runtimeType) {
            case SettingsViewShowPrivacyPolicy:
              showPrivacyPolicyWebView();
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
                  donationSegment(),
                  userSegment(),
                ]
              );
        },
      ),
    );
  }
}
