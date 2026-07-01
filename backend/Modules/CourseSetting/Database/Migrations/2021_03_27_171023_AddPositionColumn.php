<?php

use Illuminate\Database\Migrations\Migration;
use Illuminate\Support\Facades\Schema;

class AddPositionColumn extends Migration
{
    /**
     * Run the migrations.
     *
     * @return void
     */
    public function up()
    {
        if (Schema::hasTable('chapters')) {
            Schema::table('chapters', function ($table) {
                if (!Schema::hasColumn('chapters', 'position')) {
                    $table->integer('position')->default(999999);
                }
            });
        }

        if (Schema::hasTable('lessons')) {
            Schema::table('lessons', function ($table) {
                if (!Schema::hasColumn('lessons', 'position')) {
                    $table->integer('position')->default(999999);
                }
            });
        }
    }

    /**
     * Reverse the migrations.
     *
     * @return void
     */
    public function down()
    {
        //
    }
}
