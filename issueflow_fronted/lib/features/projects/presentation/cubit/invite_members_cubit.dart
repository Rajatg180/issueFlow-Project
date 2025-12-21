import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:issueflow_fronted/features/projects/domain/usecases/invite_members_usecase.dart';

class InviteMembersState {
  final bool sending;
  final String? error;
  final int? invited;
  final int? skipped;

  const InviteMembersState({required this.sending, this.error, this.invited, this.skipped});

  factory InviteMembersState.initial() => const InviteMembersState(sending: false);

  InviteMembersState copyWith({
    bool? sending,
    String? error,
    int? invited,
    int? skipped,
  }) {
    return InviteMembersState(
      sending: sending ?? this.sending,
      error: error,
      invited: invited,
      skipped: skipped,
    );
  }
}

class InviteMembersCubit extends Cubit<InviteMembersState> {
  final InviteMembersUseCase inviteMembersUseCase;

  InviteMembersCubit({required this.inviteMembersUseCase}) : super(InviteMembersState.initial());

  Future<void> send(String projectId, List<String> emails) async {
    emit(state.copyWith(sending: true, error: null, invited: null, skipped: null));
    try {
      final res = await inviteMembersUseCase(projectId, emails);
      emit(state.copyWith(
        sending: false,
        invited: (res["invited"] as num?)?.toInt() ?? 0,
        skipped: (res["skipped"] as num?)?.toInt() ?? 0,
      ));
    } catch (e) {
      emit(state.copyWith(sending: false, error: e.toString().replaceFirst("Exception: ", "")));
    }
  }
}
