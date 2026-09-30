/// LONE LINK — Result Type
///
/// A typed Result monad for explicit error handling without exceptions.
/// Inspired by Rust's Result<T, E> and Kotlin's Result.
library;

import 'package:lone_link/core/errors/failures.dart';

/// A value that is either a success [T] or a failure [LoneLinkFailure].
sealed class Result<T> {
  const Result();

  /// Creates a success result.
  const factory Result.success(T value) = Success<T>;

  /// Creates a failure result.
  const factory Result.failure(LoneLinkFailure failure) = Failure<T>;

  /// Returns true if this is a success.
  bool get isSuccess => this is Success<T>;

  /// Returns true if this is a failure.
  bool get isFailure => this is Failure<T>;

  /// Gets the success value or null.
  T? get valueOrNull => switch (this) {
        Success<T>(value: final v) => v,
        Failure<T>() => null,
      };

  /// Gets the failure or null.
  LoneLinkFailure? get failureOrNull => switch (this) {
        Success<T>() => null,
        Failure<T>(failure: final f) => f,
      };

  /// Gets the success value or throws the failure.
  T get valueOrThrow => switch (this) {
        Success<T>(value: final v) => v,
        Failure<T>(failure: final f) => throw f,
      };

  /// Maps the success value.
  Result<U> map<U>(U Function(T value) transform) => switch (this) {
        Success<T>(value: final v) => Result.success(transform(v)),
        Failure<T>(failure: final f) => Result.failure(f),
      };

  /// Flat maps the success value.
  Result<U> flatMap<U>(Result<U> Function(T value) transform) => switch (this) {
        Success<T>(value: final v) => transform(v),
        Failure<T>(failure: final f) => Result.failure(f),
      };

  /// Executes [onSuccess] or [onFailure] based on the result.
  R when<R>({
    required R Function(T value) success,
    required R Function(LoneLinkFailure failure) failure,
  }) =>
      switch (this) {
        Success<T>(value: final v) => success(v),
        Failure<T>(failure: final f) => failure(f),
      };

  /// Returns the value or a default.
  T getOrElse(T Function() defaultValue) => switch (this) {
        Success<T>(value: final v) => v,
        Failure<T>() => defaultValue(),
      };

  /// Returns the value or computes from the failure.
  T getOrHandle(T Function(LoneLinkFailure failure) handler) => switch (this) {
        Success<T>(value: final v) => v,
        Failure<T>(failure: final f) => handler(f),
      };
}

/// A successful result containing a value.
final class Success<T> extends Result<T> {
  final T value;
  const Success(this.value);

  @override
  String toString() => 'Success($value)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Success<T> && other.value == value);

  @override
  int get hashCode => value.hashCode;
}

/// A failed result containing a failure.
final class Failure<T> extends Result<T> {
  final LoneLinkFailure failure;
  const Failure(this.failure);

  @override
  String toString() => 'Failure($failure)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) || (other is Failure<T> && other.failure == failure);

  @override
  int get hashCode => failure.hashCode;
}

/// Extension to wrap async operations in a Result.
extension ResultCatch on Never {
  /// Wraps an async operation, catching exceptions and converting to Result.
  static Future<Result<T>> guardAsync<T>(Future<T> Function() operation) async {
    try {
      final value = await operation();
      return Result.success(value);
    } on LoneLinkFailure catch (e) {
      return Result.failure(e);
    } catch (e, st) {
      return Result.failure(
        DatabaseFailure(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }

  /// Wraps a synchronous operation in a Result.
  static Result<T> guard<T>(T Function() operation) {
    try {
      final value = operation();
      return Result.success(value);
    } on LoneLinkFailure catch (e) {
      return Result.failure(e);
    } catch (e, st) {
      return Result.failure(
        DatabaseFailure(message: e.toString(), cause: e, stackTrace: st),
      );
    }
  }
}
