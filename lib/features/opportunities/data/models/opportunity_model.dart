import 'package:cloud_firestore/cloud_firestore.dart';

enum OpportunityStatus { open, closed, paused }

class OpportunityModel {
  final String id;
  final String startupId;
  final String startupName;
  final String? startupLogoUrl;
  final String title;
  final String description;
  final String category;
  final List<String> skillsRequired;
  final String commitment;
  final String location;
  final DateTime postedAt;
  final DateTime? deadline;
  final OpportunityStatus status;
  final int applicantsCount;
  final bool isBookmarked;

  const OpportunityModel({
    required this.id,
    required this.startupId,
    required this.startupName,
    this.startupLogoUrl,
    required this.title,
    required this.description,
    required this.category,
    required this.skillsRequired,
    required this.commitment,
    required this.location,
    required this.postedAt,
    this.deadline,
    required this.status,
    this.applicantsCount = 0,
    this.isBookmarked = false,
  });

  bool get isOpen => status == OpportunityStatus.open;

  factory OpportunityModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return OpportunityModel(
      id: doc.id,
      startupId: data['startupId'] ?? '',
      startupName: data['startupName'] ?? '',
      startupLogoUrl: data['startupLogoUrl'],
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      category: data['category'] ?? 'Other',
      skillsRequired: List<String>.from(data['skillsRequired'] ?? []),
      commitment: data['commitment'] ?? '',
      location: data['location'] ?? '',
      postedAt: (data['postedAt'] as Timestamp).toDate(),
      deadline: data['deadline'] != null ? (data['deadline'] as Timestamp).toDate() : null,
      status: OpportunityStatus.values.firstWhere(
        (s) => s.name == data['status'],
        orElse: () => OpportunityStatus.open,
      ),
      applicantsCount: data['applicantsCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'startupId': startupId,
    'startupName': startupName,
    'startupLogoUrl': startupLogoUrl,
    'title': title,
    'description': description,
    'category': category,
    'skillsRequired': skillsRequired,
    'commitment': commitment,
    'location': location,
    'postedAt': Timestamp.fromDate(postedAt),
    'deadline': deadline != null ? Timestamp.fromDate(deadline!) : null,
    'status': status.name,
    'applicantsCount': applicantsCount,
  };

  OpportunityModel copyWith({
    String? title,
    String? description,
    String? category,
    List<String>? skillsRequired,
    String? commitment,
    String? location,
    DateTime? deadline,
    OpportunityStatus? status,
    int? applicantsCount,
    bool? isBookmarked,
  }) => OpportunityModel(
    id: id,
    startupId: startupId,
    startupName: startupName,
    startupLogoUrl: startupLogoUrl,
    title: title ?? this.title,
    description: description ?? this.description,
    category: category ?? this.category,
    skillsRequired: skillsRequired ?? this.skillsRequired,
    commitment: commitment ?? this.commitment,
    location: location ?? this.location,
    postedAt: postedAt,
    deadline: deadline ?? this.deadline,
    status: status ?? this.status,
    applicantsCount: applicantsCount ?? this.applicantsCount,
    isBookmarked: isBookmarked ?? this.isBookmarked,
  );
}
