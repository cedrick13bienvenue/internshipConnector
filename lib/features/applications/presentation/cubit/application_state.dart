part of 'application_cubit.dart';

abstract class ApplicationState extends Equatable {
  const ApplicationState();
  @override
  List<Object?> get props => [];
}

class ApplicationInitial extends ApplicationState {}
class ApplicationLoading extends ApplicationState {}

class ApplicationLoaded extends ApplicationState {
  final List<ApplicationModel> applications;
  final ApplicationStatus? filterStatus;

  const ApplicationLoaded(this.applications, {this.filterStatus});

  List<ApplicationModel> get displayed => filterStatus == null
      ? applications
      : applications.where((a) => a.status == filterStatus).toList();

  ApplicationLoaded copyWith({ApplicationStatus? filterStatus}) =>
      ApplicationLoaded(applications, filterStatus: filterStatus);

  @override
  List<Object?> get props => [applications, filterStatus];
}

class ApplicationError extends ApplicationState {
  final String message;
  const ApplicationError(this.message);
  @override
  List<Object?> get props => [message];
}
