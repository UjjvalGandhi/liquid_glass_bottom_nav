import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:path/path.dart' as p;

import 'console.dart';
import 'process_runner.dart';
import 'project.dart';

/// Clones the whole project onto this machine and resolves every package in
/// it, so a fresh device goes from nothing to a runnable checkout.
class BootstrapCommand extends Command<int> {
  BootstrapCommand() {
    argParser
      ..addOption(
        'repo',
        valueHelp: 'url',
        help: 'Git URL to clone. Defaults to the project repository.',
      )
      ..addOption(
        'ref',
        valueHelp: 'branch|tag',
        help: 'Branch or tag to check out instead of the default branch.',
      )
      ..addFlag(
        'pub-get',
        defaultsTo: true,
        help: 'Resolve dependencies for every package after cloning.',
      );
  }

  @override
  String get name => 'bootstrap';

  @override
  String get description =>
      'Clone the whole project onto this machine and resolve every package.';

  @override
  String get invocation => 'liquid_glass bootstrap [directory]';

  @override
  Future<int> run() async {
    final rest = argResults!.rest;
    if (rest.length > 1) {
      usageException('Expected at most one target directory.');
    }

    final repository = argResults!.option('repo') ?? projectRepository;
    if (!hasConfiguredRepository && argResults!.option('repo') == null) {
      stderr.writeln(
        'No repository is configured in this build of the CLI.\n'
        'Pass --repo <url> to clone from somewhere explicit.',
      );
      return 1;
    }

    final targetName =
        rest.isEmpty ? repositoryDirectoryName(repository) : rest.single;
    final target = Directory(p.join(Directory.current.path, targetName));
    if (target.existsSync()) {
      stderr.writeln('Cannot clone: ${target.path} already exists.');
      return 1;
    }

    section('Clone');
    if (await capture('git', ['--version']) == null) {
      stderr.writeln(
        'git is not installed, or not on your PATH. Install it from '
        'https://git-scm.com/downloads and run this again.',
      );
      return 1;
    }

    final ref = argResults!.option('ref');
    final cloneCode = await runProcess('git', [
      'clone',
      if (ref != null) ...['--branch', ref],
      repository,
      targetName,
    ]);
    if (cloneCode != 0) return cloneCode;
    ok('Cloned $repository');

    if (argResults!.flag('pub-get')) {
      final code = await _resolvePackages(target);
      if (code != 0) return code;
    }

    _printNextSteps(targetName);
    return 0;
  }

  /// Resolves every package in the checkout, not just the app at the root —
  /// a monorepo checkout is not usable until the plugin and the CLI resolve
  /// too.
  Future<int> _resolvePackages(Directory root) async {
    section('Dependencies');
    final packages = findPackages(root);
    if (packages.isEmpty) {
      warn('No pubspec.yaml found in the checkout');
      return 0;
    }

    for (final package in packages) {
      final label = p.relative(package.path, from: root.path);
      final flutter = isFlutterPackage(package);
      final code = await runProcess(
        flutter ? 'flutter' : 'dart',
        ['pub', 'get'],
        workingDirectory: package.path,
      );
      if (code != 0) {
        fail('${label == '.' ? '(root)' : label} failed to resolve');
        return code;
      }
      ok('${label == '.' ? '(root)' : label}  [${flutter ? 'flutter' : 'dart'}]');
    }
    return 0;
  }

  void _printNextSteps(String directory) {
    stdout.writeln('''

Done.

  cd $directory
  flutter run

The checkout contains the harness app, the plugin, and this CLI. To use the
CLI from the checkout instead of the published one:

  dart pub global activate --source path $directory/packages/liquid_glass_bottom_nav_cli
''');
  }

}
