import 'dart:io';

import 'package:args/command_runner.dart';
import 'package:liquid_glass_bottom_nav_cli/src/bootstrap_command.dart';
import 'package:liquid_glass_bottom_nav_cli/src/create_command.dart';
import 'package:liquid_glass_bottom_nav_cli/src/doctor_command.dart';
import 'package:liquid_glass_bottom_nav_cli/src/install_command.dart';

Future<void> main(List<String> arguments) async {
  final runner =
      CommandRunner<int>(
          'liquid_glass',
          'Install liquid_glass_bottom_nav_native into a Flutter project and check '
              'that the native iOS side is configured to render it.',
        )
        ..addCommand(BootstrapCommand())
        ..addCommand(CreateCommand())
        ..addCommand(InstallCommand())
        ..addCommand(DoctorCommand());

  try {
    exitCode = await runner.run(arguments) ?? 0;
  } on UsageException catch (error) {
    stderr.writeln(error);
    exitCode = 64;
  }
}
