import 'package:equatable/equatable.dart';
import '../../nav_items.dart';

/// State holds the current selected tab.
/// Equatable helps Bloc compare states efficiently (prevents unnecessary rebuilds).
class ShellState extends Equatable {
  final ShellTab selected ;

  const ShellState({required this.selected});

  /// copyWith is a standard pattern:
  /// create a new state changing only some fields.
  ShellState copyWith({ShellTab? selected}) =>
      ShellState(selected: selected ?? this.selected);

  @override
  List<Object?> get props => [selected];
}
