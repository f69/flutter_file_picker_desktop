import 'dart:io';
import 'dart:typed_data';

import 'package:path/path.dart' as p;

import 'platform_file.dart';

Future<List<PlatformFile>> filePathsToPlatformFiles(
  List<String> filePaths,
  bool withReadStream,
  bool withData,
) {
  return Future.wait(
    filePaths
        .where((String filePath) => filePath.isNotEmpty)
        .map((String filePath) async {
      final file = File(filePath);

      if (withReadStream) {
        return createPlatformFile(file, null, file.openRead());
      }

      if (!withData) {
        return createPlatformFile(file, null, null);
      }

      final bytes = await file.readAsBytes();
      return createPlatformFile(file, bytes, null);
    }).toList(),
  );
}

Future<PlatformFile> createPlatformFile(
  File file,
  Uint8List? bytes,
  Stream<List<int>>? readStream,
) async {
  int? size;
  if (file.existsSync()) {
    size = await file.length();
  }
  return PlatformFile(
    bytes: bytes,
    name: p.basename(file.path),
    path: file.path,
    readStream: readStream,
    size: size,
  );
}

Future<String?> runExecutableWithArguments(
  String executable,
  List<String> arguments,
) async {
  final processResult = await Process.run(executable, arguments);
  final path = processResult.stdout?.toString().trim();
  if (processResult.exitCode != 0 || path == null || path.isEmpty) {
    return null;
  }
  return path;
}

Future<String> isExecutableOnPath(String executable) async {
  final path = await runExecutableWithArguments('which', [executable]);
  if (path == null) {
    throw Exception(
      'Couldn\'t find the executable $executable in the path.',
    );
  }
  return path;
}
