import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:textara/domain/entities/idea_thread.dart';
import 'package:textara/presentation/providers/database_providers.dart';

/// True while the tablet threads screen is showing a thread beside the list.
final threadDetailPaneOpenProvider = StateProvider<bool>((ref) => false);

final ideaThreadsProvider = FutureProvider<List<IdeaThread>>((ref) async {
  return ref.watch(ideaThreadDaoProvider).getAllThreads();
});

final threadEvidenceProvider =
    FutureProvider.family<List<ThreadEvidence>, String>((ref, threadId) async {
      return ref.watch(ideaThreadDaoProvider).getEvidenceForThread(threadId);
    });
