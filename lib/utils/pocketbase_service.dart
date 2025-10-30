import 'package:pocketbase/pocketbase.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  PocketBaseService._internal();

  late PocketBase _pb;
  bool _initialized = false;

  // Initialize connection once
  Future<void> initialize() async {
    if (_initialized) return;
    _pb = PocketBase('http://10.0.2.2:8090');
    _initialized = true;
  }

  // Upload file
  Future<String> uploadLessonFile({
    required PlatformFile file,
    required String title,
    String? parentId,
  }) async {
    await initialize();

    if (file.bytes == null) throw Exception('File bytes are null');

    final record = await _pb
        .collection('lesson_files')
        .create(
          body: {
            'title': title,
            'file_type': _getFileType(file.extension ?? ''),
            'file_size': file.size,
            'upload_date': DateTime.now().toIso8601String(),
            if (parentId != null) 'parent_id': parentId,
          },
          files: [
            http.MultipartFile.fromBytes(
              'file_data',
              file.bytes!,
              filename: file.name,
            ),
          ],
        );

    return record.id;
  }

  // Fetch list of files
  Future<List<RecordModel>> getLessonFiles({String? parentId}) async {
    await initialize();

    final result = await _pb
        .collection('lesson_files')
        .getList(page: 1, perPage: 50, sort: '-upload_date');

    return result.items;
  }

  // Fetch single file
  Future<RecordModel> getLessonFile(String id) async {
    await initialize();
    return await _pb.collection('lesson_files').getOne(id);
  }

  // Delete file
  Future<void> deleteLessonFile(String id) async {
    await initialize();
    await _pb.collection('lesson_files').delete(id);
  }

  // File URL
  String getFileUrl(String recordId, String filename) =>
      'http://10.0.2.2:8090/api/files/lesson_files/$recordId/$filename';

  // Helper - detect file type
  String _getFileType(String ext) {
    final e = ext.toLowerCase();
    if (['pdf', 'doc', 'docx', 'txt'].contains(e)) return 'document';
    if (['ppt', 'pptx'].contains(e)) return 'presentation';
    if (['mp4'].contains(e)) return 'video';
    if (['mp3'].contains(e)) return 'audio';
    if (['jpg', 'jpeg', 'png'].contains(e)) return 'image';
    return 'other';
  }

  // Server running
  Future<bool> isServerRunning() async {
    try {
      await initialize();
      await _pb.health.check();
      return true;
    } catch (_) {
      return false;
    }
  }
}
