enum TodoPriority {
  low,
  normal,
  high,
}

class Todo {
  final String id;
  final String title;
  final String note;
  final TodoPriority priority;
  final bool isDone;
  final DateTime createdAt;
  final DateTime? dueDate;

  const Todo({
    required this.id,
    required this.title,
    required this.note,
    required this.priority,
    required this.isDone,
    required this.createdAt,
    this.dueDate,
  });

  Todo copyWith({
    String? title,
    String? note,
    TodoPriority? priority,
    bool? isDone,
    DateTime? dueDate,
    bool clearDueDate = false,
  }) {
    return Todo(
      id: id,
      title: title ?? this.title,
      note: note ?? this.note,
      priority: priority ?? this.priority,
      isDone: isDone ?? this.isDone,
      createdAt: createdAt,
      dueDate: clearDueDate ? null : dueDate ?? this.dueDate,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'note': note,
      'priority': priority.name,
      'isDone': isDone,
      'createdAt': createdAt.toIso8601String(),
      'dueDate': dueDate?.toIso8601String(),
    };
  }

  factory Todo.fromJson(Map<String, dynamic> json) {
    return Todo(
      id: json['id'] ?? '',
      title: json['title'] ?? '',
      note: json['note'] ?? '',
      priority: TodoPriority.values.firstWhere(
        (item) => item.name == json['priority'],
        orElse: () => TodoPriority.normal,
      ),
      isDone: json['isDone'] ?? false,
      createdAt: DateTime.tryParse(json['createdAt'] ?? '') ?? DateTime.now(),
      dueDate: json['dueDate'] == null
          ? null
          : DateTime.tryParse(json['dueDate']),
    );
  }

  String get priorityTitle {
    switch (priority) {
      case TodoPriority.low:
        return 'کم';
      case TodoPriority.normal:
        return 'معمولی';
      case TodoPriority.high:
        return 'مهم';
    }
  }

  String get statusTitle {
    return isDone ? 'انجام شده' : 'در حال انجام';
  }
}