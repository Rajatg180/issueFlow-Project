// import 'dart:math' as math;
// import 'package:flutter/gestures.dart';
// import 'package:flutter/material.dart';
// import 'package:flutter_bloc/flutter_bloc.dart';

// import '../../../../core/theme/app_colors.dart';
// import '../../domain/entities/issue_entity.dart';
// import '../../domain/entities/project_user_entity.dart';
// import '../bloc/issues_bloc.dart';
// import '../bloc/issues_event.dart';
// import '../bloc/issues_state.dart';
// import 'priority_badge.dart';
// import 'status_badge.dart';

// class IssuesTable extends StatefulWidget {
//   final String projectId;
//   final List<IssueEntity> issues;
//   final List<ProjectUserEntity> projectUsers;

//   const IssuesTable({
//     super.key,
//     required this.projectId,
//     required this.issues,
//     required this.projectUsers,
//   });

//   @override
//   State<IssuesTable> createState() => _IssuesTableState();
// }

// class _IssuesTableState extends State<IssuesTable> {
//   String? _editingIssueId;

//   final _titleCtrl = TextEditingController();
//   final _descCtrl = TextEditingController();

//   String _type = 'task';
//   String _priority = 'medium';
//   String _status = 'todo';

//   DateTime? _due;
//   String? _assigneeId;
//   String _reporterId = '';

//   static const String _kUnassignedSentinelId = '__UNASSIGNED__';

//   static const String _kFilterAll = '__ALL__';
//   String _typeFilter = _kFilterAll; // all | task | bug | feature
//   String _priorityFilter = _kFilterAll; // all | low | medium | high
//   String _statusFilter = _kFilterAll; // all | todo | in_progress | done

//   static const String _kAssigneeAll = '__ASSIGNEE_ALL__';
//   static const String _kAssigneeUnassigned = '__ASSIGNEE_UNASSIGNED__';
//   String _assigneeFilter = _kAssigneeAll;

//   @override
//   void dispose() {
//     _titleCtrl.dispose();
//     _descCtrl.dispose();
//     super.dispose();
//   }

//   bool _isOverdue(String dueDateStr) {
//     try {
//       final s = dueDateStr.trim();
//       if (s.isEmpty) return false;

//       final normalized = s.contains(' ') ? s.replaceFirst(' ', 'T') : s;

//       final parsed = DateTime.parse(normalized);
//       final due = DateTime(parsed.year, parsed.month, parsed.day);

//       final now = DateTime.now();
//       final today = DateTime(now.year, now.month, now.day);

//       return due.isBefore(today);
//     } catch (_) {
//       return false;
//     }
//   }

//   String _onlyDate(String s) {
//     final v = s.trim();
//     if (v.isEmpty) return v;
//     if (v.length >= 10) return v.substring(0, 10);
//     return v;
//   }

//   DateTime? _parseDate(String? s) {
//     if (s == null || s.trim().isEmpty) return null;
//     try {
//       final raw = s.trim();
//       final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
//       final d = DateTime.parse(normalized);
//       return DateTime(d.year, d.month, d.day);
//     } catch (_) {
//       try {
//         final d = DateTime.parse(_onlyDate(s));
//         return DateTime(d.year, d.month, d.day);
//       } catch (_) {
//         return null;
//       }
//     }
//   }

//   Widget typeWidegt(String type) {
//     switch (type) {
//       case 'task':
//         return const Text('Task');
//       case 'bug':
//         return const Text('Bug');
//       case 'feature':
//         return const Text('Feature');
//       default:
//         return Text(type);
//     }
//   }

//   Widget _calendarDateChip(String? dateStr) {
//     if (dateStr == null || dateStr.trim().isEmpty) {
//       return const Text('-');
//     }

