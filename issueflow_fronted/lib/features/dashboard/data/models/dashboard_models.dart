import '../../domain/entities/dashboard_entities.dart';

class DashboardSummaryModel extends DashboardSummaryEntity {
  const DashboardSummaryModel({
    required super.projectsCount,
    required super.issuesCount,
    required super.byStatus,
    required super.byPriority,
  });

  factory DashboardSummaryModel.fromJson(Map<String, dynamic> json) {
    final byStatusRaw = (json['by_status'] as Map?) ?? {};
    final byPriorityRaw = (json['by_priority'] as Map?) ?? {};

    return DashboardSummaryModel(
      projectsCount: (json['projects_count'] ?? 0) as int,
      issuesCount: (json['issues_count'] ?? 0) as int,
      byStatus: byStatusRaw.map((k, v) => MapEntry(k.toString(), (v ?? 0) as int)),
      byPriority: byPriorityRaw.map((k, v) => MapEntry(k.toString(), (v ?? 0) as int)),
    );
  }
}

class IssueCardModel extends IssueCardEntity {
  const IssueCardModel({
    required super.id,
    required super.key,
    required super.title,
    required super.status,
    required super.priority,
    required super.projectId,
    super.dueDate,
  });

  factory IssueCardModel.fromJson(Map<String, dynamic> json) {
    return IssueCardModel(
      id: json['id'].toString(),
      key: json['key'].toString(),
      title: (json['title'] ?? '').toString(),
      status: json['status'].toString(),
      priority: json['priority'].toString(),
      projectId: json['project_id'].toString(),
      dueDate: json['due_date']?.toString(),
    );
  }
}

class ActivityItemModel extends ActivityItemEntity {
  const ActivityItemModel({
    required super.projectId,
    required super.issueId,
    required super.issueKey,
    required super.issueTitle,
    required super.authorUsername,
    required super.body,
    required super.createdAt,
  });

  factory ActivityItemModel.fromJson(Map<String, dynamic> json) {
    return ActivityItemModel(
      projectId: json['project_id'].toString(),
      issueId: json['issue_id'].toString(),
      issueKey: (json['issue_key'] ?? '').toString(),
      issueTitle: (json['issue_title'] ?? '').toString(),
      authorUsername: (json['author_username'] ?? '').toString(),
      body: (json['body'] ?? '').toString(),
      createdAt: DateTime.parse(json['created_at'].toString()),
    );
  }
}

class DashboardHomeModel extends DashboardHomeEntity {
  const DashboardHomeModel({
    required super.summary,
    required super.myAssigned,
    required super.dueSoon,
    required super.overdue,
    required super.recentActivity,
  });

  factory DashboardHomeModel.fromJson(Map<String, dynamic> json) {
    final summary = DashboardSummaryModel.fromJson(json['summary'] as Map<String, dynamic>);

    final myAssigned = ((json['my_assigned'] as List?) ?? [])
        .map((e) => IssueCardModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final dueSoon = ((json['due_soon'] as List?) ?? [])
        .map((e) => IssueCardModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final overdue = ((json['overdue'] as List?) ?? [])
        .map((e) => IssueCardModel.fromJson(e as Map<String, dynamic>))
        .toList();

    final activity = ((json['recent_activity'] as List?) ?? [])
        .map((e) => ActivityItemModel.fromJson(e as Map<String, dynamic>))
        .toList();

    return DashboardHomeModel(
      summary: summary,
      myAssigned: myAssigned,
      dueSoon: dueSoon,
      overdue: overdue,
      recentActivity: activity,
    );
  }
}
