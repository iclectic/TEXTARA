import 'package:flutter_riverpod/flutter_riverpod.dart';

enum ImportJobFileStatus { pending, importing, success, failed, skipped }

class ImportJobFile {
  final String path;
  final String fileName;
  final ImportJobFileStatus status;
  final String? message;

  const ImportJobFile({
    required this.path,
    required this.fileName,
    this.status = ImportJobFileStatus.pending,
    this.message,
  });

  ImportJobFile copyWith({ImportJobFileStatus? status, String? message}) {
    return ImportJobFile(
      path: path,
      fileName: fileName,
      status: status ?? this.status,
      message: message ?? this.message,
    );
  }
}

class ImportProgress {
  final bool isImporting;
  final int total;
  final int completed;
  final String? currentFileName;
  final bool cancelled;
  final List<ImportJobFile> files;

  const ImportProgress({
    this.isImporting = false,
    this.total = 0,
    this.completed = 0,
    this.currentFileName,
    this.cancelled = false,
    this.files = const [],
  });

  double get progress => total > 0 ? completed / total : 0;
}

final importProgressProvider =
    StateNotifierProvider<ImportProgressNotifier, ImportProgress>((ref) {
      return ImportProgressNotifier();
    });

class ImportProgressNotifier extends StateNotifier<ImportProgress> {
  ImportProgressNotifier() : super(const ImportProgress());

  void startImport(List<ImportJobFile> files) {
    state = ImportProgress(
      isImporting: true,
      total: files.length,
      files: files,
    );
  }

  void updateFile(int index, ImportJobFile file) {
    if (index < 0 || index >= state.files.length) return;
    final files = [...state.files];
    files[index] = file;
    state = ImportProgress(
      isImporting: true,
      total: state.total,
      completed: state.completed,
      currentFileName: file.fileName,
      cancelled: state.cancelled,
      files: files,
    );
  }

  void updateProgress(int completed, String? fileName) {
    state = ImportProgress(
      isImporting: true,
      total: state.total,
      completed: completed,
      currentFileName: fileName,
      cancelled: state.cancelled,
      files: state.files,
    );
  }

  void requestCancel() {
    state = ImportProgress(
      isImporting: state.isImporting,
      total: state.total,
      completed: state.completed,
      currentFileName: state.currentFileName,
      cancelled: true,
      files: state.files,
    );
  }

  bool get isCancelled => state.cancelled;

  void completeImport() {
    state = const ImportProgress();
  }
}
