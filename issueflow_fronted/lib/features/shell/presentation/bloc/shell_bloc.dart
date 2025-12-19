import 'package:flutter_bloc/flutter_bloc.dart';
import '../../nav_items.dart';
import 'shell_event.dart';
import 'shell_state.dart';

class ShellBloc extends Bloc<ShellEvent, ShellState> {
  ShellBloc() : super(const ShellState(selected: ShellTab.dashboard)) {
    on<ShellTabSelected>((event, emit) {
      emit(state.copyWith(selected: event.tab));
    });

    on<ShellProjectSelected>((event, emit) {
      // When selecting a project from sidebar, jump to projects tab
      emit(
        state.copyWith(
          selected: ShellTab.projects,
          selectedProjectId: event.projectId,
        ),
      );
    });
  }
}
