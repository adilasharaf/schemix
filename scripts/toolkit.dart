#!/usr/bin/env dart
// ============================================================
// Flutter + Melos Monorepo Toolkit  (Dart port of toolkit.sh)
// ============================================================
//
// USAGE:
//   dart scripts/toolkit.dart [MODE] [OPTIONS]
//
// MODES:
//   summary              Full project summary (default)
//   files <glob>         Extract specific files from all packages
//   folder <path>        Summarize a specific folder's code + structure
//   structure            File structure of all packages and apps
//   structure <path>     File structure of a specific package/folder
//   deps                 Dependency map across all packages
//   search <pattern>     Search for a pattern in all source files
//   stats                Code statistics (lines, file counts per package)
//   changes [days]       Show recently modified files (git-based, default 7 days)
//   help                 Show this help reference
//
// EXAMPLES:
//   dart scripts/toolkit.dart summary
//   dart scripts/toolkit.dart files pubspec.yaml
//   dart scripts/toolkit.dart files "pubspec.yaml,analysis_options.yaml"
//   dart scripts/toolkit.dart files "**/*_repository.dart"
//   dart scripts/toolkit.dart folder packages/core/lib/src/network
//   dart scripts/toolkit.dart structure
//   dart scripts/toolkit.dart structure packages/core
//   dart scripts/toolkit.dart deps
//   dart scripts/toolkit.dart search "Riverpod"
//   dart scripts/toolkit.dart stats
//   dart scripts/toolkit.dart changes 7
//
// Requirements:
//   - Melos installed: dart pub global activate melos
//   - Run from monorepo root (same directory as melos.yaml / pubspec.yaml
//     with a workspace: key)
// ============================================================

// ignore_for_file: avoid_print

import 'dart:io';

import 'package:path/path.dart' as p;

// ─── ANSI ────────────────────────────────────────────────────
const _reset = '\x1B[0m';
const _bold = '\x1B[1m';
const _red = '\x1B[31m';
const _green = '\x1B[32m';
const _yellow = '\x1B[33m';
const _blue = '\x1B[34m';
const _cyan = '\x1B[36m';

void logInfo(String m) => print('$_cyanℹ️  $m$_reset');
void logSuccess(String m) => print('$_green✅ $m$_reset');
void logWarn(String m) => print('$_yellow⚠️  $m$_reset');
void logSection(String m) => print('\n$_bold$_blue━━━ $m ━━━$_reset\n');
void logError(String m) {
  print('$_red❌ $m$_reset');
  exit(1);
}

// ─── Ignore / include rules ───────────────────────────────────
const _ignoredDirs = {
  '.git',
  '.idea',
  '.vscode',
  '.dart_tool',
  '.fvm',
  '.docs',
  '.melos_tool',
  'build',
  'coverage',
  'ios',
  'android',
  'macos',
  'linux',
  'windows',
  'web',
  'test',
  'integration_test',
  'example',
  'node_modules',
};

const _ignoredFileGlobs = [
  r'\.g\.dart$',
  r'\.freezed\.dart$',
  r'\.gr\.dart$',
  r'\.mocks\.dart$',
  r'\.config\.dart$',
  r'\.gen\.dart$',
  r'\.graphql\.dart$',
  r'\.pb\.dart$',
  r'\.pbjson\.dart$',
  r'\.pbenum\.dart$',
  r'\.pbserver\.dart$',
  r'\.lock$',
  r'\.log$',
  r'\.tmp$',
  r'node_modules$',
  r'-lock\.json$',
];

const _includeExtensions = {
  '.dart',
  '.yaml',
  '.yml',
  '.json',
  '.arb',
  '.md',
  '.txt',
  '.sh',
};

// Pre-compiled ignored-file regexes
final _ignoredFileRe = _ignoredFileGlobs.map(RegExp.new).toList();

bool _isIgnoredDir(String dirPath) {
  final parts = p.split(dirPath);
  return parts.any((part) => _ignoredDirs.contains(part));
}

bool _isIgnoredFile(String filePath) {
  final name = p.basename(filePath);
  return _ignoredFileRe.any((re) => re.hasMatch(name));
}

bool _isIncludedFile(String filePath) {
  final ext = p.extension(filePath).toLowerCase();
  return _includeExtensions.contains(ext) && !_isIgnoredFile(filePath);
}

// ─── Melos helpers ────────────────────────────────────────────

