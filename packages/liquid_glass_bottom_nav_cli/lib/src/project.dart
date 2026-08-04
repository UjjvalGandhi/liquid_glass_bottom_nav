import 'dart:io';

import 'package:path/path.dart' as p;

/// The name of the plugin this tool installs.
const pluginPackage = 'liquid_glass_bottom_nav_native';

/// The repository `liquid_glass bootstrap` clones.
///
/// TODO: replace with the real URL before publishing. Until then `bootstrap`
/// refuses to run without an explicit `--repo`.
const projectRepository =
    'https://github.com/UjjvalGandhi/liquid_glass_bottom_nav.git';

/// True while [projectRepository] is still the unfilled placeholder.
bool get hasConfiguredRepository => !projectRepository.contains('<you>');

/// The directory name `git clone` would produce for [repository].
///
/// `https://host/owner/name.git` and `/local/path/name/` both give `name`.
String repositoryDirectoryName(String repository) {
  final trimmed = repository.replaceAll(RegExp(r'[/\\]+$'), '');
  final base = p.basename(trimmed);
  return base.endsWith('.git') ? base.substring(0, base.length - 4) : base;
}

/// Directories under [root] that contain a `pubspec.yaml`.
///
/// Skips hidden directories and build output, so a repo that has already been
/// built once does not send this walking through `build/` or `.dart_tool/`.
List<Directory> findPackages(Directory root, {int maxDepth = 3}) {
  final found = <Directory>[];

  void walk(Directory directory, int depth) {
    if (File(p.join(directory.path, 'pubspec.yaml')).existsSync()) {
      found.add(directory);
    }
    if (depth >= maxDepth) return;
    for (final entity in directory.listSync().whereType<Directory>()) {
      final name = p.basename(entity.path);
      if (name.startsWith('.') || name == 'build' || name == 'ios') continue;
      walk(entity, depth + 1);
    }
  }

  walk(root, 0);
  return found;
}

/// Whether the package at [directory] depends on the Flutter SDK, and so needs
/// `flutter pub get` rather than `dart pub get`.
bool isFlutterPackage(Directory directory) {
  final pubspec = File(p.join(directory.path, 'pubspec.yaml'));
  return pubspec.existsSync() &&
      RegExp(
        r'^\s+sdk:\s*flutter\s*$',
        multiLine: true,
      ).hasMatch(pubspec.readAsStringSync());
}

// Words that cannot be a Dart identifier, and so cannot be a package name.
// `flutter create` rejects these too, but catching it here means failing
// before a project directory has been created.
const _reservedWords = {
  'assert', 'break', 'case', 'catch', 'class', 'const', 'continue', 'default',
  'do', 'else', 'enum', 'extends', 'false', 'final', 'finally', 'for', 'if',
  'in', 'is', 'new', 'null', 'rethrow', 'return', 'super', 'switch', 'this',
  'throw', 'true', 'try', 'var', 'void', 'while', 'with',
};

/// Returns a readable problem with [name] as a Dart package name, or null when
/// it is valid.
String? validatePackageName(String name) {
  if (name.isEmpty) {
    return 'Project name must not be empty.';
  }
  if (!RegExp(r'^[a-z][a-z0-9_]*$').hasMatch(name)) {
    return 'Project name "$name" must be lower_snake_case: start with a '
        'letter, then only lowercase letters, digits or underscores.';
  }
  if (_reservedWords.contains(name)) {
    return 'Project name "$name" is a Dart reserved word.';
  }
  return null;
}

/// A Flutter project found on disk.
class FlutterProject {
  FlutterProject._(this.root);

  final Directory root;

  File get pubspec => File(p.join(root.path, 'pubspec.yaml'));

  Directory get iosDirectory => Directory(p.join(root.path, 'ios'));

  File get pbxproj =>
      File(p.join(root.path, 'ios', 'Runner.xcodeproj', 'project.pbxproj'));

  File get podfile => File(p.join(root.path, 'ios', 'Podfile'));

  /// True when the pubspec already declares [pluginPackage].
  bool get declaresPlugin => RegExp(
    '^\\s+$pluginPackage\\s*:',
    multiLine: true,
  ).hasMatch(pubspec.readAsStringSync());

  /// Walks up from [start] looking for a pubspec that declares Flutter.
  ///
  /// Returns null when [start] is not inside a Flutter project.
  static FlutterProject? find(Directory start) {
    var directory = start.absolute;
    while (true) {
      final pubspec = File(p.join(directory.path, 'pubspec.yaml'));
      if (pubspec.existsSync() && _declaresFlutter(pubspec)) {
        return FlutterProject._(directory);
      }
      final parent = directory.parent;
      if (parent.path == directory.path) return null;
      directory = parent;
    }
  }

  static bool _declaresFlutter(File pubspec) => RegExp(
    r'^\s+sdk:\s*flutter\s*$',
    multiLine: true,
  ).hasMatch(pubspec.readAsStringSync());
}
