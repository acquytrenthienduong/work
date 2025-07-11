/// Base class for all application failures
abstract class AppFailure {
  const AppFailure(this.message);
  
  final String message;
  
  @override
  String toString() => message;
  
  // Factory constructors for common failure types
  factory AppFailure.network(String message) => NetworkFailure(message);
  factory AppFailure.server(String message) => ServerFailure(message);
  factory AppFailure.validation(String message) => ValidationFailure(message);
  factory AppFailure.unexpected(String message) => UnexpectedFailure(message);
  factory AppFailure.notFound(String message) => NotFoundFailure(message);
  factory AppFailure.unauthorized(String message) => UnauthorizedFailure(message);
}

/// Network-related failures
class NetworkFailure extends AppFailure {
  const NetworkFailure(super.message);
  
  @override
  String toString() => 'NetworkFailure: $message';
}

/// Server-related failures
class ServerFailure extends AppFailure {
  const ServerFailure(super.message);
  
  @override
  String toString() => 'ServerFailure: $message';
}

/// Validation failures
class ValidationFailure extends AppFailure {
  const ValidationFailure(super.message);
  
  @override
  String toString() => 'ValidationFailure: $message';
}

/// Unexpected failures
class UnexpectedFailure extends AppFailure {
  const UnexpectedFailure(super.message);
  
  @override
  String toString() => 'UnexpectedFailure: $message';
}

/// Not found failures
class NotFoundFailure extends AppFailure {
  const NotFoundFailure(super.message);
  
  @override
  String toString() => 'NotFoundFailure: $message';
}

/// Unauthorized failures
class UnauthorizedFailure extends AppFailure {
  const UnauthorizedFailure(super.message);
  
  @override
  String toString() => 'UnauthorizedFailure: $message';
}

/// Extension for common failure messages
extension AppFailureExtensions on AppFailure {
  /// Get user-friendly error message
  String get userMessage {
    switch (runtimeType) {
      case NetworkFailure:
        return 'Network connection error. Please check your internet connection.';
      case ServerFailure:
        return 'Server error. Please try again later.';
      case ValidationFailure:
        return message; // Validation messages are usually user-friendly
      case NotFoundFailure:
        return 'Requested resource not found.';
      case UnauthorizedFailure:
        return 'Authentication required. Please log in again.';
      default:
        return 'An unexpected error occurred. Please try again.';
    }
  }
} 