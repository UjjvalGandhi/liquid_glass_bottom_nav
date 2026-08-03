## 0.1.0

* Initial release.
* `liquid_glass bootstrap` clones the whole project onto a new machine and
  resolves every package in the checkout, choosing `flutter pub get` or
  `dart pub get` per package.
* `liquid_glass create <name>` scaffolds a new Flutter app with the glass nav
  already wired up — `flutter create`, the dependency, the iOS deployment
  target, and a working `lib/main.dart` with a Material fallback for non-iOS
  platforms.
* `liquid_glass install` adds `liquid_glass_bottom_nav` to an existing project
  and raises the iOS deployment target to 16.0 when needed, keeping the
  original files as `.bak`.
* `liquid_glass doctor` reports whether the project and toolchain will render
  the Liquid Glass bar or fall back to the classic flat tab bar.
* `create` and `install` accept `--plugin-path` to depend on a local plugin
  checkout, for testing unreleased changes.