Future<void> _verifyMelos() async {
  final which = await Process.run('which', ['melos'], runInShell: true);
  if (which.exitCode != 0) {
    logError('Melos is not installed. Run: dart pub global activate melos');
  }
  if (!File('melos.yaml').existsSync() && !File('pubspec.yaml').existsSync()) {
    logError('melos.yaml not found. Run this script from your monorepo root.');
  }
}

/// Returns list of absolute package paths from `melos list --long`.
Future<List<_Package>> _getPackages() async {
  final result = await Process.run('melos', [
    'list',
    '--long',
  ], runInShell: true);
  if (result.exitCode != 0) {
    logError('melos list failed: ${result.stderr}');
  }

  final lines = result.stdout.toString().trim().split('\n');
  if (lines.isEmpty) return [];

  // Detect column layout from first non-empty line
  // Older Melos:  name  path          (2 columns)
  // Newer Melos:  name  version  path (3 columns)
  final firstCols = lines.first.trim().split(RegExp(r'\s+'));
  final pathCol = firstCols.length >= 3 ? 2 : 1;

  final packages = <_Package>[];
  for (final line in lines) {
    final cols = line.trim().split(RegExp(r'\s+'));
    if (cols.length <= pathCol) continue;
    packages.add(_Package(name: cols[0], path: cols[pathCol]));
  }
  return packages;
}

// ─── Timestamp helpers ────────────────────────────────────────

String _fileTimestamp() {
  final now = DateTime.now();
  return '${now.year}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')}_'
      '${now.hour.toString().padLeft(2, '0')}-'
      '${now.minute.toString().padLeft(2, '0')}-'
      '${now.second.toString().padLeft(2, '0')}';
}

String _humanTimestamp() {
  final now = DateTime.now();
  return '${now.year}-'
      '${now.month.toString().padLeft(2, '0')}-'
      '${now.day.toString().padLeft(2, '0')} '
      '${now.hour.toString().padLeft(2, '0')}:'
      '${now.minute.toString().padLeft(2, '0')}:'
      '${now.second.toString().padLeft(2, '0')}';
}

// ─── File helpers ─────────────────────────────────────────────

/// Append a file with a header to [sink]. No-ops if file doesn't exist.
void _appendFile(String filePath, StringSink sink) {
  final f = File(filePath);
  if (!f.existsSync()) return;
  sink.writeln('FILE: $filePath');
  sink.writeln('------------------------------------------------------------');
  sink.writeln(f.readAsStringSync());
  sink.writeln('');
  sink.writeln('--- END FILE ---');
  sink.writeln('');
}

/// Collect all source files under [basePath] respecting ignore rules, sorted.
List<String> _collectSourceFiles(String basePath) {
  final dir = Directory(basePath);
  if (!dir.existsSync()) return [];

  return dir
      .listSync(recursive: true)
      .whereType<File>()
      .map((f) => f.path)
      .where((path) {
        final rel = p.relative(path, from: basePath);
        if (_isIgnoredDir(rel)) return false;
        // Check every path segment for ignored dirs
        final parts = p.split(p.dirname(rel));
        if (parts.any((part) => _ignoredDirs.contains(part))) return false;
        return _isIncludedFile(path);
      })
      .toList()
    ..sort();
}

/// Build an indented tree listing under [basePath] into [sink].
void _printTree(String basePath, StringSink sink) {
  final files = _collectSourceFiles(basePath);
  for (final file in files) {
    final rel = p.relative(file, from: basePath);
    sink.writeln(rel);
  }
}

// ─── Data model ───────────────────────────────────────────────

class _Package {
  _Package({required this.name, required this.path});
  final String name;
  final String path;
}

// ============================================================
// ENTRY POINT
// ============================================================

