import 'package:cloud_firestore/cloud_firestore.dart';

enum StartupVerificationStatus { pending, verified, rejected }

class StartupModel {
  final String id;
  final String ownerId;
  final String name;
  final String description;
  final String? logoUrl;
  final String? websiteUrl;
  final List<String> categories;
  final StartupVerificationStatus verificationStatus;
  final String? verificationNote;
  final DateTime createdAt;
  final int activeOpportunities;

  const StartupModel({
    required this.id,
    required this.ownerId,
    required this.name,
    required this.description,
    this.logoUrl,
    this.websiteUrl,
    required this.categories,
    required this.verificationStatus,
    this.verificationNote,
    required this.createdAt,
    this.activeOpportunities = 0,
  });

  bool get isVerified => verificationStatus == StartupVerificationStatus.verified;

  factory StartupModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return StartupModel(
      id: doc.id,
      ownerId: data['ownerId'] ?? '',
      name: data['name'] ?? '',
      description: data['description'] ?? '',
      logoUrl: data['logoUrl'],
      websiteUrl: data['websiteUrl'],
      categories: List<String>.from(data['categories'] ?? []),
      verificationStatus: StartupVerificationStatus.values.firstWhere(
        (s) => s.name == data['verificationStatus'],
        orElse: () => StartupVerificationStatus.pending,
      ),
      verificationNote: data['verificationNote'],
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      activeOpportunities: data['activeOpportunities'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'ownerId': ownerId,
    'name': name,
    'description': description,
    'logoUrl': logoUrl,
    'websiteUrl': websiteUrl,
    'categories': categories,
    'verificationStatus': verificationStatus.name,
    'verificationNote': verificationNote,
    'createdAt': Timestamp.fromDate(createdAt),
    'activeOpportunities': activeOpportunities,
  };

  StartupModel copyWith({
    String? name,
    String? description,
    String? logoUrl,
    String? websiteUrl,
    List<String>? categories,
    StartupVerificationStatus? verificationStatus,
    String? verificationNote,
    int? activeOpportunities,
  }) => StartupModel(
    id: id,
    ownerId: ownerId,
    name: name ?? this.name,
    description: description ?? this.description,
    logoUrl: logoUrl ?? this.logoUrl,
    websiteUrl: websiteUrl ?? this.websiteUrl,
    categories: categories ?? this.categories,
    verificationStatus: verificationStatus ?? this.verificationStatus,
    verificationNote: verificationNote ?? this.verificationNote,
    createdAt: createdAt,
    activeOpportunities: activeOpportunities ?? this.activeOpportunities,
  );
}
