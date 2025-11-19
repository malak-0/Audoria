import 'dart:io';
import 'dart:typed_data';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdfx/pdfx.dart';

class TextExtractionService {

  static Future<String> extractTextFromImage(File imageFile) async {
    try {
      if (!await imageFile.exists()) {
        throw Exception('Image file does not exist: ${imageFile.path}');
      }
      
      final inputImage = InputImage.fromFile(imageFile);
      final recognizer = TextRecognizer(script: TextRecognitionScript.latin);
      final result = await recognizer.processImage(inputImage);
      final extractedText = result.text;
      await recognizer.close();
      
      print('Image text extraction: ${extractedText.length} characters extracted');
      if (extractedText.isEmpty) {
        print('WARNING: Text extraction returned empty string');
      }
      
      return extractedText;
    } catch (e, stackTrace) {
      print('ERROR in extractTextFromImage: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }

  static Future<String> extractTextFromImageBytes(Uint8List imageBytes) async {
    final tempDir = await getTemporaryDirectory();
    final tempFile = File('${tempDir.path}/temp_image_${DateTime.now().millisecondsSinceEpoch}.png');
    await tempFile.writeAsBytes(imageBytes);
    
    try {
      final text = await extractTextFromImage(tempFile);
      return text;
    } finally {
      // Clean up temp file
      if (await tempFile.exists()) {
        await tempFile.delete();
      }
    }
  }

  static Future<String> extractTextFromPDF(File pdfFile) async {
    final bytes = await pdfFile.readAsBytes();
    return await extractTextFromPDFBytes(bytes);
  }

  static Future<String> extractTextFromPDFBytes(Uint8List pdfBytes) async {
    try {
      final doc = await PdfDocument.openData(pdfBytes);
      final tempDir = await getTemporaryDirectory();
      final textBuffer = StringBuffer();

      print('PDF has ${doc.pagesCount} pages');

      for (int i = 1; i <= doc.pagesCount; i++) {
        try {
          print('Processing page $i of ${doc.pagesCount}...');
          final page = await doc.getPage(i);
          final image = await page.render(
            width: page.width,
            height: page.height,
            format: PdfPageImageFormat.png,
          );
          
          if (image == null) {
            print('WARNING: Page $i rendered as null');
            await page.close();
            continue;
          }
          
          final imageBytes = image.bytes;
          final file = File('${tempDir.path}/page_$i.png');
          await file.writeAsBytes(imageBytes);

          final text = await extractTextFromImage(file);
          print('Page $i extracted ${text.length} characters');
          textBuffer.writeln('--- Page $i ---\n$text\n');
          await page.close();
          
          // Clean up page image file
          if (await file.exists()) {
            await file.delete();
          }
        } catch (e) {
          print('Error processing page $i: $e');
          // Continue with next page
        }
      }

      await doc.close();
      final result = textBuffer.toString();
      print('Total extracted text length: ${result.length}');
      return result;
    } catch (e, stackTrace) {
      print('ERROR in extractTextFromPDFBytes: $e');
      print('Stack trace: $stackTrace');
      rethrow;
    }
  }
}
