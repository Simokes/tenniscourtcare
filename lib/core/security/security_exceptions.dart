class ValidationException implements Exception {
  final String message;
  const ValidationException(this.message);
  @override
  String toString() => message;
}

class UserNotFoundException implements Exception {
  const UserNotFoundException();
  @override
  String toString() => 'User not found';
}
