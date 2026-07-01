import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../models/quiz_model.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/error_widget.dart';

class QuizAttemptScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int quizId;

  const QuizAttemptScreen({super.key, required this.courseId, required this.quizId});

  @override
  ConsumerState<QuizAttemptScreen> createState() => _QuizAttemptScreenState();
}

class _QuizAttemptScreenState extends ConsumerState<QuizAttemptScreen> {
  @override
  void initState() {
    super.initState();
    Future.microtask(() => ref.read(quizProvider.notifier).startQuiz(
          courseId: widget.courseId,
          quizId: widget.quizId,
        ));
  }

  Future<void> _finalSubmit() async {
    await ref.read(quizProvider.notifier).finalSubmit(
          courseId: widget.courseId,
          quizId: widget.quizId,
        );
    if (mounted) {
      context.pushReplacement(
        '${AppRoutes.quizResult}?courseId=${widget.courseId}&quizId=${widget.quizId}',
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final quizState = ref.watch(quizProvider);

    if (quizState.status == QuizStatus.loading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (quizState.status == QuizStatus.error) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: AppErrorWidget(message: quizState.errorMessage ?? 'Failed to load quiz'),
      );
    }

    final quiz = quizState.currentQuiz;
    final questions = quiz?.questions ?? [];
    if (quiz == null || questions.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('Quiz')),
        body: const AppErrorWidget(message: 'No questions available for this quiz.'),
      );
    }

    final currentIndex = quizState.currentQuestionIndex;
    final currentQuestion = questions[currentIndex];
    final total = questions.length;
    final selectedAnswerId = quizState.selectedAnswers[currentQuestion.id];

    return Scaffold(
      appBar: AppBar(
        title: Text(quiz.title),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(4),
          child: LinearProgressIndicator(
            value: (currentIndex + 1) / total,
            backgroundColor: AppColors.grey200,
            valueColor: const AlwaysStoppedAnimation(AppColors.primary),
          ),
        ),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: AppSizes.md),
            child: Center(
              child: Text(
                '${currentIndex + 1}/$total',
                style: GoogleFonts.inter(fontWeight: FontWeight.w600),
              ),
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Question number label
            Text(
              'Question ${currentIndex + 1}',
              style: GoogleFonts.inter(
                fontSize: AppSizes.textSm,
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: AppSizes.sm),

            // Question text
            Text(
              currentQuestion.question,
              style: GoogleFonts.inter(
                fontSize: AppSizes.textLg,
                fontWeight: FontWeight.w700,
                height: 1.4,
              ),
            ),
            const SizedBox(height: AppSizes.xl),

            // Answer options (uses OptionModel, aliased as QuizAnswer)
            ...currentQuestion.options.map(
              (option) => _AnswerOption(
                option: option,
                isSelected: selectedAnswerId == option.id,
                onTap: () => ref.read(quizProvider.notifier).selectAnswer(
                      questionId: currentQuestion.id,
                      answerId: option.id,
                    ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.fromLTRB(
          AppSizes.screenPadding,
          AppSizes.md,
          AppSizes.screenPadding,
          AppSizes.xl,
        ),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 12,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: Row(
          children: [
            if (currentIndex > 0) ...[
              Expanded(
                child: AppButton(
                  label: 'Previous',
                  variant: AppButtonVariant.outlined,
                  onPressed: () => ref.read(quizProvider.notifier).previousQuestion(),
                ),
              ),
              const SizedBox(width: AppSizes.md),
            ],
            Expanded(
              child: quizState.isLastQuestion
                  ? AppButton(
                      label: 'Submit Quiz',
                      isLoading: quizState.status == QuizStatus.submitting,
                      onPressed: selectedAnswerId == null ? null : _finalSubmit,
                    )
                  : AppButton(
                      label: 'Next',
                      onPressed: selectedAnswerId == null
                          ? null
                          : () {
                              ref.read(quizProvider.notifier).submitCurrentAnswer();
                              ref.read(quizProvider.notifier).nextQuestion();
                            },
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _AnswerOption extends StatelessWidget {
  final OptionModel option;
  final bool isSelected;
  final VoidCallback onTap;

  const _AnswerOption({
    required this.option,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: AppSizes.sm),
        padding: const EdgeInsets.all(AppSizes.md),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary.withOpacity(0.08) : Colors.transparent,
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.grey300,
            width: isSelected ? 2 : 1,
          ),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Row(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              width: 22,
              height: 22,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: isSelected ? AppColors.primary : AppColors.grey400,
                  width: 2,
                ),
                color: isSelected ? AppColors.primary : Colors.transparent,
              ),
              child: isSelected
                  ? const Icon(Icons.check_rounded, size: 14, color: Colors.white)
                  : null,
            ),
            const SizedBox(width: AppSizes.md),
            Expanded(
              child: Text(
                option.text,
                style: GoogleFonts.inter(
                  fontSize: AppSizes.textMd,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? AppColors.primary : null,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
