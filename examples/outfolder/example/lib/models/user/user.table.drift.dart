// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:example_outfolder/models/user/user.dart' as i1;
import 'package:example_outfolder/models/user/user.table.drift.dart' as i2;
import 'package:example_outfolder/models/user/user.table.dart' as i3;
import 'package:uuid/uuid.dart' as i4;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i5;
import 'package:example_outfolder/models/profile/profile.table.drift.dart'
    as i6;
import 'package:drift/internal/modular.dart' as i7;
import 'package:example_outfolder/models/post/post.table.drift.dart' as i8;
import 'package:example_outfolder/models/order/order.table.drift.dart' as i9;
import 'package:example_outfolder/models/profile/profile.dart' as i10;
import 'package:example_outfolder/models/post/post.dart' as i11;
import 'package:example_outfolder/models/order/order.dart' as i12;

typedef $$UserTableTableCreateCompanionBuilder =
    i2.UserTableCompanion Function({
      i0.Value<String> id,
      required String email,
      required String passwordHash,
      i0.Value<String?> displayName,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });
typedef $$UserTableTableUpdateCompanionBuilder =
    i2.UserTableCompanion Function({
      i0.Value<String> id,
      i0.Value<String> email,
      i0.Value<String> passwordHash,
      i0.Value<String?> displayName,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });

final class $$UserTableTableReferences
    extends
        i0.BaseReferences<i0.GeneratedDatabase, i2.$UserTableTable, i1.User> {
  $$UserTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i0.MultiTypedResultKey<i6.$ProfileTableTable, List<i10.Profile>>
  _profileTableRefsTable(
    i0.GeneratedDatabase db,
  ) => i0.MultiTypedResultKey.fromTable(
    i7.ReadDatabaseContainer(db).resultSet<i6.$ProfileTableTable>('profiles'),
    aliasName: i0.$_aliasNameGenerator(
      i7.ReadDatabaseContainer(db).resultSet<i2.$UserTableTable>('users').id,
      i7.ReadDatabaseContainer(
        db,
      ).resultSet<i6.$ProfileTableTable>('profiles').userId,
    ),
  );

  i6.$$ProfileTableTableProcessedTableManager get profileTableRefs {
    final manager = i6
        .$$ProfileTableTableTableManager(
          $_db,
          i7.ReadDatabaseContainer(
            $_db,
          ).resultSet<i6.$ProfileTableTable>('profiles'),
        )
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_profileTableRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<i8.$PostTableTable, List<i11.Post>>
  _postTableRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i7.ReadDatabaseContainer(db).resultSet<i8.$PostTableTable>('posts'),
        aliasName: i0.$_aliasNameGenerator(
          i7.ReadDatabaseContainer(
            db,
          ).resultSet<i2.$UserTableTable>('users').id,
          i7.ReadDatabaseContainer(
            db,
          ).resultSet<i8.$PostTableTable>('posts').userId,
        ),
      );

  i8.$$PostTableTableProcessedTableManager get postTableRefs {
    final manager = i8
        .$$PostTableTableTableManager(
          $_db,
          i7.ReadDatabaseContainer($_db).resultSet<i8.$PostTableTable>('posts'),
        )
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_postTableRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }

  static i0.MultiTypedResultKey<i9.$OrderTableTable, List<i12.Order>>
  _orderTableRefsTable(i0.GeneratedDatabase db) =>
      i0.MultiTypedResultKey.fromTable(
        i7.ReadDatabaseContainer(db).resultSet<i9.$OrderTableTable>('orders'),
        aliasName: i0.$_aliasNameGenerator(
          i7.ReadDatabaseContainer(
            db,
          ).resultSet<i2.$UserTableTable>('users').id,
          i7.ReadDatabaseContainer(
            db,
          ).resultSet<i9.$OrderTableTable>('orders').userId,
        ),
      );

  i9.$$OrderTableTableProcessedTableManager get orderTableRefs {
    final manager = i9
        .$$OrderTableTableTableManager(
          $_db,
          i7.ReadDatabaseContainer(
            $_db,
          ).resultSet<i9.$OrderTableTable>('orders'),
        )
        .filter((f) => f.userId.id.sqlEquals($_itemColumn<String>('id')!));

    final cache = $_typedResult.readTableOrNull(_orderTableRefsTable($_db));
    return i0.ProcessedTableManager(
      manager.$state.copyWith(prefetchedData: cache),
    );
  }
}

