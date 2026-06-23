part of 'startup_cubit.dart';

abstract class StartupState extends Equatable {
  const StartupState();
  @override
  List<Object?> get props => [];
}

class StartupInitial extends StartupState {}
class StartupLoading extends StartupState {}

class StartupListLoaded extends StartupState {
  final List<StartupModel> startups;
  const StartupListLoaded(this.startups);
  @override
  List<Object?> get props => [startups];
}

class StartupOwnerLoaded extends StartupState {
  final StartupModel? startup;
  const StartupOwnerLoaded(this.startup);
  @override
  List<Object?> get props => [startup?.id];
}

class StartupError extends StartupState {
  final String message;
  const StartupError(this.message);
  @override
  List<Object?> get props => [message];
}
