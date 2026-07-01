<?php

namespace Modules\CourseSetting\Entities;

use Illuminate\Database\Eloquent\Model;

class Chapter extends Model
{


    protected $fillable = [];

    public function lessons()
    {
        return $this->hasMany(Lesson::class, 'chapter_id', 'id')->orderBy('position');
    }

    public function contentItems()
    {
        return $this->hasMany(CourseContentItem::class, 'chapter_id', 'id')->orderBy('sort_order');
    }
}
