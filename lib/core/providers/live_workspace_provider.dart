import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../providers/auth_provider.dart';
import '../../services/superadmin_api_service.dart';

final approvalReviewerProvider =
    Provider((ref) => ref.watch(authProvider).user);

final liveWorkspaceApiProvider = Provider((ref) => SuperAdminApiService());
final caretakerCalendarProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final id = ref.watch(authProvider.select((state) => state.user?.id));
  if (id == null) return Future.value([]);
  return ref.watch(liveWorkspaceApiProvider).getCaretakerCalendar();
});
final approvalQueueProvider =
    FutureProvider.autoDispose<List<Map<String, dynamic>>>((ref) {
  final id = ref.watch(authProvider.select((state) => state.user?.id));
  if (id == null) return Future.value([]);
  return ref.watch(liveWorkspaceApiProvider).getApprovalQueue();
});
