class Task {
  String? id;
  int userId;
  String title;
  String? description;
  String dueDate;
  String priority;
  int isCompleted;

  Task({
    this.id,
    required this.userId,
    required this.title,
    this.description,
    required this.dueDate,
    required this.priority,
    this.isCompleted = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userId': userId,
      'title': title,
      'description': description,
      'dueDate': dueDate,
      'priority': priority,
      'isCompleted': isCompleted,
    };
  }

  factory Task.fromMap(Map<String, dynamic> map) {
    return Task(
      id: map['id'],
      userId: map['userId'],
      title: map['title'],
      description: map['description'],
      dueDate: map['dueDate'],
      priority: map['priority'],
      isCompleted: map['isCompleted'],
    );
  }
}
