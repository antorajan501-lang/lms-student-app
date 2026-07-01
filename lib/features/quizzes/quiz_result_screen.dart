import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../providers/quiz_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/shimmer_loader.dart';
import '../../widgets/error_widget.dart';

class QuizResultScreen extends ConsumerWidget {
  final int courseId;
  final int quizId;

  const QuizResultScreen({super.key, required this.courseId, required this.quizId});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultAsync = ref.watch(
      quizResultProvider(QuizResultParams(courseId: courseId, quizId: quizId)),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Quiz Result'),
        automaticallyImplyLeading: false,
      ),
      body: resultAsync.when(
        data: (result) {
          final passed = result.isPassed ?? false;
          final percent = result.percentageScore ?? 0.0;

          return Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              child: Column(
                children: [
                  // Score circle
                  Container(
                    width: 160,
                    height: 160,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: passed
                            ? [AppColors.success, const Color(0xFF059669)]
                            : [AppColors.error, const Color(0xFFDC2626)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: (passed ? AppColors.success : AppColors.error).withOpacity(0.3),
                          blurRadius: 24,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '${percent.toStringAsFixed(0)}%',
                          style: GoogleFonts.inter(
                            color: Colors.white,
                            fontSize: 36,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        Text(
                          passed ? 'PASSED' : 'FAILED',
                          style: GoogleFonts.inter(
                            color: Colors.white.withOpacity(0.9),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            letterSpacing: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  Text(
                    passed ? '🎉 Congratulations!' : '😔 Better luck next time!',
                    style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.sm),
                  Text(
                    passed
                        ? 'You\'ve passed the quiz!'
                        : 'You didn\'t meet the passing score. Review the content and try again.',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.textMd,
                      color: AppColors.grey500,
                      height: 1.5,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  // Stats cards
                  Row(
                    children: [
                      _ResultStat(
                        label: 'Correct',
                        value: '${result.totalCorrect ?? 0}',
                        color: AppColors.success,
                      ),
                      const SizedBox(width: AppSizes.md),
                      _ResultStat(
                        label: 'Incorrect',
                        value: '${result.totalWrong ?? 0}',
                        color: AppColors.error,
                      ),
                      const SizedBox(width: AppSizes.md),
                      _ResultStat(
                        label: 'Total',
                        value: '${result.totalQuestions ?? 0}',
                        color: AppColors.primary,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSizes.xxl),

                  AppButton(
                    label: 'Back to Course',
                    onPressed: () {
                      context.go('${AppRoutes.courseDetail}?courseId=$courseId');
                    },
                  ),
                  const SizedBox(height: AppSizes.md),
                  if (!passed)
                    AppButton(
                      label: 'Retry Quiz',
                      variant: AppButtonVariant.outlined,
                      onPressed: () {
                        ref.read(quizProvider.notifier).reset();
                        context.pushReplacement(
                          '${AppRoutes.quizAttempt}?courseId=$courseId&quizId=$quizId',
                        );
                      },
                    ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(
            quizResultProvider(QuizResultParams(courseId: courseId, quizId: quizId)),
          ),
        ),
      ),
    );
  }
}

class _ResultStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _ResultStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: AppSizes.md),
        decoration: BoxDecoration(
          color: color.withOpacity(0.08),
          borderRadius: BorderRadius.circular(AppSizes.cardRadius),
          border: Border.all(color: color.withOpacity(0.2)),
        ),
        child: Column(
          children: [
            Text(
              value,
              style: GoogleFonts.inter(
                fontSize: 28,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
            Text(
              label,
              style: GoogleFonts.inter(fontSize: AppSizes.textSm, color: AppColors.grey500),
            ),
          ],
        ),
      ),
    );
  }
}
