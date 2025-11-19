import 'package:cloud_firestore/cloud_firestore.dart';

class LessonFile {
  final String id;
  final String title;
  final String filename;
  final String fileType;
  final int fileSize;
  final String firebaseUid;
  final List<String> sharedWith;
  final DateTime uploadDate;
  final String? fileUrl;
  final String? content; // Extracted text content
  final String? fileContent; // Base64 encoded file content

  LessonFile({
    required this.id,
    required this.title,
    required this.filename,
    required this.fileType,
    required this.fileSize,
    required this.firebaseUid,
    required this.sharedWith,
    required this.uploadDate,
    this.fileUrl,
    this.content,
    this.fileContent,
  });

  factory LessonFile.fromFirestore(Map<String, dynamic> data) {
    print('Creating LessonFile from Firestore data...');
    print('Raw data keys: ${data.keys.toList()}');

    final String filename = data['filename'] ?? 'Unknown File';
    print('Filename: $filename');

    String title = data['title'] ?? _generateTitleFromFilename(filename);
    print('Title: $title');

    String fileType = data['fileType'] ?? _getFileTypeFromFilename(filename);
    print('File type: $fileType');

    DateTime uploadDate;
    if (data['uploadDate'] != null) {
      final timestamp = data['uploadDate'];
      if (timestamp is Timestamp) {
        uploadDate = timestamp.toDate();
      } else {
        uploadDate = DateTime.now();
      }
      print('Upload date: $uploadDate');
    } else {
      uploadDate = DateTime.now();
      print('Using current date for upload date');
    }

    List<String> sharedWith = [];
    if (data['children'] != null) {
      if (data['children'] is String) {
        sharedWith = [data['children']];
      } else if (data['children'] is List) {
        sharedWith = List<String>.from(data['children']);
      }
    }
    print('Shared with: $sharedWith');

    final lesson = LessonFile(
      id: data['id'] ?? '',
      title: title,
      filename: filename,
      fileType: fileType,
      fileSize: data['fileSize'] ?? 0,
      firebaseUid: data['parentUid'] ?? '',
      sharedWith: sharedWith,
      uploadDate: uploadDate,
      content: data['content'],
      fileContent: data['fileContent'],
    );

    print('Created LessonFile: ${lesson.title} (ID: ${lesson.id})');
    return lesson;
  }

  static String _generateTitleFromFilename(String filename) {
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

  static String _getFileTypeFromFilename(String filename) {
    if (filename.isEmpty) return 'OTHER';

    final ext = filename.split('.').last.toLowerCase();
    if (ext == 'pdf') return 'PDF';
    if (['doc', 'docx'].contains(ext)) return 'DOC';
    if (['ppt', 'pptx'].contains(ext)) return 'PPT';
    if (ext == 'mp4') return 'MP4';
    if (ext == 'mp3') return 'MP3';
    if (['jpg', 'jpeg', 'png', 'gif'].contains(ext)) return 'IMAGE';
    return 'OTHER';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'title': title,
      'filename': filename,
      'type': fileType,
      'size': formattedFileSize,
      'date': formattedUploadDate,
      'sharedWith': sharedWith,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) return '$fileSize B';
    if (fileSize < 1048576) return '${(fileSize / 1024).toStringAsFixed(1)} KB';
    return '${(fileSize / 1048576).toStringAsFixed(1)} MB';
  }

  String get formattedUploadDate {
    return '${uploadDate.day}/${uploadDate.month}/${uploadDate.year}';
  }

  // Add this to your LessonFile class
  LessonFile copyWith({
    String? id,
    String? title,
    String? filename,
    String? fileType,
    int? fileSize,
    String? firebaseUid,
    List<String>? sharedWith,
    DateTime? uploadDate,
    String? fileUrl,
    String? content,
    String? fileContent,
  }) {
    return LessonFile(
      id: id ?? this.id,
      title: title ?? this.title,
      filename: filename ?? this.filename,
      fileType: fileType ?? this.fileType,
      fileSize: fileSize ?? this.fileSize,
      firebaseUid: firebaseUid ?? this.firebaseUid,
      sharedWith: sharedWith ?? this.sharedWith,
      uploadDate: uploadDate ?? this.uploadDate,
      fileUrl: fileUrl ?? this.fileUrl,
      content: content ?? this.content,
      fileContent: fileContent ?? this.fileContent,
    );
  }
}
