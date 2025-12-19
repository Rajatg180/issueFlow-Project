import 'package:equatable/equatable.dart';
import '../../nav_items.dart';

class ShellState extends Equatable {
  final ShellTab selected;

  /// Optional: if user clicks a project in sidebar, we keep it here
  final String? selectedProjectId;

  const ShellState({
    required this.selected,
    this.selectedProjectId,
  });

  ShellState copyWith({
    ShellTab? selected,
    String? selectedProjectId,
    bool clearSelectedProjectId = false,
  }) {
    return ShellState(
      selected: selected ?? this.selected,
      selectedProjectId: clearSelectedProjectId
          ? null
          : (selectedProjectId ?? this.selectedProjectId),
    );
  }

  @override
  List<Object?> get props => [selected, selectedProjectId];
}
