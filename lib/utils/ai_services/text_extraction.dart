import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class TextExtractionService {

  static Future<String> extractTextFromImage(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
    final result = await recognizer.processImage(inputImage);
    await recognizer.close();
    return result.text;
  }

  static Future<String> extractTextFromPDF(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    final doc = await PdfDocument.openData(bytes);
    final tempDir = await getTemporaryDirectory();
    final textBuffer = StringBuffer();

    for (int i = 1; i <= doc.pagesCount; i++) {
      final page = await doc.getPage(i);
      final image = await page.render(
        width: page.width,
        height: page.height,
        format: PdfPageImageFormat.png,
      );
      final imageBytes = image!.bytes;
      final file = File('${tempDir.path}/page_$i.png');
      await file.writeAsBytes(imageBytes);

      final text = await extractTextFromImage(file);
      textBuffer.writeln('--- Page $i ---\n$text\n');
      await page.close();
    }

    await doc.close();
    return textBuffer.toString();
  }
}
