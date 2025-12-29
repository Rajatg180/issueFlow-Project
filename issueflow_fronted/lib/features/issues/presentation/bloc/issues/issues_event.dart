abstract class IssuesEvent {
  const IssuesEvent();
}

class IssuesLoadRequested extends IssuesEvent {
  const IssuesLoadRequested();
}

class IssuesProjectToggled extends IssuesEvent {
  final String projectId;
  const IssuesProjectToggled(this.projectId);
}

class IssueCreateRequested extends IssuesEvent {
  final String projectId;
  final String title;
  final String? description;
  final String type;
  final String priority;
  final DateTime? dueDate;

  const IssueCreateRequested({
    required this.projectId,
    required this.title,
    this.description,
    this.type = 'task',
    this.priority = 'medium',
    this.dueDate,
  });
}

class ProjectUsersRequested extends IssuesEvent {
  final String projectId;
  const ProjectUsersRequested(this.projectId);
}

class IssueUpdateRequested extends IssuesEvent {
  final String projectId;
  final String issueId;

  final String title;
  final String? description;
  final String type;
  final String priority;
  final String status;
  final DateTime? dueDate;

  final String? assigneeId; 
  final String reporterId;

  const IssueUpdateRequested({
    required this.projectId,
    required this.issueId,
    required this.title,
    this.description,
    required this.type,
    required this.priority,
    required this.status,
    this.dueDate,
    required this.assigneeId,
    required this.reporterId,
  });
}

class IssueDeleteRequested extends IssuesEvent {
  final String projectId;
  final String issueId;

  const IssueDeleteRequested({
    required this.projectId,
    required this.issueId,
  });
}