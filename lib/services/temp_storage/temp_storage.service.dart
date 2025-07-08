import 'dart:async';
import 'dart:io';

import 'package:path/path.dart' as path;
import 'package:path_provider/path_provider.dart';
import 'package:synchronized/synchronized.dart';
import 'package:uuid/uuid.dart';
import 'package:wp_player/services/temp_storage/temp_storage.service.interface.dart';
import 'package:wp_player/utils/logger/logger.dart';

/// Singleton
class TempStorageService implements ITempStorageService {
  static TempStorageService? _instance;
  static final Lock _constructionLock = Lock();

  TempStorageService._internal();
  TempStorageService._internalDeserialize({required this.tempDir});

  final Completer<void> _prepareCompleter = Completer<void>();
  late final Directory tempDir;

  /// Should be called in only one isolate - cause has side effect that would conflict with other instances
  static Future<TempStorageService> get instanceForMainIsolate async {
    await _constructionLock.synchronized(() async {
      if (_instance != null) return;
      _instance = TempStorageService._internal();
      unawaited(Future(_instance!._prepareTempService));
      await _instance!._ensureIsPrepared(); // To not block cleaning side effect
    });
    return _instance!;
  }

  // ---------------------------------------------------

  String serializeForIsolate() {
    return tempDir.path;
  }

  factory TempStorageService.deserializeForIsolate(String data) {
    final tempDir = Directory(data);
    if (!tempDir.existsSync()) {
      throw StateError(
        "[TempStorageService]: Incoherent state - deserialize failed cause directory wasn't made / or already deleted",
      );
    }
    return TempStorageService._internalDeserialize(tempDir: tempDir);
  }
  // ---------------------------------------------------

  Future<void> _prepareTempService() async {
    Directory tempSuperDir;
    Directory tempProgramDir;
    String tempDirName;

    try {
      tempSuperDir = await getTemporaryDirectory();

      // Create app-specific subdirectory to avoid conflicts on platforms where temp dirs are shared (e.g. Windows)
      // Changing this name may require updating setup/config/installer scripts that reference it
      tempProgramDir = await Directory(path.join(tempSuperDir.path, 'Wavepaths')).create();

      // session sub dir
      tempDirName = (const Uuid()).v4();
      tempDir = await Directory(path.join(tempProgramDir.path, tempDirName)).create();
      _prepareCompleter.complete();
    } catch (_) {
      _prepareCompleter.completeError(const FileSystemException("TempStorageService: failed to prepare temp folder"));
      return;
    }

    // clean old (runs in background)
    final toDelete =
        await tempProgramDir
            .list()
            .where((entry) => entry is! Directory || path.basename(entry.path) != tempDirName)
            .map((entry) => entry.delete(recursive: true))
            .toList();
    try {
      await Future.wait(toDelete);
    } catch (e) {
      logConsole.f("[TempStorageService]: failed to clean old data, error: $e");
    }
  }

  Future<void> _ensureIsPrepared() async => await _prepareCompleter.future;

  // ---------------------------------------------------

  @override
  Future<String> writeFileToTempDir(List<int> data, {required String fileName}) async {
    final file = File(path.join(tempDir.path, fileName));

    await file.writeAsBytes(data);
    return file.path;
  }
}