Future<void> main(List<String> args) async {
  final mode = args.isEmpty ? 'summary' : args[0];
  final arg2 = args.length > 1 ? args[1] : '';
  // final arg3 = args.length > 2 ? args[2] : '';

  if (mode == 'help' || mode == '--help' || mode == '-h') {
    _showHelp();
    return;
  }

  await _verifyMelos();

  final docsDir = Directory('.docs');
  docsDir.createSync(recursive: true);

  switch (mode) {
    case 'summary':
      await _modeSummary(docsDir.path);
    case 'files':
      if (arg2.isEmpty) {
        logError('Provide file pattern(s). Example: files pubspec.yaml');
      }
      await _modeFiles(docsDir.path, arg2);
    case 'folder':
      if (arg2.isEmpty) {
        logError(
          'Provide a folder path. Example: folder packages/core/lib/src',
        );
      }
      await _modeFolder(docsDir.path, arg2);
    case 'structure':
      await _modeStructure(docsDir.path, arg2);
    case 'deps':
      await _modeDeps(docsDir.path);
    case 'search':
      if (arg2.isEmpty) {
        logError('Provide a search pattern. Example: search Riverpod');
      }
      await _modeSearch(docsDir.path, arg2);
    case 'stats':
      await _modeStats(docsDir.path);
    case 'changes':
      final days = int.tryParse(arg2) ?? 7;
      await _modeChanges(docsDir.path, days);
    default:
      logWarn('Unknown mode: $mode');
      _showHelp();
      exit(1);
  }
}

// ============================================================
// MODE: summary
// ============================================================

Future<void> _modeSummary(String docsDir) async {
  final ts = _fileTimestamp();
  final outputPath = '$docsDir/summary_$ts.txt';
  final buf = StringBuffer();
  var totalPackages = 0;
  var totalFiles = 0;

  logSection('Full Monorepo Summary');
  logInfo('Output: $outputPath');

  buf.writeln('============================================================');
  buf.writeln(' FLUTTER + MELOS MONOREPO SUMMARY');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Generated At : ${_humanTimestamp()}');
  buf.writeln('Workspace    : ${Directory.current.path}');
  buf.writeln('');

  // Root config files
  buf.writeln('============================================================');
  buf.writeln(' ROOT CONFIG FILES');
  buf.writeln('============================================================');
  buf.writeln('');
  for (final f in [
    'melos.yaml',
    'pubspec.yaml',
    'analysis_options.yaml',
    'README.md',
  ]) {
    _appendFile(f, buf);
  }

  // Packages
  buf.writeln('============================================================');
  buf.writeln(' MELOS PACKAGES');
  buf.writeln('============================================================');
  buf.writeln('');

  final packages = await _getPackages();

  for (final pkg in packages) {
    totalPackages++;

    buf.writeln('============================================================');
    buf.writeln(' PACKAGE: ${pkg.name}');
    buf.writeln(' Path   : ${pkg.path}');
    buf.writeln('============================================================');
    buf.writeln('');

    for (final f in ['pubspec.yaml', 'analysis_options.yaml', 'README.md']) {
      _appendFile(p.join(pkg.path, f), buf);
    }

    buf.writeln('DIRECTORY STRUCTURE:');
    buf.writeln('------------------------------------------------------------');
    _printTree(pkg.path, buf);
    buf.writeln('');

    buf.writeln('SOURCE FILES:');
    buf.writeln('------------------------------------------------------------');
    buf.writeln('');

    for (final file in _collectSourceFiles(pkg.path)) {
      totalFiles++;
      _appendFile(file, buf);
    }
  }

  // Melos dependency graph
  buf.writeln('============================================================');
  buf.writeln(' MELOS DEPENDENCY GRAPH');
  buf.writeln('============================================================');
  buf.writeln('');
  final graphResult = await Process.run('melos', [
    'list',
    '--graph',
  ], runInShell: true);
  buf.writeln(graphResult.stdout.toString().trim());
  buf.writeln('');

  // Workspace scripts
  buf.writeln('============================================================');
  buf.writeln(' WORKSPACE SCRIPTS');
  buf.writeln('============================================================');
  buf.writeln('');
  final scriptsResult = await Process.run('melos', [
    'run',
    '--list',
  ], runInShell: true);
  buf.writeln(scriptsResult.stdout.toString().trim());
  buf.writeln('');

  buf.writeln('============================================================');
  buf.writeln(' SUMMARY');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Packages Found : $totalPackages');
  buf.writeln('Files Included : $totalFiles');
  buf.writeln('');

  File(outputPath).writeAsStringSync(buf.toString());
  logSuccess('Summary generated → $outputPath');
  logInfo('Packages: $totalPackages | Files: $totalFiles');
}

// ============================================================
// MODE: files
// ============================================================

