import 'package:http/http.dart' as http;
import 'package:pocketbase/pocketbase.dart';
import 'package:file_picker/file_picker.dart';

class PocketBaseService {
  static final PocketBaseService _instance = PocketBaseService._internal();
  factory PocketBaseService() => _instance;
  
  PocketBaseService._internal();

  final String _baseUrl = 'http://10.0.2.2:8091'; 
  late final PocketBase _pb = PocketBase(_baseUrl);

  // Upload file from parent - ENHANCED
  Future<String> uploadLessonFile({
    required PlatformFile file,
    required String title,
    required String firebaseUid,
    List<String>? sharedWith, 
  }) async {
    if (file.bytes == null) throw Exception('File bytes are null');
    
    print('Starting file upload...');
    print('File: ${file.name}');
    print('Firebase UID: $firebaseUid');
    print('Shared with: $sharedWith');
    
    try {
      final record = await _pb.collection('parent_files').create(
        body: {
          'firebase_uid': firebaseUid, 
          'sharedWith': sharedWith ?? [],
        },
        files: [
          http.MultipartFile.fromBytes(
            'file',
            file.bytes!,
            filename: file.name,
          ),
        ],
      );
      
      print('File uploaded successfully!');
      print('Record ID: ${record.id}');
      print('File URL: ${getFileUrl(record)}');
      
      return record.id;
    } catch (e) {
      print('Upload failed: $e');
      rethrow;
    }
  }

  // Get files uploaded by parent - ENHANCED DEBUGGING
  Future<List<RecordModel>> getFilesByParent(String parentUid) async {
    try {
      print('Searching for files with UID: "$parentUid"');
      
      final records = await _pb.collection('parent_files').getFullList(
        filter: 'firebase_uid = "$parentUid"',
      );
      
      print('Found ${records.length} records for UID: $parentUid');
      
      // Show all records for debugging
      final allRecords = await _pb.collection('parent_files').getFullList();
      print('Total records in database: ${allRecords.length}');
      
      for (var record in allRecords) {
        print('Record: ${record.id}');
        print('File: ${record.data['file']}');
        print('Firebase UID: ${record.data['firebase_uid']}');
        print('Match: ${record.data['firebase_uid'] == parentUid}');
      }
      
      return records;
    } catch (e) {
      print('Error getting files: $e');
      return [];
    }
  }

  // Get ALL records for debugging
  Future<List<RecordModel>> getAllRecords() async {
    try {
      final records = await _pb.collection('parent_files').getFullList();
      print('Total records: ${records.length}');
      return records;
    } catch (e) {
      print('Error getting all records: $e');
      return [];
    }
  }

  // Other methods remain the same...
  Future<List<RecordModel>> getFilesForChild(String childUid) async {
    try {
      final records = await _pb.collection('parent_files').getFullList(
        filter: 'sharedWith ~ "$childUid"',
      );
      return records;
    } catch (e) {
      print('Error getting files for child: $e');
      return [];
    }
  }

  Future<void> updateFileSharing(String fileId, List<String> sharedWith) async {
    await _pb.collection('parent_files').update(fileId, body: {
      'sharedWith': sharedWith,
    });
  }

  Future<void> deleteLessonFile(String id) async {
    await _pb.collection('parent_files').delete(id);
  }

  String getFileUrl(RecordModel record) {
    final filename = record.getStringValue('file');
    return '$_baseUrl/api/files/parent_files/${record.id}/$filename';
  }

  // Server running check
  Future<bool> isServerRunning() async {
    try {
      await _pb.health.check();
      return true;
    } catch (e) {
      print('PocketBase server not reachable: $e');
      return false;
    }
  }
}