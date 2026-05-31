import 'package:build/build.dart';

class SchemixLogger {
  const SchemixLogger(this._scope);
  final String _scope;

  void info(String msg) => log.info(_fmt(msg));
  void warning(String msg) => log.warning(_fmt(msg));
  void severe(String msg) => log.severe(_fmt(msg));
  void verbose(String msg) => log.fine(_fmt(msg));

  void buildStart(String assetPath) => verbose('>> build start  | $assetPath');

  void buildSkip(String assetPath, String reason) =>
      verbose('-- skip         | $assetPath  ($reason)');

  void buildNoOp(String assetPath) =>
      verbose('.. no-op        | $assetPath  (no relevant classes)');

  void scanStart(int assetCount) =>
      verbose('>> scan         | $assetCount assets found');

  void scanAsset(String assetPath) => verbose('   scan         | $assetPath');

  void scanSkip(String assetPath, String reason) =>
      verbose('   scan skip    | $assetPath  ($reason)');

  void registeredEnum(String name, String assetPath, List<String> values) =>
      verbose('   enum +       | $name  [${values.join(', ')}]  <- $assetPath');

  void registeredClass(
    String name,
    String assetPath, {
    String? superclass,
    bool hasSchemix = false,
    Set<String>? fieldDeps,
    Set<String>? relationDeps,
  }) {
    final tag = hasSchemix ? '+' : '.';
    final deps = [
      if (superclass != null) 'extends $superclass',
      if (fieldDeps?.isNotEmpty ?? false) 'deps=[${fieldDeps!.join(', ')}]',
      if (relationDeps?.isNotEmpty ?? false)
        'rels=[${relationDeps!.join(', ')}]',
    ].join('  ');
    verbose('   class $tag     | $name  $deps  <- $assetPath');
  }

  void analysisResult(String assetPath, int total, int relevant) =>
      verbose('   analysis     | $assetPath  total=$total  relevant=$relevant');

  void outputWrite(String outputPath, String generator) =>
      verbose('   write        | $outputPath  [$generator]');

  void outputSkip(String outputPath, String reason) =>
      verbose('   skip write   | $outputPath  ($reason)');

  void outputWarning(String outputPath, String msg) =>
      warning('!! $outputPath  | $msg');

  void fragmentMismatch(String fragmentUri, String inputUri) =>
      verbose('!! uri mismatch | fragment=$fragmentUri  input=$inputUri');

  void error(String assetPath, Object err, [StackTrace? st]) {
    severe('!! error        | $assetPath  $err');
    if (st != null) log.fine(_fmt('   stacktrace   | $st'));
  }

  void exception(String context, Object err, [StackTrace? st]) {
    severe('!! exception    | [$context]  $err');
    if (st != null) log.fine(_fmt('   stacktrace   | $st'));
  }

  String _fmt(String msg) => '[schemix/$_scope] $msg';
}
