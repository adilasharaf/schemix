// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:example_infolder/models/post/post.dart' as i1;
import 'package:example_infolder/models/post/post.table.drift.dart' as i2;
import 'package:example_infolder/models/post/post.table.dart' as i3;
import 'package:uuid/uuid.dart' as i4;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i5;
import 'package:example_infolder/models/user/user.table.drift.dart' as i6;
import 'package:drift/internal/modular.dart' as i7;
import 'package:example_infolder/models/category/category.table.drift.dart'
    as i8;
import 'package:example_infolder/models/post_tag/post_tag.table.drift.dart'
    as i9;
import 'package:example_infolder/models/post_tag/post_tag.dart' as i10;

typedef $$PostTableTableCreateCompanionBuilder =
    i2.PostTableCompanion Function({
      i0.Value<String> id,
      i0.Value<String?> title,
      i0.Value<String?> body,
      i0.Value<String?> slug,
      required i1.PostStatus status,
      i0.Value<String?> userId,
      i0.Value<String?> categoryId,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });
typedef $$PostTableTableUpdateCompanionBuilder =
    i2.PostTableCompanion Function({
      i0.Value<String> id,
      i0.Value<String?> title,
      i0.Value<String?> body,
      i0.Value<String?> slug,
      i0.Value<i1.PostStatus> status,
      i0.Value<String?> userId,
      i0.Value<String?> categoryId,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });

