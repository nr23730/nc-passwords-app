# Password Manager App
Powered by [Nextcloud](https://nextcloud.com/).

<img src="assets/launcher/icon.png" alt="drawing" width="200"/>

A password manager app (Android + iOS) for Nextcloud's [Passwords](https://apps.nextcloud.com/apps/passwords) app.

## Install 

### Android
You can install the Android App on your Android device via the [Google Play store](https://play.google.com/store/apps/details?id=de.jbservices.nc_passwords_app) or via [fdroid](https://f-droid.org/de/packages/de.jbservices.nc_passwords_app/).

[<img src="https://play.google.com/intl/en_us/badges/images/generic/en-play-badge.png"
     alt="Get the app"
     height="70">](https://play.google.com/store/apps/details?id=de.jbservices.nc_passwords_app)
[<img src="https://fdroid.gitlab.io/artwork/badge/get-it-on.png"
     alt="Get on F-Droid"
     height="70">](https://f-droid.org/de/packages/de.jbservices.nc_passwords_app/)

Or install the apk from the last pipeline job:

[![pipeline status](https://gitlab.com/joleaf/nc-passwords-app/badges/main/pipeline.svg)](https://gitlab.com/joleaf/nc-passwords-app/-/commits/main)

### iOS
As of now, the iOS app must be built by yourself. 
Or, take a look at [this](https://github.com/johannes-schliephake/nextcloud-passwords-ios) native iOS project.

## Donate
<a href="https://www.buymeacoffee.com/joleaf" target="_blank"><img src="https://cdn.buymeacoffee.com/buttons/default-blue.png" alt="Buy Me A Pizza" height="41" width="174"></a>

## Getting Started

This application is built with [Flutter](https://flutter.dev/) and uses the [API](https://git.mdns.eu/nextcloud/passwords/wikis/developers/index) provided by the Passwords App.

[Install and configure flutter](https://flutter.dev/docs/get-started/install), then clone this repository. Then run ```flutter run``` for a debug preview on a started emulator, a connected Android or iOS device.

Depending on the changes you made you may also need to run these commands before running the application:

```flutter clean```

```flutter pub get```

```flutter pub run flutter_launcher_icons:main```

## Contributors
- [@domi77fullhd](https://gitlab.com/domi77fullhd) - Thank you for your UI support.
- [@sepo83](https://gitlab.com/sepo83) - Thank you for the support of the fdroid integration.

## Features
- View your passwords (with quick copy to clipboard functionality)
- Create/Update/Delete your passwords
- Autofill Support on Android
- View/Set/Unset your favorites
- Fast search of your passwords
- View your passwords in folder view
- Optional local biometric authentication
- Local cache of your passwords (if you have no current internet connection)
- Nextcloud theming
- Displaying the icons of linked websites
- Client side encryption

<img src="screenshots/1.jpg" alt="drawing" width="215"/>
<img src="screenshots/2.jpg" alt="drawing" width="215"/>
<img src="screenshots/3.jpg" alt="drawing" width="215"/>
<img src="screenshots/4.jpg" alt="drawing" width="215"/>
<img src="screenshots/5.jpg" alt="drawing" width="215"/>
<img src="screenshots/6.jpg" alt="drawing" width="215"/>
<img src="screenshots/7.jpg" alt="drawing" width="215"/>
<img src="screenshots/8.jpg" alt="drawing" width="215"/>
<img src="screenshots/9.jpg" alt="drawing" width="215"/>
<img src="screenshots/10.jpg" alt="drawing" width="215"/>
<img src="screenshots/11.jpg" alt="drawing" width="215"/>

## Future features
- Tag support
- Missing something? Create an [Issue](https://gitlab.com/joleaf/nc-passwords-app/-/issues/new) :)
