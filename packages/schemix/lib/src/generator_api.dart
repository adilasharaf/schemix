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

  /// Returns true if [typeName] can be imported by [generatorId].
  /// This checks if the target type has the generator enabled.
  bool canImport(String typeName, String generatorId);
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
abstract class SchemixGenerator {
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

  /// Generates file content for a batch of classes from the same source file.
  /// 
  /// The default implementation calls [generate] for each class where [shouldRun]
  /// is true and concatenates the outputs.
  /// Generators that perform cross-class aggregation (like Zod) should override this.
  String? generateForFile(List<ClassInfo> classes, GeneratorContext context) {
    final buf = StringBuffer();
    for (final classInfo in classes) {
      if (!shouldRun(classInfo)) continue;
      final output = generate(classInfo, context);
      for (final entry in output.outputs.entries) {
        if (entry.value != null && entry.value!.trim().isNotEmpty) {
          buf.writeln(entry.value);
        }
      }
    }
    final result = buf.toString().trim();
    return result.isEmpty ? null : result;
  }
}

// ── Generator registry ───────────────────────────────────────────────────────

/// A single generator registration entry.
///
/// [generator] is the [SchemixGenerator] instance.
/// [skipAnnotation] is the simple class name of the opt-out annotation
/// (e.g. `'NoDrizzle'`). When a `@Schemix`-annotated class also carries this
/// annotation, the scan builder writes `extensions[generator.id] = false`
/// into [TypeInfo], and the generator's `shouldRun` treats that as suppressed.
///
/// If [skipAnnotation] is null the generator always runs (no opt-out path).
final class GeneratorRegistration {
  const GeneratorRegistration({required this.generator, this.skipAnnotation});

  final SchemixGenerator generator;

  /// Simple annotation class name that opts a class out of this generator.
  /// Example: `'NoDrizzle'` for `@NoDrizzle()`.
  final String? skipAnnotation;
}

/// Process-global registry that tracks every [SchemixGenerator] registered
/// by generator packages' builder factories.
///
/// The scan builder reads [registrations] to populate [TypeInfo.extensions]
/// with opt-out flags, before [ClassInfo] is assembled in Phase 2.
abstract final class GeneratorRegistry {
  GeneratorRegistry._();

  static final List<GeneratorRegistration> _registrations = [];

  /// All current registrations. Read-only view.
  static List<GeneratorRegistration> get registrations =>
      List.unmodifiable(_registrations);

  /// Registers [generator] with an optional [skipAnnotation].
  ///
  /// Call once per generator package from that package's builder factory:
  /// ```dart
  /// GeneratorRegistry.register(
  ///   DrizzleSchemixGenerator(),
  ///   skipAnnotation: 'NoDrizzle',
  /// );
  /// ```
  static void register(SchemixGenerator generator, {String? skipAnnotation}) {
    _registrations.add(
      GeneratorRegistration(
        generator: generator,
        skipAnnotation: skipAnnotation,
      ),
    );
  }

  /// Returns every registered [SchemixGenerator] in registration order.
  static Iterable<SchemixGenerator> get generators =>
      _registrations.map((r) => r.generator);

  /// Finds a registered generator by its id.
  static SchemixGenerator? find(String id) {
    for (final r in _registrations) {
      if (r.generator.id == id) return r.generator;
    }
    return null;
  }
}
