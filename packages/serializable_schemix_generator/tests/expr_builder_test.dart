import 'package:schemix/models.dart';
import 'package:schemix/src/generator_api.dart';
import 'package:serializable_schemix_generator/src/expr_builder.dart';
import 'package:test/test.dart';

// ── Stub TypeGraph ─────────────────────────────────────────────────────────────

final class _StubGraph implements TypeGraph {
  const _StubGraph({this.models = const {}, this.enums = const {}});
  final Set<String> models;
  final Set<String> enums;

  @override
  bool isEnum(String name) => enums.contains(name);
  @override
  bool isModel(String name) => models.contains(name);
  @override
  bool isEmbeddable(String name) => false;
  @override
  TypeInfo? resolve(String name) => null;
  @override
  Set<String> get cyclicTypes => const {};
  @override
  String? relativeImportFor({
    required String typeName,
    required String fromSourceAssetPath,
  }) => null;
  @override
  String? relativeDrizzleImportFor({
    required String typeName,
    required String fromSourceAssetPath,
  }) => null;
}

const _emptyGraph = _StubGraph();
const _withUser = _StubGraph(models: {'User'});
const _withStatus = _StubGraph(enums: {'Status'});

// ── dartCast ──────────────────────────────────────────────────────────────────

void main() {
  group('JsonExprBuilder.dartCast', () {
    final expr = const JsonExprBuilder(_emptyGraph);

    test('String non-nullable', () {
      expect(expr.dartCast('String', false), 'as String');
    });

    test('String nullable', () {
      expect(expr.dartCast('String', true), 'as String?');
    });

    test('int non-nullable', () {
      expect(expr.dartCast('int', false), 'as int');
    });

    test('bool nullable', () {
      expect(expr.dartCast('bool', true), 'as bool?');
    });

    test('unknown type returns as dynamic', () {
      expect(expr.dartCast('Blob', false), 'as dynamic');
    });
  });

  // ── fromJson ──────────────────────────────────────────────────────────────────

  group('JsonExprBuilder.fromJson — primitives', () {
    final expr = const JsonExprBuilder(_emptyGraph);

    test('String non-nullable', () {
      const f = FieldInfo(name: 'email', dartType: 'String', isNullable: false);
      expect(expr.fromJson(f, "json['email']"), "json['email'] as String");
    });

    test('int nullable', () {
      const f = FieldInfo(name: 'age', dartType: 'int', isNullable: true);
      expect(expr.fromJson(f, "json['age']"), "json['age'] as int?");
    });

    test('DateTime non-nullable', () {
      const f = FieldInfo(
        name: 'createdAt',
        dartType: 'DateTime',
        isNullable: false,
      );
      expect(
        expr.fromJson(f, "json['createdAt']"),
        "DateTime.parse(json['createdAt'] as String)",
      );
    });

    test('DateTime nullable', () {
      const f = FieldInfo(
        name: 'deletedAt',
        dartType: 'DateTime',
        isNullable: true,
      );
      expect(
        expr.fromJson(f, "json['deletedAt']"),
        "json['deletedAt'] == null ? null : DateTime.parse(json['deletedAt'] as String)",
      );
    });
  });

  group('JsonExprBuilder.fromJson — nested model', () {
    final expr = const JsonExprBuilder(_withUser);

    test('non-nullable nested model', () {
      const f = FieldInfo(name: 'owner', dartType: 'User', isNullable: false);
      expect(
        expr.fromJson(f, "json['owner']"),
        "User.fromJson(json['owner'] as Map<String, dynamic>)",
      );
    });

    test('nullable nested model', () {
      const f = FieldInfo(name: 'author', dartType: 'User', isNullable: true);
      expect(
        expr.fromJson(f, "json['author']"),
        "json['author'] == null ? null : User.fromJson(json['author'] as Map<String, dynamic>)",
      );
    });
  });

  group('JsonExprBuilder.fromJson — enum', () {
    final expr = const JsonExprBuilder(_withStatus);

    test('non-nullable enum without fallback', () {
      const f = FieldInfo(
        name: 'status',
        dartType: 'Status',
        isNullable: false,
        isEnum: true,
      );
      expect(
        expr.fromJson(f, "json['status']"),
        "Status.values.byName(json['status'] as String)",
      );
    });

    test('nullable enum', () {
      const f = FieldInfo(
        name: 'status',
        dartType: 'Status',
        isNullable: true,
        isEnum: true,
      );
      expect(
        expr.fromJson(f, "json['status']"),
        "json['status'] == null ? null : Status.values.byName(json['status'] as String)",
      );
    });
  });

  group('JsonExprBuilder.fromJson — list', () {
    final expr = const JsonExprBuilder(_emptyGraph);

    test('non-nullable list of String', () {
      const f = FieldInfo(
        name: 'tags',
        dartType: 'String',
        isNullable: false,
        isList: true,
        listItemType: 'String',
      );
      expect(
        expr.fromJson(f, "json['tags']"),
        "(json['tags'] as List<dynamic>).map((e) => e as String).toList()",
      );
    });

    test('nullable list', () {
      const f = FieldInfo(
        name: 'tags',
        dartType: 'String',
        isNullable: true,
        isList: true,
        listItemType: 'String',
      );
      expect(
        expr.fromJson(f, "json['tags']"),
        "(json['tags'] as List<dynamic>?)?.map((e) => e as String).toList()",
      );
    });
  });

  group('JsonExprBuilder.fromJson — map', () {
    final expr = const JsonExprBuilder(_emptyGraph);

    test('non-nullable map', () {
      const f = FieldInfo(
        name: 'meta',
        dartType: 'String',
        isNullable: false,
        isMap: true,
        mapValueType: 'dynamic',
      );
      expect(
        expr.fromJson(f, "json['meta']"),
        "(json['meta'] as Map<String, dynamic>).cast<String, dynamic>()",
      );
    });
  });

  // ── toJson ────────────────────────────────────────────────────────────────────

  group('JsonExprBuilder.toJson', () {
    final expr = const JsonExprBuilder(_emptyGraph);

    test('simple primitive passthrough', () {
      const f = FieldInfo(name: 'id', dartType: 'String', isNullable: false);
      expect(expr.toJson(f, 'instance.id'), 'instance.id');
    });

    test('DateTime non-nullable calls toIso8601String', () {
      const f = FieldInfo(
        name: 'createdAt',
        dartType: 'DateTime',
        isNullable: false,
      );
      expect(
        expr.toJson(f, 'instance.createdAt'),
        'instance.createdAt.toIso8601String()',
      );
    });

    test('DateTime nullable uses null-aware operator', () {
      const f = FieldInfo(
        name: 'deletedAt',
        dartType: 'DateTime',
        isNullable: true,
      );
      expect(
        expr.toJson(f, 'instance.deletedAt'),
        'instance.deletedAt?.toIso8601String()',
      );
    });

    test('enum emits .name', () {
      const f = FieldInfo(
        name: 'status',
        dartType: 'Status',
        isNullable: false,
        isEnum: true,
      );
      expect(expr.toJson(f, 'instance.status'), 'instance.status.name');
    });

    test('nullable enum emits ?.name', () {
      const f = FieldInfo(
        name: 'status',
        dartType: 'Status',
        isNullable: true,
        isEnum: true,
      );
      expect(expr.toJson(f, 'instance.status'), 'instance.status?.name');
    });
  });

  group('JsonExprBuilder.toJson — nested model', () {
    final expr = const JsonExprBuilder(_withUser);

    test('non-nullable model calls .toJson()', () {
      const f = FieldInfo(name: 'owner', dartType: 'User', isNullable: false);
      expect(expr.toJson(f, 'instance.owner'), 'instance.owner.toJson()');
    });

    test('nullable model calls ?.toJson()', () {
      const f = FieldInfo(name: 'author', dartType: 'User', isNullable: true);
      expect(expr.toJson(f, 'instance.author'), 'instance.author?.toJson()');
    });
  });
}