final class $$PostTableTableReferences
    extends
        i0.BaseReferences<i0.GeneratedDatabase, i2.$PostTableTable, i1.Post> {
  $$PostTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i6.$UserTableTable _userIdTable(i0.GeneratedDatabase db) =>
      i7.ReadDatabaseContainer(db)
          .resultSet<i6.$UserTableTable>('users')
          .createAlias(
            i0.$_aliasNameGenerator(
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i2.$PostTableTable>('posts').userId,
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i6.$UserTableTable>('users').id,
            ),
          );

  i6.$$UserTableTableProcessedTableManager? get userId {
    final $_column = $_itemColumn<String>('user_id');
    if ($_column == null) return null;
    final manager = i6
        .$$UserTableTableTableManager(
          $_db,
          i7.ReadDatabaseContainer($_db).resultSet<i6.$UserTableTable>('users'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_userIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i8.$CategoryTableTable _categoryIdTable(i0.GeneratedDatabase db) =>
      i7.ReadDatabaseContainer(db)
          .resultSet<i8.$CategoryTableTable>('categories')
          .createAlias(
            i0.$_aliasNameGenerator(
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i2.$PostTableTable>('posts').categoryId,
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i8.$CategoryTableTable>('categories').id,
            ),
          );

  i8.$$CategoryTableTableProcessedTableManager? get categoryId {
    final $_column = $_itemColumn<String>('category_id');
    if ($_column == null) return null;
    final manager = i8
        .$$CategoryTableTableTableManager(
          $_db,
          i7.ReadDatabaseContainer(
            $_db,
          ).resultSet<i8.$CategoryTableTable>('categories'),
        )
        .filter((f) => f.id.sqlEquals($_column));
    final item = $_typedResult.readTableOrNull(_categoryIdTable($_db));
    if (item == null) return manager;
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: [item]),
    );
  }

  static i0.MultiTypedResultKey<i9.$PostTagTableTable, List<i10.PostTag>>
  _postTagTableRefsTable(
    i0.GeneratedDatabase db,
  ) => i0.MultiTypedResultKey.fromTable(
    i7.ReadDatabaseContainer(db).resultSet<i9.$PostTagTableTable>('post_tags'),
    aliasName: i0.$_aliasNameGenerator(
      i7.ReadDatabaseContainer(db).resultSet<i2.$PostTableTable>('posts').id,
      i7.ReadDatabaseContainer(
        db,
      ).resultSet<i9.$PostTagTableTable>('post_tags').postId,
    ),
  );

  i9.$$PostTagTableTableProcessedTableManager get postTagTableRefs {
    final manager = i9
        .$$PostTagTableTableTableManager(
          $_db,
          i7.ReadDatabaseContainer(
            $_db,
          ).resultSet<i9.$PostTagTableTable>('post_tags'),
        )
        .filter((f) => f.postId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_postTagTableRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$PostTableTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$PostTableTable> {
  $$PostTableTableFilterComposer({
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

  i0.ColumnFilters<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnWithTypeConverterFilters<i1.PostStatus, i1.PostStatus, String>
  get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnWithTypeConverterFilters(column),
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

  i6.$$UserTableTableFilterComposer get userId {
    final i6.$$UserTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i6.$UserTableTable>('users'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$UserTableTableFilterComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i6.$UserTableTable>('users'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i8.$$CategoryTableTableFilterComposer get categoryId {
    final i8.$$CategoryTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i8.$CategoryTableTable>('categories'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i8.$$CategoryTableTableFilterComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i8.$CategoryTableTable>('categories'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<bool> postTagTableRefs(
    i0.Expression<bool> Function(i9.$$PostTagTableTableFilterComposer f) f,
  ) {
    final i9.$$PostTagTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i9.$PostTagTableTable>('post_tags'),
      getReferencedColumn: (t) => t.postId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i9.$$PostTagTableTableFilterComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i9.$PostTagTableTable>('post_tags'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PostTableTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$PostTableTable> {
  $$PostTableTableOrderingComposer({
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

  i0.ColumnOrderings<String> get title => $composableBuilder(
    column: $table.title,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get body => $composableBuilder(
    column: $table.body,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get slug => $composableBuilder(
    column: $table.slug,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
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

  i6.$$UserTableTableOrderingComposer get userId {
    final i6.$$UserTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i6.$UserTableTable>('users'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$UserTableTableOrderingComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i6.$UserTableTable>('users'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i8.$$CategoryTableTableOrderingComposer get categoryId {
    final i8.$$CategoryTableTableOrderingComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i8.$CategoryTableTable>('categories'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i8.$$CategoryTableTableOrderingComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i8.$CategoryTableTable>('categories'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }
}

class $$PostTableTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$PostTableTable> {
  $$PostTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get title =>
      $composableBuilder(column: $table.title, builder: (column) => column);

  i0.GeneratedColumn<String> get body =>
      $composableBuilder(column: $table.body, builder: (column) => column);

  i0.GeneratedColumn<String> get slug =>
      $composableBuilder(column: $table.slug, builder: (column) => column);

  i0.GeneratedColumnWithTypeConverter<i1.PostStatus, String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i6.$$UserTableTableAnnotationComposer get userId {
    final i6.$$UserTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.userId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i6.$UserTableTable>('users'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$UserTableTableAnnotationComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i6.$UserTableTable>('users'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i8.$$CategoryTableTableAnnotationComposer get categoryId {
    final i8.$$CategoryTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.categoryId,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i8.$CategoryTableTable>('categories'),
      getReferencedColumn: (t) => t.id,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i8.$$CategoryTableTableAnnotationComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i8.$CategoryTableTable>('categories'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return composer;
  }

  i0.Expression<T> postTagTableRefs<T extends Object>(
    i0.Expression<T> Function(i9.$$PostTagTableTableAnnotationComposer a) f,
  ) {
    final i9.$$PostTagTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i9.$PostTagTableTable>('post_tags'),
      getReferencedColumn: (t) => t.postId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i9.$$PostTagTableTableAnnotationComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i9.$PostTagTableTable>('post_tags'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$PostTableTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.$PostTableTable,
          i1.Post,
          i2.$$PostTableTableFilterComposer,
          i2.$$PostTableTableOrderingComposer,
          i2.$$PostTableTableAnnotationComposer,
          $$PostTableTableCreateCompanionBuilder,
          $$PostTableTableUpdateCompanionBuilder,
          (i1.Post, i2.$$PostTableTableReferences),
          i1.Post,
          i0.PrefetchHooks Function({
            bool userId,
            bool categoryId,
            bool postTagTableRefs,
          })
        > {
  $$PostTableTableTableManager(
    i0.GeneratedDatabase db,
    i2.$PostTableTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$$PostTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$$PostTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$$PostTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String?> title = const i0.Value.absent(),
                i0.Value<String?> body = const i0.Value.absent(),
                i0.Value<String?> slug = const i0.Value.absent(),
                i0.Value<i1.PostStatus> status = const i0.Value.absent(),
                i0.Value<String?> userId = const i0.Value.absent(),
                i0.Value<String?> categoryId = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.PostTableCompanion(
                id: id,
                title: title,
                body: body,
                slug: slug,
                status: status,
                userId: userId,
                categoryId: categoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String?> title = const i0.Value.absent(),
                i0.Value<String?> body = const i0.Value.absent(),
                i0.Value<String?> slug = const i0.Value.absent(),
                required i1.PostStatus status,
                i0.Value<String?> userId = const i0.Value.absent(),
                i0.Value<String?> categoryId = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.PostTableCompanion.insert(
                id: id,
                title: title,
                body: body,
                slug: slug,
                status: status,
                userId: userId,
                categoryId: categoryId,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  i2.$$PostTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({userId = false, categoryId = false, postTagTableRefs = false}) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (postTagTableRefs)
                      i7.ReadDatabaseContainer(
                        db,
                      ).resultSet<i9.$PostTagTableTable>('post_tags'),
                  ],
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
                        if (userId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.userId,
                                    referencedTable: i2
                                        .$$PostTableTableReferences
                                        ._userIdTable(db),
                                    referencedColumn: i2
                                        .$$PostTableTableReferences
                                        ._userIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }
                        if (categoryId) {
                          state =
                              state.withJoin(
                                    currentTable: table,
                                    currentColumn: table.categoryId,
                                    referencedTable: i2
                                        .$$PostTableTableReferences
                                        ._categoryIdTable(db),
                                    referencedColumn: i2
                                        .$$PostTableTableReferences
                                        ._categoryIdTable(db)
                                        .id,
                                  )
                                  as T;
                        }

                        return state;
                      },
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (postTagTableRefs)
                        await i0.$_getPrefetchedData<
                          i1.Post,
                          i2.$PostTableTable,
                          i10.PostTag
                        >(
                          currentTable: table,
                          referencedTable: i2.$$PostTableTableReferences
                              ._postTagTableRefsTable(db),
                          managerFromTypedResult: (p0) => i2
                              .$$PostTableTableReferences(db, table, p0)
                              .postTagTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.postId == item.id,
                              ),
                          typedResults: items,
                        ),
                    ];
                  },
                );
              },
        ),
      );
}

typedef $$PostTableTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.$PostTableTable,
      i1.Post,
      i2.$$PostTableTableFilterComposer,
      i2.$$PostTableTableOrderingComposer,
      i2.$$PostTableTableAnnotationComposer,
      $$PostTableTableCreateCompanionBuilder,
      $$PostTableTableUpdateCompanionBuilder,
      (i1.Post, i2.$$PostTableTableReferences),
      i1.Post,
      i0.PrefetchHooks Function({
        bool userId,
        bool categoryId,
        bool postTagTableRefs,
      })
    >;

class $PostTableTable extends i3.PostTable
    with i0.TableInfo<$PostTableTable, i1.Post> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $PostTableTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _titleMeta = const i0.VerificationMeta(
    'title',
  );
  @override
  late final i0.GeneratedColumn<String> title = i0.GeneratedColumn<String>(
    'title',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _bodyMeta = const i0.VerificationMeta(
    'body',
  );
  @override
  late final i0.GeneratedColumn<String> body = i0.GeneratedColumn<String>(
    'body',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _slugMeta = const i0.VerificationMeta(
    'slug',
  );
  @override
  late final i0.GeneratedColumn<String> slug = i0.GeneratedColumn<String>(
    'slug',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  @override
  late final i0.GeneratedColumnWithTypeConverter<i1.PostStatus, String> status =
      i0.GeneratedColumn<String>(
        'status',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      ).withConverter<i1.PostStatus>(i2.$PostTableTable.$converterstatus);
  static const i0.VerificationMeta _userIdMeta = const i0.VerificationMeta(
    'userId',
  );
  @override
  late final i0.GeneratedColumn<String> userId = i0.GeneratedColumn<String>(
    'user_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const i0.VerificationMeta _categoryIdMeta = const i0.VerificationMeta(
    'categoryId',
  );
  @override
  late final i0.GeneratedColumn<String> categoryId = i0.GeneratedColumn<String>(
    'category_id',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES categories (id)',
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
    title,
    body,
    slug,
    status,
    userId,
    categoryId,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'posts';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Post> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('title')) {
      context.handle(
        _titleMeta,
        title.isAcceptableOrUnknown(data['title']!, _titleMeta),
      );
    }
    if (data.containsKey('body')) {
      context.handle(
        _bodyMeta,
        body.isAcceptableOrUnknown(data['body']!, _bodyMeta),
      );
    }
    if (data.containsKey('slug')) {
      context.handle(
        _slugMeta,
        slug.isAcceptableOrUnknown(data['slug']!, _slugMeta),
      );
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    }
    if (data.containsKey('category_id')) {
      context.handle(
        _categoryIdMeta,
        categoryId.isAcceptableOrUnknown(data['category_id']!, _categoryIdMeta),
      );
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
  i1.Post map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Post(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
    );
  }

  @override
  $PostTableTable createAlias(String alias) {
    return $PostTableTable(attachedDatabase, alias);
  }

  static i0.TypeConverter<i1.PostStatus, String> $converterstatus =
      i3.PostTable.$postStatusConverter;
}

class PostTableCompanion extends i0.UpdateCompanion<i1.Post> {
  final i0.Value<String> id;
  final i0.Value<String?> title;
  final i0.Value<String?> body;
  final i0.Value<String?> slug;
  final i0.Value<i1.PostStatus> status;
  final i0.Value<String?> userId;
  final i0.Value<String?> categoryId;
  final i0.Value<DateTime> createdAt;
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<int> rowid;
  const PostTableCompanion({
    this.id = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.body = const i0.Value.absent(),
    this.slug = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.userId = const i0.Value.absent(),
    this.categoryId = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  PostTableCompanion.insert({
    this.id = const i0.Value.absent(),
    this.title = const i0.Value.absent(),
    this.body = const i0.Value.absent(),
    this.slug = const i0.Value.absent(),
    required i1.PostStatus status,
    this.userId = const i0.Value.absent(),
    this.categoryId = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : status = i0.Value(status);
  static i0.Insertable<i1.Post> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? title,
    i0.Expression<String>? body,
    i0.Expression<String>? slug,
    i0.Expression<String>? status,
    i0.Expression<String>? userId,
    i0.Expression<String>? categoryId,
    i0.Expression<DateTime>? createdAt,
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (title != null) 'title': title,
      if (body != null) 'body': body,
      if (slug != null) 'slug': slug,
      if (status != null) 'status': status,
      if (userId != null) 'user_id': userId,
      if (categoryId != null) 'category_id': categoryId,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.PostTableCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String?>? title,
    i0.Value<String?>? body,
    i0.Value<String?>? slug,
    i0.Value<i1.PostStatus>? status,
    i0.Value<String?>? userId,
    i0.Value<String?>? categoryId,
    i0.Value<DateTime>? createdAt,
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<int>? rowid,
  }) {
    return i2.PostTableCompanion(
      id: id ?? this.id,
      title: title ?? this.title,
      body: body ?? this.body,
      slug: slug ?? this.slug,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      categoryId: categoryId ?? this.categoryId,
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
    if (title.present) {
      map['title'] = i0.Variable<String>(title.value);
    }
    if (body.present) {
      map['body'] = i0.Variable<String>(body.value);
    }
    if (slug.present) {
      map['slug'] = i0.Variable<String>(slug.value);
    }
    if (status.present) {
      map['status'] = i0.Variable<String>(
        i2.$PostTableTable.$converterstatus.toSql(status.value),
      );
    }
    if (userId.present) {
      map['user_id'] = i0.Variable<String>(userId.value);
    }
    if (categoryId.present) {
      map['category_id'] = i0.Variable<String>(categoryId.value);
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
    return (StringBuffer('PostTableCompanion(')
          ..write('id: $id, ')
          ..write('title: $title, ')
          ..write('body: $body, ')
          ..write('slug: $slug, ')
          ..write('status: $status, ')
          ..write('userId: $userId, ')
          ..write('categoryId: $categoryId, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