//     final d = _onlyDate(dateStr);

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [
//         const Icon(
//           Icons.calendar_month_rounded,
//           size: 16,
//           color: AppColors.mutedText,
//         ),
//         const SizedBox(width: 6),
//         Text(d, style: const TextStyle(fontSize: 12)),
//       ],
//     );
//   }

//   Widget _dueChip(String? dueDate) {
//     if (dueDate == null || dueDate.trim().isEmpty) {
//       return const Text('-');
//     }

//     final dateOnly = _onlyDate(dueDate);
//     final overdue = _isOverdue(dueDate);

//     if (!overdue) {
//       return Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//         decoration: BoxDecoration(
//           color: AppColors.surface2,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(color: AppColors.border),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             const Icon(
//               Icons.calendar_month_rounded,
//               size: 16,
//               color: AppColors.mutedText,
//             ),
//             const SizedBox(width: 6),
//             Text(dateOnly, style: const TextStyle(fontSize: 12)),
//           ],
//         ),
//       );
//     }

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
//       decoration: BoxDecoration(
//         color: const Color(0xFF7F1D1D).withOpacity(0.35),
//         borderRadius: BorderRadius.circular(999),
//         border: Border.all(color: const Color(0xFFB91C1C).withOpacity(0.8)),
//       ),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           const Icon(
//             Icons.calendar_month_rounded,
//             size: 16,
//             color: Color(0xFFFCA5A5),
//           ),
//           const SizedBox(width: 6),
//           Text(
//             dateOnly,
//             style: const TextStyle(
//               fontSize: 12,
//               fontWeight: FontWeight.w700,
//               color: Color(0xFFFCA5A5),
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   String _initial(String name) {
//     final v = name.trim();
//     if (v.isEmpty) return '?';
//     return v[0].toUpperCase();
//   }

//   Widget _avatar(String name, {double size = 22}) {
//     final letter = _initial(name);

//     final h = name.hashCode.abs();
//     final base = 0xFF000000 | (h & 0x00FFFFFF);
//     final bg = Color(base).withOpacity(0.18);
//     final border = Color(base).withOpacity(0.35);

//     return Container(
//       width: size,
//       height: size,
//       alignment: Alignment.center,
//       decoration: BoxDecoration(
//         color: bg,
//         shape: BoxShape.circle,
//         border: Border.all(color: border),
//       ),
//       child: Text(
//         letter,
//         style: const TextStyle(
//           fontSize: 12,
//           fontWeight: FontWeight.w800,
//           color: AppColors.textPrimary,
//         ),
//       ),
//     );
//   }

//   ProjectUserEntity? _findUserById(String? id) {
//     if (id == null) return null;
//     for (final u in widget.projectUsers) {
//       if (u.id == id) return u;
//     }
//     return null;
//   }

//   // Description popup (read only)
//   void _showDescriptionPopup(String title, String description) {
//     showDialog(
//       context: context,
//       builder: (_) {
//         return AlertDialog(
//           title: Text(title),
//           content: ConstrainedBox(
//             constraints: const BoxConstraints(maxWidth: 560),
//             child: SingleChildScrollView(
//               child: SelectableText(
//                 description.trim().isEmpty ? '-' : description,
//               ),
//             ),
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Close'),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   void _confirmDelete(IssueEntity issue) {
//     showDialog(
//       context: context,
//       builder: (_) {
//         return AlertDialog(
//           title: const Text('Confirm Delete'),
//           content: Text(
//             'Are you sure you want to delete issue "${issue.title}"? This action cannot be undone.',
//           ),
//           actions: [
//             TextButton(
//               onPressed: () => Navigator.of(context).pop(),
//               child: const Text('Cancel'),
//             ),
//             ElevatedButton(
//               style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
//               onPressed: () {
//                 Navigator.of(context).pop();
//                 context.read<IssuesBloc>().add(
//                   IssueDeleteRequested(
//                     projectId: widget.projectId,
//                     issueId: issue.id,
//                   ),
//                 );
//               },
//               child: const Text('Delete', style: TextStyle(color: Colors.white)),
//             ),
//           ],
//         );
//       },
//     );
//   }

//   // EDIT MODE ONLY (dropdown)
//   Widget _jiraUserCell({
//     required String text,
//     required bool allowUnassigned,
//     required void Function(ProjectUserEntity? user) onSelected,
//   }) {
//     final display = text.trim().isEmpty ? '-' : text;

//     return PopupMenuButton<ProjectUserEntity?>(
//       tooltip: '',
//       padding: EdgeInsets.zero,
//       position: PopupMenuPosition.under,
//       onSelected: onSelected,
//       itemBuilder: (ctx) {
//         if (widget.projectUsers.isEmpty) {
//           return const [
//             PopupMenuItem<ProjectUserEntity?>(
//               enabled: false,
//               value: null,
//               child: Text('No users found'),
//             ),
//           ];
//         }

//         final items = <PopupMenuEntry<ProjectUserEntity?>>[];

//         if (allowUnassigned) {
//           final sentinel = ProjectUserEntity(
//             id: _kUnassignedSentinelId,
//             username: 'Unassigned',
//           );

//           items.add(
//             PopupMenuItem<ProjectUserEntity?>(
//               value: sentinel,
//               child: Row(
//                 children: const [
//                   Icon(
//                     Icons.person_off_outlined,
//                     size: 18,
//                     color: AppColors.mutedText,
//                   ),
//                   SizedBox(width: 10),
//                   Text('Unassigned'),
//                 ],
//               ),
//             ),
//           );
//           items.add(const PopupMenuDivider(height: 8));
//         }

//         for (final u in widget.projectUsers) {
//           items.add(
//             PopupMenuItem<ProjectUserEntity?>(
//               value: u,
//               child: Row(
//                 children: [
//                   _avatar(u.username, size: 24),
//                   const SizedBox(width: 10),
//                   Flexible(
//                     child: Text(u.username, overflow: TextOverflow.ellipsis),
//                   ),
//                 ],
//               ),
//             ),
//           );
//         }

//         return items;
//       },
//       child: MouseRegion(
//         cursor: SystemMouseCursors.click,
//         child: AnimatedContainer(
//           duration: const Duration(milliseconds: 120),
//           padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//           decoration: BoxDecoration(
//             color: AppColors.surface2,
//             borderRadius: BorderRadius.circular(10),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               _avatar(display),
//               const SizedBox(width: 8),
//               Flexible(
//                 child: Text(
//                   display,
//                   style: const TextStyle(fontSize: 12, height: 1.1),
//                   overflow: TextOverflow.ellipsis,
//                 ),
//               ),
//               const SizedBox(width: 6),
//               const Icon(
//                 Icons.keyboard_arrow_down_rounded,
//                 size: 18,
//                 color: AppColors.mutedText,
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }

//   Widget _jiraUserCellReadOnly({
//     required String text,
//     bool showUnassignedIcon = false,
//   }) {
//     final display = text.trim().isEmpty ? '-' : text;

//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//       child: Row(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           if (showUnassignedIcon && display.toLowerCase() == 'unassigned') ...[
//             const Icon(
//               Icons.person_off_outlined,
//               size: 16,
//               color: AppColors.mutedText,
//             ),
//             const SizedBox(width: 8),
//           ] else ...[
//             _avatar(display),
//             const SizedBox(width: 8),
//           ],
//           Flexible(
//             child: Text(
//               display,
//               style: const TextStyle(fontSize: 12, height: 1.1),
//               overflow: TextOverflow.ellipsis,
//             ),
//           ),
//         ],
//       ),
//     );
//   }

//   Future<void> _pickDueDate() async {
//     final now = DateTime.now();
//     final picked = await showDatePicker(
//       context: context,
//       firstDate: DateTime(now.year - 1),
//       lastDate: DateTime(now.year + 5),
//       initialDate: _due ?? now,
//     );
//     if (picked != null) {
//       setState(() {
//         _due = DateTime(picked.year, picked.month, picked.day);
//       });
//     }
//   }

//   void _startEdit(IssueEntity issue) {
//     setState(() {
//       _editingIssueId = issue.id;

//       _titleCtrl.text = issue.title;
//       _descCtrl.text = issue.description ?? '';

//       _type = issue.type;
//       _priority = issue.priority;
//       _status = issue.status;

//       _due = _parseDate(issue.dueDate);

//       _assigneeId = issue.assignee?.id; // null => Unassigned
//       _reporterId = issue.reporter.id;
//     });
//   }

//   void _cancelEdit() {
//     setState(() {
//       _editingIssueId = null;
//       _titleCtrl.clear();
//       _descCtrl.clear();
//       _type = 'task';
//       _priority = 'medium';
//       _status = 'todo';
//       _due = null;
//       _assigneeId = null;
//       _reporterId = '';
//     });
//   }

//   void _doneEdit(String issueId) {
//     final title = _titleCtrl.text.trim();
//     if (title.isEmpty) return;

//     context.read<IssuesBloc>().add(
//       IssueUpdateRequested(
//         projectId: widget.projectId,
//         issueId: issueId,
//         title: title,
//         description: _descCtrl.text.trim().isEmpty
//             ? null
//             : _descCtrl.text.trim(),
//         type: _type,
//         priority: _priority,
//         status: _status,
//         dueDate: _due,
//         assigneeId: _assigneeId,
//         reporterId: _reporterId,
//       ),
//     );

//     _cancelEdit();
//   }

//   //  Filtering logic (assignee + type + priority + status) (null-safe)
//   bool _matchesFilters(IssueEntity i) {
//     // Assignee (Jira-like people filter)
//     if (_assigneeFilter != _kAssigneeAll) {
//       if (_assigneeFilter == _kAssigneeUnassigned) {
//         if (i.assignee != null) return false;
//       } else {
//         if (i.assignee?.id != _assigneeFilter) return false;
//       }
//     }

//     final type = (i.type).trim();
//     final priority = (i.priority).trim();
//     final status = (i.status).trim();

//     if (_typeFilter != _kFilterAll && type != _typeFilter) return false;
//     if (_priorityFilter != _kFilterAll && priority != _priorityFilter) {
//       return false;
//     }
//     if (_statusFilter != _kFilterAll && status != _statusFilter) return false;

//     return true;
//   }

//   Widget _filterChip({
//     required String label,
//     required List<PopupMenuEntry<String>> items,
//     required void Function(String v) onSelected,
//   }) {
//     return PopupMenuButton<String>(
//       tooltip: '',
//       position: PopupMenuPosition.under,
//       onSelected: onSelected,
//       itemBuilder: (_) => items,
//       child: Container(
//         padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
//         decoration: BoxDecoration(
//           color: AppColors.surface2,
//           borderRadius: BorderRadius.circular(999),
//           border: Border.all(color: AppColors.border),
//         ),
//         child: Row(
//           mainAxisSize: MainAxisSize.min,
//           children: [
//             Text(label, style: const TextStyle(fontSize: 12)),
//             const SizedBox(width: 6),
//             const Icon(
//               Icons.keyboard_arrow_down_rounded,
//               size: 18,
//               color: AppColors.mutedText,
//             ),
//           ],
//         ),
//       ),
//     );
//   }

//   String _typeLabel() {
//     if (_typeFilter == _kFilterAll) return 'Type: All';
//     return 'Type: ${_typeFilter[0].toUpperCase()}${_typeFilter.substring(1)}';
//   }

//   String _priorityLabel() {
//     if (_priorityFilter == _kFilterAll) return 'Priority: All';
//     return 'Priority: ${_priorityFilter[0].toUpperCase()}${_priorityFilter.substring(1)}';
//   }

//   String _statusLabel() {
//     if (_statusFilter == _kFilterAll) return 'Status: All';
//     switch (_statusFilter) {
//       case 'in_progress':
//         return 'Status: In Progress';
//       case 'todo':
//         return 'Status: Todo';
//       case 'done':
//         return 'Status: Done';
//       default:
//         return 'Status: $_statusFilter';
//     }
//   }

//   int _activeFilterCount() {
//     int c = 0;

//     // people filter
//     if (_assigneeFilter != _kAssigneeAll) c++;

//     // type/priority/status filters
//     if (_typeFilter != _kFilterAll) c++;
//     if (_priorityFilter != _kFilterAll) c++;
//     if (_statusFilter != _kFilterAll) c++;

//     return c;
//   }

//   // REPLACE your current _assigneeStrip() with this Jira-like UI
//   Widget _assigneeStrip() {
//     final users = widget.projectUsers;

//     // show first 4 avatars like Jira, rest as +N
//     const double size = 28;
//     const double overlap = 18; // smaller => more overlap
//     final visibleCount = users.length > 4 ? 4 : users.length;
//     final remaining = users.length - visibleCount;
//     final stackCount = visibleCount + (remaining > 0 ? 1 : 0);

//     final stackWidth = stackCount == 0
//         ? 0.0
//         : (size + (stackCount - 1) * overlap);

//     // Popup menu items (same logic as before: All / Unassigned / user)
//     List<PopupMenuEntry<String>> menuItems() {
//       final items = <PopupMenuEntry<String>>[
//         const PopupMenuItem<String>(value: _kAssigneeAll, child: Text('All')),
//         const PopupMenuItem<String>(
//           value: _kAssigneeUnassigned,
//           child: Text('Unassigned'),
//         ),
//         const PopupMenuDivider(),
//       ];

//       for (final u in users) {
//         items.add(
//           PopupMenuItem<String>(
//             value: u.id,
//             child: Row(
//               children: [
//                 _avatar(u.username, size: 22),
//                 const SizedBox(width: 10),
//                 Flexible(
//                   child: Text(u.username, overflow: TextOverflow.ellipsis),
//                 ),
//               ],
//             ),
//           ),
//         );
//       }

//       return items;
//     }

//     Widget avatarCircle({required Widget child, required bool selected}) {
//       return Container(
//         width: size,
//         height: size,
//         decoration: BoxDecoration(
//           shape: BoxShape.circle,
//           border: Border.all(
//             color: selected
//                 ? AppColors.border
//                 : AppColors.border.withOpacity(0.6),
//             width: selected ? 2 : 1,
//           ),
//           color: AppColors.surface2,
//         ),
//         child: ClipOval(child: child),
//       );
//     }

//     // Jira-like overlapped avatars (clickable -> opens menu)
//     final avatars = PopupMenuButton<String>(
//       tooltip: '',
//       position: PopupMenuPosition.under,
//       itemBuilder: (_) => menuItems(),
//       onSelected: (v) => setState(() => _assigneeFilter = v),
//       child: SizedBox(
//         width: stackWidth,
//         height: size,
//         child: Stack(
//           clipBehavior: Clip.none,
//           children: [
//             for (int i = 0; i < visibleCount; i++)
//               Positioned(
//                 left: i * overlap,
//                 child: Tooltip(
//                   message: users[i].username,
//                   child: avatarCircle(
//                     selected: _assigneeFilter == users[i].id,
//                     child: Center(
//                       child: _avatar(users[i].username, size: size),
//                     ),
//                   ),
//                 ),
//               ),

//             if (remaining > 0)
//               Positioned(
//                 left: visibleCount * overlap,
//                 child: avatarCircle(
//                   selected: false,
//                   child: Center(
//                     child: Text(
//                       '+$remaining',
//                       style: const TextStyle(
//                         fontSize: 11,
//                         fontWeight: FontWeight.w800,
//                         color: AppColors.textPrimary,
//                       ),
//                     ),
//                   ),
//                 ),
//               ),
//           ],
//         ),
//       ),
//     );

//     // Filter button with active count (like Jira "Filter 1")
//     final count = _activeFilterCount();

//     final filterButton =
//         //  PopupMenuButton<String>(
//         //   tooltip: '',
//         //   position: PopupMenuPosition.under,
//         //   itemBuilder: (_) => menuItems(),
//         //   onSelected: (v) => setState(() => _assigneeFilter = v),
//         // child:
//         Container(
//           height: 32,
//           padding: const EdgeInsets.symmetric(horizontal: 10),
//           decoration: BoxDecoration(
//             color: AppColors.surface2,
//             borderRadius: BorderRadius.circular(8),
//             border: Border.all(color: AppColors.border),
//           ),
//           child: Row(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(
//                 Icons.filter_list,
//                 size: 16,
//                 color: AppColors.mutedText,
//               ),
//               const SizedBox(width: 8),
//               const Text('Filter', style: TextStyle(fontSize: 12)),
//               if (count > 0) ...[
//                 const SizedBox(width: 8),
//                 Container(
//                   padding: const EdgeInsets.symmetric(
//                     horizontal: 8,
//                     vertical: 4,
//                   ),
//                   decoration: BoxDecoration(
//                     color: AppColors.surface,
//                     borderRadius: BorderRadius.circular(999),
//                     border: Border.all(color: AppColors.border),
//                   ),
//                   child: Text(
//                     '$count',
//                     style: const TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w800,
//                     ),
//                   ),
//                 ),
//               ],
//             ],
//           ),
//         );
//     // ),
//     // );

//     return Row(
//       mainAxisSize: MainAxisSize.min,
//       children: [filterButton, const SizedBox(width: 10), avatars],
//     );
//   }

//   @override
//   Widget build(BuildContext context) {
//     if (widget.issues.isEmpty) {
//       return const Padding(
//         padding: EdgeInsets.all(12),
//         child: Text("No issues in this project yet."),
//       );
//     }

//     final filteredIssues = widget.issues.where(_matchesFilters).toList();

//     final hController = ScrollController();

//     return Container(
//       margin: const EdgeInsets.symmetric(horizontal: 12),
//       decoration: BoxDecoration(
//         color: AppColors.surface,
//         border: Border.all(color: AppColors.border),
//         borderRadius: BorderRadius.circular(12),
//       ),
//       child: ClipRRect(
//         borderRadius: BorderRadius.circular(12),
//         child: Scrollbar(
//           controller: hController,
//           thumbVisibility: true,
//           notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
//           child: Listener(
//             onPointerSignal: (signal) {
//               if (signal is PointerScrollEvent) {
//                 final delta = signal.scrollDelta.dy;

//                 if (!hController.hasClients) return;

//                 final maxExtent = hController.position.maxScrollExtent;
//                 final minExtent = hController.position.minScrollExtent;

//                 final next = (hController.offset + delta).clamp(
//                   minExtent,
//                   maxExtent,
//                 );

//                 hController.jumpTo(next);
//               }
//             },
//             child: SingleChildScrollView(
//               controller: hController,
//               scrollDirection: Axis.horizontal,
//               physics: const ClampingScrollPhysics(),
//               child: ConstrainedBox(
//                 constraints: BoxConstraints(
//                   minWidth: MediaQuery.of(context).size.width,
//                 ),
//                 child: Padding(
//                   padding: const EdgeInsets.only(right: 16),
//                   child: BlocBuilder<IssuesBloc, IssuesState>(
//                     builder: (context, state) {
//                       final isUpdating = state is IssuesLoaded
//                           ? state.isUpdating
//                           : false;

//                       return Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Padding(
//                             padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
//                             child: Wrap(
//                               spacing: 10,
//                               runSpacing: 10,
//                               crossAxisAlignment: WrapCrossAlignment.center,
//                               children: [

//                                 // filter chip: assignee
//                                 _assigneeStrip(),

//                                 // filter chip : type         
//                                 _filterChip(
//                                   label: _typeLabel(),
//                                   items: const [
//                                     PopupMenuItem(
//                                       value: _kFilterAll,
//                                       child: Text('All'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'task',
//                                       child: Text('Task'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'bug',
//                                       child: Text('Bug'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'feature',
//                                       child: Text('Feature'),
//                                     ),
//                                   ],
//                                   onSelected: (v) =>
//                                       setState(() => _typeFilter = v),
//                                 ),

//                                 // filter chip : priority
//                                 _filterChip(
//                                   label: _priorityLabel(),
//                                   items: const [
//                                     PopupMenuItem(
//                                       value: _kFilterAll,
//                                       child: Text('All'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'low',
//                                       child: Text('Low'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'medium',
//                                       child: Text('Medium'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'high',
//                                       child: Text('High'),
//                                     ),
//                                   ],
//                                   onSelected: (v) =>
//                                       setState(() => _priorityFilter = v),
//                                 ),

//                                 // filter chip: status
//                                 _filterChip(
//                                   label: _statusLabel(),
//                                   items: const [
//                                     PopupMenuItem(
//                                       value: _kFilterAll,
//                                       child: Text('All'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'todo',
//                                       child: Text('Todo'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'in_progress',
//                                       child: Text('In Progress'),
//                                     ),
//                                     PopupMenuItem(
//                                       value: 'done',
//                                       child: Text('Done'),
//                                     ),
//                                   ],
//                                   onSelected: (v) =>
//                                       setState(() => _statusFilter = v),
//                                 ),
//                                 OutlinedButton.icon(
//                                   onPressed: () {
//                                     setState(() {
//                                       _assigneeFilter = _kAssigneeAll;
//                                       _typeFilter = _kFilterAll;
//                                       _priorityFilter = _kFilterAll;
//                                       _statusFilter = _kFilterAll;
//                                     });
//                                   },
//                                   icon: const Icon(Icons.clear, size: 16),
//                                   label: const Text('Clear'),
//                                 ),
//                                 Text(
//                                   'Showing ${filteredIssues.length}/${widget.issues.length}',
//                                   style: const TextStyle(
//                                     fontSize: 12,
//                                     color: AppColors.mutedText,
//                                   ),
//                                 ),
//                               ],
//                             ),
//                           ),

//                           DataTable(
//                             headingRowColor: const MaterialStatePropertyAll(
//                               AppColors.surface2,
//                             ),
//                             columns: const [
//                               DataColumn(label: Text('Key')),
//                               DataColumn(label: Text('Title')),
//                               DataColumn(label: Text('Description')),
//                               DataColumn(label: Text('Type')),
//                               DataColumn(label: Text('Priority')),
//                               DataColumn(label: Text('Status')),
//                               DataColumn(label: Text('Assignee')),
//                               DataColumn(label: Text('Reporter')),
//                               DataColumn(label: Text('Due')),
//                               DataColumn(label: Text('Created At')),
//                               DataColumn(label: Text('Updated At')),
//                               DataColumn(label: Text('Actions')),
//                             ],

//                             rows: filteredIssues.map((i) {
//                               final editing = _editingIssueId == i.id;

//                               return DataRow(
//                                 cells: [
//                                   DataCell(Text(i.key)),

//                                   // Title
//                                   DataCell(
//                                     editing
//                                         ? ConstrainedBox(
//                                             constraints: const BoxConstraints(
//                                               maxWidth: 280,
//                                             ),
//                                             child: TextField(
//                                               controller: _titleCtrl,
//                                               decoration: const InputDecoration(
//                                                 isDense: true,
//                                                 border: OutlineInputBorder(),
//                                                 contentPadding:
//                                                     EdgeInsets.symmetric(
//                                                       horizontal: 10,
//                                                       vertical: 10,
//                                                     ),
//                                               ),
//                                             ),
//                                           )
//                                         : ConstrainedBox(
//                                             constraints: const BoxConstraints(
//                                               maxWidth: 280,
//                                             ),
//                                             child: Text(
//                                               i.title,
//                                               overflow: TextOverflow.ellipsis,
//                                             ),
//                                           ),
//                                   ),

//                                   // Description
//                                   DataCell(
//                                     editing
//                                         ? ConstrainedBox(
//                                             constraints: const BoxConstraints(
//                                               maxWidth: 340,
//                                             ),
//                                             child: TextField(
//                                               controller: _descCtrl,
//                                               maxLines: 3,
//                                               minLines: 1,
//                                               decoration: const InputDecoration(
//                                                 isDense: true,
//                                                 border: OutlineInputBorder(),
//                                                 contentPadding:
//                                                     EdgeInsets.symmetric(
//                                                       horizontal: 10,
//                                                       vertical: 10,
//                                                     ),
//                                               ),
//                                             ),
//                                           )
//                                         : ConstrainedBox(
//                                             constraints: const BoxConstraints(
//                                               maxWidth: 340,
//                                             ),
//                                             child: InkWell(
//                                               onTap: () =>
//                                                   _showDescriptionPopup(
//                                                     i.title,
//                                                     i.description ?? '',
//                                                   ),
//                                               child: Text(
//                                                 (i.description == null ||
//                                                         i.description!
//                                                             .trim()
//                                                             .isEmpty)
//                                                     ? '-'
//                                                     : i.description!.trim(),
//                                                 maxLines: 2,
//                                                 overflow: TextOverflow.ellipsis,
//                                                 style: const TextStyle(
//                                                   decoration:
//                                                       TextDecoration.underline,
//                                                 ),
//                                               ),
//                                             ),
//                                           ),
//                                   ),

//                                   // Type
//                                   DataCell(
//                                     editing
//                                         ? DropdownButtonFormField<String>(
//                                             value: _type,
//                                             decoration: const InputDecoration(
//                                               isDense: true,
//                                               border: OutlineInputBorder(),
//                                               contentPadding:
//                                                   EdgeInsets.symmetric(
//                                                     horizontal: 10,
//                                                     vertical: 10,
//                                                   ),
//                                             ),
//                                             items: const [
//                                               DropdownMenuItem(
//                                                 value: 'task',
//                                                 child: Text('Task'),
//                                               ),
//                                               DropdownMenuItem(
//                                                 value: 'bug',
//                                                 child: Text('Bug'),
//                                               ),
//                                               DropdownMenuItem(
//                                                 value: 'feature',
//                                                 child: Text('Feature'),
//                                               ),
//                                             ],
//                                             onChanged: (v) => setState(
//                                               () => _type = v ?? 'task',
//                                             ),
//                                           )
//                                         : typeWidegt(i.type),
//                                   ),

//                                   // Priority
//                                   DataCell(
//                                     editing
//                                         ? DropdownButtonFormField<String>(
//                                             value: _priority,
//                                             decoration: const InputDecoration(
//                                               isDense: true,
//                                               border: OutlineInputBorder(),
//                                               contentPadding:
//                                                   EdgeInsets.symmetric(
//                                                     horizontal: 10,
//                                                     vertical: 10,
//                                                   ),
//                                             ),
//                                             items: const [
//                                               DropdownMenuItem(
//                                                 value: 'low',
//                                                 child: Text('Low'),
//                                               ),
//                                               DropdownMenuItem(
//                                                 value: 'medium',
//                                                 child: Text('Medium'),
//                                               ),
//                                               DropdownMenuItem(
//                                                 value: 'high',
//                                                 child: Text('High'),
//                                               ),
//                                             ],
//                                             onChanged: (v) => setState(
//                                               () => _priority = v ?? 'medium',
//                                             ),
//                                           )
//                                         : PriorityBadge(priority: i.priority),
//                                   ),

//                                   // Status
//                                   DataCell(
//                                     editing
//                                         ? DropdownButtonFormField<String>(
//                                             value: _status,
//                                             decoration: const InputDecoration(
//                                               isDense: true,
//                                               border: OutlineInputBorder(),
//                                               contentPadding:
//                                                   EdgeInsets.symmetric(
//                                                     horizontal: 10,
//                                                     vertical: 10,
//                                                   ),
//                                             ),
//                                             items: const [
//                                               DropdownMenuItem(
//                                                 value: 'todo',
//                                                 child: Text('Todo'),
//                                               ),
//                                               DropdownMenuItem(
//                                                 value: 'in_progress',
//                                                 child: Text('In Progress'),
//                                               ),
//                                               DropdownMenuItem(
//                                                 value: 'done',
//                                                 child: Text('Done'),
//                                               ),
//                                             ],
//                                             onChanged: (v) => setState(
//                                               () => _status = v ?? 'todo',
//                                             ),
//                                           )
//                                         : StatusBadge(status: i.status),
//                                   ),

//                                   // Assignee
//                                   DataCell(
//                                     editing
//                                         ? _jiraUserCell(
//                                             text:
//                                                 (_findUserById(
//                                                   _assigneeId,
//                                                 )?.username) ??
//                                                 'Unassigned',
//                                             allowUnassigned: true,
//                                             onSelected: (u) {
//                                               setState(() {
//                                                 if (u?.id ==
//                                                     _kUnassignedSentinelId) {
//                                                   _assigneeId = null;
//                                                 } else {
//                                                   _assigneeId = u?.id;
//                                                 }
//                                               });
//                                             },
//                                           )
//                                         : _jiraUserCellReadOnly(
//                                             text:
//                                                 i.assignee?.username ??
//                                                 'Unassigned',
//                                             showUnassignedIcon: true,
//                                           ),
//                                   ),

//                                   // Reporter
//                                   DataCell(
//                                     editing
//                                         ? _jiraUserCell(
//                                             text:
//                                                 (_findUserById(
//                                                   _reporterId,
//                                                 )?.username) ??
//                                                 i.reporter.username,
//                                             allowUnassigned: false,
//                                             onSelected: (u) {
//                                               if (u == null) return;
//                                               setState(() {
//                                                 _reporterId = u.id;
//                                               });
//                                             },
//                                           )
//                                         : _jiraUserCellReadOnly(
//                                             text: i.reporter.username,
//                                           ),
//                                   ),

//                                   // Due
//                                   DataCell(
//                                     editing
//                                         ? Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               InkWell(
//                                                 onTap: _pickDueDate,
//                                                 child: Container(
//                                                   padding:
//                                                       const EdgeInsets.symmetric(
//                                                         horizontal: 10,
//                                                         vertical: 6,
//                                                       ),
//                                                   decoration: BoxDecoration(
//                                                     color: AppColors.surface2,
//                                                     borderRadius:
//                                                         BorderRadius.circular(
//                                                           999,
//                                                         ),
//                                                     border: Border.all(
//                                                       color: AppColors.border,
//                                                     ),
//                                                   ),
//                                                   child: Row(
//                                                     mainAxisSize:
//                                                         MainAxisSize.min,
//                                                     children: [
//                                                       const Icon(
//                                                         Icons
//                                                             .calendar_month_rounded,
//                                                         size: 16,
//                                                         color:
//                                                             AppColors.mutedText,
//                                                       ),
//                                                       const SizedBox(width: 6),
//                                                       Text(
//                                                         _due == null
//                                                             ? '-'
//                                                             : '${_due!.year}-${_due!.month.toString().padLeft(2, '0')}-${_due!.day.toString().padLeft(2, '0')}',
//                                                         style: const TextStyle(
//                                                           fontSize: 12,
//                                                         ),
//                                                       ),
//                                                     ],
//                                                   ),
//                                                 ),
//                                               ),
//                                               if (_due != null) ...[
//                                                 const SizedBox(width: 8),
//                                                 IconButton(
//                                                   tooltip: 'Clear',
//                                                   onPressed: () => setState(
//                                                     () => _due = null,
//                                                   ),
//                                                   icon: const Icon(
//                                                     Icons.clear,
//                                                     size: 18,
//                                                     color: AppColors.mutedText,
//                                                   ),
//                                                 ),
//                                               ],
//                                             ],
//                                           )
//                                         : _dueChip(i.dueDate),
//                                   ),
                                  
//                                   // Created At       
//                                   DataCell(_calendarDateChip(i.createdAt)),

//                                   // Updated At
//                                   DataCell(_calendarDateChip(i.updatedAt)),

//                                   // Actions (Edit + Delete)
//                                   DataCell(
//                                     editing
//                                         ? Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               ElevatedButton(
//                                                 onPressed: isUpdating
//                                                     ? null
//                                                     : () => _doneEdit(i.id),
//                                                 child: const Text('Done'),
//                                               ),
//                                               const SizedBox(width: 8),
//                                               OutlinedButton(
//                                                 onPressed: isUpdating
//                                                     ? null
//                                                     : _cancelEdit,
//                                                 child: const Text('Cancel'),
//                                               ),
//                                             ],
//                                           )
//                                         : Row(
//                                             mainAxisSize: MainAxisSize.min,
//                                             children: [
//                                               OutlinedButton(
//                                                 onPressed: isUpdating
//                                                     ? null
//                                                     : () => _startEdit(i),
//                                                 child: const Text('Edit'),
//                                               ),
//                                               const SizedBox(width: 8),
//                                               IconButton(
//                                                 tooltip: 'Delete issue',
//                                                 onPressed: isUpdating
//                                                     ? null
//                                                     : () => _confirmDelete(i),
//                                                 icon: const Icon(
//                                                   Icons.delete_outline,
//                                                   color: Colors.red,
//                                                 ),
//                                               ),
//                                             ],
//                                           ),
//                                   ),
//                                 ],
//                               );
//                             }).toList(),
//                           ),
//                         ],
//                       );
//                     },
//                   ),
//                 ),
//               ),
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }


