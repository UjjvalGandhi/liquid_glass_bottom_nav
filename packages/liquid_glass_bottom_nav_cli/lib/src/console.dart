import 'dart:io';

// Plain ASCII markers rather than symbols or ANSI colour: this has to stay
// readable in the Windows console, which is a first-class target here.
void ok(String message) => stdout.writeln('  [ok]   $message');

void warn(String message) => stdout.writeln('  [warn] $message');

void fail(String message) => stdout.writeln('  [fail] $message');

void skip(String message) => stdout.writeln('  [--]   $message');

void section(String title) => stdout.writeln('\n$title');
