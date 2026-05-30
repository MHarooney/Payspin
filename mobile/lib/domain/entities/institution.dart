class Institution {
  const Institution({
    required this.id,
    required this.name,
    required this.fullName,
  });

  final String id;
  final String name;
  final String fullName;
}

/// Result of starting an open-banking connection: the pending connection id
/// and the bank's authorisation URL the user must visit.
class BankConnectionStart {
  const BankConnectionStart({
    required this.connectionId,
    required this.authorisationUrl,
  });

  final String connectionId;
  final String authorisationUrl;
}