import 'dart:math' as math;
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/theme/app_colors.dart';
import '../../domain/entities/issue_entity.dart';
import '../../domain/entities/project_user_entity.dart';
import '../bloc/issues_bloc.dart';
import '../bloc/issues_event.dart';
import '../bloc/issues_state.dart';
import 'priority_badge.dart';
import 'status_badge.dart';



  // ---------- COMMENTS UI ONLY ----------
  class _ChatMessage {
    final String senderId;
    final String senderName;
    final String text;
    final DateTime createdAt;

    const _ChatMessage({
      required this.senderId,
      required this.senderName,
      required this.text,
      required this.createdAt,
    });
  }

class IssuesTable extends StatefulWidget {
  final String projectId;
  final List<IssueEntity> issues;
  final List<ProjectUserEntity> projectUsers;

  const IssuesTable({
    super.key,
    required this.projectId,
    required this.issues,
    required this.projectUsers,
  });

  @override
  State<IssuesTable> createState() => _IssuesTableState();
}

class _IssuesTableState extends State<IssuesTable> {
  String? _editingIssueId;

  final _titleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();

  String _type = 'task';
  String _priority = 'medium';
  String _status = 'todo';

  DateTime? _due;
  String? _assigneeId;
  String _reporterId = '';

  static const String _kUnassignedSentinelId = '__UNASSIGNED__';

