class ApiException implements Exception {
  ApiException(this.statusCode, this.body);

  final int statusCode;
  final String body;

  @override
  String toString() => 'ApiException($statusCode)';
}

String apiErrorMessage(Object error) {
  if (error is ApiException) {
    if (error.statusCode == 0 && error.body == 'CONNECTION_TIMEOUT') {
      return 'Could not reach the server. Is the API running?';
    }
    if (error.statusCode == 0 && error.body == 'CONNECTION_REFUSED') {
      return 'Connection refused. Start the backend on port 3001.';
    }
    return 'Something went wrong (${error.statusCode})';
  }
  return 'Something went wrong';
}
