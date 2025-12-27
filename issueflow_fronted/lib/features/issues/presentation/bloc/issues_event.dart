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