Future<void> _modeFiles(String docsDir, String rawPatterns) async {
  final patterns = rawPatterns.split(',').map((s) => s.trim()).toList();
  final safeName = rawPatterns.replaceAll(RegExp(r'[/*,\s]'), '_');
  final ts = _fileTimestamp();
  final outputPath = '$docsDir/files_${safeName}_$ts.txt';
  final buf = StringBuffer();
  var totalFound = 0;
  var totalMissing = 0;

  logSection('Extract Files: $rawPatterns');
  logInfo('Output: $outputPath');

  buf.writeln('============================================================');
  buf.writeln(' FILE EXTRACTION: $rawPatterns');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Generated At : ${_humanTimestamp()}');
  buf.writeln('Workspace    : ${Directory.current.path}');
  buf.writeln('Pattern(s)   : $rawPatterns');
  buf.writeln('');

  final packages = await _getPackages();

  for (final pkg in packages) {
    buf.writeln('============================================================');
    buf.writeln(' PACKAGE: ${pkg.name} (${pkg.path})');
    buf.writeln('============================================================');
    buf.writeln('');

    var pkgFound = 0;

    for (final pattern in patterns) {
      if (pattern.contains('*') || pattern.contains('/')) {
        // Glob pattern — search recursively
        final basename = p.basename(pattern);
        final matches =
            Directory(pkg.path)
                .listSync(recursive: true)
                .whereType<File>()
                .where((f) {
                  if (_isIgnoredDir(p.relative(f.path, from: pkg.path))) {
                    return false;
                  }
                  return _matchGlob(basename, p.basename(f.path));
                })
                .map((f) => f.path)
                .toList()
              ..sort();

        if (matches.isNotEmpty) {
          buf.writeln('  [PATTERN: $pattern]');
          for (final m in matches) {
            _appendFile(m, buf);
            pkgFound++;
            totalFound++;
          }
        }
      } else {
        // Direct filename — search at root, lib/, lib/src/
        final searchDirs = [
          pkg.path,
          p.join(pkg.path, 'lib'),
          p.join(pkg.path, 'lib', 'src'),
        ];
        var foundAny = false;
        for (final dir in searchDirs) {
          final target = p.join(dir, pattern);
          if (File(target).existsSync()) {
            _appendFile(target, buf);
            pkgFound++;
            totalFound++;
            foundAny = true;
            break;
          }
        }
        if (!foundAny) {
          buf.writeln('  ⚠️  Not found: $pattern');
          buf.writeln('');
          totalMissing++;
        }
      }
    }

    if (pkgFound == 0) {
      buf.writeln('  (no matching files in this package)');
      buf.writeln('');
    }
  }

  buf.writeln('============================================================');
  buf.writeln(' SUMMARY');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Files Found   : $totalFound');
  buf.writeln('Not Found     : $totalMissing');
  buf.writeln('');

  File(outputPath).writeAsStringSync(buf.toString());
  logSuccess('File extraction complete → $outputPath');
  logInfo('Found: $totalFound | Not found: $totalMissing');
}

// Simple glob matching for single filename patterns (*, ?)
bool _matchGlob(String pattern, String name) {
  // Convert glob to regex: * → .*, ? → .
  final regex = RegExp(
    '^${pattern.replaceAll('.', r'\.').replaceAll('*', '.*').replaceAll('?', '.')}\$',
    caseSensitive: false,
  );
  return regex.hasMatch(name);
}

// ============================================================
// MODE: folder
// ============================================================

Future<void> _modeFolder(String docsDir, String targetFolder) async {
  if (!Directory(targetFolder).existsSync()) {
    logError('Folder not found: $targetFolder');
  }

  final safeName = targetFolder.replaceAll('/', '_');
  final ts = _fileTimestamp();
  final outputPath = '$docsDir/folder_${safeName}_$ts.txt';
  final buf = StringBuffer();
  var totalFiles = 0;

  logSection('Folder Summary: $targetFolder');
  logInfo('Output: $outputPath');

  buf.writeln('============================================================');
  buf.writeln(' FOLDER SUMMARY: $targetFolder');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Generated At : ${_humanTimestamp()}');
  buf.writeln('Workspace    : ${Directory.current.path}');
  buf.writeln('Folder       : $targetFolder');
  buf.writeln('');

  // Directory tree
  buf.writeln('============================================================');
  buf.writeln(' DIRECTORY STRUCTURE');
  buf.writeln('============================================================');
  buf.writeln('');
  _printTree(targetFolder, buf);
  buf.writeln('');

  // File size overview
  buf.writeln('============================================================');
  buf.writeln(' FILE SIZES');
  buf.writeln('============================================================');
  buf.writeln('');
  for (final file in _collectSourceFiles(targetFolder)) {
    final lines = File(file).readAsLinesSync().length;
    final rel = p.relative(file, from: targetFolder);
    buf.writeln('  ${lines.toString().padLeft(5)} lines  $rel');
  }
  buf.writeln('');

  // All source files
  buf.writeln('============================================================');
  buf.writeln(' SOURCE FILES');
  buf.writeln('============================================================');
  buf.writeln('');
  for (final file in _collectSourceFiles(targetFolder)) {
    totalFiles++;
    _appendFile(file, buf);
  }

  buf.writeln('============================================================');
  buf.writeln(' SUMMARY');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Folder       : $targetFolder');
  buf.writeln('Files Found  : $totalFiles');
  buf.writeln('');

  File(outputPath).writeAsStringSync(buf.toString());
  logSuccess('Folder summary generated → $outputPath');
  logInfo('Files included: $totalFiles');
}

