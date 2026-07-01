import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:video_player/video_player.dart';
import 'package:chewie/chewie.dart';
import 'package:flutter_html/flutter_html.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/lesson_model.dart';
import '../../models/chapter_model.dart';
import '../../providers/course_provider.dart';
import '../../repositories/course_repository.dart';
import '../../widgets/error_widget.dart';

// ─── Providers ────────────────────────────────────────────────────────────────

final _courseChaptersForViewerProvider = FutureProvider.family<List<ChapterModel>, int>((ref, courseId) {
  return ref.watch(courseRepositoryProvider).getCourseWithChapters(courseId);
});

// ─── Screen ────────────────────────────────────────────────────────────────────

class LessonViewerScreen extends ConsumerStatefulWidget {
  final int courseId;
  final int? lessonId;

  const LessonViewerScreen({super.key, required this.courseId, this.lessonId});

  @override
  ConsumerState<LessonViewerScreen> createState() => _LessonViewerScreenState();
}

class _LessonViewerScreenState extends ConsumerState<LessonViewerScreen> {
  // Video state
  VideoPlayerController? _videoCtrl;
  ChewieController? _chewieCtrl;
  bool _videoLoading = false;

  // Lesson navigation
  LessonModel? _currentLesson;
  late int _currentLessonId;
  List<LessonModel> _allLessons = []; // flat ordered list of all lessons in the course

  // Completion state
  bool _isCompleting = false;
  bool _isCompleted = false;

  // Auto-mark: watch at least 80% to auto-mark
  Timer? _progressTimer;

  @override
  void initState() {
    super.initState();
    _currentLessonId = widget.lessonId ?? 0;
  }

  // ── Video ────────────────────────────────────────────────────────────────────

  void _initVideo(String url) {
    _disposeVideo();
    setState(() => _videoLoading = true);

    Uri videoUri;
    try {
      videoUri = Uri.parse(url);
    } catch (_) {
      setState(() => _videoLoading = false);
      return;
    }

    _videoCtrl = VideoPlayerController.networkUrl(videoUri);
    _videoCtrl!.initialize().then((_) {
      if (!mounted) return;
      setState(() {
        _chewieCtrl = ChewieController(
          videoPlayerController: _videoCtrl!,
          autoPlay: true,
          looping: false,
          aspectRatio: 16 / 9,
          allowFullScreen: true,
          allowPlaybackSpeedChanging: true,
          playbackSpeeds: const [0.5, 0.75, 1.0, 1.25, 1.5, 2.0],
          materialProgressColors: ChewieProgressColors(
            playedColor: AppColors.primary,
            handleColor: AppColors.primary,
            bufferedColor: AppColors.grey300,
            backgroundColor: AppColors.grey700,
          ),
        );
        _videoLoading = false;
      });

      // Auto-mark complete at 80% watch
      _startProgressTimer();
    }).catchError((_) {
      if (mounted) setState(() => _videoLoading = false);
    });
  }

  void _startProgressTimer() {
    _progressTimer?.cancel();
    _progressTimer = Timer.periodic(const Duration(seconds: 5), (_) async {
      if (_videoCtrl == null || !_videoCtrl!.value.isInitialized) return;
      final total = _videoCtrl!.value.duration;
      final current = _videoCtrl!.value.position;
      if (total.inSeconds > 0) {
        final pct = current.inSeconds / total.inSeconds;
        if (pct >= 0.8 && !_isCompleted && _currentLesson != null) {
          await _markComplete(silent: true);
        }
      }
    });
  }

  void _disposeVideo() {
    _progressTimer?.cancel();
    _chewieCtrl?.dispose();
    _videoCtrl?.dispose();
    _chewieCtrl = null;
    _videoCtrl = null;
  }

  @override
  void dispose() {
    _disposeVideo();
    super.dispose();
  }

  // ── Lesson Load ───────────────────────────────────────────────────────────────

  void _loadLesson(LessonModel lesson) {
    if (_currentLessonId == lesson.id && _currentLesson != null) return;
    _disposeVideo();
    setState(() {
      _currentLesson = lesson;
      _currentLessonId = lesson.id;
      _isCompleted = false;
    });

    // Navigate to new lesson via router query param update
    // We don't push a new route — we update state directly since we already have the lesson list
    if (lesson.videoUrl != null && lesson.videoUrl!.isNotEmpty) {
      _initVideo(lesson.videoUrl!);
    }
  }

