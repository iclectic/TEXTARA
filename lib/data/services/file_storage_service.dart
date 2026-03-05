import 'dart:io';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as p;

class FileStorageService {
  static final FileStorageService _instance = FileStorageService._internal();
  factory FileStorageService() => _instance;
  FileStorageService._internal();

  Future<Directory> get _booksDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'books'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> get _coversDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'covers'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<Directory> get _exportDir async {
    final appDir = await getApplicationDocumentsDirectory();
    final dir = Directory(p.join(appDir.path, 'exports'));
    if (!await dir.exists()) {
      await dir.create(recursive: true);
    }
    return dir;
  }

  Future<String> copyBookToLibrary(String sourcePath, String bookId) async {
    final dir = await _booksDir;
    final ext = p.extension(sourcePath);
    final destPath = p.join(dir.path, '$bookId$ext');
    final sourceFile = File(sourcePath);
    if (!await sourceFile.exists()) {
      throw FileSystemException('Source file not found', sourcePath);
    }
    await sourceFile.copy(destPath);
    return destPath;
  }

  Future<String> saveCoverImage(
      List<int> imageBytes, String bookId) async {
    final dir = await _coversDir;
    final destPath = p.join(dir.path, '$bookId.jpg');
    final file = File(destPath);
    await file.writeAsBytes(imageBytes);
    return destPath;
  }

  Future<void> deleteBookFile(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<void> deleteCoverFile(String? coverPath) async {
    if (coverPath == null) return;
    final file = File(coverPath);
    if (await file.exists()) {
      await file.delete();
    }
  }

  Future<String> getExportPath(String fileName) async {
    final dir = await _exportDir;
    return p.join(dir.path, fileName);
  }

  Future<int> getFileSize(String filePath) async {
    final file = File(filePath);
    if (await file.exists()) {
      return await file.length();
    }
    return 0;
  }

  Future<bool> fileExists(String filePath) async {
    return File(filePath).exists();
  }

  Future<String> get booksDirectoryPath async {
    final dir = await _booksDir;
    return dir.path;
  }
}