// ============================================================
// MODE: structure
// ============================================================

Future<void> _modeStructure(String docsDir, String filterPath) async {
  final ts = _fileTimestamp();
  final outputPath = '$docsDir/structure_$ts.txt';
  final buf = StringBuffer();

  logSection('Directory Structure');
  logInfo('Output: $outputPath');

  buf.writeln('============================================================');
  buf.writeln(' MONOREPO DIRECTORY STRUCTURE');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Generated At : ${_humanTimestamp()}');
  buf.writeln('Workspace    : ${Directory.current.path}');
  if (filterPath.isNotEmpty) buf.writeln('Filter       : $filterPath');
  buf.writeln('');

  void printPkgStructure(String pkgPath, String pkgName) {
    buf.writeln('------------------------------------------------------------');
    buf.writeln(' $pkgName  ($pkgPath)');
    buf.writeln('------------------------------------------------------------');
    _printTree(pkgPath, buf);
    buf.writeln('');
  }

  if (filterPath.isNotEmpty) {
    if (!Directory(filterPath).existsSync()) {
      logError('Path not found: $filterPath');
    }
    printPkgStructure(filterPath, p.basename(filterPath));
  } else {
    final packages = await _getPackages();
    for (final pkg in packages) {
      printPkgStructure(pkg.path, pkg.name);
    }
  }

  File(outputPath).writeAsStringSync(buf.toString());
  logSuccess('Structure output → $outputPath');
}

// ============================================================
// MODE: deps
// ============================================================

Future<void> _modeDeps(String docsDir) async {
  final ts = _fileTimestamp();
  final outputPath = '$docsDir/deps_$ts.txt';
  final buf = StringBuffer();

  logSection('Dependency Map');
  logInfo('Output: $outputPath');

  buf.writeln('============================================================');
  buf.writeln(' MONOREPO DEPENDENCY MAP');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Generated At : ${_humanTimestamp()}');
  buf.writeln('Workspace    : ${Directory.current.path}');
  buf.writeln('');

  // Melos graph
  buf.writeln('============================================================');
  buf.writeln(' MELOS DEPENDENCY GRAPH');
  buf.writeln('============================================================');
  buf.writeln('');
  final graphResult = await Process.run('melos', [
    'list',
    '--graph',
  ], runInShell: true);
  buf.writeln(graphResult.stdout.toString().trim());
  buf.writeln('');

  // Per-package dep sections
  buf.writeln('============================================================');
  buf.writeln(' PUBSPEC.YAML — ALL PACKAGES');
  buf.writeln('============================================================');
  buf.writeln('');

  final packages = await _getPackages();

  for (final pkg in packages) {
    buf.writeln('──── ${pkg.name} ────');
    final pubspecFile = File(p.join(pkg.path, 'pubspec.yaml'));
    if (pubspecFile.existsSync()) {
      // Extract only dependency sections (mirrors the bash awk logic)
      final lines = pubspecFile.readAsLinesSync();
      var inDeps = false;
      for (final line in lines) {
        final trimmed = line.trimLeft();
        if (trimmed.startsWith('dependencies:') ||
            trimmed.startsWith('dev_dependencies:') ||
            trimmed.startsWith('dependency_overrides:')) {
          inDeps = true;
          buf.writeln(line);
          continue;
        }
        // A new top-level key (not indented) ends the section
        if (inDeps &&
            line.isNotEmpty &&
            !line.startsWith(' ') &&
            !line.startsWith('\t')) {
          inDeps = false;
        }
        if (inDeps) buf.writeln(line);
      }
    } else {
      buf.writeln('  (no pubspec.yaml)');
    }
    buf.writeln('');
  }

  File(outputPath).writeAsStringSync(buf.toString());
  logSuccess('Dependency map → $outputPath');
}