  static const String _kFilterAll = '__ALL__';
  String _typeFilter = _kFilterAll; // all | task | bug | feature
  String _priorityFilter = _kFilterAll; // all | low | medium | high
  String _statusFilter = _kFilterAll; // all | todo | in_progress | done

  static const String _kAssigneeAll = '__ASSIGNEE_ALL__';
  static const String _kAssigneeUnassigned = '__ASSIGNEE_UNASSIGNED__';
  String _assigneeFilter = _kAssigneeAll;


  final Map<String, List<_ChatMessage>> _issueChats = {}; // issueId -> messages
  final TextEditingController _chatCtrl = TextEditingController();

  @override
  void dispose() {
    _titleCtrl.dispose();
    _descCtrl.dispose();
    _chatCtrl.dispose();
    super.dispose();
  }

  // ---------- DATE HELPERS ----------
  bool _isOverdue(String dueDateStr) {
    try {
      final s = dueDateStr.trim();
      if (s.isEmpty) return false;

      final normalized = s.contains(' ') ? s.replaceFirst(' ', 'T') : s;

      final parsed = DateTime.parse(normalized);
      final due = DateTime(parsed.year, parsed.month, parsed.day);

      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      return due.isBefore(today);
    } catch (_) {
      return false;
    }
  }

  String _onlyDate(String s) {
    final v = s.trim();
    if (v.isEmpty) return v;
    if (v.length >= 10) return v.substring(0, 10);
    return v;
  }

