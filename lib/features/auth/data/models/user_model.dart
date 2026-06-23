import 'package:cloud_firestore/cloud_firestore.dart';

enum UserRole { student, startup, admin }

class UserModel {
  final String uid;
  final String email;
  final String fullName;
  final String? photoUrl;
  final UserRole role;
  final DateTime createdAt;
  final bool isOnboarded;

  const UserModel({
    required this.uid,
    required this.email,
    required this.fullName,
    this.photoUrl,
    required this.role,
    required this.createdAt,
    this.isOnboarded = false,
  });

  factory UserModel.fromFirestore(DocumentSnapshot doc) {
    final data = doc.data() as Map<String, dynamic>;
    return UserModel(
      uid: doc.id,
      email: data['email'] ?? '',
      fullName: data['fullName'] ?? '',
      photoUrl: data['photoUrl'],
      role: UserRole.values.firstWhere(
        (r) => r.name == data['role'],
        orElse: () => UserRole.student,
      ),
      createdAt: (data['createdAt'] as Timestamp).toDate(),
      isOnboarded: data['isOnboarded'] ?? false,
    );
  }

  Map<String, dynamic> toFirestore() => {
    'email': email,
    'fullName': fullName,
    'photoUrl': photoUrl,
    'role': role.name,
    'createdAt': Timestamp.fromDate(createdAt),
    'isOnboarded': isOnboarded,
  };

  UserModel copyWith({
    String? fullName,
    String? photoUrl,
    bool? isOnboarded,
  }) => UserModel(
    uid: uid,
    email: email,
    fullName: fullName ?? this.fullName,
    photoUrl: photoUrl ?? this.photoUrl,
    role: role,
    createdAt: createdAt,
    isOnboarded: isOnboarded ?? this.isOnboarded,
  );
}
