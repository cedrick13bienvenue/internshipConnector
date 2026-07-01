import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/opportunity_model.dart';
import '../../data/repositories/opportunity_repository.dart';

part 'opportunity_state.dart';

class OpportunityCubit extends Cubit<OpportunityState> {
  final OpportunityRepository _repository;
  StreamSubscription? _sub;

  OpportunityCubit(this._repository) : super(OpportunityInitial());

  void watchAll() {
    emit(OpportunityLoading());
    _sub?.cancel();
    _sub = _repository.watchAll().listen(
      (list) => emit(OpportunityLoaded(list)),
      onError: (e) => emit(OpportunityError(e.toString())),
    );
  }

  void watchMine(String startupId) {
    emit(OpportunityLoading());
    _sub?.cancel();
    _sub = _repository.watchByStartup(startupId).listen(
      (list) => emit(OpportunityLoaded(list)),
      onError: (e) => emit(OpportunityError(e.toString())),
    );
  }

  void watchByCategory(String category) {
    emit(OpportunityLoading());
    _sub?.cancel();
    _sub = _repository.watchByCategory(category).listen(
      (list) => emit(OpportunityLoaded(list)),
      onError: (e) => emit(OpportunityError(e.toString())),
    );
  }

  void search(String query) {
    final current = state;
    if (current is! OpportunityLoaded) return;
    if (query.isEmpty) {
      emit(current.copyWith(filtered: null));
      return;
    }
    final q = query.toLowerCase();
    final filtered = current.opportunities.where((o) =>
      o.title.toLowerCase().contains(q) ||
      o.startupName.toLowerCase().contains(q) ||
      o.category.toLowerCase().contains(q) ||
      o.skillsRequired.any((s) => s.toLowerCase().contains(q)),
    ).toList();
    emit(current.copyWith(filtered: filtered));
  }

  Future<void> post(OpportunityModel opportunity) async {
    await _repository.create(opportunity);
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
