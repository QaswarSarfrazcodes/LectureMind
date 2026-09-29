/// Base failure class for LectureMind.
sealed class Failure {
  const Failure(this.message, [this.code]);
  final String message;
  final String? code;

  @override
  String toString() => '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'No internet connection available.', super.code]);
}

class AuthFailure extends Failure {
  const AuthFailure([super.message = 'Invalid or expired API key.', super.code = '401']);
}

class AssemblyAiFailure extends Failure {
  const AssemblyAiFailure(super.message, [super.code]);
}

class GroqFailure extends Failure {
  const GroqFailure(super.message, [super.code]);
}

class GeminiFailure extends Failure {
  const GeminiFailure(super.message, [super.code]);
}

class ParsingFailure extends Failure {
  const ParsingFailure([super.message = 'Failed to parse response schema.', super.code]);
}

class StorageFailure extends Failure {
  const StorageFailure([super.message = 'Failed to read or write local storage.', super.code]);
}

class AudioFailure extends Failure {
  const AudioFailure([super.message = 'Microphone or audio error.', super.code]);
}

/// Generic Result type: represents either Success<T> or Failure.
class Result<T, E extends Failure> {
  const Result._({this.data, this.failure, required this.isSuccess});

  final T? data;
  final E? failure;
  final bool isSuccess;

  bool get isFailure => !isSuccess;

  factory Result.success(T data) => Result._(data: data, isSuccess: true);
  factory Result.failure(E failure) => Result._(failure: failure, isSuccess: false);

  R fold<R>(R Function(E failure) onError, R Function(T data) onSuccess) {
    if (isSuccess) {
      return onSuccess(data as T);
    } else {
      return onError(failure as E);
    }
  }
}
