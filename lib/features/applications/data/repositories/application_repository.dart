import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/application_model.dart';
import '../../../notifications/data/repositories/notification_repository.dart';

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

  Future<void> submit(ApplicationModel application) => _col.add(application.toFirestore());

  Future<void> updateStatus(
    String id,
    ApplicationStatus status, {
    required String applicantId,
    required String opportunityTitle,
  }) async {
    await _col.doc(id).update({
      'status': status.name,
      'updatedAt': Timestamp.fromDate(DateTime.now()),
    });
    await NotificationRepository().create(
      userId: applicantId,
      title: 'Application Update',
      body: 'Your application for "$opportunityTitle" has been moved to ${_statusLabel(status)}.',
      relatedId: id,
    );
  }

  Future<void> toggleStar(String id, bool isStarred) =>
      _col.doc(id).update({'isStarred': isStarred});
}

String _statusLabel(ApplicationStatus s) => switch (s) {
      ApplicationStatus.applied => 'Applied',
      ApplicationStatus.underReview => 'Under Review',
      ApplicationStatus.shortlisted => 'Shortlisted',
      ApplicationStatus.interview => 'Interview',
      ApplicationStatus.accepted => 'Accepted',
      ApplicationStatus.rejected => 'Rejected',
      ApplicationStatus.closed => 'Closed',
    };
