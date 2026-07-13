import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/notification_model.dart';

class NotificationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('notifications');

  Stream<List<NotificationModel>> watchForUser(String uid) => _col
      .where('userId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
          .map(NotificationModel.fromFirestore)
          .toList()
        ..sort((a, b) => b.createdAt.compareTo(a.createdAt)));

  Future<void> create({
    required String userId,
    required String title,
    required String body,
    String? relatedId,
  }) =>
      _col.add({
        'userId': userId,
        'title': title,
        'body': body,
        'relatedId': relatedId,
        'isRead': false,
        'createdAt': Timestamp.fromDate(DateTime.now()),
      });

  Future<void> markAsRead(String id) => _col.doc(id).update({'isRead': true});

  Future<void> markAllRead(String userId) async {
    final snap = await _col.where('userId', isEqualTo: userId).get();
    final batch = _db.batch();
    for (final doc in snap.docs) {
      final data = doc.data() as Map<String, dynamic>;
      if (data['isRead'] == false) {
        batch.update(doc.reference, {'isRead': true});
      }
    }
    await batch.commit();
  }
}
