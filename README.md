# Birthdays

A personal Android and iPhone app that reminds you of birthdays and other yearly dates at **12:00 AM on the day**. Paste your list once (from Google Keep or anywhere), and it runs fully offline: no account, no server, no internet permission.

[![Download APK](https://img.shields.io/badge/Download-Android%20APK-B5533C?style=for-the-badge&logo=android&logoColor=white)](https://github.com/HarshAn119/Birthday_reminders/releases/latest/download/app-arm64-v8a-release.apk)

Open the link on your Android phone and install it. Android will ask you to allow installs from your browser once. iPhone builds aren't published.

## Features

- **Paste or type dates.** One per line. The preview shows what was understood and flags lines it couldn't read, so nothing is skipped silently.
- **Midnight reminders**, repeating every year, with age when a birth year is given ("Rahul turns 30").
- **Three themes:** Scrapbook (default), Confetti and Midnight. Each changes the look *and* the notification wording.
- **Tap a person** to edit or delete them (deleting can be undone).

### Accepted line formats

Day comes before month in numeric dates: `02/09` is 2 September.

```
Rahul - 10 Nov 1996
Priya Sharma: 14/11/1999
Mom & Dad anniversary 2 Dec
☐ March 3rd, 1990 – Neha
Amit 05-08-01
```

- **Separators:** `/`, `-` and `.` all work, and 2-digit years are accepted.
- **Month names:** full or short (`Mar`, `March`).
- **Keep checkboxes and bullets** are stripped.
- **Names containing "anniv"** show "anniversary" or "N years together" instead of "turning N".
- **29 Feb** is reminded on 28 Feb in non-leap years.

## How reminders work

The app schedules one-off notifications for each upcoming midnight, in the phone's local time zone. It refreshes that batch every time the app opens or the list changes.

| | Android | iPhone |
|---|---|---|
| Reminders queued ahead | up to 400, covering ~2 years | the next 64 (Apple's limit) |
| Fires exactly at 12:00 | yes, if "Alarms & reminders" is allowed; otherwise within a few minutes | yes |
| Survives reboot | yes | yes |

**Known limits:**
- **Open the app occasionally.** If it isn't opened for long enough that the queued batch runs out, reminders stop. On iPhone that's once 64 reminders have fired. This is marked as a `shortcut:` in `lib/reminders.dart`.
- **Silent mode and Do Not Disturb** mute the sound. The reminder still appears on the lock screen.
- **Some Android makers' battery savers** (Xiaomi, OnePlus, Samsung) can delay reminders for rarely used apps.

## Project layout

```
lib/
  entry.dart      Entry model, line parser, next-occurrence and age logic
  reminders.dart  Notification setup and (re)scheduling
  themes.dart     The three themes: colours, fonts, widgets, notification copy
  main.dart       App state (saved in SharedPreferences), screens
test/
  entry_test.dart Parser and scheduling tests
assets/
  fonts/          Bundled Google Fonts (OFL), so the app needs no network
  icon/           App icon source (icon.html) and rendered PNGs
```

## Development

**Requirements:**
- Flutter 3.47+
- Android SDK with API 37
- For iPhone builds: full Xcode and CocoaPods

```bash
flutter pub get
```

```bash
flutter test
```

```bash
flutter run
```

### Changing the app icon

Edit `assets/icon/icon.html`, then:
1. Re-render `full.png`, `fg.png` and `stat.png` (1024×1024) with headless Chrome, opening the file with `#full`, `#fg` or `#stat` at the end of its path.
2. Regenerate the icons:

```bash
dart run flutter_launcher_icons
```

3. Copy a 96×96 `stat.png` to `android/app/src/main/res/drawable-xxxhdpi/ic_notification.png`. This is the white status-bar icon.

When releasing an icon change, raise the build number in `pubspec.yaml`. Android caches app icons per version.

To build and publish a new version, see [RELEASING.md](RELEASING.md).

## Privacy and security

- **No internet permission** in release builds, so the list never leaves the phone.
- **Data storage:** the list is stored in the app's private storage, unencrypted, and is included in Android's device backup.
- **Lock screen:** reminders show names and ages there.