// ============================================================
// MODE: search
// ============================================================

Future<void> _modeSearch(String docsDir, String pattern) async {
  final safeName = pattern.replaceAll(RegExp(r'[ /*]'), '_');
  final ts = _fileTimestamp();
  final outputPath = '$docsDir/search_${safeName}_$ts.txt';
  final buf = StringBuffer();
  var totalMatches = 0;

  logSection('Search: $pattern');
  logInfo('Output: $outputPath');

  buf.writeln('============================================================');
  buf.writeln(' SEARCH RESULTS: $pattern');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Generated At : ${_humanTimestamp()}');
  buf.writeln('Workspace    : ${Directory.current.path}');
  buf.writeln('Pattern      : $pattern');
  buf.writeln('');

  RegExp searchRe;
  try {
    searchRe = RegExp(pattern, multiLine: true);
  } catch (_) {
    // Fall back to literal string match if pattern is not valid regex
    searchRe = RegExp(RegExp.escape(pattern), multiLine: true);
  }

  final packages = await _getPackages();

  for (final pkg in packages) {
    var pkgMatches = 0;
    final files = _collectSourceFiles(pkg.path);

    for (final filePath in files) {
      final content = File(filePath).readAsStringSync();
      final lines = content.split('\n');
      final matched = <String>[];

      for (var i = 0; i < lines.length; i++) {
        if (searchRe.hasMatch(lines[i])) {
          matched.add('    ${i + 1}: ${lines[i]}');
        }
      }

      if (matched.isEmpty) continue;

      if (pkgMatches == 0) {
        buf.writeln('──── ${pkg.name} ────');
        buf.writeln('');
      }

      buf.writeln('  FILE: $filePath (${matched.length} match(es))');
      for (final m in matched) {
        buf.writeln(m);
      }
      buf.writeln('');

      pkgMatches += matched.length;
      totalMatches += matched.length;
    }
  }

  buf.writeln('');
  buf.writeln('Total Matches: $totalMatches');

  File(outputPath).writeAsStringSync(buf.toString());
  logSuccess('Search complete → $outputPath');
  logInfo('Total matches: $totalMatches');
}

// ============================================================
// MODE: stats
// ============================================================

Future<void> _modeStats(String docsDir) async {
  final ts = _fileTimestamp();
  final outputPath = '$docsDir/stats_$ts.txt';
  final buf = StringBuffer();
  var grandFiles = 0;
  var grandLines = 0;

  logSection('Code Statistics');
  logInfo('Output: $outputPath');

  buf.writeln('============================================================');
  buf.writeln(' CODE STATISTICS');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Generated At : ${_humanTimestamp()}');
  buf.writeln('Workspace    : ${Directory.current.path}');
  buf.writeln('');
  buf.writeln(
    '${'Package'.padRight(30)} '
    '${'Dart Files'.padLeft(10)} '
    '${'Total Lines'.padLeft(12)} '
    '${'Blank Lines'.padLeft(12)}',
  );
  buf.writeln(
    '${'-------'.padRight(30)} '
    '${'----------'.padLeft(10)} '
    '${'-----------'.padLeft(12)} '
    '${'-----------'.padLeft(12)}',
  );

  final packages = await _getPackages();

  for (final pkg in packages) {
    final dartFiles = Directory(pkg.path)
        .listSync(recursive: true)
        .whereType<File>()
        .where((f) {
          final rel = p.relative(f.path, from: pkg.path);
          final parts = p.split(p.dirname(rel));
          if (parts.any((part) => _ignoredDirs.contains(part))) return false;
          return p.extension(f.path) == '.dart' && !_isIgnoredFile(f.path);
        })
        .toList();

    var totalLines = 0;
    var blankLines = 0;
    for (final f in dartFiles) {
      final lines = f.readAsLinesSync();
      totalLines += lines.length;
      blankLines += lines.where((l) => l.trim().isEmpty).length;
    }

    buf.writeln(
      '${pkg.name.padRight(30)} '
      '${dartFiles.length.toString().padLeft(10)} '
      '${totalLines.toString().padLeft(12)} '
      '${blankLines.toString().padLeft(12)}',
    );

    grandFiles += dartFiles.length;
    grandLines += totalLines;
  }

  buf.writeln('${'─' * 30} ${'─' * 10} ${'─' * 12}');
  buf.writeln(
    '${'TOTAL'.padRight(30)} '
    '${grandFiles.toString().padLeft(10)} '
    '${grandLines.toString().padLeft(12)}',
  );
  buf.writeln('');

  File(outputPath).writeAsStringSync(buf.toString());
  logSuccess('Stats generated → $outputPath');
}

