import 'package:flutter/foundation.dart';

/// Completion triggers a fresh reminder query immediately, across route changes.
final maintenanceChanges = ValueNotifier<int>(0);
void notifyMaintenanceChanged() => maintenanceChanges.value++;
