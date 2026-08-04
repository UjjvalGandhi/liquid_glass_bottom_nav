# Liquid Glass Bottom Nav — Setup & Release Steps

Everything needed to take this repo from its current state to `liquid_glass
create my_app` working on any machine in the world.

Work through the sections in order. Anything marked **BLOCKER** cannot be done
by anyone but you.

- **§1–§5** — you, once: fill in metadata and publish.
- **§6** — anyone, on any new device: bare machine to running app.
- **§7–§9** — reference, local development, and known issues.

---

## 0. What is in the repo right now

```
/                                     harness Flutter app ("untitled")
  lib/main.dart                       demo screen using the plugin
  ios/                                Swift Package Manager, no Podfile
  test/widget_test.dart               1 of 2 tests currently fails (see §9)

packages/liquid_glass_bottom_nav_native/     THE PLUGIN            v0.1.0
  lib/liquid_glass_bottom_nav_native.dart    Dart API (UiKitView + method channel)
  ios/.../LiquidGlassBottomNavPlugin.swift
                                      real UITabBarController, 3 classes
  example/                            standalone example app

packages/liquid_glass_bottom_nav_cli/ THE INSTALLER CLI     v0.1.0
  bin/liquid_glass.dart               entry point
  lib/src/bootstrap_command.dart      `liquid_glass bootstrap`
  lib/src/create_command.dart         `liquid_glass create <name>`
  lib/src/install_command.dart        `liquid_glass install`
  lib/src/doctor_command.dart         `liquid_glass doctor`
  lib/src/installer.dart              shared: add dependency + iOS config
  lib/src/ios_config.dart             pbxproj / Podfile patching (+ .bak)
  lib/src/templates.dart              generated lib/main.dart
  test/                               22 tests, all passing
```

Status: both packages analyze clean, all tests pass, and `create` has been
verified end to end (generated app builds, installs and renders Liquid Glass
on an iOS 26.5 simulator).

---

## 1. BLOCKER — three things only you can supply

| # | What | Where it goes |
|---|---|---|
| 1 | A git repository URL | both `pubspec.yaml` files |
| 2 | A license choice (MIT is the norm for Flutter plugins) | `packages/liquid_glass_bottom_nav_native/LICENSE` |
| 3 | Author name + email | the podspec |

Nothing in §3–§5 can proceed until these exist.

---

## 2. Create the git repository

This repo is **not** under version control yet — `git init` has never been run.
pub.dev wants a reachable `repository:` URL, so this comes first.

```sh
cd /Users/prasantashil/Downloads/untitled

git init
git branch -M main
git add .
git commit -m "Liquid Glass bottom nav plugin and installer CLI"

# create the repo on GitHub first, then:
git remote add origin https://github.com/<you>/liquid_glass_bottom_nav_native.git
git push -u origin main
```

Before the first commit, add a `.gitignore` for the CLI package — it does not
have one, so `.dart_tool/` would be committed:

```sh
printf '.dart_tool/\n.packages\npubspec.lock\n' \
  > packages/liquid_glass_bottom_nav_cli/.gitignore
```

(`pubspec.lock` is intentionally ignored: it is a published package, not an
application.)

---

## 3. Fill in the package metadata

### 3a. License — `packages/liquid_glass_bottom_nav_native/LICENSE`

Currently the file contains exactly one line: `TODO: Add your license here.`
That is legally meaningless and will hurt the pub.dev score. Replace it, e.g.
MIT:

```
MIT License

Copyright (c) 2026 <YOUR NAME>

Permission is hereby granted, free of charge, to any person obtaining a copy
of this software and associated documentation files (the "Software"), to deal
in the Software without restriction, including without limitation the rights
to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all
copies or substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
SOFTWARE.
```

Copy the same file to `packages/liquid_glass_bottom_nav_cli/LICENSE`.

### 3b. Repository URL — both pubspecs

Each pubspec has a commented-out placeholder. Uncomment and fill in:

`packages/liquid_glass_bottom_nav_native/pubspec.yaml`

```yaml
repository: https://github.com/<you>/liquid_glass_bottom_nav_native
```

`packages/liquid_glass_bottom_nav_cli/pubspec.yaml`

```yaml
repository: https://github.com/<you>/liquid_glass_bottom_nav_native
```

This is the **only** remaining warning from `pub publish --dry-run`.

