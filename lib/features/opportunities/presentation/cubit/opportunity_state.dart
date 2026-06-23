part of 'opportunity_cubit.dart';

abstract class OpportunityState extends Equatable {
  const OpportunityState();
  @override
  List<Object?> get props => [];
}

class OpportunityInitial extends OpportunityState {}
class OpportunityLoading extends OpportunityState {}

class OpportunityLoaded extends OpportunityState {
  final List<OpportunityModel> opportunities;
  final List<OpportunityModel>? filtered;

  const OpportunityLoaded(this.opportunities, {this.filtered});

  List<OpportunityModel> get displayed => filtered ?? opportunities;

  OpportunityLoaded copyWith({List<OpportunityModel>? filtered}) =>
      OpportunityLoaded(opportunities, filtered: filtered);

  @override
  List<Object?> get props => [opportunities, filtered];
}

class OpportunityError extends OpportunityState {
  final String message;
  const OpportunityError(this.message);
  @override
  List<Object?> get props => [message];
}
