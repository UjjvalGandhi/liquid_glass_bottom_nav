import 'dart:io';

import 'ios_version.dart';

final _pbxprojTarget = RegExp(r'IPHONEOS_DEPLOYMENT_TARGET = ([\d.]+);');
final _podfilePlatform = RegExp(
  r"^(\s*)platform :ios, '([\d.]+)'",
  multiLine: true,
);

/// Every `IPHONEOS_DEPLOYMENT_TARGET` declared in an Xcode project file.
///
/// A `project.pbxproj` carries one per build configuration, so this is
/// normally two or more identical values.
List<IosVersion> readDeploymentTargets(File pbxproj) {
  if (!pbxproj.existsSync()) return const [];
  return [
    for (final match in _pbxprojTarget.allMatches(pbxproj.readAsStringSync()))
      ?IosVersion.tryParse(match[1]!),
  ];
}

/// The `platform :ios` line from a Podfile, when there is one.
IosVersion? readPodfilePlatform(File podfile) {
  if (!podfile.existsSync()) return null;
  final match = _podfilePlatform.firstMatch(podfile.readAsStringSync());
  return match == null ? null : IosVersion.tryParse(match[2]!);
}

/// Raises every deployment target in [pbxproj] that sits below [target].
///
/// Writes the original alongside as `.bak` before touching anything, and
/// leaves the file untouched when nothing needs raising, so re-running is a
/// no-op. Returns how many targets were raised.
int raiseDeploymentTargets(File pbxproj, IosVersion target) {
  if (!pbxproj.existsSync()) return 0;
  final original = pbxproj.readAsStringSync();
  var raised = 0;

  final updated = original.replaceAllMapped(_pbxprojTarget, (match) {
    final current = IosVersion.tryParse(match[1]!);
    if (current == null || current >= target) return match[0]!;
    raised++;
    return 'IPHONEOS_DEPLOYMENT_TARGET = $target;';
  });

  if (raised > 0) {
    File('${pbxproj.path}.bak').writeAsStringSync(original);
    pbxproj.writeAsStringSync(updated);
  }
  return raised;
}

/// Raises a Podfile's `platform :ios` line if it sits below [target].
///
/// Backs up and no-ops on the same terms as [raiseDeploymentTargets].
bool raisePodfilePlatform(File podfile, IosVersion target) {
  if (!podfile.existsSync()) return false;
  final original = podfile.readAsStringSync();
  var raised = false;

  final updated = original.replaceAllMapped(_podfilePlatform, (match) {
    final current = IosVersion.tryParse(match[2]!);
    if (current == null || current >= target) return match[0]!;
    raised = true;
    return "${match[1]}platform :ios, '$target'";
  });

  if (raised) {
    File('${podfile.path}.bak').writeAsStringSync(original);
    podfile.writeAsStringSync(updated);
  }
  return raised;
}
