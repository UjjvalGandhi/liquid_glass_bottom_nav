import 'dart:io';

import 'package:liquid_glass_bottom_nav_cli/src/ios_config.dart';
import 'package:liquid_glass_bottom_nav_cli/src/ios_version.dart';
import 'package:path/path.dart' as p;
import 'package:test/test.dart';

void main() {
  late Directory temp;

  setUp(() => temp = Directory.systemTemp.createTempSync('liquid_glass_test'));
  tearDown(() => temp.deleteSync(recursive: true));

  File write(String name, String contents) =>
      File(p.join(temp.path, name))..writeAsStringSync(contents);

  group('IosVersion', () {
    test('parses major and optional minor', () {
      expect(IosVersion.tryParse('16'), const IosVersion(16, 0));
      expect(IosVersion.tryParse('16.4'), const IosVersion(16, 4));
      expect(IosVersion.tryParse(' 26.0 '), const IosVersion(26, 0));
      expect(IosVersion.tryParse('nonsense'), isNull);
    });

    test('orders by major before minor', () {
      expect(const IosVersion(9, 0) < const IosVersion(16, 0), isTrue);
      expect(const IosVersion(16, 4) < const IosVersion(16, 10), isTrue);
      expect(const IosVersion(26, 0) >= const IosVersion(16, 0), isTrue);
    });
  });

  group('raiseDeploymentTargets', () {
    test('raises every target below the minimum and backs up the original', () {
      final pbxproj = write('project.pbxproj', '''
IPHONEOS_DEPLOYMENT_TARGET = 12.0;
IPHONEOS_DEPLOYMENT_TARGET = 12.0;
''');

      expect(raiseDeploymentTargets(pbxproj, const IosVersion(16, 0)), 2);
      expect(pbxproj.readAsStringSync(), isNot(contains('12.0')));
      expect(
        RegExp('IPHONEOS_DEPLOYMENT_TARGET = 16.0;')
            .allMatches(pbxproj.readAsStringSync())
            .length,
        2,
      );
      expect(
        File('${pbxproj.path}.bak').readAsStringSync(),
        contains('12.0'),
      );
    });

    test('leaves targets at or above the minimum alone', () {
      final pbxproj = write(
        'project.pbxproj',
        'IPHONEOS_DEPLOYMENT_TARGET = 26.0;',
      );

      expect(raiseDeploymentTargets(pbxproj, const IosVersion(16, 0)), 0);
      expect(pbxproj.readAsStringSync(), contains('26.0'));
      // Nothing changed, so nothing should have been backed up.
      expect(File('${pbxproj.path}.bak').existsSync(), isFalse);
    });

    test('is a no-op on a second run', () {
      final pbxproj = write(
        'project.pbxproj',
        'IPHONEOS_DEPLOYMENT_TARGET = 12.0;',
      );

      expect(raiseDeploymentTargets(pbxproj, const IosVersion(16, 0)), 1);
      expect(raiseDeploymentTargets(pbxproj, const IosVersion(16, 0)), 0);
    });

    test('reports every target it finds', () {
      final pbxproj = write('project.pbxproj', '''
IPHONEOS_DEPLOYMENT_TARGET = 16.0;
IPHONEOS_DEPLOYMENT_TARGET = 26.0;
''');

      expect(readDeploymentTargets(pbxproj), [
        const IosVersion(16, 0),
        const IosVersion(26, 0),
      ]);
    });
  });

  group('Podfile platform', () {
    test('raises a low platform line and preserves indentation', () {
      final podfile = write('Podfile', "  platform :ios, '12.0'\n");

      expect(raisePodfilePlatform(podfile, const IosVersion(16, 0)), isTrue);
      expect(podfile.readAsStringSync(), "  platform :ios, '16.0'\n");
    });

    test('leaves an adequate platform line alone', () {
      final podfile = write('Podfile', "platform :ios, '16.0'\n");

      expect(raisePodfilePlatform(podfile, const IosVersion(16, 0)), isFalse);
      expect(File('${podfile.path}.bak').existsSync(), isFalse);
    });

    test('reads back the declared platform', () {
      final podfile = write('Podfile', "platform :ios, '18.2'\n");

      expect(readPodfilePlatform(podfile), const IosVersion(18, 2));
    });

    test('handles a project with no Podfile', () {
      final missing = File(p.join(temp.path, 'Podfile'));

      expect(readPodfilePlatform(missing), isNull);
      expect(raisePodfilePlatform(missing, const IosVersion(16, 0)), isFalse);
    });
  });
}
