/// Exception thrown by repository implementations
/// when a Firestore write operation fails.
class RepositoryException implements Exception {
  const RepositoryException(this.message, {this.cause});

  final String message;
  final Object? cause;

  @override
  String toString() =>
      'RepositoryException: $message'
      '${cause != null ? ' (cause: $cause)' : ''}';
}
