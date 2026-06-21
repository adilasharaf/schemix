import 'package:schemix/schemix.dart';

/// Maps a [FieldInfo] to its Zod schema expression string.
///
/// The caller is responsible for appending `.nullish()` and `.catch()`
/// wrappers after this call — [resolve] returns only the base expression.
abstract final class ZodTypeResolver {
  ZodTypeResolver._();

  /// Resolves [field] to a Zod schema expression.
  ///
  /// [modelSchemaName] must return the variable name of the already-emitted
  /// `*Schema` constant for a given type name, or null if the type is not a
  /// known model (in which case [resolve] falls back to `z.unknown()`).
  ///
  /// [cyclicTypes] is the set of type names that participate in a reference
  /// cycle; those are wrapped in `z.lazy(() => ...)`.
  ///
  /// [requiredImports] is an output set — any `import` statement strings
  /// needed by the resolved expression are added here.
  static String resolve({
    required FieldInfo field,
    required String? Function(String typeName) modelSchemaName,
    required Set<String> cyclicTypes,
    required Set<String> requiredImports,
  }) {
    // ── Explicit overrides (highest priority) ────────────────────────────────

    if (field.converter.zodTypeOverride case final override?) return override;
    if (field.converter.zodSchemaOverride case final override?) return override;
    if (field.converter.tsConverter case final override?) return override;

    // ── List ─────────────────────────────────────────────────────────────────

    if (field.isList) {
      final itemExpr = _resolveScalar(
        dartType: field.listItemType ?? 'dynamic',
        isEnum: field.isEnum,
        field: field,
        modelSchemaName: modelSchemaName,
        cyclicTypes: cyclicTypes,
        requiredImports: requiredImports,
        applyValidation: false,
      );
      var expr = 'z.array($itemExpr)';
      if (field.validation.required) {
        expr = '$expr.nonempty()';
      } else if (field.relation.kind == RelationKind.hasMany || field.relation.kind == RelationKind.manyToMany) {
        expr = '$expr.default([])';
      }
      return expr;
    }

    // ── Map ──────────────────────────────────────────────────────────────────

    if (field.isMap) {
      final valueType = field.mapValueType ?? 'dynamic';
      final valueExpr = _resolveScalar(
        dartType: valueType,
        isEnum: false,
        field: field,
        modelSchemaName: modelSchemaName,
        cyclicTypes: cyclicTypes,
        requiredImports: requiredImports,
        applyValidation: false,
      );
      return 'z.record(z.string(), $valueExpr)';
    }

    // ── Scalar ───────────────────────────────────────────────────────────────

    return _resolveScalar(
      dartType: field.dartType,
      isEnum: field.isEnum,
      field: field,
      modelSchemaName: modelSchemaName,
      cyclicTypes: cyclicTypes,
      requiredImports: requiredImports,
      applyValidation: true,
    );
  }

  // ── Private scalar resolver ───────────────────────────────────────────────

  static String _resolveScalar({
    required String dartType,
    required bool isEnum,
    required FieldInfo field,
    required String? Function(String) modelSchemaName,
    required Set<String> cyclicTypes,
    required Set<String> requiredImports,
    required bool applyValidation,
  }) {
    // ── DateTime ─────────────────────────────────────────────────────────────

    if (dartType == 'DateTime' ||
        field.converter.hasDateTimeConverter ||
        field.converter.hasDateTimeNullableConverter) {
      return 'z.string().datetime({ offset: true })';
    }

    // ── Primitive scalars ─────────────────────────────────────────────────────

    final base = switch (dartType) {
      'String' => _buildStringSchema(field, applyValidation),
      'int' || 'double' || 'num' => _buildNumberSchema(field, applyValidation),
      'bool' => 'z.boolean()',
      'dynamic' || 'Object' || 'void' => 'z.unknown()',
      'Null' => 'z.null()',
      'Uint8List' => 'z.string().base64()',
      'Map' => 'z.record(z.string(), z.unknown())',
      'List' || 'Iterable' || 'Set' => 'z.array(z.unknown())',

      // Firebase types
      'Timestamp' => _firebaseTimestamp(requiredImports),
      'GeoPoint' => _firebaseGeoPoint(requiredImports),
      'DocumentReference' => _firebaseDocRef(requiredImports),

      // Known model or enum ────────────────────────────────────────────────
      _ => _resolveModelOrEnum(
        dartType,
        isEnum,
        field,
        modelSchemaName,
        cyclicTypes,
      ),
    };

    return base;
  }

