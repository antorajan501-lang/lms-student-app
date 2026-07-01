import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../repositories/course_repository.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/shimmer_loader.dart';

class CalendarScreen extends ConsumerStatefulWidget {
  const CalendarScreen({super.key});

  @override
  ConsumerState<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends ConsumerState<CalendarScreen> {
  late DateTime _selectedMonth;
  late DateTime _selectedDay;
  final DateFormat _monthFormat = DateFormat('MMMM yyyy');

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateTime.now();
    _selectedDay = DateTime.now();
  }

  // Generate calendar days for monthly view
  List<DateTime?> _generateMonthDays(DateTime month) {
    final firstDayOfMonth = DateTime(month.year, month.month, 1);
    final lastDayOfMonth = DateTime(month.year, month.month + 1, 0);

    final leadingEmptyDays = firstDayOfMonth.weekday - 1; // Mon = 1, so offset
    final totalDays = lastDayOfMonth.day;

    final List<DateTime?> days = [];
    for (var i = 0; i < leadingEmptyDays; i++) {
      days.add(null);
    }
    for (var i = 1; i <= totalDays; i++) {
      days.add(DateTime(month.year, month.month, i));
    }
    return days;
  }

  void _nextMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month + 1, 1);
    });
  }

  void _prevMonth() {
    setState(() {
      _selectedMonth = DateTime(_selectedMonth.year, _selectedMonth.month - 1, 1);
    });
  }

  List<Widget> _buildEventIndicators(int count) {
    final List<Widget> indicators = [];
    if (count <= 3) {
      for (int i = 0; i < count; i++) {
        indicators.add(
          Container(
            width: 8,
            height: 8,
            margin: const EdgeInsets.symmetric(horizontal: 1.5),
            decoration: const BoxDecoration(
              color: AppColors.primary,
              shape: BoxShape.circle,
            ),
          ),
        );
      }
    } else {
      indicators.add(
        Container(
          width: 8,
          height: 8,
          decoration: const BoxDecoration(
            color: AppColors.primary,
            shape: BoxShape.circle,
          ),
        ),
      );
      indicators.add(
        const SizedBox(width: 2),
      );
      indicators.add(
        Text(
          '+$count',
          style: GoogleFonts.inter(
            fontSize: 8,
            fontWeight: FontWeight.w800,
            color: AppColors.primary,
          ),
        ),
      );
    }
    return indicators;
  }

  @override
  Widget build(BuildContext context) {
    final myClassesAsync = ref.watch(myClassesFutureProvider);
    final days = _generateMonthDays(_selectedMonth);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Academic Calendar'),
      ),
      body: CustomScrollView(
        slivers: [
          // Month navigation bar
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppSizes.screenPadding,
                vertical: AppSizes.sm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left_rounded),
                    onPressed: _prevMonth,
                  ),
                  Text(
                    _monthFormat.format(_selectedMonth),
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.textLg,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.chevron_right_rounded),
                    onPressed: _nextMonth,
                  ),
                ],
              ),
            ),
          ),

          // Days of the week header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              child: Row(
                children: ['M', 'T', 'W', 'T', 'F', 'S', 'S'].map((day) {
                  return Expanded(
                    child: Center(
                      child: Text(
                        day,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: AppColors.grey500,
                          fontSize: 12,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.sm)),

          // Monthly Calendar Grid
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              child: Card(
                elevation: 0,
                color: Theme.of(context).cardTheme.color,
                child: GridView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(AppSizes.sm),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 7,
                    mainAxisSpacing: AppSizes.xs,
                    crossAxisSpacing: AppSizes.xs,
                    childAspectRatio: 1.0,
                  ),
                  itemCount: days.length,
                  itemBuilder: (context, index) {
                    final day = days[index];
                    if (day == null) return const SizedBox.shrink();

                    final now = DateTime.now();
                    final todayStart = DateTime(now.year, now.month, now.day);
                    final dayDate = DateTime(day.year, day.month, day.day);

                    final isPast = dayDate.isBefore(todayStart);
                    final isToday = dayDate.isAtSameMomentAs(todayStart);
                    final isFuture = dayDate.isAfter(todayStart);

                    final classes = myClassesAsync.value ?? [];
                    final dayEvents = _generateEventsForDay(day, classes);
                    final eventCount = dayEvents.length;

                    return GestureDetector(
                      onTap: isPast
                          ? null
                          : () {
                              setState(() {
                                _selectedDay = day;
                              });
                            },
                      child: Center(
                        child: Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: isToday
                                ? const Color(0xFF3B82F6)
                                : isPast
                                    ? (eventCount > 0
                                        ? const Color(0xFFFF6B00).withOpacity(0.15)
                                        : Colors.transparent)
                                    : (eventCount > 0
                                        ? const Color(0xFFFF6B00)
                                        : Colors.transparent),
                            shape: BoxShape.circle,
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            '${day.day}',
                            style: GoogleFonts.inter(
                              fontSize: AppSizes.textMd,
                              fontWeight: isToday || eventCount > 0
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: isToday
                                  ? Colors.white
                                  : isPast
                                      ? (eventCount > 0
                                          ? const Color(0xFFFF6B00)
                                          : AppColors.grey400)
                                      : (eventCount > 0
                                          ? Colors.white
                                          : Theme.of(context)
                                              .colorScheme
                                              .onSurface),
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.lg)),

          // Selected Day Header
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
              child: Text(
                DateFormat('EEEE, d MMMM').format(_selectedDay),
                style: GoogleFonts.inter(
                  fontSize: AppSizes.textLg,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.sm)),

          // List of events for the day
          myClassesAsync.when(
            data: (classes) {
              // Generate mock schedules mixed with real live classes
              final dayEvents = _generateEventsForDay(_selectedDay, classes);

              if (dayEvents.isEmpty) {
                return const SliverToBoxAdapter(
                  child: Padding(
                    padding: EdgeInsets.all(AppSizes.xl),
                    child: Center(
                      child: Text(
                        'No classes or schedules on this day.',
                        style: TextStyle(color: AppColors.grey500),
                      ),
                    ),
                  ),
                );
              }

              return SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final event = dayEvents[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(
                        horizontal: AppSizes.screenPadding,
                        vertical: AppSizes.xs,
                      ),
                      child: _EventCard(event: event),
                    );
                  },
                  childCount: dayEvents.length,
                ),
              );
            },
            loading: () => SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(AppSizes.screenPadding),
                child: Column(
                  children: List.generate(
                    2,
                    (_) => const Padding(
                      padding: EdgeInsets.only(bottom: AppSizes.sm),
                      child: ShimmerLoader(height: 110),
                    ),
                  ),
                ),
              ),
            ),
            error: (err, _) => SliverToBoxAdapter(
              child: AppErrorWidget(
                message: err.toString(),
                onRetry: () => ref.invalidate(myClassesFutureProvider),
              ),
            ),
          ),

          const SliverToBoxAdapter(child: SizedBox(height: AppSizes.xl)),
        ],
      ),
    );
  }

  // Generate hybrid real/mock schedules to keep UI functional & premium
  List<CalendarEvent> _generateEventsForDay(DateTime day, List<dynamic> realClasses) {
    final List<CalendarEvent> events = [];

    // Real enrolled live classes mapping
    if (realClasses.isNotEmpty && day.weekday % 2 == 1) {
      for (var i = 0; i < realClasses.length; i++) {
        final rc = realClasses[i];
        events.add(CalendarEvent(
          title: rc['title'] ?? 'Live Class Session',
          instructor: rc['assigned_instructor'] ?? 'Professor',
          time: '10:00 AM - 11:30 AM',
          type: CalendarEventType.liveClass,
          joinUrl: 'https://zoom.us/join',
        ));
      }
    }

    // Default daily schedule plans/exams
    if (day.day % 4 == 0) {
      events.add(CalendarEvent(
        title: 'Quiz Submission: Software Architecture Quiz 1',
        instructor: 'Prof. Somsak Udom',
        time: 'Due before 11:59 PM',
        type: CalendarEventType.quiz,
      ));
    }
    if (day.day % 7 == 0) {
      events.add(CalendarEvent(
        title: 'Assignment: Event-driven Microservices Case Study',
        instructor: 'Dr. Michael Chen',
        time: 'Due before 6:00 PM',
        type: CalendarEventType.assignment,
      ));
    }

    return events;
  }
}

