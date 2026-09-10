bool isCaretakerBatchComplete(
    Map<String, dynamic> batch, Iterable<Map<String, dynamic>> fulfillments) {
  String token(dynamic value) => value?.toString().trim().toLowerCase() ?? '';
  const complete = {'delivered', 'complete', 'completed'};
  if (['production_status', 'delivery_status', 'status']
      .any((key) => complete.contains(token(batch[key])))) return true;
  final references = [
    r'$id',
    'id',
    'batch_id',
    'batch_no',
    'batch_number',
    'batch_code'
  ].map((key) => token(batch[key])).where((value) => value.isNotEmpty).toSet();
  return fulfillments.any((item) {
    final linked = ['batch_id', 'batch_no', 'batch_number', 'batch_code']
        .any((key) => references.contains(token(item[key])));
    return linked &&
        (token(item['delivery_status']) == 'delivered' ||
            {'received', 'packaging', 'packaged', 'sent to sales', 'completed'}
                .contains(token(item['status'])));
  });
}
