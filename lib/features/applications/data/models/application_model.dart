import 'package:cloud_firestore/cloud_firestore.dart';

enum ApplicationStatus {
  applied,
  underReview,
  shortlisted,
  interview,
  accepted,
  rejected,
  closed,
}

class ApplicationModel {
  final String id;
  final String opportunityId;
  final String opportunityTitle;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String applicantId;
  final String applicantName;
  final String coverNote;
  final String? resumeUrl;
  final ApplicationStatus status;
  final bool isStarred;
  final DateTime appliedAt;
  final DateTime? updatedAt;

  const ApplicationModel({
    required this.id,
    required this.opportunityId,
    required this.opportunityTitle,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.applicantId,
    required this.applicantName,
    required this.coverNote,
    this.resumeUrl,
    required this.status,
    this.isStarred = false,
    required this.appliedAt,
    this.updatedAt,
  });

  factory ApplicationModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return ApplicationModel(
      id: doc.id,
      opportunityId: data['opportunityId'] ?? '',
      opportunityTitle: data['opportunityTitle'] ?? '',
      startupId: data['startupId'] ?? '',
      startupName: data['startupName'] ?? '',
      startupLogoUrl: data['startupLogoUrl'],
      applicantId: data['applicantId'] ?? '',
      applicantName: data['applicantName'] ?? '',
      coverNote: data['coverNote'] ?? '',
      resumeUrl: data['resumeUrl'],
      status: ApplicationStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => ApplicationStatus.applied,
      ),
      isStarred: data['isStarred'] ?? false,
      appliedAt: (data['appliedAt'] as Timestamp).toDate(),
      updatedAt: data['updatedAt'] != null ? (data['updatedAt'] as Timestamp).toDate() : null,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'opportunityId': opportunityId,
    'opportunityTitle': opportunityTitle,
    'startupId': startupId,
    'startupName': startupName,
    'startupLogoUrl': startupLogoUrl,
    'applicantId': applicantId,
    'applicantName': applicantName,
    'coverNote': coverNote,
    'resumeUrl': resumeUrl,
    'status': status.name,
    'isStarred': isStarred,
    'appliedAt': Timestamp.fromDate(appliedAt),
    'updatedAt': updatedAt != null ? Timestamp.fromDate(updatedAt!) : null,
  };

  ApplicationModel copyWith({ApplicationStatus? status, bool? isStarred, DateTime? updatedAt}) =>
      ApplicationModel(
        id: id,
        opportunityId: opportunityId,
        opportunityTitle: opportunityTitle,
        startupId: startupId,
        startupName: startupName,
        startupLogoUrl: startupLogoUrl,
        applicantId: applicantId,
        applicantName: applicantName,
        coverNote: coverNote,
        resumeUrl: resumeUrl,
        status: status ?? this.status,
        isStarred: isStarred ?? this.isStarred,
        appliedAt: appliedAt,
        updatedAt: updatedAt ?? this.updatedAt,
      );
}
