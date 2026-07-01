<?php

namespace Database\Seeders;

use Illuminate\Database\Seeder;

class DatabaseSeeder extends Seeder
{
    /**
     * Seed the application's database.
     *
     * @return void
     */
    public function run()
    {
        $this->call(CreateAdminSeeder::class);

        if (filter_var(env('SEED_DEMO_ASSESSMENTS', false), FILTER_VALIDATE_BOOLEAN)) {
            $this->call(AssessmentsSeeder::class);
        }

        $this->call(CleveraDemoSeeder::class);
    }
}
