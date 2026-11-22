import 'package:equatable/equatable.dart';

/// Typed failure for UI and repository boundaries.
///
/// Prefer mapping raw exceptions to [AppFailure] at service/repository edges
/// so screens can show recoverable messages instead of silent catches.
sealed class AppFailure extends Equatable {
  const AppFailure({required this.message, this.cause});

  final String message;
  final Object? cause;

  @override
  List<Object?> get props => [message, cause];
}

final class ImportFailure extends AppFailure {
  const ImportFailure({required super.message, super.cause, this.fileName});

  final String? fileName;

  @override
  List<Object?> get props => [...super.props, fileName];
}

final class BackupFailure extends AppFailure {
  const BackupFailure({required super.message, super.cause});
}

final class PersistenceFailure extends AppFailure {
  const PersistenceFailure({required super.message, super.cause});
}

final class ReaderFailure extends AppFailure {
  const ReaderFailure({required super.message, super.cause});
}

final class UnknownFailure extends AppFailure {
  const UnknownFailure({
    super.message = 'Something went wrong. Please try again.',
    super.cause,
  });
}

extension ObjectAsAppFailure on Object {
  AppFailure toAppFailure({String? fallback}) {
    if (this is AppFailure) return this as AppFailure;
    return UnknownFailure(
      message: fallback ?? 'Something went wrong. Please try again.',
      cause: this,
    );
  }
}
