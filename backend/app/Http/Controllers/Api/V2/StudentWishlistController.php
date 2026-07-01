<?php

namespace App\Http\Controllers\Api\V2;

use App\Http\Controllers\Controller;
use Illuminate\Http\JsonResponse;
use Illuminate\Http\Request;
use Illuminate\Support\Facades\Auth;
use Modules\CourseSetting\Entities\Course;

/**
 * Student wishlist management.
 * Stores wishlisted course IDs per user in the user_wishlists table
 * (falls back to a JSON column on users if table is absent).
 */
class StudentWishlistController extends Controller
{
    /**
     * GET /api/v2/wishlist
     * Returns the authenticated student's wishlisted courses.
     */
    public function index(): JsonResponse
    {
        $userId      = Auth::id();
        $wishlistIds = $this->getWishlistIds($userId);

        $courses = Course::whereIn('id', $wishlistIds)
            ->select('id', 'title', 'slug', 'thumbnail', 'price', 'discount_price', 'total_enrolled', 'type')
            ->get()
            ->map(fn ($c) => [
                'id'             => $c->id,
                'title'          => $c->title,
                'thumbnail'      => $c->thumbnail,
                'price'          => $c->price,
                'discount_price' => $c->discount_price,
                'total_enrolled' => $c->total_enrolled,
                'type'           => $c->type,
                'in_wishlist'    => true,
            ]);

        return response()->json([
            'success' => true,
            'data'    => $courses,
            'message' => 'Wishlist retrieved successfully',
        ]);
    }

    /**
     * POST /api/v2/wishlist/toggle
     * Body: { "course_id": 5 }
     * Adds to wishlist if not present, removes if already present.
     */
    public function toggle(Request $request): JsonResponse
    {
        $request->validate(['course_id' => 'required|integer|exists:courses,id']);

        $userId   = Auth::id();
        $courseId = (int) $request->course_id;
        $ids      = $this->getWishlistIds($userId);

        if (in_array($courseId, $ids)) {
            $ids        = array_values(array_diff($ids, [$courseId]));
            $inWishlist = false;
        } else {
            $ids[]      = $courseId;
            $inWishlist = true;
        }

        $this->saveWishlistIds($userId, $ids);

        return response()->json([
            'success'     => true,
            'in_wishlist' => $inWishlist,
            'message'     => $inWishlist ? 'Added to wishlist' : 'Removed from wishlist',
        ]);
    }

    // ─── helpers ───────────────────────────────────────────────────────────

    private function getWishlistIds(int $userId): array
    {
        // Use a dedicated table when available, else fallback to user meta column
        if (\Illuminate\Support\Facades\Schema::hasTable('user_wishlists')) {
            return \Illuminate\Support\Facades\DB::table('user_wishlists')
                ->where('user_id', $userId)
                ->pluck('course_id')
                ->toArray();
        }

        $user = \App\User::find($userId);
        return $user ? (json_decode($user->wishlist ?? '[]', true) ?: []) : [];
    }

    private function saveWishlistIds(int $userId, array $ids): void
    {
        if (\Illuminate\Support\Facades\Schema::hasTable('user_wishlists')) {
            \Illuminate\Support\Facades\DB::table('user_wishlists')
                ->where('user_id', $userId)
                ->delete();

            $rows = array_map(fn ($cid) => [
                'user_id'    => $userId,
                'course_id'  => $cid,
                'created_at' => now(),
                'updated_at' => now(),
            ], $ids);

            if (!empty($rows)) {
                \Illuminate\Support\Facades\DB::table('user_wishlists')->insert($rows);
            }
            return;
        }

        \App\User::where('id', $userId)->update(['wishlist' => json_encode($ids)]);
    }
}
