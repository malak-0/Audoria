import 'dart:convert';
import 'dart:io';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:file_picker/file_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:audoria/utils/ai_services/text_extraction.dart';

class FirestoreFileService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Upload file with text extraction
  Future<String> uploadFile({
    required PlatformFile file,
    required String parentUid,
    required List<String> children,
  }) async {
    if (file.bytes == null) {
      throw Exception('File bytes are null');
    }

    try {
      // Extract text from file
      String extractedText = '';
      final fileName = file.name.toLowerCase();

      // Get file type early (needed for debugging)
      final fileType = _getFileTypeFromFilename(file.name);

      // Create temporary file for text extraction
      final tempDir = await getTemporaryDirectory();
      final tempFile = File('${tempDir.path}/${file.name}');
      await tempFile.writeAsBytes(file.bytes!);

      try {
        if (fileName.endsWith('.pdf')) {
          extractedText = await TextExtractionService.extractTextFromPDF(
            tempFile,
          );
        } else if ([
          'jpg',
          'jpeg',
          'png',
          'gif',
        ].contains(fileName.split('.').last)) {
          extractedText = await TextExtractionService.extractTextFromImage(
            tempFile,
          );
        } else {
          try {
            extractedText = utf8.decode(file.bytes!);
          } catch (e) {
            extractedText = 'Text extraction not available for this file type';
          }
        }
      } catch (e) {
        extractedText = 'Text extraction failed: $e';
      }

      // Clean up temporary file
      await tempFile.delete();

      // Convert file bytes to base64 string
      final fileContentBase64 = base64Encode(file.bytes!);

      final title = _generateTitleFromFilename(file.name);

      final fileData = {
        'parentUid': parentUid,
        'children': children,
        'filename': file.name,
        'title': title,
        'fileType': fileType,
        'fileSize': file.size,
        'content': extractedText,
        'fileContent': fileContentBase64,
        'uploadDate': FieldValue.serverTimestamp(),
        'createdAt': FieldValue.serverTimestamp(),
      };

      final docRef = await _firestore.collection('files').add(fileData);
      return docRef.id;
    } catch (e) {
      rethrow;
    }
  }

  // Get files by parent UID
  Future<List<Map<String, dynamic>>> getFilesByParent(String parentUid) async {
    try {
      QuerySnapshot querySnapshot;

      // Try with orderBy first, fallback to without if index doesn't exist
      try {
        querySnapshot = await _firestore
            .collection('files')
            .where('parentUid', isEqualTo: parentUid)
            .orderBy('uploadDate', descending: true)
            .get();
      } catch (e) {
        querySnapshot = await _firestore
            .collection('files')
            .where('parentUid', isEqualTo: parentUid)
            .get();
      }

      final files = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      // Sort manually if orderBy wasn't used
      files.sort((a, b) {
        final aDate = a['uploadDate'] as Timestamp?;
        final bDate = b['uploadDate'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return files;
    } catch (e) {
      return [];
    }
  }

  // Get files for child (where child UID is in children array)
  Future<List<Map<String, dynamic>>> getFilesForChild(String childUid) async {
    try {
      QuerySnapshot querySnapshot;

      // Try with orderBy first, fallback to without if index doesn't exist
      try {
        querySnapshot = await _firestore
            .collection('files')
            .where('children', arrayContains: childUid)
            .orderBy('uploadDate', descending: true)
            .get();
      } catch (e) {
        querySnapshot = await _firestore
            .collection('files')
            .where('children', arrayContains: childUid)
            .get();
      }

      final files = querySnapshot.docs.map((doc) {
        final data = doc.data() as Map<String, dynamic>;
        return {'id': doc.id, ...data};
      }).toList();

      // Sort manually if orderBy wasn't used
      files.sort((a, b) {
        final aDate = a['uploadDate'] as Timestamp?;
        final bDate = b['uploadDate'] as Timestamp?;
        if (aDate == null && bDate == null) return 0;
        if (aDate == null) return 1;
        if (bDate == null) return -1;
        return bDate.compareTo(aDate);
      });

      return files;
    } catch (e) {
      return [];
    }
  }

  // Update file sharing (children array)
  Future<void> updateFileSharing(String fileId, List<String> children) async {
    await _firestore.collection('files').doc(fileId).update({
      'children': children,
    });
  }

  // Delete file
  Future<void> deleteFile(String fileId) async {
    await _firestore.collection('files').doc(fileId).delete();
  }

  // Helper methods
  String _getFileTypeFromFilename(String filename) {
    if (filename.isEmpty) return 'OTHER';

    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'PDF';
    if (['doc', 'docx'].contains(ext)) return 'DOC';
    if (['ppt', 'pptx'].contains(ext)) return 'PPT';
    if (ext == 'mp4') return 'MP4';
    if (ext == 'mp3') return 'MP3';
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return 'IMAGE';
    if (ext == 'txt') return 'TXT';
    return 'OTHER';
  }

  String _generateTitleFromFilename(String filename) {
    if (filename.isEmpty) return 'Untitled File';

    String nameWithoutExt = filename.split('.').first;
    nameWithoutExt = nameWithoutExt.replaceAll('_', ' ').replaceAll('-', ' ');

    List<String> words = nameWithoutExt.split(' ');
    words = words.map((word) {
      if (word.isEmpty) return word;
      return word[0].toUpperCase() + word.substring(1).toLowerCase();
    }).toList();

    return words.join(' ');
  }
}
