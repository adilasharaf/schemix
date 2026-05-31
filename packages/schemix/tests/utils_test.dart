import 'package:schemix/src/utils.dart';
import 'package:test/test.dart';

void main() {
  group('StringExtension.snakeCase', () {
    test('converts camelCase to snake_case', () {
      expect('passwordHash'.snakeCase, 'password_hash');
    });

    test('converts PascalCase to snake_case', () {
      expect('UserProfile'.snakeCase, 'User_profile');
    });

    test('handles consecutive capitals', () {
      expect('createdAt'.snakeCase, 'created_at');
    });

    test('leaves already snake_case unchanged', () {
      expect('user_id'.snakeCase, 'user_id');
    });

    test('leaves single word unchanged', () {
      expect('email'.snakeCase, 'email');
    });

    test('handles multiple transitions', () {
      expect('myFieldName'.snakeCase, 'my_field_name');
    });

    test('handles empty string', () {
      expect(''.snakeCase, '');
    });
  });

  group('StringExtension.camelCase', () {
    test('lowercases first letter of PascalCase', () {
      expect('UserProfile'.camelCase, 'userProfile');
    });

    test('leaves already camelCase unchanged', () {
      expect('userId'.camelCase, 'userId');
    });

    test('handles single uppercase letter', () {
      expect('A'.camelCase, 'a');
    });

    test('handles all-lowercase', () {
      expect('email'.camelCase, 'email');
    });
  });
}