  DateTime? _parseDate(String? s) {
    if (s == null || s.trim().isEmpty) return null;
    try {
      final raw = s.trim();
      final normalized = raw.contains(' ') ? raw.replaceFirst(' ', 'T') : raw;
      final d = DateTime.parse(normalized);
      return DateTime(d.year, d.month, d.day);
    } catch (_) {
      try {
        final d = DateTime.parse(_onlyDate(s));
        return DateTime(d.year, d.month, d.day);
      } catch (_) {
        return null;
      }
    }
  }

  // ---------- UI HELPERS ----------
  Widget typeWidegt(String type) {
    switch (type) {
      case 'task':
        return const Text('Task');
      case 'bug':
        return const Text('Bug');
      case 'feature':
        return const Text('Feature');
      default:
        return Text(type);
    }
  }

  Widget _calendarDateChip(String? dateStr) {
    if (dateStr == null || dateStr.trim().isEmpty) {
      return const Text('-');
    }

    final d = _onlyDate(dateStr);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        const Icon(
          Icons.calendar_month_rounded,
          size: 16,
          color: AppColors.mutedText,
        ),
        const SizedBox(width: 6),
        Text(d, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _dueChip(String? dueDate) {
    if (dueDate == null || dueDate.trim().isEmpty) {
      return const Text('-');
    }

    final dateOnly = _onlyDate(dueDate);
    final overdue = _isOverdue(dueDate);

    if (!overdue) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.calendar_month_rounded,
              size: 16,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 6),
            Text(dateOnly, style: const TextStyle(fontSize: 12)),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFF7F1D1D).withOpacity(0.35),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: const Color(0xFFB91C1C).withOpacity(0.8)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.calendar_month_rounded,
            size: 16,
            color: Color(0xFFFCA5A5),
          ),
          const SizedBox(width: 6),
          Text(
            dateOnly,
            style: const TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: Color(0xFFFCA5A5),
            ),
          ),
        ],
      ),
    );
  }

  String _initial(String name) {
    final v = name.trim();
    if (v.isEmpty) return '?';
    return v[0].toUpperCase();
  }

  Widget _avatar(String name, {double size = 22}) {
    final letter = _initial(name);

    final h = name.hashCode.abs();
    final base = 0xFF000000 | (h & 0x00FFFFFF);
    final bg = Color(base).withOpacity(0.18);
    final border = Color(base).withOpacity(0.35);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  ProjectUserEntity? _findUserById(String? id) {
    if (id == null) return null;
    for (final u in widget.projectUsers) {
      if (u.id == id) return u;
    }
    return null;
  }

  // ---------- POPUPS ----------
  void _showDescriptionPopup(String title, String description) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: Text(title),
          content: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: SingleChildScrollView(
              child: SelectableText(
                description.trim().isEmpty ? '-' : description,
              ),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Close'),
            ),
          ],
        );
      },
    );
  }

  void _confirmDelete(IssueEntity issue) {
    showDialog(
      context: context,
      builder: (_) {
        return AlertDialog(
          title: const Text('Confirm Delete'),
          content: Text(
            'Are you sure you want to delete issue "${issue.title}"? This action cannot be undone.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () {
                Navigator.of(context).pop();
                context.read<IssuesBloc>().add(
                      IssueDeleteRequested(
                        projectId: widget.projectId,
                        issueId: issue.id,
                      ),
                    );
              },
              child: const Text('Delete', style: TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
  }

  // ---------- EDIT MODE ONLY (dropdown) ----------
  Widget _jiraUserCell({
    required String text,
    required bool allowUnassigned,
    required void Function(ProjectUserEntity? user) onSelected,
  }) {
    final display = text.trim().isEmpty ? '-' : text;

    return PopupMenuButton<ProjectUserEntity?>(
      tooltip: '',
      padding: EdgeInsets.zero,
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (ctx) {
        if (widget.projectUsers.isEmpty) {
          return const [
            PopupMenuItem<ProjectUserEntity?>(
              enabled: false,
              value: null,
              child: Text('No users found'),
            ),
          ];
        }

        final items = <PopupMenuEntry<ProjectUserEntity?>>[];

        if (allowUnassigned) {
          final sentinel = ProjectUserEntity(
            id: _kUnassignedSentinelId,
            username: 'Unassigned',
          );

          items.add(
            PopupMenuItem<ProjectUserEntity?>(
              value: sentinel,
              child: Row(
                children: const [
                  Icon(
                    Icons.person_off_outlined,
                    size: 18,
                    color: AppColors.mutedText,
                  ),
                  SizedBox(width: 10),
                  Text('Unassigned'),
                ],
              ),
            ),
          );
          items.add(const PopupMenuDivider(height: 8));
        }

        for (final u in widget.projectUsers) {
          items.add(
            PopupMenuItem<ProjectUserEntity?>(
              value: u,
              child: Row(
                children: [
                  _avatar(u.username, size: 24),
                  const SizedBox(width: 10),
                  Flexible(
                    child: Text(u.username, overflow: TextOverflow.ellipsis),
                  ),
                ],
              ),
            ),
          );
        }

        return items;
      },
      child: MouseRegion(
        cursor: SystemMouseCursors.click,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 120),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
          decoration: BoxDecoration(
            color: AppColors.surface2,
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: AppColors.border),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              _avatar(display),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  display,
                  style: const TextStyle(fontSize: 12, height: 1.1),
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 6),
              const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 18,
                color: AppColors.mutedText,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _jiraUserCellReadOnly({
    required String text,
    bool showUnassignedIcon = false,
  }) {
    final display = text.trim().isEmpty ? '-' : text;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (showUnassignedIcon && display.toLowerCase() == 'unassigned') ...[
            const Icon(
              Icons.person_off_outlined,
              size: 16,
              color: AppColors.mutedText,
            ),
            const SizedBox(width: 8),
          ] else ...[
            _avatar(display),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Text(
              display,
              style: const TextStyle(fontSize: 12, height: 1.1),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _pickDueDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      firstDate: DateTime(now.year - 1),
      lastDate: DateTime(now.year + 5),
      initialDate: _due ?? now,
    );
    if (picked != null) {
      setState(() {
        _due = DateTime(picked.year, picked.month, picked.day);
      });
    }
  }

  void _startEdit(IssueEntity issue) {
    setState(() {
      _editingIssueId = issue.id;

      _titleCtrl.text = issue.title;
      _descCtrl.text = issue.description ?? '';

      _type = issue.type;
      _priority = issue.priority;
      _status = issue.status;

      _due = _parseDate(issue.dueDate);

      _assigneeId = issue.assignee?.id; // null => Unassigned
      _reporterId = issue.reporter.id;
    });
  }

  void _cancelEdit() {
    setState(() {
      _editingIssueId = null;
      _titleCtrl.clear();
      _descCtrl.clear();
      _type = 'task';
      _priority = 'medium';
      _status = 'todo';
      _due = null;
      _assigneeId = null;
      _reporterId = '';
    });
  }

  void _doneEdit(String issueId) {
    final title = _titleCtrl.text.trim();
    if (title.isEmpty) return;

    context.read<IssuesBloc>().add(
          IssueUpdateRequested(
            projectId: widget.projectId,
            issueId: issueId,
            title: title,
            description: _descCtrl.text.trim().isEmpty ? null : _descCtrl.text.trim(),
            type: _type,
            priority: _priority,
            status: _status,
            dueDate: _due,
            assigneeId: _assigneeId,
            reporterId: _reporterId,
          ),
        );

    _cancelEdit();
  }

  // ---------- FILTER LOGIC ----------
  bool _matchesFilters(IssueEntity i) {
    if (_assigneeFilter != _kAssigneeAll) {
      if (_assigneeFilter == _kAssigneeUnassigned) {
        if (i.assignee != null) return false;
      } else {
        if (i.assignee?.id != _assigneeFilter) return false;
      }
    }

    final type = (i.type).trim();
    final priority = (i.priority).trim();
    final status = (i.status).trim();

    if (_typeFilter != _kFilterAll && type != _typeFilter) return false;
    if (_priorityFilter != _kFilterAll && priority != _priorityFilter) return false;
    if (_statusFilter != _kFilterAll && status != _statusFilter) return false;

    return true;
  }

  Widget _filterChip({
    required String label,
    required List<PopupMenuEntry<String>> items,
    required void Function(String v) onSelected,
  }) {
    return PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      onSelected: onSelected,
      itemBuilder: (_) => items,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label, style: const TextStyle(fontSize: 12)),
            const SizedBox(width: 6),
            const Icon(
              Icons.keyboard_arrow_down_rounded,
              size: 18,
              color: AppColors.mutedText,
            ),
          ],
        ),
      ),
    );
  }

  String _typeLabel() {
    if (_typeFilter == _kFilterAll) return 'Type: All';
    return 'Type: ${_typeFilter[0].toUpperCase()}${_typeFilter.substring(1)}';
  }

  String _priorityLabel() {
    if (_priorityFilter == _kFilterAll) return 'Priority: All';
    return 'Priority: ${_priorityFilter[0].toUpperCase()}${_priorityFilter.substring(1)}';
  }

  String _statusLabel() {
    if (_statusFilter == _kFilterAll) return 'Status: All';
    switch (_statusFilter) {
      case 'in_progress':
        return 'Status: In Progress';
      case 'todo':
        return 'Status: Todo';
      case 'done':
        return 'Status: Done';
      default:
        return 'Status: $_statusFilter';
    }
  }

  int _activeFilterCount() {
    int c = 0;
    if (_assigneeFilter != _kAssigneeAll) c++;
    if (_typeFilter != _kFilterAll) c++;
    if (_priorityFilter != _kFilterAll) c++;
    if (_statusFilter != _kFilterAll) c++;
    return c;
  }

  // ---------- ASSIGNEE STRIP (unchanged) ----------
  Widget _assigneeStrip() {
    final users = widget.projectUsers;

    const double size = 28;
    const double overlap = 18;
    final visibleCount = users.length > 4 ? 4 : users.length;
    final remaining = users.length - visibleCount;
    final stackCount = visibleCount + (remaining > 0 ? 1 : 0);

    final stackWidth = stackCount == 0 ? 0.0 : (size + (stackCount - 1) * overlap);

    List<PopupMenuEntry<String>> menuItems() {
      final items = <PopupMenuEntry<String>>[
        const PopupMenuItem<String>(value: _kAssigneeAll, child: Text('All')),
        const PopupMenuItem<String>(value: _kAssigneeUnassigned, child: Text('Unassigned')),
        const PopupMenuDivider(),
      ];

      for (final u in users) {
        items.add(
          PopupMenuItem<String>(
            value: u.id,
            child: Row(
              children: [
                _avatar(u.username, size: 22),
                const SizedBox(width: 10),
                Flexible(child: Text(u.username, overflow: TextOverflow.ellipsis)),
              ],
            ),
          ),
        );
      }

      return items;
    }

    Widget avatarCircle({required Widget child, required bool selected}) {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: selected ? AppColors.border : AppColors.border.withOpacity(0.6),
            width: selected ? 2 : 1,
          ),
          color: AppColors.surface2,
        ),
        child: ClipOval(child: child),
      );
    }

    final avatars = PopupMenuButton<String>(
      tooltip: '',
      position: PopupMenuPosition.under,
      itemBuilder: (_) => menuItems(),
      onSelected: (v) => setState(() => _assigneeFilter = v),
      child: SizedBox(
        width: stackWidth,
        height: size,
        child: Stack(
          clipBehavior: Clip.none,
          children: [
            for (int i = 0; i < visibleCount; i++)
              Positioned(
                left: i * overlap,
                child: Tooltip(
                  message: users[i].username,
                  child: avatarCircle(
                    selected: _assigneeFilter == users[i].id,
                    child: Center(child: _avatar(users[i].username, size: size)),
                  ),
                ),
              ),
            if (remaining > 0)
              Positioned(
                left: visibleCount * overlap,
                child: avatarCircle(
                  selected: false,
                  child: Center(
                    child: Text(
                      '+$remaining',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );

    final count = _activeFilterCount();

    final filterButton = Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.surface2,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.filter_list, size: 16, color: AppColors.mutedText),
          const SizedBox(width: 8),
          const Text('Filter', style: TextStyle(fontSize: 12)),
          if (count > 0) ...[
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(999),
                border: Border.all(color: AppColors.border),
              ),
              child: Text(
                '$count',
                style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
              ),
            ),
          ],
        ],
      ),
    );

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [filterButton, const SizedBox(width: 10), avatars],
    );
  }

  // ---------- COMMENTS UI (table cell + open panel) ----------
  bool _isMobileLike(BuildContext context) => MediaQuery.of(context).size.width < 720;

  List<_ChatMessage> _messagesFor(String issueId) => _issueChats.putIfAbsent(issueId, () => []);

  void _sendMessage({
    required IssueEntity issue,
    required String text,
  }) {
    final trimmed = text.trim();
    if (trimmed.isEmpty) return;

     if (!mounted) return; 

    setState(() {
      _messagesFor(issue.id).add(
        _ChatMessage(
          senderId: 'me',
          senderName: 'You',
          text: trimmed,
          createdAt: DateTime.now(),
        ),
      );
    });
  }

  Widget _commentsCell(IssueEntity issue) {
    final count = _messagesFor(issue.id).length;
    return InkWell(
      borderRadius: BorderRadius.circular(10),
      onTap: () => _openComments(issue),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: AppColors.surface2,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.chat_bubble_outline, size: 16, color: AppColors.mutedText),
            const SizedBox(width: 8),
            Text(
              count == 0 ? 'Add comment' : '$count comments',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.chevron_right_rounded, size: 18, color: AppColors.mutedText),
          ],
        ),
      ),
    );
  }

  void _openComments(IssueEntity issue) {
    _chatCtrl.clear();

    if (_isMobileLike(context)) {
      _openCommentsBottomSheet(issue);
    } else {
      _openCommentsSideDrawer(issue);
    }
  }

  void _openCommentsBottomSheet(IssueEntity issue) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) {
        final viewInsets = MediaQuery.of(ctx).viewInsets.bottom;
        return AnimatedPadding(
          duration: const Duration(milliseconds: 180),
          curve: Curves.easeOut,
          padding: EdgeInsets.only(bottom: viewInsets),
          child: IssueCommentsSheet(
            headerTitle: '${issue.key} • ${issue.title}',
            projectUsers: widget.projectUsers,
            messages: _messagesFor(issue.id),
            controller: _chatCtrl,
            onSend: (text) => _sendMessage(issue: issue, text: text),
            onClose: () => Navigator.of(ctx).pop(),
            isMobile: true,
          ),
        );
      },
    );
  }

  void _openCommentsSideDrawer(IssueEntity issue) {
    showGeneralDialog(
      context: context,
      barrierLabel: 'Comments',
      barrierDismissible: true,
      barrierColor: Colors.black.withOpacity(0.35),
      transitionDuration: const Duration(milliseconds: 220),
      pageBuilder: (ctx, a1, a2) {
        return Align(
          alignment: Alignment.centerRight,
          child: Padding(
            padding: const EdgeInsets.only(right: 12),
            child: IssueCommentsSheet(
              headerTitle: '${issue.key} • ${issue.title}',
              projectUsers: widget.projectUsers,
              messages: _messagesFor(issue.id),
              controller: _chatCtrl,
              onSend: (text) => _sendMessage(issue: issue, text: text),
              onClose: () => Navigator.of(ctx).pop(),
              isMobile: false,
            ),
          ),
        );
      },
      transitionBuilder: (ctx, anim, _, child) {
        final slide = Tween<Offset>(
          begin: const Offset(1, 0),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: anim, curve: Curves.easeOutCubic));

        final fade = Tween<double>(begin: 0, end: 1).animate(anim);

        return FadeTransition(
          opacity: fade,
          child: SlideTransition(position: slide, child: child),
        );
      },
    );
  }

  // ---------- BUILD ----------
  @override
  Widget build(BuildContext context) {
    if (widget.issues.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: Text("No issues in this project yet."),
      );
    }

    final filteredIssues = widget.issues.where(_matchesFilters).toList();
    final hController = ScrollController();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: Border.all(color: AppColors.border),
        borderRadius: BorderRadius.circular(12),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Scrollbar(
          controller: hController,
          thumbVisibility: true,
          notificationPredicate: (n) => n.metrics.axis == Axis.horizontal,
          child: Listener(
            onPointerSignal: (signal) {
              if (signal is PointerScrollEvent) {
                final delta = signal.scrollDelta.dy;
                if (!hController.hasClients) return;

                final maxExtent = hController.position.maxScrollExtent;
                final minExtent = hController.position.minScrollExtent;
                final next = (hController.offset + delta).clamp(minExtent, maxExtent);
                hController.jumpTo(next);
              }
            },
            child: SingleChildScrollView(
              controller: hController,
              scrollDirection: Axis.horizontal,
              physics: const ClampingScrollPhysics(),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minWidth: MediaQuery.of(context).size.width,
                ),
                child: Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: BlocBuilder<IssuesBloc, IssuesState>(
                    builder: (context, state) {
                      final isUpdating = state is IssuesLoaded ? state.isUpdating : false;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.fromLTRB(12, 12, 12, 8),
                            child: Wrap(
                              spacing: 10,
                              runSpacing: 10,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                _assigneeStrip(),
                                _filterChip(
                                  label: _typeLabel(),
                                  items: const [
                                    PopupMenuItem(value: _kFilterAll, child: Text('All')),
                                    PopupMenuItem(value: 'task', child: Text('Task')),
                                    PopupMenuItem(value: 'bug', child: Text('Bug')),
                                    PopupMenuItem(value: 'feature', child: Text('Feature')),
                                  ],
                                  onSelected: (v) => setState(() => _typeFilter = v),
                                ),
                                _filterChip(
                                  label: _priorityLabel(),
                                  items: const [
                                    PopupMenuItem(value: _kFilterAll, child: Text('All')),
                                    PopupMenuItem(value: 'low', child: Text('Low')),
                                    PopupMenuItem(value: 'medium', child: Text('Medium')),
                                    PopupMenuItem(value: 'high', child: Text('High')),
                                  ],
                                  onSelected: (v) => setState(() => _priorityFilter = v),
                                ),
                                _filterChip(
                                  label: _statusLabel(),
                                  items: const [
                                    PopupMenuItem(value: _kFilterAll, child: Text('All')),
                                    PopupMenuItem(value: 'todo', child: Text('Todo')),
                                    PopupMenuItem(value: 'in_progress', child: Text('In Progress')),
                                    PopupMenuItem(value: 'done', child: Text('Done')),
                                  ],
                                  onSelected: (v) => setState(() => _statusFilter = v),
                                ),
                                OutlinedButton.icon(
                                  onPressed: () {
                                    setState(() {
                                      _assigneeFilter = _kAssigneeAll;
                                      _typeFilter = _kFilterAll;
                                      _priorityFilter = _kFilterAll;
                                      _statusFilter = _kFilterAll;
                                    });
                                  },
                                  icon: const Icon(Icons.clear, size: 16),
                                  label: const Text('Clear'),
                                ),
                                Text(
                                  'Showing ${filteredIssues.length}/${widget.issues.length}',
                                  style: const TextStyle(fontSize: 12, color: AppColors.mutedText),
                                ),
                              ],
                            ),
                          ),
                          DataTable(
                            headingRowColor: const MaterialStatePropertyAll(AppColors.surface2),
                            columns: const [
                              DataColumn(label: Text('Key')),
                              DataColumn(label: Text('Title')),
                              DataColumn(label: Text('Description')),
                              DataColumn(label: Text('Type')),
                              DataColumn(label: Text('Priority')),
                              DataColumn(label: Text('Status')),
                              DataColumn(label: Text('Comments')),
                              DataColumn(label: Text('Assignee')),
                              DataColumn(label: Text('Reporter')),
                              DataColumn(label: Text('Due')),
                              DataColumn(label: Text('Created At')),
                              DataColumn(label: Text('Updated At')),
                              DataColumn(label: Text('Actions')),
                            ],
                            rows: filteredIssues.map((i) {
                              final editing = _editingIssueId == i.id;

                              return DataRow(
                                cells: [
                                  DataCell(Text(i.key)),

                                  // Title
                                  DataCell(
                                    editing
                                        ? ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 280),
                                            child: TextField(
                                              controller: _titleCtrl,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          )
                                        : ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 280),
                                            child: Text(i.title, overflow: TextOverflow.ellipsis),
                                          ),
                                  ),

                                  // Description
                                  DataCell(
                                    editing
                                        ? ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 340),
                                            child: TextField(
                                              controller: _descCtrl,
                                              maxLines: 3,
                                              minLines: 1,
                                              decoration: const InputDecoration(
                                                isDense: true,
                                                border: OutlineInputBorder(),
                                                contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                              ),
                                            ),
                                          )
                                        : ConstrainedBox(
                                            constraints: const BoxConstraints(maxWidth: 340),
                                            child: InkWell(
                                              onTap: () => _showDescriptionPopup(i.title, i.description ?? ''),
                                              child: Text(
                                                (i.description == null || i.description!.trim().isEmpty) ? '-' : i.description!.trim(),
                                                maxLines: 2,
                                                overflow: TextOverflow.ellipsis,
                                                style: const TextStyle(decoration: TextDecoration.underline),
                                              ),
                                            ),
                                          ),
                                  ),

                                  // Type
                                  DataCell(
                                    editing
                                        ? DropdownButtonFormField<String>(
                                            value: _type,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            ),
                                            items: const [
                                              DropdownMenuItem(value: 'task', child: Text('Task')),
                                              DropdownMenuItem(value: 'bug', child: Text('Bug')),
                                              DropdownMenuItem(value: 'feature', child: Text('Feature')),
                                            ],
                                            onChanged: (v) => setState(() => _type = v ?? 'task'),
                                          )
                                        : typeWidegt(i.type),
                                  ),

                                  // Priority
                                  DataCell(
                                    editing
                                        ? DropdownButtonFormField<String>(
                                            value: _priority,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            ),
                                            items: const [
                                              DropdownMenuItem(value: 'low', child: Text('Low')),
                                              DropdownMenuItem(value: 'medium', child: Text('Medium')),
                                              DropdownMenuItem(value: 'high', child: Text('High')),
                                            ],
                                            onChanged: (v) => setState(() => _priority = v ?? 'medium'),
                                          )
                                        : PriorityBadge(priority: i.priority),
                                  ),

                                  // Status
                                  DataCell(
                                    editing
                                        ? DropdownButtonFormField<String>(
                                            value: _status,
                                            decoration: const InputDecoration(
                                              isDense: true,
                                              border: OutlineInputBorder(),
                                              contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                            ),
                                            items: const [
                                              DropdownMenuItem(value: 'todo', child: Text('Todo')),
                                              DropdownMenuItem(value: 'in_progress', child: Text('In Progress')),
                                              DropdownMenuItem(value: 'done', child: Text('Done')),
                                            ],
                                            onChanged: (v) => setState(() => _status = v ?? 'todo'),
                                          )
                                        : StatusBadge(status: i.status),
                                  ),

                                  // Comments
                                  DataCell(_commentsCell(i)),

                                  // Assignee
                                  DataCell(
                                    editing
                                        ? _jiraUserCell(
                                            text: (_findUserById(_assigneeId)?.username) ?? 'Unassigned',
                                            allowUnassigned: true,
                                            onSelected: (u) {
                                              setState(() {
                                                if (u?.id == _kUnassignedSentinelId) {
                                                  _assigneeId = null;
                                                } else {
                                                  _assigneeId = u?.id;
                                                }
                                              });
                                            },
                                          )
                                        : _jiraUserCellReadOnly(
                                            text: i.assignee?.username ?? 'Unassigned',
                                            showUnassignedIcon: true,
                                          ),
                                  ),

                                  // Reporter
                                  DataCell(
                                    editing
                                        ? _jiraUserCell(
                                            text: (_findUserById(_reporterId)?.username) ?? i.reporter.username,
                                            allowUnassigned: false,
                                            onSelected: (u) {
                                              if (u == null) return;
                                              setState(() => _reporterId = u.id);
                                            },
                                          )
                                        : _jiraUserCellReadOnly(text: i.reporter.username),
                                  ),

                                  // Due
                                  DataCell(
                                    editing
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              InkWell(
                                                onTap: _pickDueDate,
                                                child: Container(
                                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                                                  decoration: BoxDecoration(
                                                    color: AppColors.surface2,
                                                    borderRadius: BorderRadius.circular(999),
                                                    border: Border.all(color: AppColors.border),
                                                  ),
                                                  child: Row(
                                                    mainAxisSize: MainAxisSize.min,
                                                    children: [
                                                      const Icon(Icons.calendar_month_rounded, size: 16, color: AppColors.mutedText),
                                                      const SizedBox(width: 6),
                                                      Text(
                                                        _due == null
                                                            ? '-'
                                                            : '${_due!.year}-${_due!.month.toString().padLeft(2, '0')}-${_due!.day.toString().padLeft(2, '0')}',
                                                        style: const TextStyle(fontSize: 12),
                                                      ),
                                                    ],
                                                  ),
                                                ),
                                              ),
                                              if (_due != null) ...[
                                                const SizedBox(width: 8),
                                                IconButton(
                                                  tooltip: 'Clear',
                                                  onPressed: () => setState(() => _due = null),
                                                  icon: const Icon(Icons.clear, size: 18, color: AppColors.mutedText),
                                                ),
                                              ],
                                            ],
                                          )
                                        : _dueChip(i.dueDate),
                                  ),

                                  DataCell(_calendarDateChip(i.createdAt)),
                                  DataCell(_calendarDateChip(i.updatedAt)),

                                  // Actions
                                  DataCell(
                                    editing
                                        ? Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              ElevatedButton(
                                                onPressed: isUpdating ? null : () => _doneEdit(i.id),
                                                child: const Text('Done'),
                                              ),
                                              const SizedBox(width: 8),
                                              OutlinedButton(
                                                onPressed: isUpdating ? null : _cancelEdit,
                                                child: const Text('Cancel'),
                                              ),
                                            ],
                                          )
                                        : Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              OutlinedButton(
                                                onPressed: isUpdating ? null : () => _startEdit(i),
                                                child: const Text('Edit'),
                                              ),
                                              const SizedBox(width: 8),
                                              IconButton(
                                                tooltip: 'Delete issue',
                                                onPressed: isUpdating ? null : () => _confirmDelete(i),
                                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                              ),
                                            ],
                                          ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ],
                      );
                    },
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Separate widget for comments drawer / bottom-sheet UI.
/// UI-only chat (local state passed in).
class IssueCommentsSheet extends StatelessWidget {
  final String headerTitle;
  final List<ProjectUserEntity> projectUsers;
  final List<_ChatMessage> messages;
  final TextEditingController controller;
  final void Function(String text) onSend;
  final VoidCallback onClose;
  final bool isMobile;

