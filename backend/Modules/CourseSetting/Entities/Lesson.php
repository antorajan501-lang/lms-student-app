<?php

namespace Modules\CourseSetting\Entities;

use App\LessonComplete;
use Illuminate\Database\Eloquent\Model;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Schema;
use Illuminate\Validation\ValidationException;
use Modules\Assignment\Entities\InfixAssignment;
use Modules\BunnyStorage\Entities\BunnyLesson;
use Modules\H5P\Entities\H5pContent;
use Modules\H5P\Entities\H5pReport;
use Modules\Org\Entities\OrgMaterial;
use Modules\Quiz\Entities\OnlineQuiz;
use Modules\Setting\Entities\UsedMedia;


class Lesson extends Model
{


    protected $guarded = ['id'];

    public function chapter()
    {

        return $this->belongsTo(Chapter::class)->withDefault();
    }

    public function course()
    {

        return $this->belongsTo(Course::class)->withDefault();
    }

    public function courseSession()
    {
        return $this->belongsTo(\App\Models\CourseSession::class, 'course_session_id')->withDefault();
    }

    public function quiz()
    {

        return $this->hasMany(OnlineQuiz::class, 'id', 'quiz_id');
    }

    public function assignment()
    {

        return $this->hasMany(InfixAssignment::class, 'id', 'assignment_id');
    }

    public function assignmentInfo()
    {

        return $this->hasOne(InfixAssignment::class, 'id', 'assignment_id');
    }

    public function completed()
    {
        $id = 0;
        if (Auth::check()) {
            $id = Auth::user()->id;
        }
        return $this->hasOne(LessonComplete::class, 'lesson_id', 'id')->where('user_id', $id);
    }

    public function lessonQuiz()
    {
        return $this->belongsTo(OnlineQuiz::class, 'quiz_id')->withDefault();

    }

    protected static function boot()
    {
        parent::boot();

        static::saving(function ($lesson) {
            if (!Schema::hasTable('lessons')
                || !$lesson->course_id
                || is_null($lesson->is_lock)
                || (int)$lesson->is_lock !== 0) {
                return;
            }

            $previewExists = static::where('course_id', $lesson->course_id)
                ->where('is_lock', 0)
                ->when($lesson->exists, function ($query) use ($lesson) {
                    return $query->where('id', '!=', $lesson->id);
                })
                ->exists();

            // Temporarily disabled to allow multiple free previews for registered students
            // if ($previewExists) {
            //     throw ValidationException::withMessages([
            //         'is_lock' => 'Only one curriculum lesson can be selected as the free preview.',
            //     ]);
            // }
        });

        static::created(function ($lesson) {
            $self_hosts = ['Self', 'Image', 'PDF', 'Word', 'Excel', 'Text', 'Zip', 'PowerPoint'];
            if (in_array($lesson->host, $self_hosts)) {
                $file = $lesson->video_url;
                $filesize = filesize($file); // bytes
                // $filesize = round($filesize / 1024 / 1024, 1); //MB
                $filesize = round($filesize / 1024, 2); //KB

                $lesson->old_file_size = $filesize;
                $lesson->file_size = $filesize;
                $lesson->save();
            }
            if (isModuleActive('LmsSaas')) {
                if (in_array($lesson->host, $self_hosts)) {
                    saasPlanManagement('upload_limit', 'create', $filesize);
                }
            }
        });
        self::deleting(function ($lesson) {
            saasPlanManagement('upload_limit', 'delete', $lesson->filesize);
        });
    }

    public function files()
    {
        return $this->hasMany(LessonFile::class, 'lesson_id')->orderByDesc('version');
    }

    public function orgMaterial()
    {
        return $this->belongsTo(OrgMaterial::class)->withDefault();
    }

    public function h5pContent()
    {
        return $this->belongsTo(H5pContent::class, 'h5p_id', 'id')->withDefault();
    }

    public function h5pReport($student_id)
    {
        return $this->hasOne(H5pReport::class, 'lesson_id', 'id')->where('user_id', $student_id)->first();
    }

    public function bunnyLesson()
    {
        return $this->hasOne(BunnyLesson::class, 'lesson_id');
    }

    public function video_url_media()
    {
        return $this->morphOne(UsedMedia::class, 'usable')->where('used_for', 'video_url');
    }

}
