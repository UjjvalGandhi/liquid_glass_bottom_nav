import 'console.dart';
import 'ios_config.dart';
import 'ios_version.dart';
import 'process_runner.dart';
import 'project.dart';

/// Adds the plugin to [project] and reports what happened.
///
/// [pluginPath] depends on a local copy of the plugin instead of the published
/// one, which is how you smoke-test an unreleased change.
///
/// Returns a process exit code, so a failed `pub` run propagates out to the
/// shell rather than being swallowed.
Future<int> addPlugin(FlutterProject project, {String? pluginPath}) async {
  section('Dependency');
  if (project.declaresPlugin) {
    ok('$pluginPackage is already in pubspec.yaml');
    return runFlutter(['pub', 'get'], workingDirectory: project.root.path);
  }

  // `flutter pub add` picks a sane constraint and rewrites the pubspec without
  // disturbing comments or ordering, which hand-editing YAML cannot do. It
  // runs an implicit `pub get` afterwards.
  final code = await runFlutter([
    'pub',
    'add',
    pluginPackage,
    if (pluginPath != null) ...['--path', pluginPath],
  ], workingDirectory: project.root.path);

  if (code == 0) {
    ok(
      pluginPath == null
          ? 'Added $pluginPackage to pubspec.yaml'
          : 'Added $pluginPackage from $pluginPath',
    );
  }
  return code;
}

/// Brings [project]'s iOS build settings up to the version the plugin needs.
///
/// Does nothing when [enabled] is false or there is no iOS project, so this is
/// safe to call unconditionally on Windows and Linux.
void configureIos(FlutterProject project, {required bool enabled}) {
  section('iOS');
  if (!project.iosDirectory.existsSync()) {
    skip('No ios/ directory — nothing to configure');
    return;
  }
  if (!enabled) {
    skip('Skipped by --no-ios-config');
    return;
  }

  final raised = raiseDeploymentTargets(
    project.pbxproj,
    minimumDeploymentTarget,
  );
  if (raised > 0) {
    ok(
      'Raised $raised deployment target(s) to $minimumDeploymentTarget '
      '(original saved as project.pbxproj.bak)',
    );
  } else if (project.pbxproj.existsSync()) {
    ok('Deployment target already at least $minimumDeploymentTarget');
  } else {
    warn('No Runner.xcodeproj found — set the deployment target yourself');
  }

  if (raisePodfilePlatform(project.podfile, minimumDeploymentTarget)) {
    ok(
      'Raised Podfile platform to $minimumDeploymentTarget '
      '(original saved as Podfile.bak)',
    );
  }
}
