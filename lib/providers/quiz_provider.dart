import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api/api_client.dart';
import '../models/quiz_model.dart';
import '../repositories/quiz_repository.dart';

// ── Quiz State ────────────────────────────────────────────────────────────────
enum QuizStatus { idle, loading, inProgress, submitting, completed, error }

class QuizState {
  final QuizStatus status;
  final QuizModel? currentQuiz;
  final QuizResultModel? result;
  final int currentQuestionIndex;
  final Map<int, int> selectedAnswers; // questionId → answerId
  final String? errorMessage;

  const QuizState({
    this.status = QuizStatus.idle,
    this.currentQuiz,
    this.result,
    this.currentQuestionIndex = 0,
    this.selectedAnswers = const {},
    this.errorMessage,
  });

  QuizState copyWith({
    QuizStatus? status,
    QuizModel? currentQuiz,
    QuizResultModel? result,
    int? currentQuestionIndex,
    Map<int, int>? selectedAnswers,
    String? errorMessage,
  }) {
    return QuizState(
      status: status ?? this.status,
      currentQuiz: currentQuiz ?? this.currentQuiz,
      result: result ?? this.result,
      currentQuestionIndex: currentQuestionIndex ?? this.currentQuestionIndex,
      selectedAnswers: selectedAnswers ?? this.selectedAnswers,
      errorMessage: errorMessage,
    );
  }

  bool get isLastQuestion =>
      currentQuiz != null &&
      currentQuestionIndex >= (currentQuiz!.questions?.length ?? 1) - 1;

  int get totalQuestions => currentQuiz?.questions?.length ?? 0;
  int get answeredCount => selectedAnswers.length;
}

// ── Quiz Notifier ─────────────────────────────────────────────────────────────
class QuizNotifier extends StateNotifier<QuizState> {
  final QuizRepository _repo;

  QuizNotifier(this._repo) : super(const QuizState());

  Future<void> startQuiz({required int courseId, required int quizId}) async {
    state = state.copyWith(status: QuizStatus.loading, errorMessage: null);
    try {
      final quiz = await _repo.startQuiz(courseId: courseId, quizId: quizId);
      state = state.copyWith(
        status: QuizStatus.inProgress,
        currentQuiz: quiz,
        currentQuestionIndex: 0,
        selectedAnswers: {},
      );
    } on ApiException catch (e) {
      state = state.copyWith(status: QuizStatus.error, errorMessage: e.message);
    }
  }

  void selectAnswer({required int questionId, required int answerId}) {
    final updated = Map<int, int>.from(state.selectedAnswers);
    updated[questionId] = answerId;
    state = state.copyWith(selectedAnswers: updated);
  }

  Future<void> submitCurrentAnswer() async {
    if (state.currentQuiz == null) return;
    final questions = state.currentQuiz!.questions ?? [];
    if (state.currentQuestionIndex >= questions.length) return;

    final question = questions[state.currentQuestionIndex];
    final answerId = state.selectedAnswers[question.id];
    if (answerId == null) return;

    try {
      await _repo.submitSingleAnswer(
        courseId: state.currentQuiz!.courseId ?? 0,
        quizId: state.currentQuiz!.id,
        questionId: question.id,
        answerId: answerId,
      );
    } on ApiException catch (e) {
      state = state.copyWith(errorMessage: e.message);
    }
  }

  void nextQuestion() {
    if (!state.isLastQuestion) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex + 1,
      );
    }
  }

  void previousQuestion() {
    if (state.currentQuestionIndex > 0) {
      state = state.copyWith(
        currentQuestionIndex: state.currentQuestionIndex - 1,
      );
    }
  }

  Future<void> finalSubmit({required int courseId, required int quizId}) async {
    state = state.copyWith(status: QuizStatus.submitting, errorMessage: null);
    try {
      final result = await _repo.finalSubmit(courseId: courseId, quizId: quizId);
      state = state.copyWith(status: QuizStatus.completed, result: result);
    } on ApiException catch (e) {
      state = state.copyWith(status: QuizStatus.error, errorMessage: e.message);
    }
  }

  void reset() => state = const QuizState();
}

// ── Providers ────────────────────────────────────────────────────────────────
final quizProvider = StateNotifierProvider<QuizNotifier, QuizState>((ref) {
  final repo = ref.watch(quizRepositoryProvider);
  return QuizNotifier(repo);
});

final quizHistoryProvider = FutureProvider<List<QuizResultModel>>((ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuizHistory();
});

final myQuizzesProvider = FutureProvider<List<QuizModel>>((ref) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getMyQuizzes();
});

final quizResultProvider =
    FutureProvider.family<QuizResultModel, QuizResultParams>((ref, params) async {
  final repo = ref.watch(quizRepositoryProvider);
  return repo.getQuizResult(courseId: params.courseId, quizId: params.quizId);
});

class QuizResultParams {
  final int courseId;
  final int quizId;
  const QuizResultParams({required this.courseId, required this.quizId});

  @override
  bool operator ==(Object other) =>
      other is QuizResultParams && other.courseId == courseId && other.quizId == quizId;

  @override
  int get hashCode => Object.hash(courseId, quizId);
}
