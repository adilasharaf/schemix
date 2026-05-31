import 'package:analyzer/dart/element/element.dart';
import 'package:schemix/models.dart';
import 'package:source_gen/source_gen.dart';

/// Validates annotation combinations on a fully-analyzed [ClassInfo].
/// Throws [InvalidGenerationSourceError] on the first conflict found so
/// build_runner surfaces a precise error pointing to the source location.
abstract final class AnnotationValidator {
  static void validate(ClassInfo classInfo, ClassElement element) {
    for (final field in classInfo.allFields) {
      if (field.isIgnored) continue;

      final fieldEl = _fieldElement(element, field.name);

      _check(
        field.sync.offlineOnly && field.sync.cloudOnly,
        fieldEl,
        '@OfflineOnly and @CloudOnly cannot both be set on "${field.name}".',
      );

      _check(
        field.db.isPrimaryKey && field.isNullable,
        fieldEl,
        '@PrimaryKey field "${field.name}" must not be nullable.',
      );

      _check(
        field.isCreatedAt && field.isUpdatedAt,
        fieldEl,
        '@CreatedAt and @UpdatedAt cannot both be set on "${field.name}".',
      );

      _check(
        field.security.encrypted && field.platform.zodIgnore,
        fieldEl,
        '@Encrypted field "${field.name}" is excluded from Zod output via '
        '@ZodIgnore but will still appear in Drift/Drizzle. '
        'Use @IgnoreField to exclude from all targets.',
      );

      _check(
        field.serialization.isIgnored &&
            (field.db.isPrimaryKey ||
                field.validation.hasConstraints ||
                field.relation.hasRelation),
        fieldEl,
        '@IgnoreField on "${field.name}" conflicts with other active '
        'annotations (@PrimaryKey, validation, or relation). '
        'Remove the conflicting annotations or remove @IgnoreField.',
      );
    }
  }

  static void _check(bool condition, FieldElement? element, String message) {
    if (!condition) return;
    throw InvalidGenerationSourceError(message, element: element);
  }

  static FieldElement? _fieldElement(ClassElement classEl, String fieldName) {
    try {
      return classEl.fields.firstWhere((f) => f.name == fieldName);
    } catch (_) {
      return null;
    }
  }
}
