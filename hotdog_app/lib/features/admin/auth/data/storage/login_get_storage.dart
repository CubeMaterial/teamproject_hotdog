import 'dart:io';

import 'package:get_storage/get_storage.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';

import 'login_storage_keys.dart';

class LoginGetStorage {
  LoginGetStorage({GetStorage? storage}) {
    _registerLoginPathProvider();
    _storage =
        storage ?? GetStorage(LoginStorageKeys.container, _defaultStoragePath);
    _initStorage = _storage.initStorage;
  }

  static String get _defaultStoragePath {
    final home =
        Platform.environment['HOME'] ??
        Platform.environment['USERPROFILE'] ??
        Directory.systemTemp.path;

    return '$home${Platform.pathSeparator}.hotdog_app';
  }

  late final GetStorage _storage;
  late final Future<bool> _initStorage;

  static void _registerLoginPathProvider() {
    Directory(_defaultStoragePath).createSync(recursive: true);
    PathProviderPlatform.instance = _LoginPathProvider(_defaultStoragePath);
  }

  Future<T?> read<T>(String key) async {
    await _initStorage;
    return _storage.read<T>(key);
  }

  Future<void> write(String key, Object? value) async {
    await _initStorage;
    return _storage.write(key, value);
  }

  Future<void> remove(String key) async {
    await _initStorage;
    return _storage.remove(key);
  }
}

class _LoginPathProvider extends PathProviderPlatform {
  _LoginPathProvider(this.storagePath);

  final String storagePath;

  @override
  Future<String?> getTemporaryPath() async => storagePath;

  @override
  Future<String?> getApplicationSupportPath() async => storagePath;

  @override
  Future<String?> getLibraryPath() async => storagePath;

  @override
  Future<String?> getApplicationDocumentsPath() async => storagePath;

  @override
  Future<String?> getApplicationCachePath() async => storagePath;

  @override
  Future<String?> getDownloadsPath() async => storagePath;
}
