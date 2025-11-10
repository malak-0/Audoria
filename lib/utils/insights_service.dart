import 'package:audoria/models/insights_model.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class InsightsService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // Save insights when child finishes answering questions
  Future<void> saveInsights({
    required String childId,
    required String parentId,
    required int totalQuestions,
    required int correctAnswers,
    required int wrongAnswers,
  }) async {
    try {
      final insights = InsightsModel(
        childId: childId,
        parentId: parentId,
        totalQuestions: totalQuestions,
        correctAnswers: correctAnswers,
        wrongAnswers: wrongAnswers,
        completedAt: DateTime.now(),
        createdAt: DateTime.now(),
      );

      await _firestore.collection('insights').add(insights.toFirestore());
    } catch (e) {
      print('Error saving insights: $e');
      rethrow;
    }
  }

  // Get all insights for a specific child
  Future<List<InsightsModel>> getChildInsights(String childId) async {
    try {
      final querySnapshot = await _firestore
          .collection('insights')
          .where('childId', isEqualTo: childId)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => InsightsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching child insights: $e');
      rethrow;
    }
  }

  // Get all insights for a parent's children
  Future<List<InsightsModel>> getParentChildrenInsights(String parentId) async {
    try {
      final querySnapshot = await _firestore
          .collection('insights')
          .where('parentId', isEqualTo: parentId)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => InsightsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching parent children insights: $e');
      rethrow;
    }
  }

  // Get insights for a specific child (for parent view)
  Future<List<InsightsModel>> getInsightsForChild(
    String parentId,
    String childId,
  ) async {
    try {
      final querySnapshot = await _firestore
          .collection('insights')
          .where('parentId', isEqualTo: parentId)
          .where('childId', isEqualTo: childId)
          .orderBy('completedAt', descending: true)
          .get();

      return querySnapshot.docs
          .map((doc) => InsightsModel.fromFirestore(doc))
          .toList();
    } catch (e) {
      print('Error fetching insights for child: $e');
      rethrow;
    }
  }

  // Get aggregated statistics for a child
  Future<Map<String, dynamic>> getChildStatistics(String childId) async {
    try {
      final insights = await getChildInsights(childId);

      if (insights.isEmpty) {
        return {
          'totalSessions': 0,
          'totalQuestions': 0,
          'totalCorrect': 0,
          'totalWrong': 0,
          'averageAccuracy': 0.0,
        };
      }

      int totalQuestions = 0;
      int totalCorrect = 0;
      int totalWrong = 0;

      for (var insight in insights) {
        totalQuestions += insight.totalQuestions;
        totalCorrect += insight.correctAnswers;
        totalWrong += insight.wrongAnswers;
      }

      final averageAccuracy = totalQuestions > 0
          ? (totalCorrect / totalQuestions) * 100
          : 0.0;

      return {
        'totalSessions': insights.length,
        'totalQuestions': totalQuestions,
        'totalCorrect': totalCorrect,
        'totalWrong': totalWrong,
        'averageAccuracy': averageAccuracy,
      };
    } catch (e) {
      print('Error calculating child statistics: $e');
      rethrow;
    }
  }

  // Get current child ID from Firebase Auth
  String? getCurrentChildId() {
    return _auth.currentUser?.uid;
  }

  // Get parent ID from child's document in Firestore
  Future<String?> getParentIdFromChild(String childId) async {
    try {
      // Search through all users to find the parent
      // The child document is stored under users/{parentId}/children/{childId}
      final usersSnapshot = await _firestore.collection('users').get();

      for (var userDoc in usersSnapshot.docs) {
        final childDoc = await _firestore
            .collection('users')
            .doc(userDoc.id)
            .collection('children')
            .doc(childId)
            .get();

        if (childDoc.exists) {
          final childData = childDoc.data();
          // Return parentId from child document or the userDoc.id
          return childData?['parentUid'] ?? userDoc.id;
        }
      }

      return null;
    } catch (e) {
      print('Error getting parent ID from child: $e');
      return null;
    }
  }
}