  const IssueCommentsSheet({
    super.key,
    required this.headerTitle,
    required this.projectUsers,
    required this.messages,
    required this.controller,
    required this.onSend,
    required this.onClose,
    required this.isMobile,
  });

  String _initial(String name) {
    final v = name.trim();
    if (v.isEmpty) return '?';
    return v[0].toUpperCase();
  }

  Widget _avatar(String name, {double size = 28}) {
    final letter = _initial(name);
    final h = name.hashCode.abs();
    final base = 0xFF000000 | (h & 0x00FFFFFF);
    final bg = Color(base).withOpacity(0.18);
    final border = Color(base).withOpacity(0.35);

    return Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: bg,
        shape: BoxShape.circle,
        border: Border.all(color: border),
      ),
      child: Text(
        letter,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w800,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final w = MediaQuery.of(context).size.width;
    final h = MediaQuery.of(context).size.height;

    final panelWidth = isMobile ? w : math.min(420.0, w * 0.35);
    final panelHeight = isMobile ? h * 0.92 : h * 0.90;

    return Material(
      color: Colors.transparent,
      child: Container(
        width: panelWidth,
        height: panelHeight,
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(isMobile ? 18 : 14),
          border: Border.all(color: AppColors.border),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.25),
              blurRadius: 18,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 10, 12),
              decoration: const BoxDecoration(
                color: AppColors.surface2,
                borderRadius: BorderRadius.vertical(top: Radius.circular(14)),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      headerTitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Close',
                    onPressed: onClose,
                    icon: const Icon(Icons.close_rounded, color: AppColors.mutedText),
                  ),
                ],
              ),
            ),

            // Members strip
            if (projectUsers.isNotEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(14, 10, 14, 10),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      const Icon(Icons.group_outlined, size: 18, color: AppColors.mutedText),
                      const SizedBox(width: 10),
                      for (final u in projectUsers) ...[
                        Tooltip(
                          message: u.username,
                          child: Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: _avatar(u.username, size: 28),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),

            const Divider(height: 1, color: AppColors.border),

            // Messages
            Expanded(
              child: messages.isEmpty
                  ? const Center(
                      child: Text(
                        'No comments yet.\nBe the first to add one.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: AppColors.mutedText),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.fromLTRB(14, 12, 14, 12),
                      itemCount: messages.length,
                      itemBuilder: (ctx, index) {
                        final m = messages[index];
                        final isMe = m.senderId == 'me';

                        return Align(
                          alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
                          child: Container(
                            margin: const EdgeInsets.only(bottom: 10),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            constraints: BoxConstraints(maxWidth: math.min(520, w * 0.75)),
                            decoration: BoxDecoration(
                              color: isMe ? AppColors.surface2 : AppColors.surface2.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: AppColors.border),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    _avatar(m.senderName, size: 22),
                                    const SizedBox(width: 8),
                                    Flexible(
                                      child: Text(
                                        m.senderName,
                                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${m.createdAt.hour.toString().padLeft(2, '0')}:${m.createdAt.minute.toString().padLeft(2, '0')}',
                                      style: const TextStyle(fontSize: 11, color: AppColors.mutedText),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                Text(m.text, style: const TextStyle(fontSize: 13, height: 1.25)),
                              ],
                            ),
                          ),
                        );
                      },
                    ),
            ),

            const Divider(height: 1, color: AppColors.border),

            // Composer
            Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: controller,
                      textInputAction: TextInputAction.send,
                      onSubmitted: (v) {
                        onSend(v);
                        controller.clear();
                      },
                      decoration: InputDecoration(
                        hintText: 'Write a comment…',
                        isDense: true,
                        filled: true,
                        fillColor: AppColors.surface2,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                          borderSide: const BorderSide(color: AppColors.border),
                        ),
                        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  ElevatedButton.icon(
                    onPressed: () {
                      onSend(controller.text);
                      controller.clear();
                    },
                    icon: const Icon(Icons.send_rounded, size: 18),
                    label: const Text('Send'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
