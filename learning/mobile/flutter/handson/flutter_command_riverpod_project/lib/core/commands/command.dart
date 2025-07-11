import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../errors/failures.dart';
import '../utils/logger.dart';

/// Result wrapper for command execution
abstract class Result<T> {
  const Result();
  
  bool get isSuccess => this is Success<T>;
  bool get isFailure => this is Failure<T>;
  
  T? get data => isSuccess ? (this as Success<T>).data : null;
  AppFailure? get failure => isFailure ? (this as Failure<T>).failure : null;
}

class Success<T> extends Result<T> {
  final T data;
  const Success(this.data);
  
  @override
  String toString() => 'Success(data: $data)';
}

class Failure<T> extends Result<T> {
  final AppFailure failure;
  const Failure(this.failure);
  
  @override
  String toString() => 'Failure(failure: $failure)';
}

/// Command action type definitions
typedef CommandAction0<T> = Future<Result<T>> Function();
typedef CommandAction1<T, A> = Future<Result<T>> Function(A arg);
typedef CommandAction2<T, A, B> = Future<Result<T>> Function(A arg1, B arg2);

/// Base command class that integrates with Riverpod
abstract class Command<T> extends ChangeNotifier {
  Command({
    this.name,
    required this.ref,
  });
  
  final String? name;
  final Ref ref;
  
  bool _isExecuting = false;
  Result<T>? _result;
  
  /// Whether the command is currently executing
  bool get isExecuting => _isExecuting;
  
  /// Whether the command has completed successfully
  bool get isSuccess => _result?.isSuccess ?? false;
  
  /// Whether the command has failed
  bool get isFailure => _result?.isFailure ?? false;
  
  /// Whether the command has completed (success or failure)
  bool get isCompleted => _result != null;
  
  /// The result of the command execution
  Result<T>? get result => _result;
  
  /// The data if command succeeded
  T? get data => _result?.data;
  
  /// The failure if command failed
  AppFailure? get failure => _result?.failure;
  
  /// Clear the current result
  void clearResult() {
    _result = null;
    notifyListeners();
  }
  
  /// Execute the command
  Future<void> execute() async {
    // Prevent multiple executions
    if (_isExecuting) {
      AppLogger.logger.w('Command ${name ?? runtimeType} is already executing');
      return;
    }
    
    _isExecuting = true;
    _result = null;
    notifyListeners();
    
    try {
      AppLogger.logger.d('Executing command ${name ?? runtimeType}');
      
      final result = await performAction();
      _result = result;
      
      if (result.isSuccess) {
        AppLogger.logger.i('Command ${name ?? runtimeType} succeeded');
      } else {
        AppLogger.logger.e('Command ${name ?? runtimeType} failed: ${result.failure}');
      }
      
    } catch (error, stackTrace) {
      AppLogger.logger.e(
        'Command ${name ?? runtimeType} threw exception',
        error: error,
        stackTrace: stackTrace,
      );
      
      _result = Failure(AppFailure.unexpected(error.toString()));
    } finally {
      _isExecuting = false;
      notifyListeners();
    }
  }
  
  /// Override this method to implement command logic
  Future<Result<T>> performAction();
  
  @override
  void dispose() {
    AppLogger.logger.d('Disposing command ${name ?? runtimeType}');
    super.dispose();
  }
}

/// Command with no parameters
class Command0<T> extends Command<T> {
  Command0({
    super.name,
    required super.ref,
    required this.action,
  });
  
  final CommandAction0<T> action;
  
  @override
  Future<Result<T>> performAction() => action();
}

/// Command with one parameter
class Command1<T, A> extends Command<T> {
  Command1({
    super.name,
    required super.ref,
    required this.action,
  });
  
  final CommandAction1<T, A> action;
  A? _lastArg;
  
  Future<void> executeWith(A arg) async {
    _lastArg = arg;
    await execute();
  }
  
  @override
  Future<Result<T>> performAction() {
    if (_lastArg == null) {
      throw StateError('Command1 must be executed with executeWith(arg)');
    }
    return action(_lastArg as A);
  }
}

/// Command with two parameters
class Command2<T, A, B> extends Command<T> {
  Command2({
    super.name,
    required super.ref,
    required this.action,
  });
  
  final CommandAction2<T, A, B> action;
  A? _lastArg1;
  B? _lastArg2;
  
  Future<void> executeWith(A arg1, B arg2) async {
    _lastArg1 = arg1;
    _lastArg2 = arg2;
    await execute();
  }
  
  @override
  Future<Result<T>> performAction() {
    if (_lastArg1 == null || _lastArg2 == null) {
      throw StateError('Command2 must be executed with executeWith(arg1, arg2)');
    }
    return action(_lastArg1 as A, _lastArg2 as B);
  }
}

/// Extensions for easier result handling
extension ResultExtensions<T> on Result<T> {
  /// Execute different callbacks based on result
  R when<R>({
    required R Function(T data) success,
    required R Function(AppFailure failure) failure,
  }) {
    if (isSuccess) {
      return success(data!);
    } else {
      return failure(this.failure!);
    }
  }
  
  /// Execute different callbacks based on result (with void return)
  void whenOrNull({
    void Function(T data)? success,
    void Function(AppFailure failure)? failure,
  }) {
    if (isSuccess && success != null) {
      success(data!);
    } else if (isFailure && failure != null) {
      failure(this.failure!);
    }
  }
} 