// dart format width=80
// ignore_for_file: type=lint
import 'package:drift/drift.dart' as i0;
import 'package:example/models/profile/profile.dart' as i1;
import 'package:example/models/profile/profile.table.drift.dart' as i2;
import 'package:example/models/profile/profile.table.dart' as i3;
import 'package:uuid/uuid.dart' as i4;
import 'package:drift/src/runtime/query_builder/query_builder.dart' as i5;

typedef $$ProfileTableTableCreateCompanionBuilder =
    i2.ProfileTableCompanion Function({
      i0.Value<String> id,
      required String userId,
      i0.Value<String?> website,
      i0.Value<String?> phoneNumber,
      required bool isActive,
      i0.Value<int?> age,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });
typedef $$ProfileTableTableUpdateCompanionBuilder =
    i2.ProfileTableCompanion Function({
      i0.Value<String> id,
      i0.Value<String> userId,
      i0.Value<String?> website,
      i0.Value<String?> phoneNumber,
      i0.Value<bool> isActive,
      i0.Value<int?> age,
      i0.Value<DateTime> createdAt,
      i0.Value<DateTime> updatedAt,
      i0.Value<DateTime?> deletedAt,
      i0.Value<int> rowid,
    });

class $$ProfileTableTableFilterComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$ProfileTableTable> {
  $$ProfileTableTableFilterComposer({
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

  i0.ColumnFilters<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => i0.ColumnFilters(column),
  );

  i0.ColumnFilters<int> get age => $composableBuilder(
    column: $table.age,
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
}

class $$ProfileTableTableOrderingComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$ProfileTableTable> {
  $$ProfileTableTableOrderingComposer({
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

  i0.ColumnOrderings<String> get userId => $composableBuilder(
    column: $table.userId,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get website => $composableBuilder(
    column: $table.website,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<bool> get isActive => $composableBuilder(
    column: $table.isActive,
    builder: (column) => i0.ColumnOrderings(column),
  );

  i0.ColumnOrderings<int> get age => $composableBuilder(
    column: $table.age,
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

class $$ProfileTableTableAnnotationComposer
    extends i0.Composer<i0.GeneratedDatabase, i2.$ProfileTableTable> {
  $$ProfileTableTableAnnotationComposer({
    required super.$db,
    required super.$table,
    super.joinBuilder,
    super.$addJoinBuilderToRootComposer,
    super.$removeJoinBuilderFromRootComposer,
  });
  i0.GeneratedColumn<String> get id =>
      $composableBuilder(column: $table.id, builder: (column) => column);

  i0.GeneratedColumn<String> get userId =>
      $composableBuilder(column: $table.userId, builder: (column) => column);

  i0.GeneratedColumn<String> get website =>
      $composableBuilder(column: $table.website, builder: (column) => column);

  i0.GeneratedColumn<String> get phoneNumber => $composableBuilder(
    column: $table.phoneNumber,
    builder: (column) => column,
  );

  i0.GeneratedColumn<bool> get isActive =>
      $composableBuilder(column: $table.isActive, builder: (column) => column);

  i0.GeneratedColumn<int> get age =>
      $composableBuilder(column: $table.age, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get createdAt =>
      $composableBuilder(column: $table.createdAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get updatedAt =>
      $composableBuilder(column: $table.updatedAt, builder: (column) => column);

  i0.GeneratedColumn<DateTime> get deletedAt =>
      $composableBuilder(column: $table.deletedAt, builder: (column) => column);
}

class $$ProfileTableTableTableManager
    extends
        i0.RootTableManager<
          i0.GeneratedDatabase,
          i2.$ProfileTableTable,
          i1.Profile,
          i2.$$ProfileTableTableFilterComposer,
          i2.$$ProfileTableTableOrderingComposer,
          i2.$$ProfileTableTableAnnotationComposer,
          $$ProfileTableTableCreateCompanionBuilder,
          $$ProfileTableTableUpdateCompanionBuilder,
          (
            i1.Profile,
            i0.BaseReferences<
              i0.GeneratedDatabase,
              i2.$ProfileTableTable,
              i1.Profile
            >,
          ),
          i1.Profile,
          i0.PrefetchHooks Function()
        > {
  $$ProfileTableTableTableManager(
    i0.GeneratedDatabase db,
    i2.$ProfileTableTable table,
  ) : super(
        i0.TableManagerState(
          db: db,
          table: table,
          createFilteringComposer: () =>
              i2.$$ProfileTableTableFilterComposer($db: db, $table: table),
          createOrderingComposer: () =>
              i2.$$ProfileTableTableOrderingComposer($db: db, $table: table),
          createComputedFieldComposer: () =>
              i2.$$ProfileTableTableAnnotationComposer($db: db, $table: table),
          updateCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                i0.Value<String> userId = const i0.Value.absent(),
                i0.Value<String?> website = const i0.Value.absent(),
                i0.Value<String?> phoneNumber = const i0.Value.absent(),
                i0.Value<bool> isActive = const i0.Value.absent(),
                i0.Value<int?> age = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ProfileTableCompanion(
                id: id,
                userId: userId,
                website: website,
                phoneNumber: phoneNumber,
                isActive: isActive,
                age: age,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          createCompanionCallback:
              ({
                i0.Value<String> id = const i0.Value.absent(),
                required String userId,
                i0.Value<String?> website = const i0.Value.absent(),
                i0.Value<String?> phoneNumber = const i0.Value.absent(),
                required bool isActive,
                i0.Value<int?> age = const i0.Value.absent(),
                i0.Value<DateTime> createdAt = const i0.Value.absent(),
                i0.Value<DateTime> updatedAt = const i0.Value.absent(),
                i0.Value<DateTime?> deletedAt = const i0.Value.absent(),
                i0.Value<int> rowid = const i0.Value.absent(),
              }) => i2.ProfileTableCompanion.insert(
                id: id,
                userId: userId,
                website: website,
                phoneNumber: phoneNumber,
                isActive: isActive,
                age: age,
                createdAt: createdAt,
                updatedAt: updatedAt,
                deletedAt: deletedAt,
                rowid: rowid,
              ),
          withReferenceMapper: (p0) => p0
              .map((e) => (e.readTable(table), i0.BaseReferences(db, table, e)))
              .toList(),
          prefetchHooksCallback: null,
        ),
      );
}

typedef $$ProfileTableTableProcessedTableManager =
    i0.ProcessedTableManager<
      i0.GeneratedDatabase,
      i2.$ProfileTableTable,
      i1.Profile,
      i2.$$ProfileTableTableFilterComposer,
      i2.$$ProfileTableTableOrderingComposer,
      i2.$$ProfileTableTableAnnotationComposer,
      $$ProfileTableTableCreateCompanionBuilder,
      $$ProfileTableTableUpdateCompanionBuilder,
      (
        i1.Profile,
        i0.BaseReferences<
          i0.GeneratedDatabase,
          i2.$ProfileTableTable,
          i1.Profile
        >,
      ),
      i1.Profile,
      i0.PrefetchHooks Function()
    >;

class $ProfileTableTable extends i3.ProfileTable
    with i0.TableInfo<$ProfileTableTable, i1.Profile> {
  @override
  final i0.GeneratedDatabase attachedDatabase;
  final String? _alias;
  $ProfileTableTable(this.attachedDatabase, [this._alias]);
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
  );
  static const i0.VerificationMeta _websiteMeta = const i0.VerificationMeta(
    'website',
  );
  @override
  late final i0.GeneratedColumn<String> website = i0.GeneratedColumn<String>(
    'website',
    aliasedName,
    true,
    type: i0.DriftSqlType.string,
    requiredDuringInsert: false,
  );
  static const i0.VerificationMeta _phoneNumberMeta = const i0.VerificationMeta(
    'phoneNumber',
  );
  @override
  late final i0.GeneratedColumn<String> phoneNumber =
      i0.GeneratedColumn<String>(
        'phone_number',
        aliasedName,
        true,
        type: i0.DriftSqlType.string,
        requiredDuringInsert: false,
      );
  static const i0.VerificationMeta _isActiveMeta = const i0.VerificationMeta(
    'isActive',
  );
  @override
  late final i0.GeneratedColumn<bool> isActive = i0.GeneratedColumn<bool>(
    'is_active',
    aliasedName,
    false,
    type: i0.DriftSqlType.bool,
    requiredDuringInsert: true,
    defaultConstraints: i0.GeneratedColumn.constraintIsAlways(
      'CHECK ("is_active" IN (0, 1))',
    ),
  );
  static const i0.VerificationMeta _ageMeta = const i0.VerificationMeta('age');
  @override
  late final i0.GeneratedColumn<int> age = i0.GeneratedColumn<int>(
    'age',
    aliasedName,
    true,
    type: i0.DriftSqlType.int,
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
    website,
    phoneNumber,
    isActive,
    age,
    createdAt,
    updatedAt,
    deletedAt,
  ];
  @override
  String get aliasedName => _alias ?? actualTableName;
  @override
  String get actualTableName => $name;
  static const String $name = 'profiles';
  @override
  i0.VerificationContext validateIntegrity(
    i0.Insertable<i1.Profile> instance, {
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
    if (data.containsKey('website')) {
      context.handle(
        _websiteMeta,
        website.isAcceptableOrUnknown(data['website']!, _websiteMeta),
      );
    }
    if (data.containsKey('phone_number')) {
      context.handle(
        _phoneNumberMeta,
        phoneNumber.isAcceptableOrUnknown(
          data['phone_number']!,
          _phoneNumberMeta,
        ),
      );
    }
    if (data.containsKey('is_active')) {
      context.handle(
        _isActiveMeta,
        isActive.isAcceptableOrUnknown(data['is_active']!, _isActiveMeta),
      );
    } else if (isInserting) {
      context.missing(_isActiveMeta);
    }
    if (data.containsKey('age')) {
      context.handle(
        _ageMeta,
        age.isAcceptableOrUnknown(data['age']!, _ageMeta),
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
  i1.Profile map(Map<String, dynamic> data, {String? tablePrefix}) {
    final effectivePrefix = tablePrefix != null ? '$tablePrefix.' : '';
    return i1.Profile(
      id: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}id'],
      )!,
      userId: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}user_id'],
      )!,
      website: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}website'],
      ),
      phoneNumber: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.string,
        data['${effectivePrefix}phone_number'],
      ),
      isActive: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.bool,
        data['${effectivePrefix}is_active'],
      )!,
      age: attachedDatabase.typeMapping.read(
        i0.DriftSqlType.int,
        data['${effectivePrefix}age'],
      ),
    );
  }

  @override
  $ProfileTableTable createAlias(String alias) {
    return $ProfileTableTable(attachedDatabase, alias);
  }
}

class ProfileTableCompanion extends i0.UpdateCompanion<i1.Profile> {
  final i0.Value<String> id;
  final i0.Value<String> userId;
  final i0.Value<String?> website;
  final i0.Value<String?> phoneNumber;
  final i0.Value<bool> isActive;
  final i0.Value<int?> age;
  final i0.Value<DateTime> createdAt;
  final i0.Value<DateTime> updatedAt;
  final i0.Value<DateTime?> deletedAt;
  final i0.Value<int> rowid;
  const ProfileTableCompanion({
    this.id = const i0.Value.absent(),
    this.userId = const i0.Value.absent(),
    this.website = const i0.Value.absent(),
    this.phoneNumber = const i0.Value.absent(),
    this.isActive = const i0.Value.absent(),
    this.age = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  });
  ProfileTableCompanion.insert({
    this.id = const i0.Value.absent(),
    required String userId,
    this.website = const i0.Value.absent(),
    this.phoneNumber = const i0.Value.absent(),
    required bool isActive,
    this.age = const i0.Value.absent(),
    this.createdAt = const i0.Value.absent(),
    this.updatedAt = const i0.Value.absent(),
    this.deletedAt = const i0.Value.absent(),
    this.rowid = const i0.Value.absent(),
  }) : userId = i0.Value(userId),
       isActive = i0.Value(isActive);
  static i0.Insertable<i1.Profile> custom({
    i0.Expression<String>? id,
    i0.Expression<String>? userId,
    i0.Expression<String>? website,
    i0.Expression<String>? phoneNumber,
    i0.Expression<bool>? isActive,
    i0.Expression<int>? age,
    i0.Expression<DateTime>? createdAt,
    i0.Expression<DateTime>? updatedAt,
    i0.Expression<DateTime>? deletedAt,
    i0.Expression<int>? rowid,
  }) {
    return i0.RawValuesInsertable({
      if (id != null) 'id': id,
      if (userId != null) 'user_id': userId,
      if (website != null) 'website': website,
      if (phoneNumber != null) 'phone_number': phoneNumber,
      if (isActive != null) 'is_active': isActive,
      if (age != null) 'age': age,
      if (createdAt != null) 'created_at': createdAt,
      if (updatedAt != null) 'updated_at': updatedAt,
      if (deletedAt != null) 'deleted_at': deletedAt,
      if (rowid != null) 'rowid': rowid,
    });
  }

  i2.ProfileTableCompanion copyWith({
    i0.Value<String>? id,
    i0.Value<String>? userId,
    i0.Value<String?>? website,
    i0.Value<String?>? phoneNumber,
    i0.Value<bool>? isActive,
    i0.Value<int?>? age,
    i0.Value<DateTime>? createdAt,
    i0.Value<DateTime>? updatedAt,
    i0.Value<DateTime?>? deletedAt,
    i0.Value<int>? rowid,
  }) {
    return i2.ProfileTableCompanion(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      website: website ?? this.website,
      phoneNumber: phoneNumber ?? this.phoneNumber,
      isActive: isActive ?? this.isActive,
      age: age ?? this.age,
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
    if (website.present) {
      map['website'] = i0.Variable<String>(website.value);
    }
    if (phoneNumber.present) {
      map['phone_number'] = i0.Variable<String>(phoneNumber.value);
    }
    if (isActive.present) {
      map['is_active'] = i0.Variable<bool>(isActive.value);
    }
    if (age.present) {
      map['age'] = i0.Variable<int>(age.value);
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
    return (StringBuffer('ProfileTableCompanion(')
          ..write('id: $id, ')
          ..write('userId: $userId, ')
          ..write('website: $website, ')
          ..write('phoneNumber: $phoneNumber, ')
          ..write('isActive: $isActive, ')
          ..write('age: $age, ')
          ..write('createdAt: $createdAt, ')
          ..write('updatedAt: $updatedAt, ')
          ..write('deletedAt: $deletedAt, ')
          ..write('rowid: $rowid')
          ..write(')'))
        .toString();
  }
}

class _$ProfileInsertable implements i0.Insertable<i1.Profile> {
  i1.Profile _object;
  _$ProfileInsertable(this._object);
  @override
  Map<String, i0.Expression> toColumns(bool nullToAbsent) {
    return i2.ProfileTableCompanion(
      id: i0.Value(_object.id),
      userId: i0.Value(_object.userId),
      website: i0.Value(_object.website),
      phoneNumber: i0.Value(_object.phoneNumber),
      isActive: i0.Value(_object.isActive),
      age: i0.Value(_object.age),
    ).toColumns(false);
  }
}

extension ProfileToInsertable on i1.Profile {
  _$ProfileInsertable toInsertable() {
    return _$ProfileInsertable(this);
  }
}