Then set the same URL as the clone target for `liquid_glass bootstrap`, in
`packages/liquid_glass_bottom_nav_cli/lib/src/project.dart`:

```dart
const projectRepository =
    'https://github.com/<you>/liquid_glass_bottom_nav_native.git';
```

Until this is filled in, `bootstrap` exits with a clear error rather than
attempting to clone a placeholder URL.

### 3c. Podspec metadata

`packages/liquid_glass_bottom_nav_native/ios/liquid_glass_bottom_nav_native.podspec`, lines
13–15 still hold the `flutter create` placeholders:

```ruby
s.homepage = 'http://example.com'                        # -> your repo URL
s.author   = { 'Your Company' => 'email@example.com' }   # -> your name/email
```

Note this file is **vestigial** — the project uses Swift Package Manager, not
CocoaPods. Fix it anyway so consumers on CocoaPods are not broken.

---

## 4. Verify before publishing

```sh
# plugin
cd packages/liquid_glass_bottom_nav_native
flutter analyze
flutter pub publish --dry-run        # must report 0 warnings

# CLI
cd ../liquid_glass_bottom_nav_cli
dart analyze
dart test                            # 16 tests
dart pub publish --dry-run

# harness app
cd ../..
flutter analyze
```

Also confirm the package name is free — open
<https://pub.dev/packages/liquid_glass_bottom_nav_native>. A 404 means it is
available.

---

## 5. Publish

Publish the **plugin first**. The CLI does not depend on it at build time (it
is pure Dart), but `liquid_glass create` runs `flutter pub add
liquid_glass_bottom_nav_native`, which fails until the plugin is live.

```sh
cd packages/liquid_glass_bottom_nav_native
flutter pub publish

cd ../liquid_glass_bottom_nav_cli
dart pub publish
```

Both are irreversible — a published version can be retracted but never
replaced. Re-read the `--dry-run` output before confirming.

After publishing, point the harness app at the released plugin instead of the
local path. Keep local development working with an override:

`/pubspec.yaml`
```yaml
dependencies:
  liquid_glass_bottom_nav_native: ^0.1.0

dependency_overrides:
  liquid_glass_bottom_nav_native:
    path: packages/liquid_glass_bottom_nav_native
```

---

## 6. New device — from a bare machine to a running app

Everything below assumes a machine with **nothing installed**. If Flutter and
git are already there, skip to step 3.

### Step 1 — install git

| Platform | How |
|---|---|
| Windows | <https://git-scm.com/download/win>, or `winget install Git.Git` |
| macOS | `xcode-select --install` (ships git), or `brew install git` |
| Linux | `sudo apt install git` / `sudo dnf install git` |

Verify: `git --version`

### Step 2 — install the Flutter SDK

Flutter bundles Dart, so this covers the `dart` command too. Follow
<https://docs.flutter.dev/get-started/install> for your platform, then add
Flutter's `bin` to `PATH`.

| Platform | Typical PATH entry |
|---|---|
| Windows | `C:\src\flutter\bin` |
| macOS / Linux | `$HOME/flutter/bin` |

Verify both:

```sh
flutter --version
dart --version
```

Then let Flutter tell you what is still missing:

```sh
flutter doctor
```

### Step 3 — iOS toolchain (macOS only)

Liquid Glass is an iOS feature, so seeing it requires a Mac:

1. Install **Xcode 26 or newer** from the App Store.
2. `sudo xcodebuild -license accept`
3. `xcodebuild -downloadPlatform iOS` to get an iOS 26+ simulator runtime.

On Windows and Linux you can still build and run the project — the app falls
back to a Material `NavigationBar`, and the CLI skips the iOS steps rather
than failing.

### Step 4 — install the command

```sh
dart pub global activate liquid_glass_bottom_nav_cli
```

If the shell then reports `liquid_glass: command not found`, the pub cache is
not on `PATH`:

| Platform | Add to PATH |
|---|---|
| macOS / Linux | `$HOME/.pub-cache/bin` |
| Windows | `%LOCALAPPDATA%\Pub\Cache\bin` |

Verify: `liquid_glass --help`

### Step 5 — pull the project down and run it

```sh
liquid_glass bootstrap
cd liquid_glass_bottom_nav_native
flutter run
```

That is the whole journey. Everything from here is reference.

---

## 7. Command reference

Works identically on macOS, Windows and Linux.

