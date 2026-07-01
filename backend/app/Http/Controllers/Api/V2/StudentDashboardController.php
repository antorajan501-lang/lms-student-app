<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use App\LessonComplete;
use Illuminate\Http\JsonResponse;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Cache;
use Modules\Certificate\Entities\CertificateRecord;
use Modules\CourseSetting\Entities\Course;
use Modules\CourseSetting\Entities\CourseEnrolled;
use Modules\CourseSetting\Entities\Lesson;

/**
 * Student-specific dashboard aggregation controller.
 * Provides all data needed to render the student dashboard in a single request.
 */
class StudentDashboardController extends Controller
{
    /**
     * GET /api/v2/student/dashboard
     *
     * Returns an aggregated snapshot of the authenticated student's learning state:
     *  - enrolled_courses   : list of enrolled courses with progress %
     *  - in_progress        : count of courses the student has started but not completed
     *  - completed          : count of courses completed (100% progress)
     *  - certificates_earned: count of certificates the student has received
     *  - recent_activity    : the last 5 lessons completed
     */
    public function dashboard(): JsonResponse
    {
        $userId = Auth::id();
        $cacheKey = "student_dashboard_{$userId}";

        // 60-second soft cache to avoid hammering the DB on every tab switch
        $data = Cache::remember($cacheKey, 60, function () use ($userId) {

            // All enrollments with the related course
            $enrollments = CourseEnrolled::with(['course' => function ($q) {
                $q->select('id', 'title', 'slug', 'thumbnail', 'type', 'total_enrolled');
            }])
                ->where('student_id', $userId)
                ->latest()
                ->take(10)
                ->get();

            // Per-course progress
            $enrolledWithProgress = $enrollments->map(function ($enrollment) use ($userId) {
                $courseId   = $enrollment->course_id;
                $totalLessons = Lesson::whereHas('chapter', fn ($q) =>
                    $q->where('course_id', $courseId)
                )->count();

                $completedLessons = LessonComplete::where('user_id', $userId)
                    ->where('course_id', $courseId)
                    ->count();

                $progress = $totalLessons > 0
                    ? round(($completedLessons / $totalLessons) * 100)
                    : 0;

                return [
                    'enrollment_id'     => $enrollment->id,
                    'course_id'         => $courseId,
                    'course_title'      => optional($enrollment->course)->title,
                    'course_thumbnail'  => optional($enrollment->course)->thumbnail,
                    'course_type'       => optional($enrollment->course)->type,
                    'progress'          => $progress,
                    'enrolled_at'       => $enrollment->created_at,
                ];
            });

            // Global stats
            $totalEnrolled   = CourseEnrolled::where('student_id', $userId)->count();
            $inProgress      = $enrolledWithProgress->filter(fn ($e) => $e['progress'] > 0 && $e['progress'] < 100)->count();
            $completed       = $enrolledWithProgress->filter(fn ($e) => $e['progress'] >= 100)->count();
            $certificateCount = CertificateRecord::where('student_id', $userId)->count();

            // Recent lesson completions
            $recentActivity = LessonComplete::with(['lesson:id,title', 'course:id,title'])
                ->where('user_id', $userId)
                ->latest()
                ->take(5)
                ->get()
                ->map(fn ($lc) => [
                    'lesson_title'  => optional($lc->lesson)->title,
                    'course_title'  => optional($lc->course)->title,
                    'completed_at'  => $lc->created_at,
                ]);

            return [
                'enrolled_courses'    => $enrolledWithProgress->values(),
                'stats' => [
                    'total_enrolled'       => $totalEnrolled,
                    'in_progress'          => $inProgress,
                    'completed'            => $completed,
                    'certificates_earned'  => $certificateCount,
                ],
                'recent_activity' => $recentActivity,
            ];
        });

        return response()->json([
            'success' => true,
            'data'    => $data,
            'message' => 'Dashboard data retrieved successfully',
        ]);
    }

    /**
     * GET /api/v2/student/course-progress/{courseId}
     *
     * Returns detailed progress for a single course:
     *  - progress_percent
     *  - completed_lessons  : array of lesson IDs the student has completed
     *  - total_lessons
     */
    public function courseProgress(int $courseId): JsonResponse
    {
        $userId = Auth::id();

        // Verify enrollment
        $enrolled = CourseEnrolled::where('student_id', $userId)
            ->where('course_id', $courseId)
            ->exists();

        if (!$enrolled) {
            return response()->json([
                'success' => false,
                'message' => 'You are not enrolled in this course.',
            ], 403);
        }

        $totalLessons = Lesson::whereHas('chapter', fn ($q) =>
            $q->where('course_id', $courseId)
        )->count();

        $completedRecords = LessonComplete::where('user_id', $userId)
            ->where('course_id', $courseId)
            ->get();

        $completedCount   = $completedRecords->count();
        $progress         = $totalLessons > 0
            ? round(($completedCount / $totalLessons) * 100)
            : 0;

        return response()->json([
            'success' => true,
            'data' => [
                'course_id'          => $courseId,
                'total_lessons'      => $totalLessons,
                'completed_lessons'  => $completedCount,
                'completed_ids'      => $completedRecords->pluck('lesson_id'),
                'progress_percent'   => $progress,
            ],
            'message' => 'Course progress retrieved successfully',
        ]);
    }
}
