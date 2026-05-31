/// Names that map directly to a primitive or well-known type in every
/// generator target. Types that appear here are never looked up in the
/// [CrossFileRegistry] as user-defined models.
final class SchemixConstants {
  SchemixConstants._();

  static const Set<String> dartPrimitives = {
    'String',
    'int',
    'double',
    'num',
    'bool',
    'dynamic',
    'Object',
    'DateTime',
    'Duration',
    'void',
    'Null',
    'Never',
    'List',
    'Map',
    'Set',
    'Iterable',
    'Uint8List',
    'Timestamp',
    'GeoPoint',
    'DocumentReference',
    'FieldValue',
    'Blob',
  };

  /// File suffixes that the file builder must skip to avoid re-processing
  /// generated outputs.
  static const Set<String> generatedSuffixes = {
    '.g.dart',
    '.schemix.dart',
    '.table.dart',
    '.freezed.dart',
    '.drift.dart',
  };
}