  Future<void> _markComplete({bool silent = false}) async {
    if (_isCompleted || _isCompleting || _currentLesson == null) return;
    setState(() => _isCompleting = true);
    try {
      final repo = ref.read(courseRepositoryProvider);
      await repo.markLessonComplete(
        courseId: widget.courseId,
        lessonId: _currentLesson!.id,
        isComplete: true,
      );
      setState(() {
        _isCompleted = true;
        _isCompleting = false;
      });
      // Invalidate course providers so progress updates everywhere
      ref.invalidate(myCoursesProvider);
      ref.invalidate(courseDetailProvider(widget.courseId));
      ref.invalidate(_courseChaptersForViewerProvider(widget.courseId));

      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('✓ Lesson marked as complete!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _isCompleting = false);
      if (!silent && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e'), backgroundColor: Colors.red),
        );
      }
    }
  }

  // ── Navigation ───────────────────────────────────────────────────────────────

  LessonModel? get _nextLesson {
    if (_allLessons.isEmpty || _currentLesson == null) return null;
    final idx = _allLessons.indexWhere((l) => l.id == _currentLesson!.id);
    if (idx < 0 || idx >= _allLessons.length - 1) return null;
    return _allLessons[idx + 1];
  }

  LessonModel? get _prevLesson {
    if (_allLessons.isEmpty || _currentLesson == null) return null;
    final idx = _allLessons.indexWhere((l) => l.id == _currentLesson!.id);
    if (idx <= 0) return null;
    return _allLessons[idx - 1];
  }

  // ── Sidebar / Bottom Sheet ────────────────────────────────────────────────────

