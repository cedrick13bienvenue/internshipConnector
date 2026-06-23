import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/application_model.dart';
import '../../data/repositories/application_repository.dart';

part 'application_state.dart';

class ApplicationCubit extends Cubit<ApplicationState> {
  final ApplicationRepository _repository;
  StreamSubscription? _sub;

  ApplicationCubit(this._repository) : super(ApplicationInitial());

  void watchMyApplications(String uid) {
    emit(ApplicationLoading());
    _sub?.cancel();
    _sub = _repository.watchByApplicant(uid).listen(
      (list) => emit(ApplicationLoaded(list)),
      onError: (e) => emit(ApplicationError(e.toString())),
    );
  }

  void filterByStatus(ApplicationStatus? status) {
    final current = state;
    if (current is! ApplicationLoaded) return;
    emit(current.copyWith(filterStatus: status));
  }

  Future<void> submit(ApplicationModel application) async {
    try {
      await _repository.submit(application);
    } catch (e) {
      emit(ApplicationError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
