import 'package:farmestates_ai_dashbaord/screens/quality/quality_assurance_dashboard_redesigned.dart';
import 'package:farmestates_ai_dashbaord/screens/quality/quality_assurance_nav_screens.dart';
import 'package:farmestates_ai_dashbaord/screens/quality/quality_status.dart';
import 'package:farmestates_ai_dashbaord/screens/quality/quality_workflow_screen.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('quality screens compile with the shared status model', () {
    expect(const QualityAssuranceDashboardRedesigned(), isNotNull);
    expect(const QualityReportsScreen(), isNotNull);
    expect(
      const QualityWorkflowScreen(stage: QualityWorkflowStage.inspection),
      isNotNull,
    );
  });

  group('qualityRecordState', () {
    test('packaged batch without an inspection remains pending', () {
      final record = <String, dynamic>{
        'status': 'Packaged',
        'quality_status': 'Pending Inspection',
      };

      expect(
        qualityRecordState(record),
        QualityRecordState.pendingInspection,
      );
      expect(isPendingQualityInspection(record), isTrue);
    });

    test('finished inspection moves the batch out of pending', () {
      final record = <String, dynamic>{
        'status': 'Packaged',
        'quality_status': 'Inspected',
      };

      expect(qualityRecordState(record), QualityRecordState.inspected);
      expect(isPendingQualityInspection(record), isFalse);
      expect(qualityRecordLabel(record), 'Awaiting Approval');
    });

    test('approved and rejected decisions retain their QA state', () {
      expect(
        qualityRecordState(<String, dynamic>{
          'status': 'Sent to Sales',
          'quality_status': 'Approved',
        }),
        QualityRecordState.approved,
      );
      expect(
        qualityRecordState(<String, dynamic>{
          'status': 'Packaged',
          'quality_status': 'Rejected',
        }),
        QualityRecordState.rejected,
      );
    });

    test('legacy sent-to-sales records are treated as approved', () {
      expect(
        qualityRecordState(<String, dynamic>{
          'status': 'Sent to Sales',
          'quality_status': 'Pending Inspection',
        }),
        QualityRecordState.approved,
      );
    });
  });
}
