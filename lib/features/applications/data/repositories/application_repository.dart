import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

class ApplicationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('applications');

  Stream<List<ApplicationModel>> watchByApplicant(String uid) => _col
      .where('applicantId', isEqualTo: uid)
      .orderBy('appliedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ApplicationModel.fromFirestore).toList());

  Stream<List<ApplicationModel>> watchByOpportunity(String opportunityId) => _col
      .where('opportunityId', isEqualTo: opportunityId)
      .orderBy('appliedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(ApplicationModel.fromFirestore).toList());

  Future<bool> hasApplied(String uid, String opportunityId) async {
    final snap = await _col
        .where('applicantId', isEqualTo: uid)
        .where('opportunityId', isEqualTo: opportunityId)
        .limit(1)
        .get();
    return snap.docs.isNotEmpty;
  }

  Future<ApplicationModel> submit(ApplicationModel application) async {
    final ref = await _col.add(application.toFirestore());
    final doc = await ref.get();
    return ApplicationModel.fromFirestore(doc);
  }

  Future<void> updateStatus(String id, ApplicationStatus status) => _col.doc(id).update({
    'status': status.name,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  });
}
