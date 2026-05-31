import 'package:build/build.dart';
import 'package:schemix/models.dart';

/// Read-only view of the cross-file type graph passed to every generator.
/// Generators must not mutate the registry; all queries go through this interface.
abstract interface class TypeGraph {
  bool isEnum(String name);
  bool isModel(String name);
  bool isEmbeddable(String name);
  TypeInfo? resolve(String name);

  /// Names of all types that participate in a reference cycle.
  /// Used by Zod generator to emit `z.lazy()` wrappers.
  Set<String> get cyclicTypes;

  /// Returns the relative import path (no `.ts` extension) from [fromSourceAssetPath]
  /// to the Zod output file for [typeName], or null if they share the same file.
  String? relativeImportFor({
    required String typeName,
    required String fromSourceAssetPath,
  });

  /// Same as [relativeImportFor] but resolves to the Drizzle output file.
  String? relativeDrizzleImportFor({
    required String typeName,
    required String fromSourceAssetPath,
  });
}

/// Per-invocation context passed to [SchemixGenerator.generate].
final class GeneratorContext {
  const GeneratorContext({
    required this.typeGraph,
    required this.options,
    required this.sourceAssetPath,
  });

  /// Read-only view of the full type graph for cross-file lookups.
  final TypeGraph typeGraph;

  /// Builder options declared in `build.yaml` for this generator.
  final BuilderOptions options;

  /// Asset path of the source `.dart` file being processed, e.g. `lib/models/user.dart`.
  final String sourceAssetPath;
}

/// Output produced by a single [SchemixGenerator.generate] call.
/// Keys are file extensions (e.g. `'.g.ts'`, `'.drizzle.ts'`);
/// values are the file contents. An empty or null value means no file is written.
final class GeneratorOutput {
  const GeneratorOutput(this.outputs);
  const GeneratorOutput.empty() : outputs = const {};
  final Map<String, String?> outputs;
}

/// Contract every Schemix generator must implement.
///
/// A generator is responsible for a single output target (e.g. Zod, Drift, Drizzle).
/// The build infrastructure calls [shouldRun] before [generate] to allow cheap
/// opt-out without allocating output buffers.
abstract interface class SchemixGenerator {
  /// Stable identifier used as the key in [FieldInfo.extensions] and for logging.
  String get id;

  /// File extensions this generator can produce, e.g. `['.g.ts', '.drizzle.ts']`.
  /// Must match the keys declared in `buildExtensions` in the generator's `build.yaml`.
  List<String> get outputExtensions;

  /// Returns false if this generator should be skipped for [classInfo].
  /// Called before [generate]; returning false avoids any allocation.
  bool shouldRun(ClassInfo classInfo);

  /// Transforms [classInfo] into file content for each declared [outputExtensions].
  /// Returns a [GeneratorOutput] whose keys are a subset of [outputExtensions].
  GeneratorOutput generate(ClassInfo classInfo, GeneratorContext context);
}
