import '../exceptions/app_exception.dart';

class AppResult<T> {
  final T? data;
  final AppException? error;
  final bool isSuccess;

  AppResult({
    required this.data,
    required this.error,
    required this.isSuccess,
  });

  factory AppResult.success(T data) {
    return AppResult(
      data: data,
      error: null,
      isSuccess: true,
    );
  }

  factory AppResult.failure(AppException error) {
    return AppResult(
      data: null,
      error: error,
      isSuccess: false,
    );
  }

  R when<R>({
    required R Function(T data) onSuccess,
    required R Function(AppException error) onFailure,
  }) {
    if (isSuccess && data != null) {
      return onSuccess(data as T);
    } else {
      return onFailure(error!);
    }
  }

  Future<R> whenAsync<R>({
    required Future<R> Function(T data) onSuccess,
    required Future<R> Function(AppException error) onFailure,
  }) async {
    if (isSuccess && data != null) {
      return await onSuccess(data as T);
    } else {
      return await onFailure(error!);
    }
  }
}