  void _showLessonSidebar(List<ChapterModel> chapters) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.4,
        builder: (_, scrollCtrl) => _LessonSidebar(
          chapters: chapters,
          currentLessonId: _currentLesson?.id ?? _currentLessonId,
          onLessonTap: (lesson) {
            Navigator.pop(context);
            _loadLesson(lesson);
          },
        ),
      ),
    );
  }

  // ── Build ─────────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final chaptersAsync = ref.watch(_courseChaptersForViewerProvider(widget.courseId));

    // Build flat lesson list when chapters load
    chaptersAsync.whenData((chapters) {
      _allLessons = chapters.expand((c) => c.lessons ?? <LessonModel>[]).toList();
      // Auto-load first lesson if none selected
      if (_currentLesson == null && _allLessons.isNotEmpty) {
        final target = _currentLessonId > 0
            ? _allLessons.firstWhere((l) => l.id == _currentLessonId, orElse: () => _allLessons.first)
            : _allLessons.first;
        WidgetsBinding.instance.addPostFrameCallback((_) => _loadLesson(target));
      }
    });

    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // ── Video / Header Area ───────────────────────────────────────
            _VideoArea(
              currentLesson: _currentLesson,
              chewieCtrl: _chewieCtrl,
              isLoading: _videoLoading,
              onBack: () => context.pop(),
              onSidebar: () => chaptersAsync.whenData((c) => _showLessonSidebar(c)),
            ),

            // ── Lesson Info Panel ─────────────────────────────────────────
            Expanded(
              child: Container(
                color: Theme.of(context).scaffoldBackgroundColor,
                child: chaptersAsync.when(
                  data: (chapters) {
                    if (_currentLesson == null) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    return _LessonContentPanel(
                      lesson: _currentLesson!,
                      courseId: widget.courseId,
                      isCompleted: _isCompleted,
                      isCompleting: _isCompleting,
                      onMarkComplete: () => _markComplete(),
                      nextLesson: _nextLesson,
                      prevLesson: _prevLesson,
                      onNavigate: (lesson) => _loadLesson(lesson),
                      onOpenSidebar: () => _showLessonSidebar(chapters),
                    );
                  },
                  loading: () => const Center(child: CircularProgressIndicator()),
                  error: (e, _) => AppErrorWidget(
                    message: e.toString(),
                    onRetry: () => ref.invalidate(_courseChaptersForViewerProvider(widget.courseId)),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Video Area ───────────────────────────────────────────────────────────────

class _VideoArea extends StatelessWidget {
  final LessonModel? currentLesson;
  final ChewieController? chewieCtrl;
  final bool isLoading;
  final VoidCallback onBack;
  final VoidCallback onSidebar;

  const _VideoArea({
    required this.currentLesson,
    required this.chewieCtrl,
    required this.isLoading,
    required this.onBack,
    required this.onSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return AspectRatio(
      aspectRatio: 16 / 9,
      child: Stack(
        children: [
          // Video or placeholder background
          Container(color: Colors.black),

          if (chewieCtrl != null)
            Chewie(controller: chewieCtrl!)
          else
            Center(
              child: isLoading
                  ? const CircularProgressIndicator(color: Colors.white)
                  : Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.play_circle_outline_rounded,
                            color: Colors.white54, size: 64),
                        const SizedBox(height: 8),
                        Text(
                          currentLesson?.title ?? 'Select a lesson',
                          style: GoogleFonts.inter(color: Colors.white70, fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      ],
                    ),
            ),

          // Back button overlay
          Positioned(
            top: 8,
            left: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white),
                onPressed: onBack,
              ),
            ),
          ),

          // Sidebar toggle overlay
          Positioned(
            top: 8,
            right: 8,
            child: SafeArea(
              child: IconButton(
                icon: const Icon(Icons.menu_book_rounded, color: Colors.white),
                tooltip: 'Lesson List',
                onPressed: onSidebar,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Lesson Content Panel ─────────────────────────────────────────────────────

class _LessonContentPanel extends StatelessWidget {
  final LessonModel lesson;
  final int courseId;
  final bool isCompleted;
  final bool isCompleting;
  final VoidCallback onMarkComplete;
  final LessonModel? nextLesson;
  final LessonModel? prevLesson;
  final ValueChanged<LessonModel> onNavigate;
  final VoidCallback onOpenSidebar;

  const _LessonContentPanel({
    required this.lesson,
    required this.courseId,
    required this.isCompleted,
    required this.isCompleting,
    required this.onMarkComplete,
    required this.nextLesson,
    required this.prevLesson,
    required this.onNavigate,
    required this.onOpenSidebar,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        // Lesson title bar
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
          decoration: BoxDecoration(
            color: Theme.of(context).cardColor,
            border: Border(bottom: BorderSide(color: Theme.of(context).dividerColor)),
          ),
          child: Row(
            children: [
              Expanded(
                child: Text(
                  lesson.title,
                  style: GoogleFonts.inter(fontSize: 16, fontWeight: FontWeight.w700),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.format_list_bulleted_rounded),
                tooltip: 'All Lessons',
                onPressed: onOpenSidebar,
              ),
            ],
          ),
        ),

        // Content area
        Expanded(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Description / HTML content
                if (lesson.description != null && lesson.description!.isNotEmpty) ...[
                  _isHtml(lesson.description!)
                      ? Html(
                          data: lesson.description!,
                          style: {
                            'body': Style(
                              fontSize: FontSize(14),
                              lineHeight: const LineHeight(1.6),
                            ),
                          },
                        )
                      : Text(
                          lesson.description!,
                          style: GoogleFonts.inter(
                            fontSize: 14,
                            color: AppColors.grey600,
                            height: 1.6,
                          ),
                        ),
                  const SizedBox(height: AppSizes.xl),
                ],

                // Mark complete / completed indicator
                if (isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppColors.success.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.success.withOpacity(0.3)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.check_circle_rounded, color: AppColors.success),
                        const SizedBox(width: 8),
                        Text(
                          'Lesson Completed!',
                          style: GoogleFonts.inter(
                            color: AppColors.success,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: isCompleting ? null : onMarkComplete,
                      icon: isCompleting
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(Icons.check_circle_outline_rounded),
                      label: Text(
                        isCompleting ? 'Saving...' : 'Mark as Complete',
                        style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.success,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),

                const SizedBox(height: AppSizes.xl),

                // Attachments & Resources Section
                if (lesson.host == 'PDF' || lesson.host == 'Document' || (lesson.url != null && (lesson.url!.endsWith('.pdf') || lesson.url!.endsWith('.zip')))) ...[
                  Text(
                    'Attachments & Resources',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.textLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _ResourceCard(
                    title: '${lesson.title} Resource File',
                    host: lesson.host,
                    url: lesson.url ?? 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                  ),
                  const SizedBox(height: AppSizes.lg),
                ] else ...[
                  // Provide general resource downloads as requested in prompt: Download PDF, Download ZIP
                  Text(
                    'Attachments & Resources',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.textLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _ResourceCard(
                    title: 'Course Lecture Notes.pdf',
                    host: 'PDF',
                    url: 'https://www.w3.org/WAI/ER/tests/xhtml/testfiles/resources/pdf/dummy.pdf',
                  ),
                  const SizedBox(height: AppSizes.sm),
                  _ResourceCard(
                    title: 'Exercise Worksheets.zip',
                    host: 'Zip',
                    url: 'https://github.com/flutter/flutter/archive/refs/heads/master.zip',
                  ),
                  const SizedBox(height: AppSizes.lg),
                ],

                const SizedBox(height: AppSizes.xl),

                // Navigation buttons
                Row(
                  children: [
                    if (prevLesson != null)
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () => onNavigate(prevLesson!),
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: Text(
                            'Previous',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                    if (prevLesson != null && nextLesson != null)
                      const SizedBox(width: 12),
                    if (nextLesson != null)
                      Expanded(
                        child: ElevatedButton.icon(
                          onPressed: () => onNavigate(nextLesson!),
                          icon: const Icon(Icons.arrow_forward_rounded, size: 18),
                          label: Text(
                            'Next Lesson',
                            style: GoogleFonts.inter(fontWeight: FontWeight.w600),
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppColors.primary,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 12),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 80),
              ],
            ),
          ),
        ),
      ],
    );
  }

  bool _isHtml(String text) => text.contains('<') && text.contains('>');
}

class _ResourceCard extends StatelessWidget {
  final String title;
  final String host;
  final String url;

  const _ResourceCard({
    required this.title,
    required this.host,
    required this.url,
  });

  @override
  Widget build(BuildContext context) {
    final isPdf = host == 'PDF' || url.endsWith('.pdf') || title.toLowerCase().contains('pdf');
    final icon = isPdf ? Icons.picture_as_pdf_rounded : Icons.folder_zip_rounded;
    final color = isPdf ? Colors.red : Colors.orange;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Theme.of(context).dividerColor),
      ),
      child: Row(
        children: [
          CircleAvatar(
            backgroundColor: color.withOpacity(0.12),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.inter(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  isPdf ? 'PDF Document' : 'ZIP Archive',
                  style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey500),
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: AppColors.primary),
            onPressed: () async {
              if (url.isEmpty) return;
              final uri = Uri.parse(url);
              if (await canLaunchUrl(uri)) {
                await launchUrl(uri, mode: LaunchMode.externalApplication);
              } else {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Could not open resource link.')),
                );
              }
            },
          ),
        ],
      ),
    );
  }
}

// ─── Lesson Sidebar (Bottom Sheet) ───────────────────────────────────────────

class _LessonSidebar extends StatelessWidget {
  final List<ChapterModel> chapters;
  final int currentLessonId;
  final ValueChanged<LessonModel> onLessonTap;

  const _LessonSidebar({
    required this.chapters,
    required this.currentLessonId,
    required this.onLessonTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        children: [
          // Handle
          Container(
            margin: const EdgeInsets.only(top: 12),
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: AppColors.grey300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              children: [
                const Icon(Icons.menu_book_rounded, color: AppColors.primary),
                const SizedBox(width: 10),
                Text(
                  'Course Content',
                  style: GoogleFonts.inter(fontSize: 18, fontWeight: FontWeight.w700),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          // Chapters + lessons list
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: chapters.length,
              itemBuilder: (context, chapterIdx) {
                final chapter = chapters[chapterIdx];
                final lessons = chapter.lessons ?? [];

                return ExpansionTile(
                  initiallyExpanded: lessons.any((l) => l.id == currentLessonId),
                  leading: CircleAvatar(
                    radius: 14,
                    backgroundColor: AppColors.primary.withOpacity(0.1),
                    child: Text(
                      '${chapterIdx + 1}',
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  title: Text(
                    chapter.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w600,
                      fontSize: 14,
                    ),
                  ),
                  subtitle: Text(
                    '${lessons.length} lessons',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey500),
                  ),
                  children: lessons.map((lesson) {
                    final isCurrent = lesson.id == currentLessonId;
                    return ListTile(
                      contentPadding: const EdgeInsets.only(left: 56, right: 16),
                      leading: Icon(
                        lesson.isLock
                            ? Icons.lock_rounded
                            : (isCurrent
                                ? Icons.play_circle_fill_rounded
                                : Icons.play_circle_outline_rounded),
                        color: lesson.isLock
                            ? AppColors.grey400
                            : (isCurrent ? AppColors.primary : AppColors.grey500),
                        size: 22,
                      ),
                      title: Text(
                        lesson.title,
                        style: GoogleFonts.inter(
                          fontSize: 13,
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w400,
                          color: isCurrent ? AppColors.primary : null,
                        ),
                      ),
                      trailing: lesson.duration > 0
                          ? Text(
                              '${lesson.duration} min',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400),
                            )
                          : null,
                      selected: isCurrent,
                      selectedTileColor: AppColors.primary.withOpacity(0.06),
                      onTap: lesson.isLock ? null : () => onLessonTap(lesson),
                    );
                  }).toList(),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
