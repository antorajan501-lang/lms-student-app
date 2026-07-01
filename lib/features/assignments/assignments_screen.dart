import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/app_button.dart';
import '../../providers/assignments_provider.dart';

class AssignmentsScreen extends ConsumerStatefulWidget {
  const AssignmentsScreen({super.key});

  @override
  ConsumerState<AssignmentsScreen> createState() => _AssignmentsScreenState();
}

class _AssignmentsScreenState extends ConsumerState<AssignmentsScreen> {
  void _showSubmissionModal(AssignmentItem assignment) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => _SubmissionBottomSheet(
        assignment: assignment,
        onSubmit: (fileName) {
          ref.read(assignmentsProvider.notifier).submitAssignment(assignment.id);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Assignment "${assignment.title}" submitted successfully!'),
              backgroundColor: AppColors.success,
              behavior: SnackBarBehavior.floating,
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final assignments = ref.watch(assignmentsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Assignments'),
      ),
      body: ListView.builder(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        itemCount: assignments.length,
        itemBuilder: (context, index) {
          final assign = assignments[index];

          Color statusColor;
          String statusText;
          switch (assign.status) {
            case AssignmentStatus.pending:
              statusColor = AppColors.warning;
              statusText = 'Pending';
              break;
            case AssignmentStatus.submitted:
              statusColor = AppColors.accent;
              statusText = 'Submitted';
              break;
            case AssignmentStatus.graded:
              statusColor = AppColors.success;
              statusText = 'Graded';
              break;
          }

          return Card(
            elevation: 0,
            margin: const EdgeInsets.only(bottom: AppSizes.md),
            color: Theme.of(context).cardColor,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(AppSizes.cardRadius),
              side: BorderSide(color: Theme.of(context).dividerColor),
            ),
            child: ExpansionTile(
              shape: const Border(),
              leading: Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: statusColor.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(AppSizes.radiusSm),
                ),
                child: Text(
                  statusText,
                  style: GoogleFonts.inter(
                    color: statusColor,
                    fontWeight: FontWeight.w700,
                    fontSize: 11,
                  ),
                ),
              ),
              title: Text(
                assign.title,
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w700,
                  fontSize: AppSizes.textMd,
                ),
              ),
              subtitle: Text(
                '${assign.courseName}\n${assign.dueDate}',
                style: GoogleFonts.inter(color: AppColors.grey500, fontSize: 12),
              ),
              childrenPadding: const EdgeInsets.all(AppSizes.md),
              expandedAlignment: Alignment.topLeft,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Divider(height: 1),
                    const SizedBox(height: AppSizes.md),
                    Text(
                      'Details:',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        fontSize: AppSizes.textSm,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      assign.description,
                      style: GoogleFonts.inter(color: AppColors.grey600, fontSize: 13),
                    ),
                    const SizedBox(height: AppSizes.md),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Marks: ${assign.obtainedMarks != null ? "${assign.obtainedMarks} / " : ""}${assign.marks}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                            ),
                            Text(
                              'Min. Passing: ${assign.minPercentage}%',
                              style: const TextStyle(color: AppColors.grey500, fontSize: 11),
                            ),
                          ],
                        ),
                        if (assign.status == AssignmentStatus.pending)
                          ElevatedButton.icon(
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: Colors.white,
                              minimumSize: const Size(100, 36),
                              padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                            ),
                            onPressed: () => _showSubmissionModal(assign),
                            icon: const Icon(Icons.upload_file_rounded, size: 16),
                            label: const Text('Submit', style: TextStyle(fontSize: 12)),
                          )
                        else if (assign.status == AssignmentStatus.graded)
                          Row(
                            children: [
                              const Icon(Icons.stars_rounded, color: AppColors.success, size: 18),
                              const SizedBox(width: 4),
                              Text(
                                'Grade: ${((assign.obtainedMarks ?? 0) / assign.marks * 100).toInt()}%',
                                style: GoogleFonts.inter(
                                  fontWeight: FontWeight.bold,
                                  color: AppColors.success,
                                ),
                              ),
                            ],
                          )
                        else
                          const Text(
                            'Awaiting Grading',
                            style: TextStyle(fontStyle: FontStyle.italic, color: AppColors.grey500),
                          ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}



class _SubmissionBottomSheet extends StatefulWidget {
  final AssignmentItem assignment;
  final Function(String fileName) onSubmit;

  const _SubmissionBottomSheet({required this.assignment, required this.onSubmit});

  @override
  State<_SubmissionBottomSheet> createState() => _SubmissionBottomSheetState();
}

class _SubmissionBottomSheetState extends State<_SubmissionBottomSheet> {
  String? _selectedFileName;
  bool _isUploading = false;

  void _simulatePickFile() async {
    setState(() => _isUploading = true);
    await Future.delayed(const Duration(seconds: 1));
    setState(() {
      _selectedFileName = '${widget.assignment.title.replaceAll(" ", "_")}_submission.pdf';
      _isUploading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(
        left: AppSizes.screenPadding,
        right: AppSizes.screenPadding,
        top: AppSizes.xl,
        bottom: MediaQuery.of(context).viewInsets.bottom + AppSizes.xl,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Submit Assignment',
                style: GoogleFonts.inter(
                  fontWeight: FontWeight.w800,
                  fontSize: AppSizes.textLg,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close_rounded),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: AppSizes.md),
          Text(
            widget.assignment.title,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          Text(
            widget.assignment.courseName,
            style: const TextStyle(color: AppColors.grey500, fontSize: 12),
          ),
          const SizedBox(height: AppSizes.xl),

          // File Picker Area
          GestureDetector(
            onTap: _isUploading ? null : _simulatePickFile,
            child: Container(
              width: double.infinity,
              height: 120,
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkBg : AppColors.grey50,
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                border: Border.all(
                  color: isDark ? AppColors.darkBorder : AppColors.grey300,
                  style: BorderStyle.solid,
                ),
              ),
              alignment: Alignment.center,
              child: _isUploading
                  ? const CircularProgressIndicator()
                  : _selectedFileName != null
                      ? Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.picture_as_pdf_rounded, color: AppColors.error, size: 36),
                            const SizedBox(height: 8),
                            Text(
                              _selectedFileName!,
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                              textAlign: TextAlign.center,
                            ),
                          ],
                        )
                      : Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.cloud_upload_outlined, color: AppColors.grey400, size: 36),
                            const SizedBox(height: 8),
                            const Text(
                              'Tap to upload file (PDF, ZIP, DOCX)',
                              style: TextStyle(color: AppColors.grey500, fontSize: 12),
                            ),
                          ],
                        ),
            ),
          ),
          const SizedBox(height: AppSizes.xl),
          AppButton(
            label: 'Submit Assignment',
            onPressed: _selectedFileName != null
                ? () {
                    widget.onSubmit(_selectedFileName!);
                    Navigator.pop(context);
                  }
                : null,
          ),
        ],
      ),
    );
  }
}
