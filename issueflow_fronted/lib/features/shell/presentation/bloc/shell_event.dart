import 'package:equatable/equatable.dart';
import '../../nav_items.dart';

/// Events are actions coming from UI/user interactions.
/// Using `sealed class` means only specific event types can exist.
sealed class ShellEvent extends Equatable {
  const ShellEvent();

  @override
  List<Object?> get props => [];
}

/// Fired when user selects a tab in the sidebar/drawer.
class ShellTabSelected extends ShellEvent {
  final ShellTab tab;
  const ShellTabSelected(this.tab);

  @override
  List<Object?> get props => [tab];
}
