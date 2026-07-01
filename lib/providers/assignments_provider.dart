import 'package:flutter_riverpod/flutter_riverpod.dart';

enum AssignmentStatus { pending, submitted, graded }

class AssignmentItem {
  final int id;
  final String title;
  final String courseName;
  final String dueDate;
  final int marks;
  final int minPercentage;
  final String description;
  final AssignmentStatus status;
  final int? obtainedMarks;

  const AssignmentItem({
    required this.id,
    required this.title,
    required this.courseName,
    required this.dueDate,
    required this.marks,
    required this.minPercentage,
    required this.description,
    required this.status,
    this.obtainedMarks,
  });

  AssignmentItem copyWith({
    AssignmentStatus? status,
    int? obtainedMarks,
  }) {
    return AssignmentItem(
      id: id,
      title: title,
      courseName: courseName,
      dueDate: dueDate,
      marks: marks,
      minPercentage: minPercentage,
      description: description,
      status: status ?? this.status,
      obtainedMarks: obtainedMarks ?? this.obtainedMarks,
    );
  }
}

class AssignmentsNotifier extends StateNotifier<List<AssignmentItem>> {
  AssignmentsNotifier() : super(_initialAssignments);

  static final List<AssignmentItem> _initialAssignments = [
    const AssignmentItem(
      id: 1,
      title: 'Microservices Design Patterns Case Study',
      courseName: 'Managerial Accounting Advance Course',
      dueDate: 'Due: July 5, 2026',
      marks: 100,
      minPercentage: 50,
      status: AssignmentStatus.pending,
      description: 'Analyze an e-commerce microservices system. Propose appropriate patterns (API Gateway, Event-driven Messaging, CQRS) with architectural diagrams.',
    ),
    const AssignmentItem(
      id: 2,
      title: 'Auditing Systems Audit Log Report',
      courseName: 'Financial Management Essentials',
      dueDate: 'Due: June 30, 2026',
      marks: 50,
      minPercentage: 60,
      status: AssignmentStatus.submitted,
      description: 'Submit the final audit report Excel spreadsheets based on the provided corporate transaction dataset.',
    ),
    const AssignmentItem(
      id: 3,
      title: 'Database Schema Design Project',
      courseName: 'Relational Database Design',
      dueDate: 'Submitted: June 20, 2026',
      marks: 100,
      minPercentage: 50,
      status: AssignmentStatus.graded,
      obtainedMarks: 92,
      description: 'Create an optimized schema design in 3NF for a hospital patient booking application.',
    ),
  ];

  void submitAssignment(int id) {
    state = [
      for (final assignment in state)
        if (assignment.id == id)
          assignment.copyWith(status: AssignmentStatus.submitted)
        else
          assignment,
    ];
  }
}

final assignmentsProvider = StateNotifierProvider<AssignmentsNotifier, List<AssignmentItem>>((ref) {
  return AssignmentsNotifier();
});
