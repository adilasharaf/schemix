// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:example_outfolder/models/post_tag/post_tag.dart' as i1;
import 'package:example_outfolder/models/post_tag/post_tag.table.drift.dart'
    as i2;
import 'package:example_outfolder/models/post_tag/post_tag.table.dart' as i3;
import 'package:uuid/uuid.dart' as i4;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i5;
import 'package:example_outfolder/models/post/post.table.drift.dart' as i6;
import 'package:drift/internal/modular.dart' as i7;
import 'package:example_outfolder/models/tag/tag.table.drift.dart' as i8;

typedef $$PostTagTableTableCreateCompanionBuilder =
    i2.PostTagTableCompanion Function({
      i0.Value<String> id,
      required String postId,
      required String tagId,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });
typedef $$PostTagTableTableUpdateCompanionBuilder =
    i2.PostTagTableCompanion Function({
      i0.Value<String> id,
      i0.Value<String> postId,
      i0.Value<String> tagId,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });

final class $$PostTagTableTableReferences
    extends
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.$PostTagTableTable,
          i1.PostTag
        > {
  $$PostTagTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i6.$PostTableTable _postIdTable(i0.GeneratedDatabase db) =>
      i7.ReadDatabaseContainer(db)
          .resultSet<i6.$PostTableTable>('posts')
          .createAlias(
            i0.$_aliasNameGenerator(
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i2.$PostTagTableTable>('post_tags').postId,
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i6.$PostTableTable>('posts').id,
            ),
          );

  i6.$$PostTableTableProcessedTableManager get postId {
    final $_column = $_itemColumn<String>('post_id')!;

    final manager = i6
        .$$PostTableTableTableManager(
          $_db,
          i7.ReadDatabaseContainer($_db).resultSet<i6.$PostTableTable>('posts'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_postIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i8.$TagTableTable _tagIdTable(i0.GeneratedDatabase db) =>
      i7.ReadDatabaseContainer(db)
          .resultSet<i8.$TagTableTable>('tags')
          .createAlias(
            i0.$_aliasNameGenerator(
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i2.$PostTagTableTable>('post_tags').tagId,
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i8.$TagTableTable>('tags').id,
            ),
          );

  i8.$$TagTableTableProcessedTableManager get tagId {
    final $_column = $_itemColumn<String>('tag_id')!;

    final manager = i8
        .$$TagTableTableTableManager(
          $_db,
          i7.ReadDatabaseContainer($_db).resultSet<i8.$TagTableTable>('tags'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_tagIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }
}

class $$PostTagTableTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$PostTagTableTable> {
  $$PostTagTableTableFilterComposer({
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

  i0.ColumnFilters<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnFilters(column),
  );

  i6.$$PostTableTableFilterComposer get postId {
    final i6.$$PostTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.postId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i6.$PostTableTable>('posts'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$PostTableTableFilterComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i6.$PostTableTable>('posts'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i8.$$TagTableTableFilterComposer get tagId {
    final i8.$$TagTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i8.$TagTableTable>('tags'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i8.$$TagTableTableFilterComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i8.$TagTableTable>('tags'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostTagTableTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$PostTagTableTable> {
  $$PostTagTableTableOrderingComposer({
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

  i0.ColumnOrderings<DateTime> get createdAt => $composableBuilder(
    column: $table.createdAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get updatedAt => $composableBuilder(
    column: $table.updatedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<DateTime> get deletedAt => $composableBuilder(
    column: $table.deletedAt,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i6.$$PostTableTableOrderingComposer get postId {
    final i6.$$PostTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.postId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i6.$PostTableTable>('posts'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$PostTableTableOrderingComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i6.$PostTableTable>('posts'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i8.$$TagTableTableOrderingComposer get tagId {
    final i8.$$TagTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i8.$TagTableTable>('tags'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i8.$$TagTableTableOrderingComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i8.$TagTableTable>('tags'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostTagTableTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$PostTagTableTable> {
  $$PostTagTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i6.$$PostTableTableAnnotationComposer get postId {
    final i6.$$PostTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.postId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i6.$PostTableTable>('posts'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$PostTableTableAnnotationComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i6.$PostTableTable>('posts'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i8.$$TagTableTableAnnotationComposer get tagId {
    final i8.$$TagTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.tagId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i8.$TagTableTable>('tags'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i8.$$TagTableTableAnnotationComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i8.$TagTableTable>('tags'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostTagTableTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.$PostTagTableTable,
          i1.PostTag,
          i2.$$PostTagTableTableFilterComposer,
          i2.$$PostTagTableTableOrderingComposer,
          i2.$$PostTagTableTableAnnotationComposer,
          $$PostTagTableTableCreateCompanionBuilder,
          $$PostTagTableTableUpdateCompanionBuilder,
          (i1.PostTag, i2.$$PostTagTableTableReferences),
          i1.PostTag,
          i0.PrefetchHooks Function({bool postId, bool tagId})
        > {
  $$PostTagTableTableTableManager(
    i0.GeneratedDatabase db,
    i2.$PostTagTableTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$$PostTagTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$$PostTagTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$$PostTagTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> postId = const i0.Value.absent(),
                i0.Value<String> tagId = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.PostTagTableCompanion(
                id: id,
                postId: postId,
                tagId: tagId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                required String postId,
                required String tagId,
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.PostTagTableCompanion.insert(
                id: id,
                postId: postId,
                tagId: tagId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  i2.$$PostTagTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({postId = false, tagId = false}) {
            return i0.PrefetchHooks(
              db: db,
              explicitlyWatchedTables: [],
              addJoins:
                  <
                    T extends i0.TableManagerState<
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic,
                      dynamic
                    >
                  >(state) {
                    if (postId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.postId,
                                referencedTable: i2
                                    .$$PostTagTableTableReferences
                                    ._postIdTable(db),
                                referencedColumn: i2
                                    .$$PostTagTableTableReferences
                                    ._postIdTable(db)
                                    .id,
                              )
                              as T;
                    }
                    if (tagId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.tagId,
                                referencedTable: i2
                                    .$$PostTagTableTableReferences
                                    ._tagIdTable(db),
                                referencedColumn: i2
                                    .$$PostTagTableTableReferences
                                    ._tagIdTable(db)
                                    .id,
                              )
                              as T;
                    }

                    return state;
                  },
              getPrefetchedDataCallback: (items) async {
                return [];
              },
            );
          },
        ),
      );
}

typedef $$PostTagTableTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.$PostTagTableTable,
      i1.PostTag,
      i2.$$PostTagTableTableFilterComposer,
      i2.$$PostTagTableTableOrderingComposer,
      i2.$$PostTagTableTableAnnotationComposer,
      $$PostTagTableTableCreateCompanionBuilder,
      $$PostTagTableTableUpdateCompanionBuilder,
      (i1.PostTag, i2.$$PostTagTableTableReferences),
      i1.PostTag,
      i0.PrefetchHooks Function({bool postId, bool tagId})
    >;

class $PostTagTableTable extends i3.PostTagTable
    with i0.TableInfo<$PostTagTableTable, i1.PostTag> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostTagTableTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _postIdMeta = const i0.VerificationMeta(
    'postId',
  );
  @override
  late final i0.GeneratedColumn<String> postId = i0.GeneratedColumn<String>(
    'post_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES posts (id)',
    ),
  );
  static const i0.VerificationMeta _tagIdMeta = const i0.VerificationMeta(
    'tagId',
  );
  @override
  late final i0.GeneratedColumn<String> tagId = i0.GeneratedColumn<String>(
    'tag_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES tags (id)',
    ),
  );
  static const i0.VerificationMeta _createdAtMeta = const i0.VerificationMeta(
    'createdAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> createdAt =
      i0.GeneratedColumn<DateTime>(
        'created_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: i5.currentDateAndTime,
      );
  static const i0.VerificationMeta _updatedAtMeta = const i0.VerificationMeta(
    'updatedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> updatedAt =
      i0.GeneratedColumn<DateTime>(
        'updated_at',
        aliasedName,
        false,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: false,
        defaultValue: i5.currentDateAndTime,
      );
  static const i0.VerificationMeta _deletedAtMeta = const i0.VerificationMeta(
    'deletedAt',
  );
  @override
  late final i0.GeneratedColumn<DateTime> deletedAt =
      i0.GeneratedColumn<DateTime>(
        'deleted_at',
        aliasedName,
        true,
        type: i0.DriftSqlType.dateTime,
        requiredDuringInsert: false,
      );
  @override
  List<i0.GeneratedColumn> get $columns => [
    id,
    postId,
    tagId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'post_tags';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.PostTag> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('post_id')) {
      context.handle(
        _postIdMeta,
        postId.isAcceptableOrUnknown(data['post_id']!, _postIdMeta),
      );
    } else if (isInserting) {
      context.missing(_postIdMeta);
    }
    if (data.containsKey('tag_id')) {
      context.handle(
        _tagIdMeta,
        tagId.isAcceptableOrUnknown(data['tag_id']!, _tagIdMeta),
      );
    } else if (isInserting) {
      context.missing(_tagIdMeta);
    }
    if (data.containsKey('created_at')) {
      context.handle(
        _createdAtMeta,
        createdAt.isAcceptableOrUnknown(data['created_at']!, _createdAtMeta),
      );
    }
    if (data.containsKey('updated_at')) {
      context.handle(
        _updatedAtMeta,
        updatedAt.isAcceptableOrUnknown(data['updated_at']!, _updatedAtMeta),
      );
    }
    if (data.containsKey('deleted_at')) {
      context.handle(
        _deletedAtMeta,
        deletedAt.isAcceptableOrUnknown(data['deleted_at']!, _deletedAtMeta),
      );
    }
    return context;
  }

  @override
  Set<i0.GeneratedColumn> get $primaryKey => const {};
  @override
  List<Set<i0.GeneratedColumn>> get uniqueKeys => [
    {postId, tagId},
  ];
  @override
  i1.PostTag map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.PostTag(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      postId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}post_id'],
      )!,
      tagId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}tag_id'],
      )!,
    );
  }

  @override
  $PostTagTableTable createAlias(String alias) {
    return $PostTagTableTable(attachedDatabase, alias);
  }
}

class PostTagTableCompanion extends i0.UpdateCompanion<i1.PostTag> {
  final i0.Value<String> id;
  final i0.Value<String> postId;
  final i0.Value<String> tagId;
  final i0.Value<DateTime> createdAt;
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<int> rowid;
  const PostTagTableCompanion({
    this.id = const i0.Value.absent(),
    this.postId = const i0.Value.absent(),
    this.tagId = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  PostTagTableCompanion.insert({
    this.id = const i0.Value.absent(),
    required String postId,
    required String tagId,
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : postId = i0.Value(postId),
       tagId = i0.Value(tagId);
  static i0.Insertable<i1.PostTag> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? postId,
    i0.Expression<String>? tagId,
    i0.Expression<DateTime>? createdAt,
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (postId != null) 'post_id': postId,
      if (tagId != null) 'tag_id': tagId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.PostTagTableCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? postId,
    i0.Value<String>? tagId,
    i0.Value<DateTime>? createdAt,
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<int>? rowid,
  }) {
    return i2.PostTagTableCompanion(
      id: id ?? this.id,
      postId: postId ?? this.postId,
      tagId: tagId ?? this.tagId,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      deletedAt: deletedAt ?? this.deletedAt,
      rowid: rowid ?? this.rowid,
    );
  }

  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    final map = <String, i0.Expression>{};
    if (id.present) {
      map['id'] = i0.Variable<String>(id.value);
    }
    if (postId.present) {
      map['post_id'] = i0.Variable<String>(postId.value);
    }
    if (tagId.present) {
      map['tag_id'] = i0.Variable<String>(tagId.value);
    }
    if (createdAt.present) {
      map['created_at'] = i0.Variable<DateTime>(createdAt.value);
    }
    if (updatedAt.present) {
      map['updated_at'] = i0.Variable<DateTime>(updatedAt.value);
    }
    if (deletedAt.present) {
      map['deleted_at'] = i0.Variable<DateTime>(deletedAt.value);
    }
    if (rowid.present) {
      map['rowid'] = i0.Variable<int>(rowid.value);
    }
    return map;
  }

  @override
  String toString() {
    return (StringBuffer('PostTagTableCompanion(')
          ..write('id: $id, ')
          ..write('postId: $postId, ')
          ..write('tagId: $tagId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
