import 'package:equatable/equatable.dart';
import '../../../domain/entities/invite_entity.dart';

class InvitesState extends Equatable {
  final bool loading;
  final String? acceptingToken;

  /// ✅ NEW: set when an invite is accepted successfully
  /// so UI can react (refresh projects, pop page, toast, etc.)
  final String? acceptedToken;

  final List<InviteEntity> invites;
  final String? error;

  const InvitesState({
    required this.loading,
    required this.invites,
    this.acceptingToken,
    this.acceptedToken,
    this.error,
  });

  factory InvitesState.initial() => const InvitesState(
        loading: false,
        invites: [],
        acceptingToken: null,
        acceptedToken: null,
        error: null,
      );

  InvitesState copyWith({
    bool? loading,
    List<InviteEntity>? invites,
    String? acceptingToken,
    String? acceptedToken,
    String? error,
  }) {
    return InvitesState(
      loading: loading ?? this.loading,
      invites: invites ?? this.invites,
      acceptingToken: acceptingToken,
      acceptedToken: acceptedToken,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
        loading,
        acceptingToken,
        acceptedToken,
        invites,
        error,
      ];
}
