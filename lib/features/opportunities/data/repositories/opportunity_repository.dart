import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/opportunity_model.dart';

class OpportunityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('opportunities');

  Stream<List<OpportunityModel>> watchAll() => _col
      .orderBy('postedAt', descending: true)
      .snapshots()
      .map((s) => s.docs
          .map(OpportunityModel.fromFirestore)
          .where((o) => o.status == OpportunityStatus.open)
          .toList());

  Stream<List<OpportunityModel>> watchByCategory(String category) => _col
      .where('category', isEqualTo: category)
      .snapshots()
      .map((s) => s.docs
          .map(OpportunityModel.fromFirestore)
          .where((o) => o.status == OpportunityStatus.open)
          .toList()
        ..sort((a, b) => b.postedAt.compareTo(a.postedAt)));

  Stream<List<OpportunityModel>> watchByStartup(String startupId) => _col
      .where('startupId', isEqualTo: startupId)
      .snapshots()
      .map((s) => s.docs
          .map(OpportunityModel.fromFirestore)
          .toList()
        ..sort((a, b) => b.postedAt.compareTo(a.postedAt)));

  Future<List<OpportunityModel>> getByStartup(String startupId) async {
    final snap = await _col.where('startupId', isEqualTo: startupId).get();
    return snap.docs
        .map(OpportunityModel.fromFirestore)
        .where((o) => o.status == OpportunityStatus.open)
        .toList()
      ..sort((a, b) => b.postedAt.compareTo(a.postedAt));
  }

  Future<OpportunityModel> getById(String id) async {
    final doc = await _col.doc(id).get();
    return OpportunityModel.fromFirestore(doc);
  }

  Future<OpportunityModel> create(OpportunityModel opportunity) async {
    await _col.add(opportunity.toFirestore());
    return opportunity.copyWith();
  }

  Future<void> update(OpportunityModel opportunity) =>
      _col.doc(opportunity.id).update(opportunity.toFirestore());

  Future<void> close(String id) =>
      _col.doc(id).update({'status': OpportunityStatus.closed.name});

  Future<void> delete(String id) => _col.doc(id).delete();
}
