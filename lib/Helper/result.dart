class Result<T> {
  final T? value;
  final String? message;

  Result.success(this.value) : message = null;
  Result.failure(this.message) : value = null;

  bool get isSuccess => message == null;
}