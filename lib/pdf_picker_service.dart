import 'dart:io';
import 'package:file_picker/file_picker.dart';

class PDFPickerService {
  Future<File?> pickPDF() async {
    final result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf'],
    );
    if (result != null && result.files.isNotEmpty) {
      return File(result.files.single.path!);
    }
    return null;
  }
}
