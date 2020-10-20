import 'package:flutter/material.dart';
import 'package:flutter_i18n/flutter_i18n.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:provider/provider.dart';
import './provider/nextcloud_auth_provider.dart';

import './provider/passwords_provider.dart';
import './provider/local_auth_provider.dart';
import './provider/theme_provider.dart';
import './provider/settings_provider.dart';

import './screens/settings_screen.dart';
import './screens/password_edit_screen.dart';
import './screens/passwords_favorite_screen.dart';
import './screens/local_auth_screen.dart';
import './screens/folder_select_screen.dart';
import './screens/nextcloud_auth_screen.dart';
import './screens/passwords_overview_screen.dart';
import './screens/passwords_folder_screen.dart';

Future<void> main() async {
  final FlutterI18nDelegate flutterI18nDelegate = FlutterI18nDelegate(
    translationLoader: FileTranslationLoader(
      useCountryCode: false,
      fallbackFile: 'en',
      basePath: 'assets/i18n',
      //forcedLocale: Locale('de'),
    ),
  );
  await flutterI18nDelegate.load(null);
  WidgetsFlutterBinding.ensureInitialized();
  runApp(NCPasswordsApp(flutterI18nDelegate));
}

class NCPasswordsApp extends StatelessWidget {
  final FlutterI18nDelegate flutterI18nDelegate;

  NCPasswordsApp(this.flutterI18nDelegate);

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider<SettingsProvider>(
          create: (context) => SettingsProvider(),
        ),
        ChangeNotifierProvider<LocalAuthProvider>(
          create: (ctx) => LocalAuthProvider(),
        ),
        ChangeNotifierProvider<NextcloudAuthProvider>(
          create: (ctx) => NextcloudAuthProvider(),
        ),
        ChangeNotifierProxyProvider<NextcloudAuthProvider, PasswordsProvider>(
          create: (context) => PasswordsProvider(null),
          update: (context, ncAuth, previous) => PasswordsProvider(ncAuth),
        ),
        ChangeNotifierProxyProvider<NextcloudAuthProvider, ThemeProvider>(
          create: (context) => ThemeProvider(null),
          update: (context, ncAuth, previous) => ThemeProvider(ncAuth),
        )
      ],
      builder: FlutterI18n.rootAppBuilder(),
      child: Builder(
        builder: (context) => _buildApp(context),
      ),
    );
  }

  Widget _buildApp(BuildContext context) {
    final webAuth = Provider.of<NextcloudAuthProvider>(context, listen: false);
    final themeProvider = Provider.of<ThemeProvider>(context, listen: false);
    final settings = Provider.of<SettingsProvider>(context, listen: false);
    return MaterialApp(
      title: 'NC Passwords',
      localizationsDelegates: [
        flutterI18nDelegate,
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate
      ],
      supportedLocales: [
        const Locale('en', ''),
        const Locale('de', ''),
      ],
      theme: Provider.of<ThemeProvider>(context).currentTheme(),
      routes: {
        PasswordsOverviewScreen.routeName: (ctx) => PasswordsOverviewScreen(),
        PasswordEditScreen.routeName: (ctx) => PasswordEditScreen(),
        PasswordsFolderScreen.routeName: (ctx) => PasswordsFolderScreen(),
        PasswordsFavoriteScreen.routeName: (ctx) => PasswordsFavoriteScreen(),
        FolderSelectScreen.routeName: (ctx) => FolderSelectScreen(),
        SettingsScreen.routeName: (ctx) => SettingsScreen(),
      },
      home: FutureBuilder(
        future: settings.loadFromStorage(webAuth, themeProvider),
        builder: (ctx2, snapshot) {
          return snapshot.connectionState == ConnectionState.done
              ? _rootRoute(ctx2)
              : Scaffold(
                  backgroundColor: Colors.black,
                  body: Center(child: CircularProgressIndicator()));
        },
      ),
    );
  }

  Widget _rootRoute(BuildContext ctx) {
    final autofill =
        WidgetsBinding.instance.window.defaultRouteName == '/autofill';
    final localAuth = Provider.of<LocalAuthProvider>(ctx, listen: false);
    final webAuth = Provider.of<NextcloudAuthProvider>(ctx, listen: false);
    final settings = Provider.of<SettingsProvider>(ctx, listen: false);
    return !localAuth.isAuthenticated && settings.useBiometricAuth
        ? LocalAuthScreen()
        : !webAuth.isAuthenticated
            ? NextcloudAuthScreen()
            : _loadHome(autofill ? StartView.AllPasswords : settings.startView);
  }

  Widget _loadHome(StartView startView) {
    switch (startView) {
      case StartView.AllPasswords:
        {
          return PasswordsOverviewScreen();
        }
      case StartView.Folders:
        {
          return PasswordsFolderScreen();
        }
      case StartView.Favorites:
        {
          return PasswordsFavoriteScreen();
        }
      default:
        {
          return PasswordsOverviewScreen();
        }
    }
  }
}
