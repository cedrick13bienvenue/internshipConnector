import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, startup, admin }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;
  final String? bio;
  final List<String> skills;
  final String? program;
  final UserRole role;
  final DateTime createdAt;
  final bool isOnboarded;
  final bool isEmailVerified;
  final List<String> savedOpportunities;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.photoUrl,
    this.bio,
    this.skills = const [],
    this.program,
    required this.role,
    required this.createdAt,
    this.isOnboarded = false,
    this.isEmailVerified = false,
    this.savedOpportunities = const [],
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'],
      bio: data['bio'],
      skills: List<String>.from(data['skills'] ?? []),
      program: data['program'],
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.student,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isOnboarded: data['isOnboarded'] ?? false,
      isEmailVerified: data['isEmailVerified'] ?? false,
      savedOpportunities: List<String>.from(data['savedOpportunities'] ?? []),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'fullName': fullName,
    'photoUrl': photoUrl,
    'bio': bio,
    'skills': skills,
    'program': program,
    'role': role.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'isOnboarded': isOnboarded,
    'isEmailVerified': isEmailVerified,
    'savedOpportunities': savedOpportunities,
  };

  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    String? bio,
    List<String>? skills,
    String? program,
    bool? isOnboarded,
    bool? isEmailVerified,
    List<String>? savedOpportunities,
  }) => UserModel(
    uid: uid,
    email: email,
    fullName: fullName ?? this.fullName,
    photoUrl: photoUrl ?? this.photoUrl,
    bio: bio ?? this.bio,
    skills: skills ?? this.skills,
    program: program ?? this.program,
    role: role,
    createdAt: createdAt,
    isOnboarded: isOnboarded ?? this.isOnboarded,
    isEmailVerified: isEmailVerified ?? this.isEmailVerified,
    savedOpportunities: savedOpportunities ?? this.savedOpportunities,
  );
}
