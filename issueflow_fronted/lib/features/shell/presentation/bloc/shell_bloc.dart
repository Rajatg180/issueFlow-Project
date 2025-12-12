import 'package:flutter_bloc/flutter_bloc.dart';
import '../../nav_items.dart';
import 'shell_event.dart';
import 'shell_state.dart';

/// ShellBloc controls which tab is selected across the app.
/// This is the foundation for navigation without using a full router yet.
class ShellBloc extends Bloc<ShellEvent, ShellState> {
  /// Initial state: Dashboard tab selected
  ShellBloc() : super(const ShellState(selected: ShellTab.dashboard)) {
    /// When a tab is selected in UI, emit new state with that tab.
    on<ShellTabSelected>((event, emit) {
      emit(state.copyWith(selected: event.tab));
    });
  }
}
