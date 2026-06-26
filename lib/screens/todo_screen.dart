import 'package:flutter/material.dart';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/todo.dart';
import '../widgets/stat_card.dart';
import '../widgets/todo_item.dart';

enum TodoFilter { all, active, done }

class TodoScreen extends StatefulWidget {
  const TodoScreen({super.key});

  @override
  State<TodoScreen> createState() => _TodoScreenState();
}

class _TodoScreenState extends State<TodoScreen> {
  static const String todosCacheKey = 'todos_cache_v1';
  TodoFilter selectedFilter = TodoFilter.all;
  @override
  void initState() {
    super.initState();
    loadTodosFromCache();
  }

  Future<void> loadTodosFromCache() async {
    final prefs = await SharedPreferences.getInstance();
    final cachedData = prefs.getString(todosCacheKey);

    if (cachedData == null) return;

    try {
      final decodedData = jsonDecode(cachedData);

      if (decodedData is! List) return;

      final loadedTodos = decodedData
          .map((item) => Todo.fromJson(Map<String, dynamic>.from(item)))
          .toList();

      if (!mounted) return;

      setState(() {
        todos
          ..clear()
          ..addAll(loadedTodos);
      });
    } catch (_) {
      await prefs.remove(todosCacheKey);
    }
  }

  Future<void> saveTodosToCache() async {
    final prefs = await SharedPreferences.getInstance();

    final encodedData = jsonEncode(todos.map((todo) => todo.toJson()).toList());

    await prefs.setString(todosCacheKey, encodedData);
  }

  final List<Todo> todos = [
    Todo(
      id: '1',
      title: 'مرور ویجت‌های Flutter',
      note: 'Column، Row، Container و ListView را یک بار تمرین کنم.',
      priority: TodoPriority.high,
      isDone: false,
      createdAt: DateTime.now(),
      dueDate: DateTime.now().add(const Duration(days: 1)),
    ),
    Todo(
      id: '2',
      title: 'تمرین setState',
      note: 'یک مثال ساده با تغییر رنگ یا شمارنده بسازم.',
      priority: TodoPriority.normal,
      isDone: true,
      createdAt: DateTime.now(),
    ),
  ];

  List<Todo> get filteredTodos {
    switch (selectedFilter) {
      case TodoFilter.all:
        return todos;
      case TodoFilter.active:
        return todos.where((todo) => !todo.isDone).toList();
      case TodoFilter.done:
        return todos.where((todo) => todo.isDone).toList();
    }
  }

  int get doneCount {
    return todos.where((todo) => todo.isDone).length;
  }

  int get activeCount {
    return todos.where((todo) => !todo.isDone).length;
  }

  double get progressValue {
    if (todos.isEmpty) return 0;
    return doneCount / todos.length;
  }

  void addTodo({
    required String title,
    required String note,
    required TodoPriority priority,
    required DateTime? dueDate,
  }) {
    final newTodo = Todo(
      id: DateTime.now().millisecondsSinceEpoch.toString(),
      title: title,
      note: note,
      priority: priority,
      isDone: false,
      createdAt: DateTime.now(),
      dueDate: dueDate,
    );

    setState(() {
      todos.insert(0, newTodo);
    });

    saveTodosToCache();

    showMessage('کار جدید اضافه شد');
  }

  void updateTodo({
    required Todo oldTodo,
    required String title,
    required String note,
    required TodoPriority priority,
    required DateTime? dueDate,
  }) {
    final index = todos.indexWhere((todo) => todo.id == oldTodo.id);

    if (index == -1) return;

    setState(() {
      todos[index] = oldTodo.copyWith(
        title: title,
        note: note,
        priority: priority,
        dueDate: dueDate,
        clearDueDate: dueDate == null,
      );
    });

    saveTodosToCache();

    showMessage('کار ویرایش شد');
  }

  void toggleTodo(Todo selectedTodo) {
    final index = todos.indexWhere((todo) => todo.id == selectedTodo.id);

    if (index == -1) return;

    setState(() {
      todos[index] = selectedTodo.copyWith(isDone: !selectedTodo.isDone);
    });

    saveTodosToCache();
  }

