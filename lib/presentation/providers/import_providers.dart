import 'package:flutter_riverpod/flutter_riverpod.dart';

final importProgressProvider =
    StateNotifierProvider<ImportProgressNotifier, ImportProgress>((ref) {
      return ImportProgressNotifier();
    });

class ImportProgress {
  final bool isImporting;
  final int total;
  final int completed;
  final String? currentFileName;

  const ImportProgress({
    this.isImporting = false,
    this.total = 0,
    this.completed = 0,
    this.currentFileName,
  });

  double get progress => total > 0 ? completed / total : 0;
}

class ImportProgressNotifier extends StateNotifier<ImportProgress> {
  ImportProgressNotifier() : super(const ImportProgress());

  void startImport(int total) {
    state = ImportProgress(isImporting: true, total: total);
  }

  void updateProgress(int completed, String? fileName) {
    state = ImportProgress(
      isImporting: true,
      total: state.total,
      completed: completed,
      currentFileName: fileName,
    );
  }

  void completeImport() {
    state = const ImportProgress();
  }
}
