import 'package:flutter_test/flutter_test.dart';
import '../../../lib/core/utils/caretaker_batch_status.dart';

void main() {
  const batch = {
    'id': 'internal-1',
    'batch_no': 'B-001',
    'production_status': 'Harvested'
  };
  test('harvesting alone and pending deliveries remain open', () {
    expect(isCaretakerBatchComplete(batch, []), isFalse);
    expect(
        isCaretakerBatchComplete(batch, [
          {'batch_number': 'B-001', 'status': 'Scheduled'}
        ]),
        isFalse);
    expect(
        isCaretakerBatchComplete(batch, [
          {'batch_number': 'OTHER', 'status': 'Received'}
        ]),
        isFalse);
  });
  test('receipt and later fulfillment stages close caretaker work', () {
    for (final status in [
      'Received',
      'Packaging',
      'Packaged',
      'Sent to Sales',
      'Completed'
    ]) {
      expect(
          isCaretakerBatchComplete(batch, [
            {'batch_number': ' b-001 ', 'status': status}
          ]),
          isTrue);
    }
    expect(
        isCaretakerBatchComplete(batch, [
          {'batch_id': 'internal-1', 'delivery_status': 'Delivered'}
        ]),
        isTrue);
  });
  test('delivered and completed batch statuses are closed', () {
    for (final status in ['Delivered', 'Completed', 'Complete']) {
      expect(
          isCaretakerBatchComplete({...batch, 'production_status': status}, []),
          isTrue);
    }
    expect(
        isCaretakerBatchComplete({}, [
          {'status': 'Received'}
        ]),
        isFalse);
  });
}
