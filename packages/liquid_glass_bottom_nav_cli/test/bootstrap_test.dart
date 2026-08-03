import 'dart:io';

import 'package:liquid_glass_bottom_nav_cli/src/project.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  group('repositoryDirectoryName', () {
    test('strips the .git suffix from a remote URL', () {
      expect(
        repositoryDirectoryName('https://github.com/you/my_project.git'),
        'my_project',
      );
    });

    test('handles a URL without the suffix', () {
      expect(
        repositoryDirectoryName('https://github.com/you/my_project'),
        'my_project',
      );
    });

    test('handles trailing slashes and local paths', () {
      expect(repositoryDirectoryName('/tmp/origin/'), 'origin');
      expect(repositoryDirectoryName('git@host:you/my_project.git'), 'my_project');
    });
  });

  group('findPackages', () {
    late Directory temp;

    setUp(() => temp = Directory.systemTemp.createTempSync('bootstrap_test'));
    tearDown(() => temp.deleteSync(recursive: true));

    void makePackage(String relative, {required bool flutter}) {
      final directory = Directory(p.join(temp.path, relative))
        ..createSync(recursive: true);
      File(p.join(directory.path, 'pubspec.yaml')).writeAsStringSync(
        flutter
            ? 'name: x\ndependencies:\n  flutter:\n    sdk: flutter\n'
            : 'name: x\ndependencies:\n  args: ^2.0.0\n',
      );
    }

    test('finds the root and every nested package', () {
      makePackage('.', flutter: true);
      makePackage('packages/plugin', flutter: true);
      makePackage('packages/cli', flutter: false);

      final found = findPackages(
        temp,
      ).map((d) => p.relative(d.path, from: temp.path)).toSet();

      expect(found, {'.', 'packages/plugin', 'packages/cli'});
    });

    test('skips build output and hidden directories', () {
      makePackage('.', flutter: true);
      makePackage('build/leftover', flutter: true);
      makePackage('.dart_tool/leftover', flutter: true);

      final found = findPackages(
        temp,
      ).map((d) => p.relative(d.path, from: temp.path));

      expect(found, ['.']);
    });

    test('distinguishes Flutter packages from pure Dart ones', () {
      makePackage('plugin', flutter: true);
      makePackage('cli', flutter: false);

      expect(isFlutterPackage(Directory(p.join(temp.path, 'plugin'))), isTrue);
      expect(isFlutterPackage(Directory(p.join(temp.path, 'cli'))), isFalse);
    });
  });
}
