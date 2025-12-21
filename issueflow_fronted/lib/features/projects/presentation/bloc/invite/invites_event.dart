import 'package:equatable/equatable.dart';

sealed class InvitesEvent extends Equatable {
  const InvitesEvent();
  @override
  List<Object?> get props => [];
}

class InvitesFetchRequested extends InvitesEvent {
  const InvitesFetchRequested();
}

class InvitesAcceptRequested extends InvitesEvent {
  final String token;
  const InvitesAcceptRequested(this.token);

  @override
  List<Object?> get props => [token];
}
