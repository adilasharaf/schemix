import 'package:schemix/schemix.dart';
import 'package:schemix_builder/schemix_builder.dart';

import 'copy.dart';
import 'ctor_params.dart';
import 'expr_builder.dart';
import 'from_json.dart';
import 'header.dart';
import 'to_json.dart';

final class SerializableGenerator implements SchemixGenerator {
  static final _log = const SchemixLogger('serializable');

  @override
  String get id => 'serializable';

  @override
  List<String> get outputExtensions => const ['.schemix.dart'];

  @override
  bool shouldRun(ClassInfo classInfo) =>
      classInfo.hasSchemix && !classInfo.isEnum && !classInfo.abstractSchema;

  @override
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context) {
    final ctorResolver = CtorParamResolver(_log);
    final exprBuilder = JsonExprBuilder(context.typeGraph);
    final fromJson = FromJsonGenerator(exprBuilder, _log);
    final toJson = ToJsonGenerator(exprBuilder, _log);
    final copy = CopyGenerator(_log);

    _log.verbose('   generate     | ${classInfo.name}');

    final ctorParams = ctorResolver.resolve(classInfo);

    final block = [
      fromJson.generate(classInfo, ctorParams: ctorParams, jsonKey: _jsonKey),
      toJson.generate(classInfo, jsonKey: _jsonKey),
      copy.generate(classInfo, ctorParams: ctorParams),
    ].join('\n\n');

    return GeneratorOutput({'.schemix.dart': block});
  }

  String _jsonKey(FieldInfo field) => field.effectiveJsonName;
}

/// Assembles the full `.schemix.dart` part file from per-class [GeneratorOutput]s.
///
/// Called by the builder factory after all classes in a file have been
/// processed. Returns an empty string if no output was produced.
String assembleFile(
  List<ClassInfo> classes,
  String assetPath,
  GeneratorContext context,
) {
  final log = const SchemixLogger('serializable');
  log.buildStart(assetPath);

  final generator = SerializableGenerator();
  final blocks = classes
      .where(generator.shouldRun)
      .map((c) => generator.generate(c, context))
      .expand((o) => o.outputs.values)
      .whereType<String>()
      .where((s) => s.trim().isNotEmpty)
      .join('\n\n');

  if (blocks.isEmpty) {
    log.buildNoOp(assetPath);
    return '';
  }

  log.outputWrite(assetPath, 'serializable');
  return '${SerializableHeader.build(assetPath)}\n\n$blocks\n';
}
