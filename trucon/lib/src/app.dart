import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

import 'sample_feature/sample_item_details_view.dart';
import 'settings/settings_controller.dart';
import 'settings/settings_view.dart';
import 'pages/login.dart';

/// The Widget that configures your application.
class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.settingsController,
  });

  final SettingsController settingsController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: settingsController,
      builder: (BuildContext context, Widget? child) {
        return MaterialApp(
          restorationScopeId: 'app',
          title: AppLocalizations.of(context)?.appTitle ?? 'MyApp', // Added null safety check

          theme: ThemeData(),
          darkTheme: ThemeData.dark(),
          themeMode: settingsController.themeMode,

          // Set the initial route
          initialRoute: '/',

          // Define routes
          onGenerateRoute: (RouteSettings routeSettings) {
            return MaterialPageRoute<void>(
              settings: routeSettings,
              builder: (BuildContext context) {
                switch (routeSettings.name) {
                  case '/':
                    return const LoginPage(); // Initial screen set to LoginPage
                  case SettingsView.routeName:
                    return SettingsView(controller: settingsController);
                  case SampleItemDetailsView.routeName:
                    return const SampleItemDetailsView();
                  default:
                    return const LoginPage(); // Default to LoginPage
                }
              },
            );
          },
        );
      },
    );
  }
}
