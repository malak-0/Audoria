import 'package:cloud_firestore/cloud_firestore.dart';

class InsightsModel {
  final String? id;
  final String childId;
  final String parentId;
  final int totalQuestions;
  final int correctAnswers;
  final int wrongAnswers;
  final DateTime completedAt;
  final DateTime createdAt;

  InsightsModel({
    this.id,
    required this.childId,
    required this.parentId,
    required this.totalQuestions,
    required this.correctAnswers,
    required this.wrongAnswers,
    required this.completedAt,
    required this.createdAt,
  });

  // Calculate accuracy percentage
  double get accuracyPercentage {
    if (totalQuestions == 0) return 0.0;
    return (correctAnswers / totalQuestions) * 100;
  }

  // Get score as string (e.g., "8/10")
  String get scoreString => '$correctAnswers/$totalQuestions';

  // Convert to Firestore document
  Map<String, dynamic> toFirestore() {
    return {
      'childId': childId,
      'parentId': parentId,
      'totalQuestions': totalQuestions,
      'correctAnswers': correctAnswers,
      'wrongAnswers': wrongAnswers,
      'completedAt': Timestamp.fromDate(completedAt),
      'createdAt': Timestamp.fromDate(createdAt),
    };
  }

  // Create from Firestore document
  factory InsightsModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return InsightsModel(
      id: doc.id,
      childId: data['childId'] ?? '',
      parentId: data['parentId'] ?? '',
      totalQuestions: data['totalQuestions'] ?? 0,
      correctAnswers: data['correctAnswers'] ?? 0,
      wrongAnswers: data['wrongAnswers'] ?? 0,
      completedAt:
          (data['completedAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  // Create from map (for testing or other sources)
  factory InsightsModel.fromMap(Map<String, dynamic> map, {String? id}) {
    return InsightsModel(
      id: id,
      childId: map['childId'] ?? '',
      parentId: map['parentId'] ?? '',
      totalQuestions: map['totalQuestions'] ?? 0,
      correctAnswers: map['correctAnswers'] ?? 0,
      wrongAnswers: map['wrongAnswers'] ?? 0,
      completedAt: map['completedAt'] is Timestamp
          ? (map['completedAt'] as Timestamp).toDate()
          : map['completedAt'] is DateTime
          ? map['completedAt'] as DateTime
          : DateTime.now(),
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : map['createdAt'] is DateTime
          ? map['createdAt'] as DateTime
          : DateTime.now(),
    );
  }
}