// ============================================================
// MODE: changes
// ============================================================

Future<void> _modeChanges(String docsDir, int days) async {
  final ts = _fileTimestamp();
  final outputPath = '$docsDir/changes_${days}d_$ts.txt';
  final buf = StringBuffer();

  logSection('Recent Changes (last $days days)');
  logInfo('Output: $outputPath');

  // Verify git
  final gitCheck = await Process.run('git', [
    'rev-parse',
    '--git-dir',
  ], runInShell: true);
  if (gitCheck.exitCode != 0) {
    logError('Git is not available or this is not a git repository.');
  }

  buf.writeln('============================================================');
  buf.writeln(' RECENTLY CHANGED FILES (last $days days)');
  buf.writeln('============================================================');
  buf.writeln('');
  buf.writeln('Generated At : ${_humanTimestamp()}');
  buf.writeln('Workspace    : ${Directory.current.path}');
  buf.writeln('Range        : Last $days days');
  buf.writeln('');

  final since = DateTime.now().subtract(Duration(days: days));
  final sinceStr =
      '${since.year}-${since.month.toString().padLeft(2, '0')}-${since.day.toString().padLeft(2, '0')}';

  // Changed files list
  final logResult = await Process.run('git', [
    'log',
    '--since=$sinceStr',
    '--name-only',
    '--pretty=format:',
  ], runInShell: true);

  final changedFiles =
      logResult.stdout
          .toString()
          .split('\n')
          .map((l) => l.trim())
          .where((l) => l.isNotEmpty)
          .where((l) => RegExp(r'\.(dart|yaml|yml|json|arb|md)$').hasMatch(l))
          .where(
            (l) => !RegExp(r'\.g\.dart|\.freezed\.dart|\.gr\.dart').hasMatch(l),
          )
          .toSet()
          .toList()
        ..sort();

  buf.writeln('Changed Files:');
  buf.writeln('------------------------------------------------------------');
  for (final f in changedFiles) {
    buf.writeln(f);
  }
  buf.writeln('');
  buf.writeln('');

  // Git log summary
  buf.writeln('Git Log Summary:');
  buf.writeln('------------------------------------------------------------');
  final gitLog = await Process.run('git', [
    'log',
    '--since=$sinceStr',
    '--oneline',
    '--no-merges',
  ], runInShell: true);
  buf.writeln(gitLog.stdout.toString().trim());
  buf.writeln('');

  // Changed file contents
  buf.writeln('------------------------------------------------------------');
  buf.writeln('Changed File Contents:');
  buf.writeln('------------------------------------------------------------');
  buf.writeln('');
  for (final filePath in changedFiles) {
    if (File(filePath).existsSync()) {
      _appendFile(filePath, buf);
    }
  }

  File(outputPath).writeAsStringSync(buf.toString());
  logSuccess('Changes report → $outputPath');
}

// ============================================================
// HELP
// ============================================================

