import 'dart:io';
import 'package:syncfusion_flutter_pdf/pdf.dart';

class PDFTextExtractor {
  Future<String> extractText(File file) async {
    try {
      final bytes = await file.readAsBytes();
      final document = PdfDocument(inputBytes: bytes);

      // Use Syncfusion's utility to extract text from whole document
      final text = PdfTextExtractor(document).extractText();

      document.dispose();
      return text;
    } catch (e) {
      rethrow;
    }
  }
}
