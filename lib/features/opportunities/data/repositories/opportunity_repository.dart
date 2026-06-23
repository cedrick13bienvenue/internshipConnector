import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/opportunity_model.dart';

class OpportunityRepository {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  CollectionReference get _col => _db.collection('opportunities');

  Stream<List<OpportunityModel>> watchAll() => _col
      .where('status', isEqualTo: 'open')
      .orderBy('postedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OpportunityModel.fromFirestore).toList());

  Stream<List<OpportunityModel>> watchByCategory(String category) => _col
      .where('status', isEqualTo: 'open')
      .where('category', isEqualTo: category)
      .orderBy('postedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OpportunityModel.fromFirestore).toList());

  Stream<List<OpportunityModel>> watchByStartup(String startupId) => _col
      .where('startupId', isEqualTo: startupId)
      .orderBy('postedAt', descending: true)
      .snapshots()
      .map((s) => s.docs.map(OpportunityModel.fromFirestore).toList());

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
}
