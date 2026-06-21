// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:example/models/tag/tag.dart' as i1;
import 'package:example/models/tag/tag.table.drift.dart' as i2;
import 'package:example/models/tag/tag.table.dart' as i3;
import 'package:uuid/uuid.dart' as i4;

typedef $$TagTableTableCreateCompanionBuilder =
    i2.TagTableCompanion Function({
      i0.Value<String> id,
      required String name,
      required String slug,
      i0.Value<int> rowid,
    });
typedef $$TagTableTableUpdateCompanionBuilder =
    i2.TagTableCompanion Function({
      i0.Value<String> id,
      i0.Value<String> name,
      i0.Value<String> slug,
      i0.Value<int> rowid,
    });

class $$TagTableTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$TagTableTable> {
  $$TagTableTableFilterComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnFilters<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => i0.ColumnFilters(column),
  );
}

class $$TagTableTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$TagTableTable> {
  $$TagTableTableOrderingComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.ColumnOrderings<String> get id => $composableBuilder(
    column: $table.id,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get name => $composableBuilder(
    column: $table.name,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => i0.ColumnOrderings(column),
  );
}

class $$TagTableTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$TagTableTable> {
  $$TagTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get name =>
      $composableBuilder(column: $table.name, builder: (column) => column);

  i0.GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);
}

class $$TagTableTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.$TagTableTable,
          i1.Tag,
          i2.$$TagTableTableFilterComposer,
          i2.$$TagTableTableOrderingComposer,
          i2.$$TagTableTableAnnotationComposer,
          $$TagTableTableCreateCompanionBuilder,
          $$TagTableTableUpdateCompanionBuilder,
          (
            i1.Tag,
            i0.BaseReferences<i0.GeneratedDatabase, i2.$TagTableTable, i1.Tag>,
          ),
          i1.Tag,
          i0.PrefetchHooks Function()
        > {
  $$TagTableTableTableManager(i0.GeneratedDatabase db, i2.$TagTableTable table)
    : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$$TagTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$$TagTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$$TagTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> name = const i0.Value.absent(),
                i0.Value<String> slug = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TagTableCompanion(
                id: id,
                name: name,
                slug: slug,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                required String name,
                required String slug,
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.TagTableCompanion.insert(
                id: id,
                name: name,
                slug: slug,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$TagTableTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.$TagTableTable,
      i1.Tag,
      i2.$$TagTableTableFilterComposer,
      i2.$$TagTableTableOrderingComposer,
      i2.$$TagTableTableAnnotationComposer,
      $$TagTableTableCreateCompanionBuilder,
      $$TagTableTableUpdateCompanionBuilder,
      (
        i1.Tag,
        i0.BaseReferences<i0.GeneratedDatabase, i2.$TagTableTable, i1.Tag>,
      ),
      i1.Tag,
      i0.PrefetchHooks Function()
    >;

class $TagTableTable extends i3.TagTable
    with i0.TableInfo<$TagTableTable, i1.Tag> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $TagTableTable(this.attachedDatabase, [this._alias]);
  static const i0.VerificationMeta _idMeta = const i0.VerificationMeta('id');
  @override
  late final i0.GeneratedColumn<String> id = i0.GeneratedColumn<String>(
    'id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    clientDefault: () => const i4.Uuid().v4(),
  );
  static const i0.VerificationMeta _nameMeta = const i0.VerificationMeta(
    'name',
  );
  @override
  late final i0.GeneratedColumn<String> name = i0.GeneratedColumn<String>(
    'name',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  static const i0.VerificationMeta _slugMeta = const i0.VerificationMeta(
    'slug',
  );
  @override
  late final i0.GeneratedColumn<String> slug = i0.GeneratedColumn<String>(
    'slug',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
  );
  @override
  List<i0.GeneratedColumn> get $columns => [id, name, slug];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'tags';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Tag> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('name')) {
      context.handle(
        _nameMeta,
        name.isAcceptableOrUnknown(data['name']!, _nameMeta),
      );
    } else if (isInserting) {
      context.missing(_nameMeta);
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    } else if (isInserting) {
      context.missing(_slugMeta);
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  i1.Tag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Tag(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      name: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}name'],
      )!,
      slug: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}slug'],
      )!,
    );
  }

  @override
  $TagTableTable createAlias(String alias) {
    return $TagTableTable(attachedDatabase, alias);
  }
}

class TagTableCompanion extends i0.UpdateCompanion<i1.Tag> {
  final i0.Value<String> id;
  final i0.Value<String> name;
  final i0.Value<String> slug;
  final i0.Value<int> rowid;
  const TagTableCompanion({
    this.id = const i0.Value.absent(),
    this.name = const i0.Value.absent(),
    this.slug = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  TagTableCompanion.insert({
    this.id = const i0.Value.absent(),
    required String name,
    required String slug,
    this.rowid = const i0.Value.absent(),
  }) : name = i0.Value(name),
       slug = i0.Value(slug);
  static i0.Insertable<i1.Tag> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? name,
    i0.Expression<String>? slug,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (name != null) 'name': name,
      if (slug != null) 'slug': slug,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.TagTableCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? name,
    i0.Value<String>? slug,
    i0.Value<int>? rowid,
  }) {
    return i2.TagTableCompanion(
      id: id ?? this.id,
      name: name ?? this.name,
      slug: slug ?? this.slug,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (name.present) {
      map['name'] = i0.Variable<String>(name.value);
    }
    if (slug.present) {
      map['slug'] = i0.Variable<String>(slug.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('TagTableCompanion(')
          ..write('id: $id, ')
          ..write('name: $name, ')
          ..write('slug: $slug, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$TagInsertable implements i0.Insertable<i1.Tag> {
  i1.Tag _object;
  _$TagInsertable(this._object);
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    return i2.TagTableCompanion(
      id: i0.Value(_object.id),
      name: i0.Value(_object.name),
      slug: i0.Value(_object.slug),
    ).toColumns(false);
  }
}

extension TagToInsertable on i1.Tag {
  _$TagInsertable toInsertable() {
    return _$TagInsertable(this);
  }
}