  void deleteTodo(Todo selectedTodo) {
    final index = todos.indexWhere((todo) => todo.id == selectedTodo.id);

    if (index == -1) return;

    setState(() {
      todos.removeAt(index);
    });

    saveTodosToCache();

    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('«${selectedTodo.title}» حذف شد'),
        behavior: SnackBarBehavior.floating,
        action: SnackBarAction(
          label: 'بازگردانی',
          onPressed: () {
            setState(() {
              todos.insert(index, selectedTodo);
            });

            saveTodosToCache();
          },
        ),
      ),
    );
  }

  void clearDoneTodos() {
    final hasDoneTodo = todos.any((todo) => todo.isDone);

    if (!hasDoneTodo) {
      showMessage('کاری برای پاک کردن وجود ندارد');
      return;
    }

    setState(() {
      todos.removeWhere((todo) => todo.isDone);
    });

    saveTodosToCache();

    showMessage('کارهای انجام‌شده پاک شدند');
  }

  void showMessage(String text) {
    ScaffoldMessenger.of(context).clearSnackBars();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(text), behavior: SnackBarBehavior.floating),
    );
  }

  String filterTitle(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return 'همه';
      case TodoFilter.active:
        return 'فعال';
      case TodoFilter.done:
        return 'انجام‌شده';
    }
  }

  IconData filterIcon(TodoFilter filter) {
    switch (filter) {
      case TodoFilter.all:
        return Icons.list_alt_rounded;
      case TodoFilter.active:
        return Icons.pending_actions_rounded;
      case TodoFilter.done:
        return Icons.task_alt_rounded;
    }
  }

  Color priorityColor(TodoPriority priority) {
    switch (priority) {
      case TodoPriority.low:
        return const Color(0xFF0EA5E9);
      case TodoPriority.normal:
        return const Color(0xFF8B5CF6);
      case TodoPriority.high:
        return const Color(0xFFEF4444);
    }
  }

  String formatDate(DateTime date) {
    return '${date.year}/${date.month}/${date.day}';
  }

  Future<void> openTodoSheet({Todo? todo}) async {
    final titleController = TextEditingController(text: todo?.title ?? '');
    final noteController = TextEditingController(text: todo?.note ?? '');

    TodoPriority selectedPriority = todo?.priority ?? TodoPriority.normal;
    DateTime? selectedDate = todo?.dueDate;

    final isEditing = todo != null;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setSheetState) {
            return Padding(
              padding: EdgeInsets.only(
                left: 14,
                right: 14,
                bottom: MediaQuery.of(context).viewInsets.bottom + 14,
              ),
              child: Container(
                padding: const EdgeInsets.all(18),
                decoration: const BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.vertical(
                    top: Radius.circular(30),
                    bottom: Radius.circular(30),
                  ),
                ),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Center(
                        child: Container(
                          width: 46,
                          height: 5,
                          decoration: BoxDecoration(
                            color: const Color(0xFFE5E7EB),
                            borderRadius: BorderRadius.circular(20),
                          ),
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        isEditing ? 'ویرایش کار' : 'کار جدید',
                        style: const TextStyle(
                          fontSize: 21,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                      const SizedBox(height: 16),
                      TextField(
                        controller: titleController,
                        textInputAction: TextInputAction.next,
                        decoration: InputDecoration(
                          labelText: 'عنوان کار',
                          hintText: 'مثلا: انجام تمرین فلاتر',
                          prefixIcon: const Icon(Icons.title_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: noteController,
                        minLines: 2,
                        maxLines: 4,
                        decoration: InputDecoration(
                          labelText: 'توضیح کوتاه',
                          hintText: 'توضیح اختیاری درباره کار',
                          prefixIcon: const Icon(Icons.notes_rounded),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(18),
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'اولویت',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: TodoPriority.values.map((priority) {
                          final selected = selectedPriority == priority;
                          final color = priorityColor(priority);

                          return ChoiceChip(
                            selected: selected,
                            label: Text(
                              priority == TodoPriority.low
                                  ? 'کم'
                                  : priority == TodoPriority.normal
                                  ? 'معمولی'
                                  : 'مهم',
                            ),
                            avatar: Icon(
                              selected
                                  ? Icons.check_circle_rounded
                                  : Icons.circle_outlined,
                              size: 18,
                              color: selected ? Colors.white : color,
                            ),
                            selectedColor: color,
                            labelStyle: TextStyle(
                              color: selected ? Colors.white : color,
                              fontWeight: FontWeight.w800,
                            ),
                            backgroundColor: color.withOpacity(0.08),
                            side: BorderSide(color: color.withOpacity(0.25)),
                            onSelected: (_) {
                              setSheetState(() {
                                selectedPriority = priority;
                              });
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 16),
                      InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () async {
                          final now = DateTime.now();

                          final pickedDate = await showDatePicker(
                            context: context,
                            initialDate: selectedDate ?? now,
                            firstDate: DateTime(now.year - 1),
                            lastDate: DateTime(now.year + 3),
                          );

                          if (pickedDate != null) {
                            setSheetState(() {
                              selectedDate = pickedDate;
                            });
                          }
                        },
                        child: Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: const Color(0xFFF9FAFB),
                            borderRadius: BorderRadius.circular(18),
                            border: Border.all(color: const Color(0xFFE5E7EB)),
                          ),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_month_rounded),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  selectedDate == null
                                      ? 'تاریخ انجام انتخاب نشده'
                                      : 'تاریخ انجام: ${formatDate(selectedDate!)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ),
                              if (selectedDate != null)
                                IconButton(
                                  onPressed: () {
                                    setSheetState(() {
                                      selectedDate = null;
                                    });
                                  },
                                  icon: const Icon(Icons.close_rounded),
                                ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 20),
                      SizedBox(
                        height: 52,
                        child: FilledButton.icon(
                          onPressed: () {
                            final title = titleController.text.trim();
                            final note = noteController.text.trim();

                            if (title.isEmpty) {
                              showMessage('عنوان کار را وارد کن');
                              return;
                            }

                            Navigator.pop(context);

                            if (isEditing) {
                              updateTodo(
                                oldTodo: todo,
                                title: title,
                                note: note,
                                priority: selectedPriority,
                                dueDate: selectedDate,
                              );
                            } else {
                              addTodo(
                                title: title,
                                note: note,
                                priority: selectedPriority,
                                dueDate: selectedDate,
                              );
                            }
                          },
                          icon: Icon(
                            isEditing
                                ? Icons.save_rounded
                                : Icons.add_task_rounded,
                          ),
                          label: Text(
                            isEditing ? 'ذخیره تغییرات' : 'افزودن کار',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );

    titleController.dispose();
    noteController.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final percent = (progressValue * 100).round();

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => openTodoSheet(),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'کار جدید',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
      ),
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topRight,
            end: Alignment.bottomLeft,
            colors: [Color(0xFFE0E7FF), Color(0xFFF8FAFC), Color(0xFFFDF2F8)],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 680),
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: Column(
                  children: [
                    buildHeader(percent),
                    const SizedBox(height: 14),
                    // Row(
                    //   children: [
                    //     StatCard(
                    //       title: 'کل کارها',
                    //       value: '${todos.length}',
                    //       icon: Icons.dashboard_rounded,
                    //       color: const Color(0xFF4F46E5),
                    //     ),
                    //     const SizedBox(width: 10),
                    //     StatCard(
                    //       title: 'فعال',
                    //       value: '$activeCount',
                    //       icon: Icons.pending_actions_rounded,
                    //       color: const Color(0xFFF97316),
                    //     ),
                    //     const SizedBox(width: 10),
                    //     StatCard(
                    //       title: 'انجام‌شده',
                    //       value: '$doneCount',
                    //       icon: Icons.task_alt_rounded,
                    //       color: const Color(0xFF16A34A),
                    //     ),
                    //   ],
                    // ),
                    const SizedBox(height: 14),
                    buildFilterBar(),
                    const SizedBox(height: 10),
                    Expanded(
                      child: filteredTodos.isEmpty
                          ? buildEmptyState()
                          : ListView.builder(
                              padding: const EdgeInsets.only(
                                top: 4,
                                bottom: 90,
                              ),
                              itemCount: filteredTodos.length,
                              itemBuilder: (context, index) {
                                final todo = filteredTodos[index];

                                return TodoItem(
                                  todo: todo,
                                  onToggle: () => toggleTodo(todo),
                                  onEdit: () => openTodoSheet(todo: todo),
                                  onDelete: () => deleteTodo(todo),
                                );
                              },
                            ),
                    ),
                    const Text(
                      'طراحی شده توسط امیرمحمد قاسم زاده',
                      style: TextStyle(
                        color: Color(0xFF6B7280),
                        fontSize: 12.5,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    const SizedBox(height: 6),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget buildHeader(int percent) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.88),
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.055),
            blurRadius: 24,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              CircleAvatar(
                radius: 24,
                backgroundColor: Color(0xFFEEF2FF),
                child: Icon(Icons.checklist_rounded, color: Color(0xFF4F46E5)),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  'لیست کارهای من',
                  style: TextStyle(
                    fontSize: 23,
                    fontWeight: FontWeight.w900,
                    color: Color(0xFF111827),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Text(
            'کارهایت را مرتب کن، اولویت بده و مرحله‌به‌مرحله انجامشان بده.',
            style: TextStyle(
              height: 1.6,
              color: Color(0xFF4B5563),
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(20),
                  child: LinearProgressIndicator(
                    value: progressValue,
                    minHeight: 10,
                    backgroundColor: const Color(0xFFE5E7EB),
                    valueColor: const AlwaysStoppedAnimation(Color(0xFF4F46E5)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                '$percent٪',
                style: const TextStyle(
                  color: Color(0xFF4F46E5),
                  fontWeight: FontWeight.w900,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildFilterBar() {
    return Container(
      padding: const EdgeInsets.all(7),
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(0.82),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(color: Colors.white.withOpacity(0.75)),
      ),
      child: Row(
        children: TodoFilter.values.map((filter) {
          final selected = selectedFilter == filter;

          return Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: InkWell(
                borderRadius: BorderRadius.circular(18),
                onTap: () {
                  setState(() {
                    selectedFilter = filter;
                  });
                },
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 220),
                  padding: const EdgeInsets.symmetric(vertical: 11),
                  decoration: BoxDecoration(
                    color: selected
                        ? const Color(0xFF4F46E5)
                        : Colors.transparent,
                    borderRadius: BorderRadius.circular(18),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        filterIcon(filter),
                        size: 18,
                        color: selected
                            ? Colors.white
                            : const Color(0xFF6B7280),
                      ),
                      const SizedBox(width: 5),
                      Text(
                        filterTitle(filter),
                        style: TextStyle(
                          color: selected
                              ? Colors.white
                              : const Color(0xFF6B7280),
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget buildEmptyState() {
    String title;
    String description;

    if (selectedFilter == TodoFilter.done) {
      title = 'هنوز کاری انجام نشده';
      description = 'هر کاری را تیک بزنی، اینجا نمایش داده می‌شود.';
    } else if (selectedFilter == TodoFilter.active) {
      title = 'کار فعالی نداری';
      description = 'همه کارها انجام شده یا هنوز کاری اضافه نکرده‌ای.';
    } else {
      title = 'لیستت خالیه';
      description = 'با دکمه «کار جدید» اولین کارت را اضافه کن.';
    }

    return Center(
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(26),
        decoration: BoxDecoration(
          color: Colors.white.withOpacity(0.82),
          borderRadius: BorderRadius.circular(28),
          border: Border.all(color: Colors.white.withOpacity(0.75)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.inbox_rounded, size: 70, color: Color(0xFF9CA3AF)),
            const SizedBox(height: 14),
            Text(
              title,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Color(0xFF111827),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              description,
              textAlign: TextAlign.center,
              style: const TextStyle(
                height: 1.7,
                color: Color(0xFF6B7280),
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: () => openTodoSheet(),
              icon: const Icon(Icons.add_rounded),
              label: const Text(
                'افزودن کار',
                style: TextStyle(fontWeight: FontWeight.w900),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
