import 'package:schemix/models.dart';
import 'package:schemix_builder/src/logger.dart';

import 'column_builder.dart';

/// Builds the body of a Drift `Table` subclass — i.e. all column getter
/// declarations, including timestamp and soft-delete injections.
final class DriftTableBodyBuilder {
  final DriftColumnBuilder _columnBuilder;

  const DriftTableBodyBuilder(this._columnBuilder);

  /// Returns an ordered list of indented column declaration strings.
  ///
  /// Injected columns (`createdAt`, `updatedAt`, `deletedAt`) are appended
  /// after the explicitly declared fields so that the generated output is
  /// deterministic and the developer-declared fields always appear first.
  List<String> buildTableBody(ClassInfo cls, SchemixLogger log) {
    final hasCreatedAt = cls.allFields.any((f) => f.isCreatedAt);
    final hasUpdatedAt = cls.allFields.any((f) => f.isUpdatedAt);
    final hasDeletedAt = cls.allFields.any((f) => f.isDeletedAt);

    final columns = <String>[];

    for (final field in cls.allFields) {
      if (_columnBuilder.skipField(field)) {
        log.verbose(
          '   field skip    | ${cls.name}.${field.name}'
          '  (${_columnBuilder.fieldSkipReason(field)})',
        );
        continue;
      }

      final col = _columnBuilder.buildColumn(field);
      if (col != null) {
        columns.add('  $col');
      } else {
        log.verbose(
          '   field null    | ${cls.name}.${field.name}'
          '  (no drift type mapping)',
        );
      }
    }

    // ── Auto-injected lifecycle columns ──────────────────────────────────

    if (cls.enableTimestamps) {
      if (!hasCreatedAt) {
        log.verbose('   ts inject     | ${cls.name}.createdAt');
        columns.add(
          "  DateTimeColumn get createdAt =>"
          " dateTime().named('created_at').withDefault(currentDateAndTime)();",
        );
      }
      if (!hasUpdatedAt) {
        log.verbose('   ts inject     | ${cls.name}.updatedAt');
        columns.add(
          "  DateTimeColumn get updatedAt =>"
          " dateTime().named('updated_at').withDefault(currentDateAndTime)();",
        );
      }
    }

    if (cls.enableSoftDelete && !hasDeletedAt) {
      log.verbose('   sd inject     | ${cls.name}.deletedAt');
      columns.add(
        "  DateTimeColumn get deletedAt =>"
        " dateTime().named('deleted_at').nullable()();",
      );
    }

    return columns;
  }
}
