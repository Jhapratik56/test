import 'dart:io';
import 'package:google_ml_kit/google_ml_kit.dart';

class TextRecognitionService {
  Future<String> recognizeTextFromImage(File image) async {
    final inputImage = InputImage.fromFile(image);
    final textRecognizer = GoogleMlKit.vision.textRecognizer();
    final RecognizedText recognizedText = await textRecognizer.processImage(inputImage);
    await textRecognizer.close();

    return recognizedText.text;
  }
}
