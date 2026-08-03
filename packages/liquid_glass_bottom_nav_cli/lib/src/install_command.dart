import 'dart:io';

import 'package:args/command_runner.dart';

import 'console.dart';
import 'installer.dart';
import 'ios_version.dart';
import 'project.dart';

/// Adds the plugin to the Flutter project surrounding the current directory.
class InstallCommand extends Command<int> {
  InstallCommand() {
    argParser
      ..addFlag(
        'ios-config',
        defaultsTo: true,
        help:
            'Raise the iOS deployment target if it is below '
            '$minimumDeploymentTarget. The original files are kept as .bak.',
      )
      ..addOption(
        'plugin-path',
        valueHelp: 'path',
        help:
            'Depend on a local copy of $pluginPackage instead of the published '
            'one. For testing an unreleased plugin change.',
      );
  }

  @override
  String get name => 'install';

  @override
  String get description =>
      'Add $pluginPackage to the Flutter project in the current directory.';

  @override
  Future<int> run() async {
    final project = FlutterProject.find(Directory.current);
    if (project == null) {
      stderr.writeln(
        'No Flutter project found in ${Directory.current.path} or any parent '
        'directory.\nRun this from inside a Flutter app.',
      );
      return 1;
    }

    section('Project');
    ok('Flutter project at ${project.root.path}');

    final code = await addPlugin(
      project,
      pluginPath: argResults!.option('plugin-path'),
    );
    if (code != 0) return code;

    configureIos(project, enabled: argResults!.flag('ios-config'));

    stdout.writeln(
      '\nDone. Run `liquid_glass doctor` to check what will render, or see\n'
      'https://pub.dev/packages/$pluginPackage for the widget snippet.\n',
    );
    return 0;
  }
}
