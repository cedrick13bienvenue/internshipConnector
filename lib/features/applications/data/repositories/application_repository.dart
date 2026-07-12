import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:http/http.dart' as http;
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

  Future<void> submit(ApplicationModel application) => _col.add(application.toFirestore());

  Future<String> uploadResume(String applicantId, String opportunityId, Uint8List bytes) async {
    final cloudName = dotenv.env['CLOUDINARY_CLOUD_NAME']!;
    final preset = dotenv.env['CLOUDINARY_RESUME_PRESET']!;
    final uri = Uri.parse('https://api.cloudinary.com/v1_1/$cloudName/raw/upload');
    final publicId = 'resumes/${applicantId}_$opportunityId';
    final request = http.MultipartRequest('POST', uri)
      ..fields['upload_preset'] = preset
      ..fields['public_id'] = publicId
      ..files.add(http.MultipartFile.fromBytes('file', bytes, filename: 'resume.pdf'));
    final streamed = await request.send();
    final body = jsonDecode(await streamed.stream.bytesToString());
    if (streamed.statusCode != 200) {
      throw Exception('Upload failed: ${body['error']?['message'] ?? 'Unknown error'}');
    }
    return body['secure_url'] as String;
  }

  Future<void> updateStatus(String id, ApplicationStatus status) => _col.doc(id).update({
    'status': status.name,
    'updatedAt': Timestamp.fromDate(DateTime.now()),
  });
}
