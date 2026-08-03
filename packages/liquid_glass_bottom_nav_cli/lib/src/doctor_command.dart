import 'dart:io';

import 'package:args/command_runner.dart';

import 'console.dart';
import 'ios_config.dart';
import 'ios_version.dart';
import 'process_runner.dart';
import 'project.dart';

/// Reports whether this machine and project can actually render the Liquid
/// Glass bar, rather than the flat fallback.
class DoctorCommand extends Command<int> {
  @override
  String get name => 'doctor';

  @override
  String get description =>
      'Check whether this project will render the Liquid Glass bar.';

  @override
  Future<int> run() async {
    final project = FlutterProject.find(Directory.current);

    section('Project');
    if (project == null) {
      fail('No Flutter project found here or in any parent directory');
      return 1;
    }
    ok('Flutter project at ${project.root.path}');
    if (project.declaresPlugin) {
      ok('$pluginPackage declared in pubspec.yaml');
    } else {
      fail('$pluginPackage not in pubspec.yaml — run `liquid_glass install`');
    }

    final target = _reportIos(project);
    final hasGlassRuntime = await _reportToolchain();
    _reportVerdict(target: target, hasGlassRuntime: hasGlassRuntime);
    return 0;
  }

  /// Returns the lowest deployment target found, or null when there is no
  /// iOS project to inspect.
  IosVersion? _reportIos(FlutterProject project) {
    section('iOS project');
    if (!project.iosDirectory.existsSync()) {
      skip('No ios/ directory in this project');
      return null;
    }

    final targets = readDeploymentTargets(project.pbxproj);
    if (targets.isEmpty) {
      warn('No IPHONEOS_DEPLOYMENT_TARGET found in Runner.xcodeproj');
      return null;
    }

    final lowest = targets.reduce((a, b) => a < b ? a : b);
    if (lowest < minimumDeploymentTarget) {
      fail(
        'Deployment target $lowest is below the required '
        '$minimumDeploymentTarget — run `liquid_glass install`',
      );
    } else {
      ok('Deployment target $lowest');
    }

    final podfilePlatform = readPodfilePlatform(project.podfile);
    if (podfilePlatform != null) {
      podfilePlatform < minimumDeploymentTarget
          ? fail('Podfile platform :ios, $podfilePlatform is too low')
          : ok('Podfile platform :ios, $podfilePlatform');
    } else {
      skip('No Podfile (Swift Package Manager project)');
    }

    return lowest;
  }

  /// Returns whether a simulator new enough to show Liquid Glass is installed.
  Future<bool> _reportToolchain() async {
    section('Toolchain');
    if (!Platform.isMacOS) {
      skip(
        'Xcode and simulator checks skipped — iOS builds require macOS. '
        'Everything else above still applies.',
      );
      return false;
    }

    final xcode = await capture('xcodebuild', ['-version']);
    xcode == null
        ? warn('Xcode not found on PATH')
        : ok(xcode.split('\n').first);

    final runtimes = await capture('xcrun', ['simctl', 'list', 'runtimes']);
    final glassRuntimes = _iosRuntimesAtLeast(
      runtimes,
      liquidGlassDeploymentTarget,
    );
    glassRuntimes.isEmpty
        ? warn(
            'No iOS $liquidGlassDeploymentTarget+ simulator runtime installed',
          )
        : ok('Simulator runtime: ${glassRuntimes.join(', ')}');
    return glassRuntimes.isNotEmpty;
  }

  void _reportVerdict({
    required IosVersion? target,
    required bool hasGlassRuntime,
  }) {
    section('Verdict');
    if (target == null) {
      skip('No iOS project to judge');
    } else if (target < minimumDeploymentTarget) {
      fail(
        'Will not build: deployment target $target is below the required '
        '$minimumDeploymentTarget. Run `liquid_glass install`.',
      );
    } else {
      // The deployment target only sets the build floor. Which bar you get is
      // decided at runtime by the device's OS version, because every iOS 26
      // API in the plugin sits behind an `#available` guard.
      ok(
        'Builds against iOS $target. Liquid Glass renders on iOS '
        '$liquidGlassDeploymentTarget+ devices; older devices get the classic '
        'flat tab bar.',
      );
      if (Platform.isMacOS && !hasGlassRuntime) {
        warn(
          'No iOS $liquidGlassDeploymentTarget+ simulator installed, so you '
          'cannot see the Liquid Glass treatment locally.',
        );
      }
    }
    stdout.writeln();
  }

  List<String> _iosRuntimesAtLeast(String? output, IosVersion minimum) {
    if (output == null) return const [];
    return [
      for (final match in RegExp(
        r'^iOS ([\d.]+)',
        multiLine: true,
      ).allMatches(output))
        if (IosVersion.tryParse(match[1]!) case final version?)
          if (version >= minimum) 'iOS ${match[1]}',
    ];
  }
}
