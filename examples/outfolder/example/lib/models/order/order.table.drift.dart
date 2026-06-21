// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:example_outfolder/models/order/order.dart' as i1;
import 'package:example_outfolder/models/order/order.table.drift.dart' as i2;
import 'package:example_outfolder/models/order/order.table.dart' as i3;
import 'package:uuid/uuid.dart' as i4;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i5;
import 'package:example_outfolder/models/user/user.table.drift.dart' as i6;
import 'package:drift/internal/modular.dart' as i7;

typedef $$OrderTableTableCreateCompanionBuilder =
    i2.OrderTableCompanion Function({
      i0.Value<String> id,
      required String userId,
      i0.Value<String> status,
      i0.Value<int?> orderNumber,
      i0.Value<String?> creditCardToken,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });
typedef $$OrderTableTableUpdateCompanionBuilder =
    i2.OrderTableCompanion Function({
      i0.Value<String> id,
      i0.Value<String> userId,
      i0.Value<String> status,
      i0.Value<int?> orderNumber,
      i0.Value<String?> creditCardToken,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });

final class $$OrderTableTableReferences
    extends
        i0.BaseReferences<i0.GeneratedDatabase, i2.$OrderTableTable, i1.Order> {
  $$OrderTableTableReferences(super.$_db, super.$_table, super.$_typedResult);

  static i6.$UserTableTable _userIdTable(i0.GeneratedDatabase db) =>
      i7.ReadDatabaseContainer(db)
          .resultSet<i6.$UserTableTable>('users')
          .createAlias(
            i0.$_aliasNameGenerator(
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i2.$OrderTableTable>('orders').userId,
              i7.ReadDatabaseContainer(
                db,
              ).resultSet<i6.$UserTableTable>('users').id,
            ),
          );

  i6.$$UserTableTableProcessedTableManager get userId {
    final $_column = $_itemColumn<String>('user_id')!;

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
}

class $$OrderTableTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$OrderTableTable> {
  $$OrderTableTableFilterComposer({
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

  i0.ColumnFilters<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get creditCardToken => $composableBuilder(
    column: $table.creditCardToken,
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
}

class $$OrderTableTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$OrderTableTable> {
  $$OrderTableTableOrderingComposer({
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

  i0.ColumnOrderings<String> get status => $composableBuilder(
    column: $table.status,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get creditCardToken => $composableBuilder(
    column: $table.creditCardToken,
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
}

class $$OrderTableTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$OrderTableTable> {
  $$OrderTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get status =>
      $composableBuilder(column: $table.status, builder: (column) => column);

  i0.GeneratedColumn<int> get orderNumber => $composableBuilder(
    column: $table.orderNumber,
    builder: (column) => column,
  );

  i0.GeneratedColumn<String> get creditCardToken => $composableBuilder(
    column: $table.creditCardToken,
    builder: (column) => column,
  );

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
}

class $$OrderTableTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.$OrderTableTable,
          i1.Order,
          i2.$$OrderTableTableFilterComposer,
          i2.$$OrderTableTableOrderingComposer,
          i2.$$OrderTableTableAnnotationComposer,
          $$OrderTableTableCreateCompanionBuilder,
          $$OrderTableTableUpdateCompanionBuilder,
          (i1.Order, i2.$$OrderTableTableReferences),
          i1.Order,
          i0.PrefetchHooks Function({bool userId})
        > {
  $$OrderTableTableTableManager(
    i0.GeneratedDatabase db,
    i2.$OrderTableTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$$OrderTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$$OrderTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$$OrderTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> userId = const i0.Value.absent(),
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<int?> orderNumber = const i0.Value.absent(),
                i0.Value<String?> creditCardToken = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.OrderTableCompanion(
                id: id,
                userId: userId,
                status: status,
                orderNumber: orderNumber,
                creditCardToken: creditCardToken,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                required String userId,
                i0.Value<String> status = const i0.Value.absent(),
                i0.Value<int?> orderNumber = const i0.Value.absent(),
                i0.Value<String?> creditCardToken = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.OrderTableCompanion.insert(
                id: id,
                userId: userId,
                status: status,
                orderNumber: orderNumber,
                creditCardToken: creditCardToken,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map(
                (e) => (
                  e.readTable(table),
                  i2.$$OrderTableTableReferences(db, table, e),
                ),
              )
              .toList(),
          prefetchHooksCallback: ({userId = false}) {
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
                    if (userId) {
                      state =
                          state.withJoin(
                                currentTable: table,
                                currentColumn: table.userId,
                                referencedTable: i2.$$OrderTableTableReferences
                                    ._userIdTable(db),
                                referencedColumn: i2.$$OrderTableTableReferences
                                    ._userIdTable(db)
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

typedef $$OrderTableTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.$OrderTableTable,
      i1.Order,
      i2.$$OrderTableTableFilterComposer,
      i2.$$OrderTableTableOrderingComposer,
      i2.$$OrderTableTableAnnotationComposer,
      $$OrderTableTableCreateCompanionBuilder,
      $$OrderTableTableUpdateCompanionBuilder,
      (i1.Order, i2.$$OrderTableTableReferences),
      i1.Order,
      i0.PrefetchHooks Function({bool userId})
    >;

class $OrderTableTable extends i3.OrderTable
    with i0.TableInfo<$OrderTableTable, i1.Order> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $OrderTableTable(this.attachedDatabase, [this._alias]);
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
  static const i0.VerificationMeta _userIdMeta = const i0.VerificationMeta(
    'userId',
  );
  @override
  late final i0.GeneratedColumn<String> userId = i0.GeneratedColumn<String>(
    'user_id',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'REFERENCES users (id)',
    ),
  );
  static const i0.VerificationMeta _statusMeta = const i0.VerificationMeta(
    'status',
  );
  @override
  late final i0.GeneratedColumn<String> status = i0.GeneratedColumn<String>(
    'status',
    aliasedName,
    false,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
    defaultValue: const i5.Constant('pending'),
  );
  static const i0.VerificationMeta _orderNumberMeta = const i0.VerificationMeta(
    'orderNumber',
  );
  @override
  late final i0.GeneratedColumn<int> orderNumber = i0.GeneratedColumn<int>(
    'order_number',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _creditCardTokenMeta =
      const i0.VerificationMeta('creditCardToken');
  @override
  late final i0.GeneratedColumn<String> creditCardToken =
      i0.GeneratedColumn<String>(
        'credit_card_token',
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
    userId,
    status,
    orderNumber,
    creditCardToken,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'orders';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Order> instance, {
    bool isInserting = false,
  }) {
    final context = i0.VerificationContext();
    final data = instance.toColumns(true);
    if (data.containsKey('id')) {
      context.handle(_idMeta, id.isAcceptableOrUnknown(data['id']!, _idMeta));
    }
    if (data.containsKey('user_id')) {
      context.handle(
        _userIdMeta,
        userId.isAcceptableOrUnknown(data['user_id']!, _userIdMeta),
      );
    } else if (isInserting) {
      context.missing(_userIdMeta);
    }
    if (data.containsKey('status')) {
      context.handle(
        _statusMeta,
        status.isAcceptableOrUnknown(data['status']!, _statusMeta),
      );
    }
    if (data.containsKey('order_number')) {
      context.handle(
        _orderNumberMeta,
        orderNumber.isAcceptableOrUnknown(
          data['order_number']!,
          _orderNumberMeta,
        ),
      );
    }
    if (data.containsKey('credit_card_token')) {
      context.handle(
        _creditCardTokenMeta,
        creditCardToken.isAcceptableOrUnknown(
          data['credit_card_token']!,
          _creditCardTokenMeta,
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
  i1.Order map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Order(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      status: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}status'],
      )!,
      orderNumber: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}order_number'],
      ),
      creditCardToken: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}credit_card_token'],
      ),
    );
  }

  @override
  $OrderTableTable createAlias(String alias) {
    return $OrderTableTable(attachedDatabase, alias);
  }
}

class OrderTableCompanion extends i0.UpdateCompanion<i1.Order> {
  final i0.Value<String> id;
  final i0.Value<String> userId;
  final i0.Value<String> status;
  final i0.Value<int?> orderNumber;
  final i0.Value<String?> creditCardToken;
  final i0.Value<DateTime> createdAt;
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<int> rowid;
  const OrderTableCompanion({
    this.id = const i0.Value.absent(),
    this.userId = const i0.Value.absent(),
    this.status = const i0.Value.absent(),
    this.orderNumber = const i0.Value.absent(),
    this.creditCardToken = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  OrderTableCompanion.insert({
    this.id = const i0.Value.absent(),
    required String userId,
    this.status = const i0.Value.absent(),
    this.orderNumber = const i0.Value.absent(),
    this.creditCardToken = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : userId = i0.Value(userId);
  static i0.Insertable<i1.Order> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? userId,
    i0.Expression<String>? status,
    i0.Expression<int>? orderNumber,
    i0.Expression<String>? creditCardToken,
    i0.Expression<DateTime>? createdAt,
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (status != null) 'status': status,
      if (orderNumber != null) 'order_number': orderNumber,
      if (creditCardToken != null) 'credit_card_token': creditCardToken,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.OrderTableCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? userId,
    i0.Value<String>? status,
    i0.Value<int?>? orderNumber,
    i0.Value<String?>? creditCardToken,
    i0.Value<DateTime>? createdAt,
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<int>? rowid,
  }) {
    return i2.OrderTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      status: status ?? this.status,
      orderNumber: orderNumber ?? this.orderNumber,
      creditCardToken: creditCardToken ?? this.creditCardToken,
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
    if (userId.present) {
      map['user_id'] = i0.Variable<String>(userId.value);
    }
    if (status.present) {
      map['status'] = i0.Variable<String>(status.value);
    }
    if (orderNumber.present) {
      map['order_number'] = i0.Variable<int>(orderNumber.value);
    }
    if (creditCardToken.present) {
      map['credit_card_token'] = i0.Variable<String>(creditCardToken.value);
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
    return (StringBuffer('OrderTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('status: $status, ')
          ..write('orderNumber: $orderNumber, ')
          ..write('creditCardToken: $creditCardToken, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}
