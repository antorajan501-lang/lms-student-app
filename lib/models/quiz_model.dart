import 'package:equatable/equatable.dart';

// ── Quiz (summary) ────────────────────────────────────────────────────────────
class QuizModel extends Equatable {
  final int id;
  final String title;
  final String categoryName;
  final String? instructions;
  final double minPercentage;
  final int totalQuestions;
  final int time;
  final bool multipleAttend;
  // Available after startQuiz — questions list
  final List<QuestionModel>? questions;
  final int? courseId;

  const QuizModel({
    required this.id,
    required this.title,
    required this.categoryName,
    this.instructions,
    required this.minPercentage,
    required this.totalQuestions,
    required this.time,
    required this.multipleAttend,
    this.questions,
    this.courseId,
  });

  factory QuizModel.fromJson(Map<String, dynamic> json) {
    final rawQuestions = json['questions'] as List? ?? [];
    return QuizModel(
      id: json['quiz_id'] as int? ?? json['id'] as int? ?? 0,
      title: json['quiz_title'] as String? ?? json['name'] as String? ?? json['title'] as String? ?? '',
      categoryName: json['category_name'] as String? ??
          (json['category'] is Map ? json['category']['name'] ?? '' : ''),
      instructions: json['instructions'] as String?,
      minPercentage: (json['min_percentage'] as num?)?.toDouble() ??
          (json['min_percentange'] as num?)?.toDouble() ??
          0.0,
      totalQuestions: json['num_of_question'] as int? ??
          json['total_questions'] as int? ??
          (rawQuestions.isNotEmpty ? rawQuestions.length : 0),
      time: json['time'] as int? ?? 0,
      multipleAttend: json['multiple_attend'] as bool? ?? false,
      questions: rawQuestions
          .map((q) => QuestionModel.fromJson(q as Map<String, dynamic>))
          .toList(),
      courseId: json['course_id'] as int?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'quiz_id': id,
      'quiz_title': title,
      'category_name': categoryName,
      'instructions': instructions,
      'min_percentage': minPercentage,
      'num_of_question': totalQuestions,
      'time': time,
      'multiple_attend': multipleAttend,
    };
  }

  @override
  List<Object?> get props =>
      [id, title, categoryName, instructions, minPercentage, totalQuestions, time, multipleAttend, questions, courseId];
}

// ── Option ────────────────────────────────────────────────────────────────────
class OptionModel extends Equatable {
  final int id;
  final String text;

  const OptionModel({required this.id, required this.text});

  factory OptionModel.fromJson(Map<String, dynamic> json) {
    return OptionModel(
      id: json['id'] as int? ?? 0,
      text: json['option'] as String? ?? json['answer'] as String? ?? '',
    );
  }

  Map<String, dynamic> toJson() => {'id': id, 'option': text};

  @override
  List<Object?> get props => [id, text];
}

// ── Question ──────────────────────────────────────────────────────────────────
class QuestionModel extends Equatable {
  final int id;
  final String question;
  final String type;
  final double marks;
  final String? explanation;
  final List<OptionModel> options;
  final List<OptionModel> answers;

  const QuestionModel({
    required this.id,
    required this.question,
    required this.type,
    required this.marks,
    this.explanation,
    required this.options,
    required this.answers,
  });

  factory QuestionModel.fromJson(Map<String, dynamic> json) {
    final rawOptions = json['options'] as List? ?? [];
    final rawAnswers = json['answers'] as List? ?? [];
    return QuestionModel(
      id: json['question_id'] as int? ?? json['id'] as int? ?? 0,
      question: json['question'] as String? ?? '',
      type: json['question_type'] as String? ?? json['type'] as String? ?? 'M',
      marks: (json['mark'] as num?)?.toDouble() ?? (json['marks'] as num?)?.toDouble() ?? 1.0,
      explanation: json['explanation'] as String?,
      options: rawOptions.map((o) => OptionModel.fromJson(o as Map<String, dynamic>)).toList(),
      answers: rawAnswers.map((a) => OptionModel.fromJson(a as Map<String, dynamic>)).toList(),
    );
  }

  Map<String, dynamic> toJson() => {
        'question_id': id,
        'question': question,
        'question_type': type,
        'mark': marks,
        'explanation': explanation,
        'options': options.map((o) => o.toJson()).toList(),
        'answers': answers.map((a) => a.toJson()).toList(),
      };

  @override
  List<Object?> get props => [id, question, type, marks, explanation, options, answers];
}

// ── Quiz Answer (alias for OptionModel used in attempt screen) ─────────────
typedef QuizAnswer = OptionModel;

// ── Quiz Test (session) ───────────────────────────────────────────────────────
class QuizTestModel extends Equatable {
  final int quizTestId;
  final int userId;
  final int courseId;
  final int quizId;
  final String? startAt;
  final String? endAt;
  final double duration;

  const QuizTestModel({
    required this.quizTestId,
    required this.userId,
    required this.courseId,
    required this.quizId,
    this.startAt,
    this.endAt,
    required this.duration,
  });

  factory QuizTestModel.fromJson(Map<String, dynamic> json) {
    return QuizTestModel(
      quizTestId: json['id'] as int? ?? json['quiz_test_id'] as int? ?? 0,
      userId: json['user_id'] as int? ?? 0,
      courseId: json['course_id'] as int? ?? 0,
      quizId: json['quiz_id'] as int? ?? 0,
      startAt: json['start_at'] as String?,
      endAt: json['end_at'] as String?,
      duration: (json['duration'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': quizTestId,
        'user_id': userId,
        'course_id': courseId,
        'quiz_id': quizId,
        'start_at': startAt,
        'end_at': endAt,
        'duration': duration,
      };

  @override
  List<Object?> get props => [quizTestId, userId, courseId, quizId, startAt, endAt, duration];
}

// ── Quiz Result ───────────────────────────────────────────────────────────────
class QuizResultModel extends Equatable {
  final int? quizId;
  final int? courseId;
  final double? percentageScore;
  final int? totalQuestions;
  final int? totalCorrect;
  final int? totalWrong;
  final bool? isPassed;
  final String? completedAt;

  const QuizResultModel({
    this.quizId,
    this.courseId,
    this.percentageScore,
    this.totalQuestions,
    this.totalCorrect,
    this.totalWrong,
    this.isPassed,
    this.completedAt,
  });

  factory QuizResultModel.fromJson(Map<String, dynamic> json) {
    return QuizResultModel(
      quizId: json['quiz_id'] as int?,
      courseId: json['course_id'] as int?,
      percentageScore: (json['percentage_score'] as num?)?.toDouble() ??
          (json['percentage'] as num?)?.toDouble(),
      totalQuestions: json['total_questions'] as int? ?? json['num_of_question'] as int?,
      totalCorrect: json['total_correct'] as int? ?? json['correct_answers'] as int?,
      totalWrong: json['total_wrong'] as int? ?? json['wrong_answers'] as int?,
      isPassed: json['is_passed'] as bool? ?? (json['status'] == 'pass'),
      completedAt: json['completed_at'] as String?,
    );
  }

  Map<String, dynamic> toJson() => {
        'quiz_id': quizId,
        'course_id': courseId,
        'percentage_score': percentageScore,
        'total_questions': totalQuestions,
        'total_correct': totalCorrect,
        'total_wrong': totalWrong,
        'is_passed': isPassed,
        'completed_at': completedAt,
      };

  @override
  List<Object?> get props => [quizId, courseId, percentageScore, totalQuestions, totalCorrect, totalWrong, isPassed];
}