class $$UserTableTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$UserTableTable> {
  $$UserTableTableFilterComposer({
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

  i0.ColumnFilters<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get displayName => $composableBuilder(
    column: $table.displayName,
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

  i0.Expression<bool> profileTableRefs(
    i0.Expression<bool> Function(i6.$$ProfileTableTableFilterComposer f) f,
  ) {
    final i6.$$ProfileTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i6.$ProfileTableTable>('profiles'),
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$ProfileTableTableFilterComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i6.$ProfileTableTable>('profiles'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> postTableRefs(
    i0.Expression<bool> Function(i8.$$PostTableTableFilterComposer f) f,
  ) {
    final i8.$$PostTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i8.$PostTableTable>('posts'),
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i8.$$PostTableTableFilterComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i8.$PostTableTable>('posts'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<bool> orderTableRefs(
    i0.Expression<bool> Function(i9.$$OrderTableTableFilterComposer f) f,
  ) {
    final i9.$$OrderTableTableFilterComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i9.$OrderTableTable>('orders'),
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i9.$$OrderTableTableFilterComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i9.$OrderTableTable>('orders'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserTableTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$UserTableTable> {
  $$UserTableTableOrderingComposer({
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

  i0.ColumnOrderings<String> get email => $composableBuilder(
    column: $table.email,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get displayName => $composableBuilder(
    column: $table.displayName,
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
}

class $$UserTableTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$UserTableTable> {
  $$UserTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get email =>
      $composableBuilder(column: $table.email, builder: (column) => column);

  i0.GeneratedColumn<String> get passwordHash => $composableBuilder(
    column: $table.passwordHash,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get displayName => $composableBuilder(
    column: $table.displayName,
    builder: (column) => column,
  );

  i0.GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);

  i0.Expression<T> profileTableRefs<T extends Object>(
    i0.Expression<T> Function(i6.$$ProfileTableTableAnnotationComposer a) f,
  ) {
    final i6.$$ProfileTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i6.$ProfileTableTable>('profiles'),
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i6.$$ProfileTableTableAnnotationComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i6.$ProfileTableTable>('profiles'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> postTableRefs<T extends Object>(
    i0.Expression<T> Function(i8.$$PostTableTableAnnotationComposer a) f,
  ) {
    final i8.$$PostTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i8.$PostTableTable>('posts'),
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i8.$$PostTableTableAnnotationComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i8.$PostTableTable>('posts'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }

  i0.Expression<T> orderTableRefs<T extends Object>(
    i0.Expression<T> Function(i9.$$OrderTableTableAnnotationComposer a) f,
  ) {
    final i9.$$OrderTableTableAnnotationComposer composer = $composerBuilder(
      composer: this,
      getCurrentColumn: (t) => t.id,
      referencedTable: i7.ReadDatabaseContainer(
        $db,
      ).resultSet<i9.$OrderTableTable>('orders'),
      getReferencedColumn: (t) => t.userId,
      builder:
          (
            joinBuilder, {
            $addJoinBuilderToRootComposer,
            $removeJoinBuilderFromRootComposer,
          }) => i9.$$OrderTableTableAnnotationComposer(
            $db: $db,
            $table: i7.ReadDatabaseContainer(
              $db,
            ).resultSet<i9.$OrderTableTable>('orders'),
            $addJoinBuilderToRootComposer: $addJoinBuilderToRootComposer,
            joinBuilder: joinBuilder,
            $removeJoinBuilderFromRootComposer:
                $removeJoinBuilderFromRootComposer,
          ),
    );
    return f(composer);
  }
}

class $$UserTableTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.$UserTableTable,
          i1.User,
          i2.$$UserTableTableFilterComposer,
          i2.$$UserTableTableOrderingComposer,
          i2.$$UserTableTableAnnotationComposer,
          $$UserTableTableCreateCompanionBuilder,
          $$UserTableTableUpdateCompanionBuilder,
          (i1.User, i2.$$UserTableTableReferences),
          i1.User,
          i0.PrefetchHooks Function({
            bool profileTableRefs,
            bool postTableRefs,
            bool orderTableRefs,
          })
        > {
  $$UserTableTableTableManager(
    i0.GeneratedDatabase db,
    i2.$UserTableTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$$UserTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$$UserTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$$UserTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> email = const i0.Value.absent(),
                i0.Value<String> passwordHash = const i0.Value.absent(),
                i0.Value<String?> displayName = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.UserTableCompanion(
                id: id,
                email: email,
                passwordHash: passwordHash,
                displayName: displayName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                required String email,
                required String passwordHash,
                i0.Value<String?> displayName = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.UserTableCompanion.insert(
                id: id,
                email: email,
                passwordHash: passwordHash,
                displayName: displayName,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  i2.$$UserTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback:
              ({
                profileTableRefs = false,
                postTableRefs = false,
                orderTableRefs = false,
              }) {
                return i0.PrefetchHooks(
                  db: db,
                  explicitlyWatchedTables: [
                    if (profileTableRefs)
                      i7.ReadDatabaseContainer(
                        db,
                      ).resultSet<i6.$ProfileTableTable>('profiles'),
                    if (postTableRefs)
                      i7.ReadDatabaseContainer(
                        db,
                      ).resultSet<i8.$PostTableTable>('posts'),
                    if (orderTableRefs)
                      i7.ReadDatabaseContainer(
                        db,
                      ).resultSet<i9.$OrderTableTable>('orders'),
                  ],
                  addJoins: null,
                  getPrefetchedDataCallback: (items) async {
                    return [
                      if (profileTableRefs)
                        await i0.$_getPrefetchedData<
                          i1.User,
                          i2.$UserTableTable,
                          i10.Profile
                        >(
                          currentTable: table,
                          referencedTable: i2.$$UserTableTableReferences
                              ._profileTableRefsTable(db),
                          managerFromTypedResult: (p0) => i2
                              .$$UserTableTableReferences(db, table, p0)
                              .profileTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (postTableRefs)
                        await i0.$_getPrefetchedData<
                          i1.User,
                          i2.$UserTableTable,
                          i11.Post
                        >(
                          currentTable: table,
                          referencedTable: i2.$$UserTableTableReferences
                              ._postTableRefsTable(db),
                          managerFromTypedResult: (p0) => i2
                              .$$UserTableTableReferences(db, table, p0)
                              .postTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
                              ),
                          typedResults: items,
                        ),
                      if (orderTableRefs)
                        await i0.$_getPrefetchedData<
                          i1.User,
                          i2.$UserTableTable,
                          i12.Order
                        >(
                          currentTable: table,
                          referencedTable: i2.$$UserTableTableReferences
                              ._orderTableRefsTable(db),
                          managerFromTypedResult: (p0) => i2
                              .$$UserTableTableReferences(db, table, p0)
                              .orderTableRefs,
                          referencedItemsForCurrentItem:
                              (item, referencedItems) => referencedItems.where(
                                (e) => e.userId == item.id,
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

typedef $$UserTableTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.$UserTableTable,
      i1.User,
      i2.$$UserTableTableFilterComposer,
      i2.$$UserTableTableOrderingComposer,
      i2.$$UserTableTableAnnotationComposer,
      $$UserTableTableCreateCompanionBuilder,
      $$UserTableTableUpdateCompanionBuilder,
      (i1.User, i2.$$UserTableTableReferences),
      i1.User,
      i0.PrefetchHooks Function({
        bool profileTableRefs,
        bool postTableRefs,
        bool orderTableRefs,
      })
    >;

class $UserTableTable extends i3.UserTable
    with i0.TableInfo<$UserTableTable, i1.User> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $UserTableTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _emailMeta = const i0.VerificationMeta(
    'email',
  );
  @override
  late final i0.GeneratedColumn<String> email = i0.GeneratedColumn<String>(
    'email',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways('UNIQUE'),
  );
  static const i0.VerificationMeta _passwordHashMeta =
      const i0.VerificationMeta('passwordHash');
  @override
  late final i0.GeneratedColumn<String> passwordHash =
      i0.GeneratedColumn<String>(
        'password_hash',
        aliasedName,
        false,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: true,
      );
  static const i0.VerificationMeta _displayNameMeta = const i0.VerificationMeta(
    'displayName',
  );
  @override
  late final i0.GeneratedColumn<String> displayName =
      i0.GeneratedColumn<String>(
        'display_name',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
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
    email,
    passwordHash,
    displayName,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'users';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.User> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('email')) {
      context.handle(
        _emailMeta,
        email.isAcceptableOrUnknown(data['email']!, _emailMeta),
      );
    } else if (isInserting) {
      context.missing(_emailMeta);
    }
    if (data.containsKey('password_hash')) {
      context.handle(
        _passwordHashMeta,
        passwordHash.isAcceptableOrUnknown(
          data['password_hash']!,
          _passwordHashMeta,
        ),
      );
    } else if (isInserting) {
      context.missing(_passwordHashMeta);
    }
    if (data.containsKey('display_name')) {
      context.handle(
        _displayNameMeta,
        displayName.isAcceptableOrUnknown(
          data['display_name']!,
          _displayNameMeta,
        ),
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
  i1.User map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.User(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      email: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}email'],
      )!,
      passwordHash: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}password_hash'],
      )!,
      displayName: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}display_name'],
      ),
    );
  }

  @override
  $UserTableTable createAlias(String alias) {
    return $UserTableTable(attachedDatabase, alias);
  }
}

class UserTableCompanion extends i0.UpdateCompanion<i1.User> {
  final i0.Value<String> id;
  final i0.Value<String> email;
  final i0.Value<String> passwordHash;
  final i0.Value<String?> displayName;
  final i0.Value<DateTime> createdAt;
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<int> rowid;
  const UserTableCompanion({
    this.id = const i0.Value.absent(),
    this.email = const i0.Value.absent(),
    this.passwordHash = const i0.Value.absent(),
    this.displayName = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  UserTableCompanion.insert({
    this.id = const i0.Value.absent(),
    required String email,
    required String passwordHash,
    this.displayName = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : email = i0.Value(email),
       passwordHash = i0.Value(passwordHash);
  static i0.Insertable<i1.User> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? email,
    i0.Expression<String>? passwordHash,
    i0.Expression<String>? displayName,
    i0.Expression<DateTime>? createdAt,
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (email != null) 'email': email,
      if (passwordHash != null) 'password_hash': passwordHash,
      if (displayName != null) 'display_name': displayName,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.UserTableCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? email,
    i0.Value<String>? passwordHash,
    i0.Value<String?>? displayName,
    i0.Value<DateTime>? createdAt,
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<int>? rowid,
  }) {
    return i2.UserTableCompanion(
      id: id ?? this.id,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      displayName: displayName ?? this.displayName,
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
    if (email.present) {
      map['email'] = i0.Variable<String>(email.value);
    }
    if (passwordHash.present) {
      map['password_hash'] = i0.Variable<String>(passwordHash.value);
    }
    if (displayName.present) {
      map['display_name'] = i0.Variable<String>(displayName.value);
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
    return (StringBuffer('UserTableCompanion(')
          ..write('id: $id, ')
          ..write('email: $email, ')
          ..write('passwordHash: $passwordHash, ')
          ..write('displayName: $displayName, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
