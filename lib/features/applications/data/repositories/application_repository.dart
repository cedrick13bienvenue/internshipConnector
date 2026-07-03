import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';

class ApplicationRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('applications');

  Stream<List<ApplicationModel>> watchByApplicant(String uid) => _col
      .where('applicantId', isEqualTo: uid)
      .snapshots()
      .map((s) => s.docs
          .map(ApplicationModel.fromFirestore)
          .toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt)));

  Stream<List<ApplicationModel>> watchByStartup(String startupId) => _col
      .where('startupId', isEqualTo: startupId)
      .snapshots()
      .map((s) => s.docs
          .map(ApplicationModel.fromFirestore)
          .toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt)));

  Stream<List<ApplicationModel>> watchByOpportunity(String opportunityId) => _col
      .where('opportunityId', isEqualTo: opportunityId)
      .snapshots()
      .map((s) => s.docs
          .map(ApplicationModel.fromFirestore)
          .toList()
        ..sort((a, b) => b.appliedAt.compareTo(a.appliedAt)));

  Future<bool> hasApplied(String uid, String opportunityId) async {
    final snap = await _col.where('applicantId', isEqualTo: uid).get();
    return snap.docs.any(
      (d) => (d.data() as Map<String, dynamic>)['opportunityId'] == opportunityId,
    );
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