enum CalendarEventType { liveClass, quiz, assignment }

class CalendarEvent {
  final String title;
  final String instructor;
  final String time;
  final CalendarEventType type;
  final String? joinUrl;

  CalendarEvent({
    required this.title,
    required this.instructor,
    required this.time,
    required this.type,
    this.joinUrl,
  });
}

class _EventCard extends StatelessWidget {
  final CalendarEvent event;

  const _EventCard({required this.event});

  @override
  Widget build(BuildContext context) {
    Color typeColor;
    IconData icon;
    String typeLabel;

    switch (event.type) {
      case CalendarEventType.liveClass:
        typeColor = AppColors.primary;
        icon = Icons.video_camera_front_rounded;
        typeLabel = 'Live Class';
        break;
      case CalendarEventType.quiz:
        typeColor = AppColors.warning;
        icon = Icons.timer_rounded;
        typeLabel = 'Upcoming Quiz';
        break;
      case CalendarEventType.assignment:
        typeColor = AppColors.accent;
        icon = Icons.assignment_outlined;
        typeLabel = 'Assignment Due';
        break;
    }

    return Card(
      elevation: 0,
      color: Theme.of(context).cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
        side: BorderSide(color: Theme.of(context).dividerColor),
      ),
      child: Padding(
        padding: const EdgeInsets.all(AppSizes.md),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status Icon Block
            Container(
              padding: const EdgeInsets.all(AppSizes.sm),
              decoration: BoxDecoration(
                color: typeColor.withOpacity(0.08),
                borderRadius: BorderRadius.circular(AppSizes.radiusMd),
              ),
              child: Icon(icon, color: typeColor, size: 24),
            ),
            const SizedBox(width: AppSizes.md),

            // Text Info Block
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Type tag
                  Text(
                    typeLabel.toUpperCase(),
                    style: GoogleFonts.inter(
                      color: typeColor,
                      fontSize: 10,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.8,
                    ),
                  ),
                  const SizedBox(height: 2),
                  // Title
                  Text(
                    event.title,
                    style: GoogleFonts.inter(
                      fontWeight: FontWeight.w700,
                      fontSize: AppSizes.textMd,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xs),
                  // Time
                  Row(
                    children: [
                      const Icon(Icons.schedule_rounded,
                          color: AppColors.grey400, size: 14),
                      const SizedBox(width: 4),
                      Text(
                        event.time,
                        style: GoogleFonts.inter(
                          fontSize: 12,
                          color: AppColors.grey500,
                        ),
                      ),
                    ],
                  ),
                  if (event.joinUrl != null) ...[
                    const SizedBox(height: AppSizes.md),
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        minimumSize: const Size(120, 36),
                        padding: const EdgeInsets.symmetric(horizontal: AppSizes.md),
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                      ),
                      onPressed: () async {
                        final uri = Uri.parse(event.joinUrl!);
                        if (await canLaunchUrl(uri)) {
                          await launchUrl(uri);
                        }
                      },
                      icon: const Icon(Icons.play_circle_fill_rounded, size: 16),
                      label: const Text('Join Live Class', style: TextStyle(fontSize: 12)),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Riverpod provider to load live classes from the repository
final myClassesFutureProvider = FutureProvider<List<dynamic>>((ref) async {
  final repo = ref.watch(courseRepositoryProvider);
  return repo.getMyClasses();
});
