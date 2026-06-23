import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:equatable/equatable.dart';
import '../../data/models/startup_model.dart';
import '../../data/repositories/startup_repository.dart';

part 'startup_state.dart';

class StartupCubit extends Cubit<StartupState> {
  final StartupRepository _repository;
  StreamSubscription? _sub;

  StartupCubit(this._repository) : super(StartupInitial());

  void watchVerified() {
    _sub?.cancel();
    _sub = _repository.watchVerified().listen(
      (list) => emit(StartupListLoaded(list)),
      onError: (e) => emit(StartupError(e.toString())),
    );
  }

  Future<void> loadMyStartup(String uid) async {
    emit(StartupLoading());
    try {
      final startup = await _repository.getByOwner(uid);
      emit(StartupOwnerLoaded(startup));
    } catch (e) {
      emit(StartupError(e.toString()));
    }
  }

  Future<void> register(StartupModel startup) async {
    emit(StartupLoading());
    try {
      final created = await _repository.register(startup);
      emit(StartupOwnerLoaded(created));
    } catch (e) {
      emit(StartupError(e.toString()));
    }
  }

  @override
  Future<void> close() {
    _sub?.cancel();
    return super.close();
  }
}