void _showHelp() {
  print('');
  print(
    '$_bold╔══════════════════════════════════════════════════════════════╗$_reset',
  );
  print(
    '$_bold║       Flutter + Melos Monorepo Toolkit  —  Help Reference   ║$_reset',
  );
  print(
    '$_bold╚══════════════════════════════════════════════════════════════╝$_reset',
  );
  print('');

  print('${_cyan}USAGE$_reset');
  print('  dart scripts/toolkit.dart [MODE] [ARG]');
  print('  Run from the monorepo root (same folder as melos.yaml).');
  print('');

  void section(
    String name,
    String desc,
    String output,
    List<String> examples, [
    String? notes,
  ]) {
    print('$_bold$_blue── $name ${'─' * (55 - name.length)}$_reset');
    print('  $desc');
    print('');
    print('  ${_yellow}Output:$_reset $output');
    print('');
    print('  Usage:');
    for (final e in examples) {
      print('    dart scripts/toolkit.dart $e');
    }
    if (notes != null) {
      print('');
      print('  $notes');
    }
    print('');
  }

  section(
    'summary',
    'Full monorepo dump for AI/LLM ingestion.\n'
        '  Includes: root configs, every package\'s pubspec + source files,\n'
        '  directory trees, Melos dependency graph, and workspace scripts.',
    '.docs/summary_<timestamp>.txt',
    ['summary', '           # summary is the default'],
  );

  section(
    'files <pattern(s)>',
    'Extract one or more specific files from every package and app.\n'
        '  Pass a single filename, a comma-separated list, or a glob pattern.',
    '.docs/files_<pattern>_<timestamp>.txt',
    [
      'files pubspec.yaml',
      'files "pubspec.yaml,analysis_options.yaml"',
      'files "README.md,CHANGELOG.md"',
      'files "*_repository.dart"   # glob',
      'files "*_provider.dart"',
    ],
    'Direct filenames are searched at package root, lib/, and lib/src/.\n'
        '  Glob patterns search the entire package tree.',
  );

  section(
    'folder <path>',
    'Deep-dive into one folder: tree + per-file line counts + all source.\n'
        '  Great for understanding a single feature or layer.',
    '.docs/folder_<path>_<timestamp>.txt',
    [
      'folder packages/core/lib/src',
      'folder packages/data/lib/src/repositories',
      'folder apps/mobile/lib/features/auth',
    ],
  );

  section(
    'structure [path]',
    'Directory tree of all packages, or one specific package/folder.\n'
        '  Generated files (*.g.dart, *.freezed.dart, etc.) are excluded.',
    '.docs/structure_<timestamp>.txt',
    [
      'structure              # all packages',
      'structure packages/core',
      'structure apps/mobile',
    ],
  );

  section(
    'deps',
    'Compact dependency overview across all packages.\n'
        '  Shows: Melos graph + dependency sections from every pubspec.yaml.',
    '.docs/deps_<timestamp>.txt',
    ['deps'],
  );

  section(
    'search <pattern>',
    'Search a text or regex pattern across every source file in every package.\n'
        '  Results are grouped by package with file paths and line numbers.',
    '.docs/search_<pattern>_<timestamp>.txt',
    [
      'search Riverpod',
      'search "class.*Repository"',
      r'search "TODO|FIXME|HACK"',
      'search ConsumerWidget',
      'search go_router',
    ],
    'Pattern is a Dart RegExp. Generated files are excluded.',
  );

  section(
    'stats',
    'Code size table: Dart file count, total lines, and blank lines per package.\n'
        '  Workspace totals are appended at the bottom.',
    '.docs/stats_<timestamp>.txt',
    ['stats'],
  );

  section(
    'changes [days]',
    'Git-based report of recently modified source files.\n'
        '  Includes: changed file list, git log summary, and full file contents.',
    '.docs/changes_<N>d_<timestamp>.txt',
    [
      'changes          # last 7 days (default)',
      'changes 3        # last 3 days',
      'changes 30       # last 30 days',
    ],
    'Requires git. Must have commits in the repository.',
  );

  print(
    '$_bold$_blue── General Notes ───────────────────────────────────────────────$_reset',
  );
  print(
    '  • All output files are written to $_yellow.docs/$_reset (created automatically).',
  );
  print(
    '  • Filenames include a timestamp so runs never overwrite each other.',
  );
  print('  • Generated files (*.g.dart, *.freezed.dart, *.gr.dart, etc.) are');
  print('    always excluded from output.');
  print('  • test/ and integration_test/ directories are excluded.');
  print('  • Melos must be installed: dart pub global activate melos');
  print('  • Run from the monorepo root (same directory as melos.yaml).');
  print('');

  print(
    '$_bold$_blue── Quick Reference ─────────────────────────────────────────────$_reset',
  );
  final rows = [
    ['summary', 'Whole repo dump  →  AI/LLM context'],
    ['files', 'Specific files   →  pubspec.yaml from all pkgs'],
    ['folder', 'Single folder    →  feature / layer deep-dive'],
    ['structure', 'Tree view        →  architecture overview'],
    ['deps', 'Dep map          →  version audit'],
    ['search', 'Pattern search   →  find usages / TODOs'],
    ['stats', 'Line counts      →  codebase size snapshot'],
    ['changes', 'Git diff window  →  PR / sprint summary'],
  ];
  for (final r in rows) {
    print('  $_cyan${r[0].padRight(10)}$_reset  ${r[1]}');
  }
  print('');
}
