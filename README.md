# Password Manager App
Powered by [Nextcloud](https://nextcloud.com/).

<img src="assets/launcher/icon.png" alt="drawing" width="200"/>

A password manager app (android + iOS) for Nextcloud's [Passwords](https://apps.nextcloud.com/apps/passwords) app.

You can [Install the Android App](https://play.google.com/store/apps/details?id=de.jbservices.nc_passwords_app) on your Android device via the Google Play store.

[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png"
     alt="Get the app"
     height="70">](https://play.google.com/store/apps/details?id=de.jbservices.nc_passwords_app)

As of now, the iOS app must be built by yourself.

## Getting Started

This application is built with [Flutter](https://flutter.dev/) and uses the [API](https://git.mdns.eu/nextcloud/passwords/wikis/developers/index) provided by the Passwords App.

[Install and configure flutter](https://flutter.dev/docs/get-started/install), then clone this repository. Then run ```flutter run``` for a debug preview on a started emulator, a connected Android or iOs device.

Depending on the changes you made you may also need to run these commands before running the application:

```flutter clean```

```flutter pub get```

```flutter pub run flutter_launcher_icons:main```

## Features
- View your passwords (with a copy to clipboard functionality)
- Create/Update/Delete your passwords
- Autofill Support on Android
- View/Set/Unset your favorites
- Fast search of your passwords
- View your passwords in folder view
- Optional Local Biometric Authentication
- Local cache of your passwords (if you have no current internet connection)
- Nextcloud theming

<img src="screenshots/1.jpg" alt="drawing" width="200"/>
<img src="screenshots/2.jpg" alt="drawing" width="200"/>
<img src="screenshots/3.jpg" alt="drawing" width="200"/>
<img src="screenshots/4.jpg" alt="drawing" width="200"/>
<img src="screenshots/5.jpg" alt="drawing" width="200"/>
<img src="screenshots/6.jpg" alt="drawing" width="200"/>
<img src="screenshots/7.jpg" alt="drawing" width="200"/>
<img src="screenshots/8.jpg" alt="drawing" width="200"/>

## Future features
- Tag support
- Client side encryption
- Missing something? create an [Issue](https://gitlab.com/joleaf/nc-passwords-app/-/issues/new) :)
