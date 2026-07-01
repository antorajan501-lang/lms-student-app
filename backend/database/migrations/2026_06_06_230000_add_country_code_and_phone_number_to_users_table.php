<?php

use App\Support\UserPhone;
use Illuminate\Database\Migrations\Migration;
use Illuminate\Database\Schema\Blueprint;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Schema;

return new class extends Migration
{
    private string $indexName = 'users_country_code_phone_number_unique';

    public function up(): void
    {
        Schema::table('users', function (Blueprint $table) {
            if (!Schema::hasColumn('users', 'country_code')) {
                $table->string('country_code', 10)->nullable()->after('phone');
            }

            if (!Schema::hasColumn('users', 'phone_number')) {
                $table->string('phone_number', 20)->nullable()->after('country_code');
            }
        });

        $this->backfillSplitPhoneColumns();

        if (!$this->indexExists('users', $this->indexName)) {
            Schema::table('users', function (Blueprint $table) {
                $table->unique(['country_code', 'phone_number'], $this->indexName);
            });
        }
    }

    public function down(): void
    {
        if ($this->indexExists('users', $this->indexName)) {
            Schema::table('users', function (Blueprint $table) {
                $table->dropUnique($this->indexName);
            });
        }

        $columns = collect(['phone_number', 'country_code'])
            ->filter(fn ($column) => Schema::hasColumn('users', $column))
            ->values()
            ->all();

        if (!empty($columns)) {
            Schema::table('users', function (Blueprint $table) use ($columns) {
                $table->dropColumn($columns);
            });
        }
    }

    private function backfillSplitPhoneColumns(): void
    {
        if (!Schema::hasColumn('users', 'country_code') || !Schema::hasColumn('users', 'phone_number')) {
            return;
        }

        $rows = DB::table('users')
            ->whereIn('role_id', [2, 3])
            ->whereNotNull('phone')
            ->where(function ($query) {
                $query->whereNull('country_code')
                    ->orWhereNull('phone_number');
            })
            ->select('id', 'phone')
            ->orderBy('id')
            ->get();

        $candidates = [];

        foreach ($rows as $row) {
            $parsed = UserPhone::parseCombined($row->phone);

            if (!$parsed) {
                continue;
            }

            $key = $parsed['country_code'] . '|' . $parsed['phone_number'];
            $candidates[$key][] = [
                'id' => $row->id,
                'country_code' => $parsed['country_code'],
                'phone_number' => $parsed['phone_number'],
            ];
        }

        foreach ($candidates as $candidateGroup) {
            if (count($candidateGroup) !== 1) {
                continue;
            }

            $candidate = $candidateGroup[0];

            DB::table('users')
                ->where('id', $candidate['id'])
                ->update([
                    'country_code' => $candidate['country_code'],
                    'phone_number' => $candidate['phone_number'],
                ]);
        }
    }

    private function indexExists(string $table, string $indexName): bool
    {
        try {
            if (DB::connection()->getDriverName() === 'mysql') {
                return collect(DB::select("SHOW INDEX FROM {$table} WHERE Key_name = ?", [$indexName]))->isNotEmpty();
            }

            return collect(Schema::getIndexes($table))
                ->contains(fn ($index) => ($index['name'] ?? null) === $indexName);
        } catch (Throwable $e) {
            return false;
        }
    }
};
