Set<String> salesUserIdentity({
  String? id,
  String? email,
  String? name,
}) {
  return {id, email, name}
      .map((value) => (value ?? '').trim().toLowerCase())
      .where((value) => value.isNotEmpty)
      .toSet();
}

bool isSaleAssignedToIdentity(
  Map<String, dynamic> sale,
  Set<String> identity,
) {
  if (identity.isEmpty) return false;

  final assignedIdentity = {
    sale['sales_person_id'],
    sale['sales_person_email'],
    sale['sales_person_name'],
  }
      .map((value) => '${value ?? ''}'.trim().toLowerCase())
      .where((value) => value.isNotEmpty);

  final assignedValues = assignedIdentity.toList();
  if (assignedValues.isNotEmpty) {
    return assignedValues.any(identity.contains);
  }

  // Older records used created_by as the Sales Personnel owner.
  final legacyOwner = '${sale['created_by'] ?? ''}'.trim().toLowerCase();
  return legacyOwner.isNotEmpty && identity.contains(legacyOwner);
}
