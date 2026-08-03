import 'dart:io';

/// Runs [executable] with its output streamed straight to this terminal.
///
/// `runInShell` is required on Windows, where `flutter` and `dart` are `.bat`
/// shims that `Process.start` cannot launch directly.
Future<int> runProcess(
  String executable,
  List<String> arguments, {
  String? workingDirectory,
}) async {
  try {
    final process = await Process.start(
      executable,
      arguments,
      workingDirectory: workingDirectory,
      runInShell: Platform.isWindows,
      mode: ProcessStartMode.inheritStdio,
    );
    return process.exitCode;
  } on ProcessException {
    stderr.writeln(
      'Could not run `$executable`. Make sure it is installed and on your '
      'PATH.',
    );
    return 127;
  }
}

/// Runs the Flutter tool.
Future<int> runFlutter(
  List<String> arguments, {
  required String workingDirectory,
}) => runProcess('flutter', arguments, workingDirectory: workingDirectory);

/// Runs `flutter create`, generating the project as a subdirectory of the
/// current working directory.
Future<int> runFlutterCreate(String name, {String? org}) => runFlutter([
  'create',
  if (org != null) ...['--org', org],
  name,
], workingDirectory: Directory.current.path);

/// Runs [executable] and returns its trimmed stdout, or null if it is
/// unavailable or exits non-zero.
///
/// Used for probing the toolchain, where a missing tool is a normal answer
/// rather than an error.
Future<String?> capture(String executable, List<String> arguments) async {
  try {
    final result = await Process.run(
      executable,
      arguments,
      runInShell: Platform.isWindows,
    );
    if (result.exitCode != 0) return null;
    final output = (result.stdout as String).trim();
    return output.isEmpty ? null : output;
  } on ProcessException {
    return null;
  }
}