```sh
dart pub global activate liquid_glass_bottom_nav_cli
```

If the shell then reports `liquid_glass: command not found`, the pub cache is
not on `PATH`:

| Platform | Add to PATH |
|---|---|
| macOS / Linux | `$HOME/.pub-cache/bin` |
| Windows | `%LOCALAPPDATA%\Pub\Cache\bin` |

**Get this whole project onto a new machine** — the harness app, the plugin
source and the CLI, all resolved and ready to run:

```sh
liquid_glass bootstrap
cd liquid_glass_bottom_nav_native && flutter run
```

It clones the repository and runs `pub get` in every package it finds,
choosing `flutter pub get` or `dart pub get` per package. Needs `git` on
`PATH`. Use `--repo <url>` to clone from elsewhere, `--ref <branch|tag>` to
pin a version, `--no-pub-get` to clone only.

> The repository URL is compiled into the CLI as `projectRepository` in
> `packages/liquid_glass_bottom_nav_cli/lib/src/project.dart`. **It is still
> the `<you>` placeholder** — fill it in as part of §3b, otherwise `bootstrap`
> refuses to run without an explicit `--repo`.

**New app from scratch:**

```sh
liquid_glass create my_app
cd my_app && flutter run
```

**Add to an existing app:**

```sh
cd path/to/existing_app
liquid_glass install
```

**Check what will actually render:**

```sh
liquid_glass doctor
```

Useful flags:

| Flag | Commands | Effect |
|---|---|---|
| `--repo <url>` | `bootstrap` | clone from a different repository |
| `--ref <branch\|tag>` | `bootstrap` | check out a specific version |
| `--no-pub-get` | `bootstrap` | clone without resolving |
| `--org com.example` | `create` | bundle identifier prefix |
| `--plugin-path <dir>` | `create`, `install` | use a local plugin checkout |
| `--no-ios-config` | `create`, `install` | leave Xcode settings untouched |

On Windows and Linux the iOS step is skipped rather than failed — the
dependency still installs, and the app runs against the Material fallback.

---

## 8. Developing locally without publishing

`--plugin-path` makes the whole flow work before anything is on pub.dev:

```sh
cd packages/liquid_glass_bottom_nav_cli
dart pub global activate --source path .

cd /tmp
liquid_glass create demo_app \
  --plugin-path /Users/prasantashil/Downloads/untitled/packages/liquid_glass_bottom_nav_native
cd demo_app && flutter run
```

To run the harness app on a simulator:

```sh
cd /Users/prasantashil/Downloads/untitled
flutter build ios --simulator --debug
xcrun simctl boot "iPhone 17 Pro"
xcrun simctl install booted build/ios/iphonesimulator/Runner.app
xcrun simctl launch booted com.example.untitled
```

---

## 9. Known open items

These are real and unfixed. None block publishing.

**1. `selectedIndex` is write-once.** The Swift side has no
`setMethodCallHandler` — the method channel is `invokeMethod`-only,
native → Dart. Combined with `UiKitView` not rebuilding on `creationParams`
changes, the widget *looks* like a controlled component but is not: changing
`selectedIndex` programmatically from Dart silently does nothing, and the two
sides drift apart. Fix by adding a native handler for a `selectTab` call.

**2. `test/widget_test.dart` is stale.** 1 of 2 tests fails. It expects an
"Explore" tab (`lib/main.dart` now says "Setting") and an "Add" button that no
longer exists.

**3. The icon fix trades away Dynamic Type.** `tabImage(named:)` in
`LiquidGlassBottomNavPlugin.swift` flattens each SF Symbol to a template raster
at `pointSize: 22`, which is what stops tab bars from silently substituting the
`.fill` variant (this is why `play.rectangle` was rendering as the much heavier
`play.rectangle.fill`). The cost: icons no longer scale with accessibility text
sizes, and hierarchical/variable symbol rendering is unavailable. The
alternative is to accept the substitution and name only `.fill` symbols.

**4. Deployment target vs. runtime version.** Easy to get backwards, and worth
keeping in the README: `IPHONEOS_DEPLOYMENT_TARGET` sets only the *build*
floor. Whether Liquid Glass or the flat fallback renders is decided at runtime
by the device's OS version, because every iOS 26 API is behind `#available`. A
project targeting iOS 16.0 still shows full Liquid Glass on an iOS 26 device.
This is exactly what `liquid_glass doctor` reports.
