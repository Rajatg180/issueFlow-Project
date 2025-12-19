import 'package:equatable/equatable.dart';
import '../../nav_items.dart';

sealed class ShellEvent extends Equatable {
  const ShellEvent();

  @override
  List<Object?> get props => [];
}

class ShellTabSelected extends ShellEvent {
  final ShellTab tab;
  const ShellTabSelected(this.tab);

  @override
  List<Object?> get props => [tab];
}

/// Fired when user clicks a project in the sidebar
class ShellProjectSelected extends ShellEvent {
  final String projectId;
  const ShellProjectSelected(this.projectId);

  @override
  List<Object?> get props => [projectId];
}