  // ── String schema ─────────────────────────────────────────────────────────

  static String _buildStringSchema(FieldInfo field, bool applyValidation) {
    if (!applyValidation) return 'z.string()';

    final v = field.validation;
    final buf = StringBuffer('z.string()');

    if (v.isEmail) buf.write('.email()');
    if (v.isUrl) buf.write('.url()');
    if (v.isUuid) buf.write('.uuid()');
    if (v.isIpAddress) buf.write('.ip()');
    if (v.regex != null) buf.write('.regex(/${v.regex}/u)');
    if (v.minLength != null && v.maxLength != null) {
      buf.write('.min(${v.minLength}).max(${v.maxLength})');
    } else if (v.minLength != null) {
      buf.write('.min(${v.minLength})');
    } else if (v.maxLength != null) {
      buf.write('.max(${v.maxLength})');
    }
    if (v.required) buf.write('.min(1)');

    if (v.allowedValues.isNotEmpty) {
      final joined = v.allowedValues.map(_jsLiteral).join(', ');
      buf.write('.refine(v => [$joined].includes(v as never))');
    }
    if (v.disallowedValues.isNotEmpty) {
      final joined = v.disallowedValues.map(_jsLiteral).join(', ');
      buf.write('.refine(v => ![$joined].includes(v as never))');
    }

    return buf.toString();
  }

  // ── Number schema ─────────────────────────────────────────────────────────

  static String _buildNumberSchema(FieldInfo field, bool applyValidation) {
    final isInt = field.dartType == 'int';
    final base = isInt ? 'z.number().int()' : 'z.number()';
    if (!applyValidation) return base;

    final v = field.validation;
    final buf = StringBuffer(base);

    if (v.min != null) buf.write('.gte(${v.min})');
    if (v.max != null) buf.write('.lte(${v.max})');

    return buf.toString();
  }

  // ── Model / enum ──────────────────────────────────────────────────────────

  static String _resolveModelOrEnum(
    String dartType,
    bool isEnum,
    FieldInfo field,
    String? Function(String) modelSchemaName,
    Set<String> cyclicTypes,
  ) {
    final schemaName = modelSchemaName(dartType);
    if (schemaName == null) return 'z.unknown()';

    if (cyclicTypes.contains(dartType)) {
      return 'z.lazy(() => $schemaName)';
    }

    // Enum with fallback
    if (isEnum) {
      if (field.db.databaseDefault case final def?) {
        final catch_ = DefaultResolver.toZodCatch(def.toString());
        if (catch_ != null) return '$schemaName.catch($catch_)';
      }
    }

    return schemaName;
  }

  // ── Firebase helpers ──────────────────────────────────────────────────────

  static String _firebaseTimestamp(Set<String> imports) {
    imports.add(
      "import { firestoreTimestampSchema } from '@schemix/firebase';",
    );
    return 'firestoreTimestampSchema';
  }

  static String _firebaseGeoPoint(Set<String> imports) {
    imports.add("import { firestoreGeoPointSchema } from '@schemix/firebase';");
    return 'firestoreGeoPointSchema';
  }

  static String _firebaseDocRef(Set<String> imports) {
    imports.add("import { firestoreDocRefSchema } from '@schemix/firebase';");
    return 'firestoreDocRefSchema';
  }

  // ── Literal helper ────────────────────────────────────────────────────────

  static String _jsLiteral(dynamic value) {
    if (value is String) return "'$value'";
    if (value is bool) return value ? 'true' : 'false';
    return '$value';
  }
}

/// Resolves a [DatabaseDefault] value to a `.catch(value)` Zod argument,
/// or returns null if the default cannot be represented as a JS literal.
abstract final class DefaultResolver {
  DefaultResolver._();

  static String? toZodCatch(String dartDefault) {
    // Bool literals
    if (dartDefault == 'true') return 'true';
    if (dartDefault == 'false') return 'false';

    // Numeric literals
    if (double.tryParse(dartDefault) != null) return dartDefault;
    if (int.tryParse(dartDefault) != null) return dartDefault;

    // String literals (dart prints them with surrounding quotes already removed)
    if (!dartDefault.contains('.')) return "'$dartDefault'";

    // Enum constants — e.g. "UserStatus.active" → "'active'"
    final dot = dartDefault.lastIndexOf('.');
    if (dot != -1) {
      final variant = dartDefault.substring(dot + 1);
      if (variant.isNotEmpty) return "'$variant'";
    }

    return null;
  }
}
