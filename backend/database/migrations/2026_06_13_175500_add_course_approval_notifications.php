<?php

use Illuminate\Support\Facades\DB;
use Illuminate\Database\Migrations\Migration;
use Modules\SystemSetting\Entities\EmailTemplate;

class AddCourseApprovalNotifications extends Migration
{
    public function up()
    {
        $this->courseApprovalRequestedNotification();
        $this->courseApprovedNotification();
    }

    public function down()
    {
        EmailTemplate::where('act', 'Course_Approval_Requested')->delete();
        EmailTemplate::where('act', 'Course_Approved')->delete();
    }

    public function courseApprovalRequestedNotification()
    {
        $subject = 'Requesting Approval for Add Course';
        $br = "<br/>";
        $body = 'Hello {{admin}}, A new course ({{course}}) has been submitted for approval by {{instructor}}.  ' . $br . "{{footer}}";

        EmailTemplate::updateOrCreate([
            'act' => 'Course_Approval_Requested',
        ], [
            'name' => $subject,
            'subj' => $subject,
            'email_body' => htmlPart($subject, $body),
            'shortcodes' => '{"admin":"Admin Name","course":"Course Name","instructor":"Instructor Name"}',
            'status' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }

    public function courseApprovedNotification()
    {
        $subject = 'Course Approved';
        $br = "<br/>";
        $body = 'Hello {{instructor}}, Your course ({{course}}) has been approved by the admin and is now live.  ' . $br . "{{footer}}";

        EmailTemplate::updateOrCreate([
            'act' => 'Course_Approved',
        ], [
            'name' => $subject,
            'subj' => $subject,
            'email_body' => htmlPart($subject, $body),
            'shortcodes' => '{"instructor":"Instructor Name","course":"Course Name"}',
            'status' => 1,
            'created_at' => now(),
            'updated_at' => now(),
        ]);
    }
}
