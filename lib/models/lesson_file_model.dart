class LessonFile {
  final String id;
  final String title;
  final String filename;
  final String fileType;
  final int fileSize;
  final DateTime uploadDate;
  final String? fileUrl;

  LessonFile({
    required this.id,
    required this.title,
    required this.filename,
    required this.fileType,
    required this.fileSize,
    required this.uploadDate,
    this.fileUrl,
  });

  factory LessonFile.fromPocketBase(Map<String, dynamic> data) {
    return LessonFile(
      id: data['id'] ?? '',
      title: data['title'] ?? '',
      filename: data['filename'] ?? '',
      fileType: data['file_type'] ?? 'other',
      fileSize: data['file_size'] ?? 0,
      uploadDate:
          DateTime.tryParse(data['upload_date'] ?? '') ?? DateTime.now(),
      fileUrl: data['file_data'] != null
          ? 'http://10.0.2.2:8090/api/files/lesson_files/${data['id']}/${data['filename']}'
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'filename': filename,
      'file_type': fileType,
      'file_size': fileSize,
      'upload_date': uploadDate.toIso8601String(),
      'file_url': fileUrl,
    };
  }

  String get formattedFileSize {
    if (fileSize < 1024) {
      return '${fileSize}B';
    } else if (fileSize < 1024 * 1024) {
      return '${(fileSize / 1024).toStringAsFixed(1)}KB';
    } else {
      return '${(fileSize / (1024 * 1024)).toStringAsFixed(1)}MB';
    }
  }

  String get formattedUploadDate {
    final months = [
      'Jan',
      'Feb',
      'Mar',
      'Apr',
      'May',
      'Jun',
      'Jul',
      'Aug',
      'Sep',
      'Oct',
      'Nov',
      'Dec',
    ];
    return '${uploadDate.day} ${months[uploadDate.month - 1]}, ${uploadDate.year}';
  }
}
