const farmTeamAssignmentKeys = <String, List<String>>{
  'Farm Owner': ['ownerID', 'owner_id', 'ownerId'],
  'Farm Manager': [
    'farm_manager_id',
    'farmManagerId',
    'farmManagerID',
    'farm_manager',
    'farmManager',
    'farm_manager_email',
    'farmManagerEmail',
    'farm_manager_name',
    'farmManagerName',
    'assigned_manager_id',
    'assignedManagerId',
    'assignedManagerID',
    'assignedManagers',
    'manager_ids',
    'managerIds',
    'managerIDs',
  ],
  'Caretaker': ['caretaker_ids', 'caretakerID', 'caretaker_id', 'caretakerId'],
  'Technician': ['technician_id', 'technicianID', 'technicianId'],
};

String assignmentToken(dynamic value) =>
    value?.toString().trim().toLowerCase().replaceAll(RegExp(r'\s+'), ' ') ??
    '';

Set<String> assignmentReferences(dynamic value) {
  if (value is Iterable) {
    return value.expand(assignmentReferences).toSet();
  }
  if (value is Map) {
    return [r'$id', 'id', 'user_id', 'email', 'name']
        .expand((key) => assignmentReferences(value[key]))
        .toSet();
  }
  final token = assignmentToken(value);
  return token.isEmpty || token == 'unassigned' || token == 'system'
      ? <String>{}
      : {token};
}

bool isManagerTeamFarm(
  Map<String, dynamic> farm, {
  required Map<String, dynamic>? manager,
  required List<Map<String, dynamic>> users,
}) {
  if (manager == null) return false;
  final identities = assignmentReferences(manager);
  if (identities.isEmpty) return false;
  for (final user in users) {
    final aliases = assignmentReferences(user);
    if (aliases.intersection(identities).isNotEmpty) identities.addAll(aliases);
  }
  final assigned = farmTeamAssignmentKeys['Farm Manager']!
      .expand((key) => assignmentReferences(farm[key]))
      .toSet();
  if (assigned.isNotEmpty) return assigned.intersection(identities).isNotEmpty;
  // Legacy accounts may carry their farm assignment on the user document.
  final farmIds = [r'$id', 'id', 'farmID', 'farm_id', 'farmId']
      .expand((key) => assignmentReferences(farm[key]))
      .toSet();
  return farmIds
      .intersection(assignmentReferences(manager['farmID']))
      .isNotEmpty;
}

/// New lists use IDs; older farms retain their single assignment.
List<String> farmCaretakerIds(Map<String, dynamic> farm) {
  final raw = farm['caretaker_ids'];
  final values = raw is List && raw.isNotEmpty
      ? raw
      : [
          farm['caretakerID'] ??
              farm['caretaker_id'] ??
              farm['caretakerId'] ??
              farm['careTakerID']
        ];
  return values
      .where((v) => v != null)
      .map((v) => v.toString().trim())
      .where((v) => v.isNotEmpty && v.toLowerCase() != 'unassigned')
      .toSet()
      .toList();
}

bool isAssignedFarmCaretaker(Map<String, dynamic> farm,
    {required String id, required String email}) {
  final identities = {id.trim().toLowerCase(), email.trim().toLowerCase()}
    ..remove('');
  return farmCaretakerIds(farm)
      .any((value) => identities.contains(value.toLowerCase()));
}
