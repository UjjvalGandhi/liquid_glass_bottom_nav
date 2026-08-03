import 'package:liquid_glass_bottom_nav_cli/src/project.dart';
import 'package:liquid_glass_bottom_nav_cli/src/templates.dart';
import 'package:test/test.dart';

void main() {
  group('validatePackageName', () {
    test('accepts lower_snake_case names', () {
      expect(validatePackageName('my_app'), isNull);
      expect(validatePackageName('app2'), isNull);
      expect(validatePackageName('a'), isNull);
    });

    test('rejects names Dart cannot use as an identifier', () {
      expect(validatePackageName(''), contains('must not be empty'));
      expect(validatePackageName('My_App'), contains('lower_snake_case'));
      expect(validatePackageName('my-app'), contains('lower_snake_case'));
      expect(validatePackageName('2cool'), contains('lower_snake_case'));
      expect(validatePackageName('my app'), contains('lower_snake_case'));
    });

    test('rejects reserved words', () {
      expect(validatePackageName('class'), contains('reserved word'));
      expect(validatePackageName('for'), contains('reserved word'));
    });
  });

  group('mainDartTemplate', () {
    test('substitutes the app name and leaves no placeholder behind', () {
      final source = mainDartTemplate('my_app');

      expect(source, contains("title: 'my_app'"));
      expect(source, isNot(contains('__APP_NAME__')));
    });

    test('keeps Dart interpolation intact', () {
      // The template is a raw string, so `$_searchQuery` must survive into the
      // generated file rather than being interpolated by the CLI.
      expect(mainDartTemplate('my_app'), contains(r"'Searching: $_searchQuery'"));
    });

    test('wires up the pieces that are easy to forget', () {
      final source = mainDartTemplate('my_app');

      expect(source, contains('extendBody: true'));
      expect(source, contains('Alignment.bottomCenter'));
      expect(source, contains('fallback:'));
    });
  });
}
