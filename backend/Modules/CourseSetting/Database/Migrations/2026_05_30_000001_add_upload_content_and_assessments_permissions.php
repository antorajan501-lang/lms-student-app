<?php

use Illuminate\Support\Facades\Schema;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Cache;
use Modules\RolePermission\Entities\Permission;

class AddUploadContentAndAssessmentsPermissions extends Migration
{
    public function up()
    {
        $routes = [
            [
                'name' => 'Upload Content',
                'route' => 'course.upload-content',
                'type' => 2,
                'parent_route' => 'courses',
                'backend' => 1,
                'status' => 1,
            ],
            [
                'name' => 'Assessments',
                'route' => 'course.assessments',
                'type' => 2,
                'parent_route' => 'courses',
                'backend' => 1,
                'status' => 1,
            ],
        ];

        permissionUpdateOrCreate($routes);

        // Safe cache flushing without booting nested console commands
        try {
            Cache::flush();
        } catch (\Exception $e) {
            // best effort cache clear
        }
    }

    public function down()
    {
        Permission::whereIn('route', ['course.upload-content', 'course.assessments'])->delete();
        try {
            Cache::flush();
        } catch (\Exception $e) {
            // best effort cache clear
        }
    }
}
