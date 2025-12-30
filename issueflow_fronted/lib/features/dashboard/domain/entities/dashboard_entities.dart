class DashboardSummaryEntity {
  final int projectsCount;
  final int issuesCount;

  /// Keys: todo / in_progress / done
  final Map<String, int> byStatus;

  /// Keys: low / medium / high
  final Map<String, int> byPriority;

  const DashboardSummaryEntity({
    required this.projectsCount,
    required this.issuesCount,
    required this.byStatus,
    required this.byPriority,
  });
}

class IssueCardEntity {
  final String id;
  final String key;
  final String title;
  final String status;
  final String priority;
  final String projectId;
  final String? dueDate; // yyyy-mm-dd

  const IssueCardEntity({
    required this.id,
    required this.key,
    required this.title,
    required this.status,
    required this.priority,
    required this.projectId,
    this.dueDate,
  });
}

class ActivityItemEntity {
  final String projectId;
  final String issueId;
  final String issueKey;
  final String issueTitle;
  final String authorUsername;
  final String body;
  final DateTime createdAt;

  const ActivityItemEntity({
    required this.projectId,
    required this.issueId,
    required this.issueKey,
    required this.issueTitle,
    required this.authorUsername,
    required this.body,
    required this.createdAt,
  });
}

class DashboardHomeEntity {
  final DashboardSummaryEntity summary;
  final List<IssueCardEntity> myAssigned;
  final List<IssueCardEntity> dueSoon;
  final List<IssueCardEntity> overdue;
  final List<ActivityItemEntity> recentActivity;

  const DashboardHomeEntity({
    required this.summary,
    required this.myAssigned,
    required this.dueSoon,
    required this.overdue,
    required this.recentActivity,
  });
}
