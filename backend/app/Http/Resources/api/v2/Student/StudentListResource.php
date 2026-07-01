<?php

namespace App\Http\Resources\api\v2\Student;

use App\Services\StudentVerificationService;
use Illuminate\Http\Request;
use Illuminate\Http\Resources\Json\JsonResource;

class StudentListResource extends JsonResource
{
    public function toArray(Request $request): array
    {
        return [
            'student_id'    => (int)$this->id,
            'full_name'     => (string)$this->name,
            'email'         => (string)$this->email,
            'student_image' =>getProfileImage($this->image,$this->name),
            'status'        => (bool)$this->status,
            'verification_status' => StudentVerificationService::status($this->resource),
            'verification_label' => StudentVerificationService::label($this->resource),
        ];
    }
}
