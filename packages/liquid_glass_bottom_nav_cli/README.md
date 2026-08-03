# liquid_glass_bottom_nav_cli

One command to install [`liquid_glass_bottom_nav`][plugin] into a Flutter
project and configure the native iOS side it needs.

## Install the command

```sh
dart pub global activate liquid_glass_bottom_nav_cli
```

Works on macOS, Windows and Linux.

If your shell reports `liquid_glass: command not found`, the pub cache is not
on your `PATH`. Add whichever applies:

| Platform | Directory |
|---|---|
| macOS / Linux | `$HOME/.pub-cache/bin` |
| Windows | `%LOCALAPPDATA%\Pub\Cache\bin` |

## Get the whole project onto a new machine

```sh
liquid_glass bootstrap
```

Clones the full repository — harness app, plugin and this CLI — and runs
`pub get` in every package it finds, picking `flutter pub get` or `dart pub
get` per package. Then `cd` in and `flutter run`.

Options: `--repo <url>` to clone from somewhere else, `--ref <branch|tag>` to
check out a specific version, `--no-pub-get` to clone only. Pass a directory
name as an argument to override the default (taken from the repo name).

Requires `git` on your `PATH`; the command says so plainly if it is missing.

## Start a new app

One command, from nothing to a running glass nav:

```sh
liquid_glass create my_app
cd my_app && flutter run
```

This runs `flutter create`, adds the plugin, raises the iOS deployment target,
and writes a `lib/main.dart` with a four-tab bar already wired up — including
the `extendBody: true` and full-screen `Stack` placement the widget needs, and
a Material `NavigationBar` fallback so the app still runs on Android, web and
desktop.

Options: `--org com.example` to set the bundle identifier prefix,
`--plugin-path <dir>` to depend on a local plugin checkout instead of the
published one, `--no-ios-config` to leave Xcode settings alone.

## Add it to an existing app

From anywhere inside your Flutter app:

```sh
liquid_glass install
```

This will:

1. Find the project root by walking up from the current directory.
2. Run `flutter pub add liquid_glass_bottom_nav`, then `flutter pub get`.
3. Raise `IPHONEOS_DEPLOYMENT_TARGET` to 16.0 in `ios/Runner.xcodeproj` if it
   is lower, and the `platform :ios` line in your `Podfile` if you have one.
   **The originals are saved alongside as `.bak`.** Pass `--no-ios-config` to
   skip this entirely.
4. Print the widget snippet to paste in.

Re-running is a no-op. On Windows and Linux step 3 is skipped, since iOS
builds require macOS — the dependency is still added, so you can develop
against the fallback widget.

## Check your setup

```sh
liquid_glass doctor
```

The plugin guards every iOS 26 API with `#available`, so on older systems it
builds and runs fine but quietly renders the classic flat tab bar instead of
Liquid Glass. `doctor` tells you which one you are going to get, and why:

```
Project
  [ok]   Flutter project at /Users/you/my_app
  [ok]   liquid_glass_bottom_nav declared in pubspec.yaml

iOS project
  [ok]   Deployment target 16.0
  [--]   No Podfile (Swift Package Manager project)

Toolchain
  [ok]   Xcode 26.5
  [ok]   Simulator runtime: iOS 26.5

Verdict
  [ok]   Builds against iOS 16.0. Liquid Glass renders on iOS 26.0+ devices;
         older devices get the classic flat tab bar.
```

Note that the deployment target sets only the *build* floor. Which bar you get
is decided at runtime by the device's OS version, so a project targeting iOS
16.0 still shows full Liquid Glass when run on iOS 26.

`doctor` exits non-zero when something is actually broken, so it is safe to
put in CI.

[plugin]: https://pub.dev/packages/liquid_glass_bottom_nav
