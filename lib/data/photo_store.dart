import 'dart:io';

import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

import 'repository.dart';

/// Medicine photos live in the app's documents folder. Medicines store only the
/// file name, and this resolves it to a path on the current device.
class PhotoStore {
  PhotoStore._(this.dir);

  final Directory dir;

  static Future<PhotoStore> open() async {
    final docs = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(docs.path, 'photos'));
    await dir.create(recursive: true);
    return PhotoStore._(dir);
  }

  String path(String name) => p.join(dir.path, name);

  File? file(String? name) {
    if (name == null) return null;
    final f = File(path(name));
    return f.existsSync() ? f : null;
  }

  /// Copies a picked image into the store and returns its new file name.
  Future<String> add(String sourcePath) async {
    final ext = p.extension(sourcePath).isEmpty ? '.jpg' : p.extension(sourcePath);
    final name = '${newId()}$ext';
    await File(sourcePath).copy(path(name));
    return name;
  }

  Future<void> remove(String? name) async {
    final f = file(name);
    if (f != null) await f.delete();
  }
}
