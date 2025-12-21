import 'package:flutter_bloc/flutter_bloc.dart';
import '../../../domain/usecases/accept_invite_usecase.dart';
import '../../../domain/usecases/list_my_invites_usecase.dart';
import 'invites_event.dart';
import 'invites_state.dart';

class InvitesBloc extends Bloc<InvitesEvent, InvitesState> {
  final ListMyInvitesUseCase listMyInvitesUseCase;
  final AcceptInviteUseCase acceptInviteUseCase;

  InvitesBloc({
    required this.listMyInvitesUseCase,
    required this.acceptInviteUseCase,
  }) : super(InvitesState.initial()) {
    on<InvitesFetchRequested>(_onFetch);
    on<InvitesAcceptRequested>(_onAccept);
  }

  Future<void> _onFetch(InvitesFetchRequested event, Emitter<InvitesState> emit) async {
    emit(state.copyWith(
      loading: true,
      error: null,
      acceptingToken: null,
      acceptedToken: null, // ✅ reset
    ));

    try {
      final items = await listMyInvitesUseCase();
      emit(state.copyWith(
        loading: false,
        invites: items,
        error: null,
        acceptedToken: null, // ✅ keep reset
      ));
    } catch (e) {
      emit(state.copyWith(
        loading: false,
        error: e.toString().replaceFirst("Exception: ", ""),
        acceptedToken: null,
      ));
    }
  }

  Future<void> _onAccept(InvitesAcceptRequested event, Emitter<InvitesState> emit) async {
    emit(state.copyWith(
      acceptingToken: event.token,
      error: null,
      acceptedToken: null, // ✅ reset before accept
    ));

    try {
      await acceptInviteUseCase(event.token);

      // refresh list after accept
      final items = await listMyInvitesUseCase();

      emit(state.copyWith(
        acceptingToken: null,
        invites: items,
        error: null,
        acceptedToken: event.token, // ✅ success signal for UI
      ));
    } catch (e) {
      emit(state.copyWith(
        acceptingToken: null,
        error: e.toString().replaceFirst("Exception: ", ""),
        acceptedToken: null,
      ));
    }
  }
}
