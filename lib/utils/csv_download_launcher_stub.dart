import 'dart:convert';
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';

Future<bool> downloadCsvFile({
  required String fileName,
  required String csv,
}) async {
  final bytes = Uint8List.fromList(utf8.encode(csv));
  final path = await FilePicker.platform.saveFile(
    dialogTitle: 'Download report',
    fileName: fileName,
    type: FileType.custom,
    allowedExtensions: const ['csv'],
    bytes: bytes,
  );
  return path != null;
}
