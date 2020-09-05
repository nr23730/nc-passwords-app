import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';

import './provider/nextcloud_auth_provider.dart';
import './provider/passwords_provider.dart';
import './provider/local_auth_provider.dart';
import './provider/settings_provider.dart';

import './screens/settings_screen.dart';
import './screens/password_edit_screen.dart';
import './screens/passwords_favorite_screen.dart';
import './screens/local_auth_screen.dart';
import './screens/nextcloud_auth_screen.dart';
import './screens/passwords_overview_screen.dart';
import './screens/passwords_folder_screen.dart';

void main() {
  runApp(NCPasswordsApp());
}

class NCPasswordsApp extends StatelessWidget {
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
      ],
      child: MaterialApp(
        title: 'NC Passwords',
        // theme: ThemeData.dark(),
        theme: ThemeData(
          primarySwatch: Colors.teal,
          accentColor: Colors.blueGrey,
          fontFamily: "Quicksand",
          textTheme: ThemeData.light().textTheme.copyWith(
                bodyText1: GoogleFonts.raleway(),
                bodyText2: GoogleFonts.raleway(),
              ),
          appBarTheme: AppBarTheme(
            textTheme: ThemeData.light().textTheme.copyWith(
                  headline6: GoogleFonts.raleway(
                      textStyle:
                          TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
          ),
        ),
        routes: {
          PasswordsOverviewScreen.routeName: (ctx) => PasswordsOverviewScreen(),
          PasswordEditScreen.routeName: (ctx) => PasswordEditScreen(),
          PasswordsFolderScreen.routeName: (ctx) => PasswordsFolderScreen(),
          PasswordsFavoriteScreen.routeName: (ctx) => PasswordsFavoriteScreen(),
          SettingsScreen.routeName: (ctx) => SettingsScreen(),
          // home route
          '/': (ctx) {
            final localAuth =
                Provider.of<LocalAuthProvider>(ctx, listen: false);
            final webAuth =
                Provider.of<NextcloudAuthProvider>(ctx, listen: false);
            final settings = Provider.of<SettingsProvider>(ctx, listen: false);
            return FutureBuilder(
              future: settings.loadFromStorage(webAuth),
              builder: (ctx2, snapshot) => snapshot.connectionState ==
                      ConnectionState.done
                  ? !localAuth.isAuthenticated && settings.useBiometricAuth
                      ? LocalAuthScreen()
                      : !webAuth.isAuthenticated
                          ? NextcloudAuthScreen()
                          : loadHome(settings.startView)
                  : Scaffold(body: Center(child: CircularProgressIndicator())),
            );
          }
        },
      ),
    );
  }

  Widget loadHome(StartView startView) {
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
