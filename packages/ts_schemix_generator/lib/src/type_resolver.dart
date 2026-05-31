import 'package:schemix/schemix.dart';

/// Maps a [FieldInfo] to its TypeScript type string.
///
/// Nullability (`| null` / `?`) is applied by the caller
/// ([TsInterfaceGenerator]) so that it can be combined correctly with the
/// optional-property marker (`?:`).
abstract final class TsTypeResolver {
  TsTypeResolver._();

  /// Resolves [field] to a TypeScript type expression (without nullability).
  ///
  /// [modelTsType] must return the TypeScript type name for a given Dart type
  /// name if it is a known model/enum, or null if unknown (falls back to
  /// `unknown`).
  static String resolve({
    required FieldInfo field,
    required String? Function(String typeName) modelTsType,
  }) {
    // ── Explicit override ───────────────────────────────────────────────────

    if (field.converter.tsTypeOverride case final override?) return override;

    // ── List ─────────────────────────────────────────────────────────────────

    if (field.isList) {
      final inner = _resolveScalar(
        dartType: field.listItemType ?? 'unknown',
        field: field,
        modelTsType: modelTsType,
      );
      return 'Array<$inner>';
    }

    // ── Map ──────────────────────────────────────────────────────────────────

    if (field.isMap) {
      final valueType = _resolveScalar(
        dartType: field.mapValueType ?? 'unknown',
        field: field,
        modelTsType: modelTsType,
      );
      return 'Record<string, $valueType>';
    }

    // ── Scalar ───────────────────────────────────────────────────────────────

    return _resolveScalar(
      dartType: field.dartType,
      field: field,
      modelTsType: modelTsType,
    );
  }

  // ── Private ───────────────────────────────────────────────────────────────

  static String _resolveScalar({
    required String dartType,
    required FieldInfo field,
    required String? Function(String) modelTsType,
  }) {
    // DateTime is always `string` in TS (ISO-8601 from the API layer).
    if (dartType == 'DateTime' ||
        field.converter.hasDateTimeConverter ||
        field.converter.hasDateTimeNullableConverter) {
      return 'string';
    }

    return switch (dartType) {
      'String' => 'string',
      'int' || 'double' || 'num' => 'number',
      'bool' => 'boolean',
      'dynamic' || 'Object' => 'unknown',
      'void' || 'Null' => 'undefined',
      'Uint8List' => 'string', // base64 encoded
      'Map' => 'Record<string, unknown>',
      'List' || 'Iterable' || 'Set' => 'Array<unknown>',

      // Firebase types
      'Timestamp' => '{ seconds: number; nanoseconds: number }',
      'GeoPoint' => '{ latitude: number; longitude: number }',
      'DocumentReference' => 'string', // serialized as path string
      'FieldValue' => 'unknown',
      'Blob' => 'string', // base64
      // User-defined model or enum
      _ => modelTsType(dartType) ?? 'unknown',
    };
  }
}
