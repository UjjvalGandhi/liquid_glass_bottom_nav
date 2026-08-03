import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'console.dart';
import 'installer.dart';
import 'ios_version.dart';
import 'process_runner.dart';
import 'project.dart';
import 'templates.dart';

/// Creates a new Flutter app with the glass nav already wired up.
class CreateCommand extends Command<int> {
  CreateCommand() {
    argParser
      ..addFlag(
        'ios-config',
        defaultsTo: true,
        help:
            'Raise the iOS deployment target if it is below '
            '$minimumDeploymentTarget. The original files are kept as .bak.',
      )
      ..addOption(
        'org',
        valueHelp: 'com.example',
        help: 'Reverse-domain organisation for the generated project.',
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
  String get name => 'create';

  @override
  String get description =>
      'Create a new Flutter app with $pluginPackage already wired up.';

  @override
  String get invocation => 'liquid_glass create <project_name>';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length != 1) {
      usageException('Expected exactly one project name.');
    }

    final name = rest.single;
    final problem = validatePackageName(name);
    if (problem != null) {
      stderr.writeln(problem);
      return 1;
    }

    final target = Directory(p.join(Directory.current.path, name));
    if (target.existsSync()) {
      stderr.writeln('Cannot create "$name": ${target.path} already exists.');
      return 1;
    }

    section('Project');
    final org = argResults!.option('org');
    final code = await runFlutterCreate(name, org: org);
    if (code != 0) return code;
    ok('Created Flutter project $name');

    final project = FlutterProject.find(target);
    if (project == null) {
      stderr.writeln('flutter create did not produce a project at $target.');
      return 1;
    }

    final addCode = await addPlugin(
      project,
      pluginPath: argResults!.option('plugin-path'),
    );
    if (addCode != 0) return addCode;

    configureIos(project, enabled: argResults!.flag('ios-config'));

    section('Source');
    File(p.join(project.root.path, 'lib', 'main.dart'))
        .writeAsStringSync(mainDartTemplate(name));
    ok('Wrote lib/main.dart with a 4-tab glass nav');

    stdout.writeln('''

Done.

  cd $name
  flutter run

On iOS 26 you get the Liquid Glass bar; everywhere else the app falls back to
a Material NavigationBar, so it still runs on Android, web and desktop.
Run `liquid_glass doctor` inside the project to see which one you will get.
''');
    return 0;
  }
}
