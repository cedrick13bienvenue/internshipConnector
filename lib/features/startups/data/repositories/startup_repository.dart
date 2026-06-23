import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/startup_model.dart';

class StartupRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('startups');

  Stream<List<StartupModel>> watchVerified() => _col
      .where('verificationStatus', isEqualTo: StartupVerificationStatus.verified.name)
      .snapshots()
      .map((s) => s.docs.map(StartupModel.fromFirestore).toList());

  Future<StartupModel?> getByOwner(String uid) async {
    final snap = await _col.where('ownerId', isEqualTo: uid).limit(1).get();
    if (snap.docs.isEmpty) return null;
    return StartupModel.fromFirestore(snap.docs.first);
  }

  Future<StartupModel> getById(String id) async {
    final doc = await _col.doc(id).get();
    return StartupModel.fromFirestore(doc);
  }

  Future<StartupModel> register(StartupModel startup) async {
    final ref = await _col.add(startup.toFirestore());
    final doc = await ref.get();
    return StartupModel.fromFirestore(doc);
  }

  Future<void> update(StartupModel startup) =>
      _col.doc(startup.id).update(startup.toFirestore());
}
