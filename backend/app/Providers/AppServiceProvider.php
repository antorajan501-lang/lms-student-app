<?php

namespace App\Providers;

use App\AboutPage;
use App\Models\LmsInstitute;
use App\OAuth\GoogleDriveProvider;
use App\User;
use Exception;
use Illuminate\Database\Eloquent\Builder;
use Illuminate\Pagination\Paginator;
use Illuminate\Support\Carbon;
use Illuminate\Support\Facades\Auth;
use Illuminate\Support\Facades\Blade;
use Illuminate\Support\Facades\Cache;
use Illuminate\Support\Facades\DB;
use Illuminate\Support\Facades\Log;
use Illuminate\Support\Facades\Schema;
use Illuminate\Support\Facades\Storage;
use Illuminate\Support\Facades\URL;
use Illuminate\Support\Facades\View;
use Illuminate\Support\ServiceProvider;
use Laravel\Passport\Console\ClientCommand;
use Laravel\Passport\Console\InstallCommand;
use Laravel\Passport\Console\KeysCommand;
use Modules\Chat\Entities\Status;
use Modules\CourseSetting\Entities\Category;
use Modules\CourseSetting\Entities\Course;
use Modules\CourseSetting\Entities\CourseLevel;
use Modules\FrontendManage\Entities\BecomeInstructor;
use Modules\FrontendManage\Entities\HeaderMenu;
use Modules\FrontendManage\Entities\HomeContent;
use Modules\FrontendManage\Entities\WorkProcess;
use Modules\RolePermission\Entities\Permission;
use Modules\SidebarManager\Entities\PermissionSection;
use Spatie\Translatable\Facades\Translatable;
use Spatie\Valuestore\Valuestore;

class AppServiceProvider extends ServiceProvider
{
    public function register()
    {
        if (!app()->runningInConsole()) {
            $scriptFilename = realpath($_SERVER['SCRIPT_FILENAME'] ?? '') ?: '';
            $documentRoot = realpath($_SERVER['DOCUMENT_ROOT'] ?? '') ?: '';
            $assetUrl = (string) config('app.asset_url');
            $assetHost = parse_url($assetUrl, PHP_URL_HOST);
            $appHost = parse_url((string) config('app.url'), PHP_URL_HOST);

            $servedFromPublic = (strpos($scriptFilename, 'public' . DIRECTORY_SEPARATOR . 'index.php') !== false) 
                             || (str_ends_with($documentRoot, 'public'));

            if (!$servedFromPublic && ($assetUrl === '' || $assetHost === null || $assetHost === $appHost)) {
                $baseAppUrl = rtrim(config('app.url'), '/');
                config(['app.asset_url' => $baseAppUrl . '/public']);
            }
        }

        config(['google2fa.view' => theme('auth.google2fa')]);

        // Only force HTTPS when the configured app URL itself uses https.
        // This prevents forcing https on local dev where APP_ENV may be 'production'
        // but the URL is local/http (which would close connections).
        if (config('app.env') === 'production' && str_starts_with((string) config('app.url'), 'https')) {
            URL::forceScheme('https');
        }
    }

    public function boot()
    {
        Carbon::setLocale(config('app.locale'));

        // Ensure storage and bootstrap cache directories exist to avoid write errors
        try {
            $storagePaths = [
                storage_path('framework/cache/data'),
                storage_path('framework/sessions'),
                storage_path('framework/views'),
                storage_path('logs'),
                base_path('bootstrap/cache'),
            ];

            foreach ($storagePaths as $path) {
                if (!file_exists($path)) {
                    @mkdir($path, 0775, true);
                }
                @chmod($path, 0775);
            }
        } catch (\Exception $e) {
            // best-effort only; if this fails we'll rely on deploy-time fixes
            Log::warning('Could not ensure storage directories: ' . $e->getMessage());
        }

        if (isModuleActive('LmsSaas') || isModuleActive('LmsSaasMD')) {
            $domain = SaasDomain();
        } else {
            $domain = 'main';
        }
        if (isModuleActive('LmsSaasMD')) {
            if (!Storage::has('saas_db.json')) {
                $path = Storage::path('saas_db.json');
                $data = LmsInstitute::get(['db_database', 'db_username', 'db_password', 'domain']);
                $content = [];
                foreach ($data as $row) {
                    $content[$row->domain] = [
                        "DB_DATABASE" => $row->domain == 'main' ? env('DB_DATABASE') : $row->db_database,
                        "DB_USERNAME" => $row->domain == 'main' ? env('DB_USERNAME') : $row->db_username,
                        "DB_PASSWORD" => $row->domain == 'main' ? env('DB_PASSWORD') : $row->db_password,
                    ];
                }
                file_put_contents($path, json_encode($content, JSON_PRETTY_PRINT));
            }
        }


        if (empty(SaasInstitute())) {
            redirect(env('APP_URL'))->send();
        }

        session()->put('domain', $domain);

        Paginator::useBootstrap();
        $this->registerLivewireTableComponentAliases();


        if (env('FORCE_HTTPS') && !app()->isLocal() && !in_array(request()->getHost(), ['127.0.0.1', 'localhost'])) {
            URL::forceScheme('https');
            $this->app['request']->server->set('HTTPS', true);
        }

        Schema::defaultStringLength(191);
        $this->commands([
            InstallCommand::class,
            ClientCommand::class,
            KeysCommand::class,
        ]);

        try {
            // During installation routes the database may be uninitialized.
            // Skip registering view composers that query the DB to avoid HTTP 500 errors.
            if (!app()->runningInConsole() && $this->app->has('request')) {
                try {
                    $req = $this->app['request'];
                    $uri = $req->getRequestUri() ?? '';
                    if (str_starts_with($uri, '/install') || str_contains($uri, '/install')) {
                        return;
                    }
                } catch (Exception $e) {
                    // safe fallback: continue boot
                }
            }
            if (isModuleActive('Chat')) {
                $datatable = DB::connection()->getDatabaseName();
                if ($datatable) {
                    if (hasTable('chat_notifications')) {
                        view()->composer([
                            'backend.partials.menu',
                            theme('partials._dashboard_master'),
                            theme('partials._dashboard_menu'),
                            theme('pages.fullscreen_video'),
                        ], function ($view) {
                            $notifications = DB::table('chat_notifications')->where('notifiable_id', auth()->id())
                                ->where('read_at', null)
                                ->get();

                            foreach ($notifications as $notification) {
                                $notification->data = json_decode($notification->data);
                            }
                            $notifications = $notifications->sortByDesc('created_at');

                            $view->with(['notifications_for_chat' => $notifications]);
                        });
                    }

                    view()->composer('*', function ($view) {

                        $seed = session()->get('user_status_seedable');
                        if (isModuleActive('Chat') && auth()->check() && is_null($seed)) {
                            $users = User::all();
                            foreach ($users as $user) {
                                if (hasTable('chat_statuses')) {
                                    Status::firstOrCreate([
                                        'user_id' => $user->id,
                                    ], [
                                        'user_id' => $user->id,
                                        'status' => 0
                                    ]);
                                }

                            }

                            session()->put('user_status_seedable', 'false');
                        }
                    });

                    view()->composer('*', function ($view) {
                        if (auth()->check()) {
                            $this->app->singleton('extend_view', function ($app) {
                                if (auth()->user()->role_id == 3) {
                                    return theme('layouts.dashboard_master');
                                } else {
                                    return 'backend.master';
                                }
                            });
                        }
                    });

                }
            }

            if (Settings('frontend_active_theme')) {
                $this->app->singleton('topbarSetting', function () {
                    $topbarSetting = DB::table('topbar_settings')
                        ->first();
                    return $topbarSetting;
                });
            }

            View::composer([
                theme('partials._leaderboard'),
            ], function ($view) use ($domain) {
                $data =[
                  'course_levels' => CourseLevel::select('id', 'title')->where('status', 1)->get(),
                  'courses' => Course::select('id', 'title','level')->when(request()->get('level'),function ($q){
                      $q->where('level',request()->get('level'));
                  })->where('status', 1)->get(),
                  'institutes' => LmsInstitute::select('id', 'name')->where('status', 1)->get(),
                ];
                $view->with($data);

            });

            View::composer(['backend.partials.sidebar', 'backend.partials.nav',], function ($view) use ($domain) {

                $roleId = 0;
                if (Auth::check()) {
                    $roleId = Auth::user()->role_id;
                }

                if (Auth::check() && $roleId == 2) {
                    $data['sections'] = Cache::rememberForever('SidebarPermissionList_2' . $domain, function () use ($domain) {
                        try {
                            $config = Settings('educator_sidebar_config');
                            if ($config) {
                                $config = json_decode($config, true);
                            }

                            if ($config) {
                                $allowedIds = DB::table('role_permission')
                                    ->where('role_id', 2)
                                    ->where('status', 1)
                                    ->pluck('permission_id')
                                    ->toArray();

                                $all_menus = Permission::whereIn('id', $allowedIds)
                                    ->where('type', '!=', 3)
                                    ->where('backend', 1)
                                    ->get();

                                foreach ($all_menus as $menu) {
                                    if (isset($config['menu_positions'][$menu->id])) {
                                        $menu->position = $config['menu_positions'][$menu->id];
                                    }
                                    if (isset($config['menu_statuses'][$menu->id])) {
                                        $menu->menu_status = $config['menu_statuses'][$menu->id];
                                    }
                                    if (isset($config['menu_sections'][$menu->id])) {
                                        $menu->section_id = $config['menu_sections'][$menu->id];
                                    }
                                    if (isset($config['menu_parent_routes'][$menu->id])) {
                                        $menu->parent_route = $config['menu_parent_routes'][$menu->id];
                                    }
                                    if (isset($config['menu_types'][$menu->id])) {
                                        $menu->type = $config['menu_types'][$menu->id];
                                    }
                                }

                                $sections = PermissionSection::all()->map(function ($section) use ($all_menus, $config) {
                                    if (isset($config['section_positions'][$section->id])) {
                                        $section->position = $config['section_positions'][$section->id];
                                    }

                                    $sectionPermissions = $all_menus->where('section_id', $section->id);
                                    $sortedPermissions = $sectionPermissions->sortBy('position');

                                    $activeMenus = $sortedPermissions->where('type', 1)->where('menu_status', 1);
                                    $activeSubmenus = $sortedPermissions->where('type', 2)->where('menu_status', 1);

                                    $section->setRelation('permissions', $sortedPermissions);
                                    $section->setRelation('activeMenus', $activeMenus);
                                    $section->setRelation('activeSubmenus', $activeSubmenus);

                                    return $section;
                                })->sortBy('position');

                                return $sections;
                            }
                        } catch (Exception $e) {
                            // best effort fallback to default educator loading
                        }

                        try {
                            if (hasTable('permission_sections')) {
                                $query = PermissionSection::query();
                                if (!showEcommerce()) {
                                    $query->where('ecommerce', '!=', 1);
                                }
                                return $query->with('activeMenus.childs', 'activeSubmenus.childs', 'permissions', 'activeMenus', 'activeSubmenus')->orderBy('position')->get();
                            }
                        } catch (Exception $e) {
                            return [];
                        }

                        return [];
                    });
                } else {
                    $data['sections'] = Cache::rememberForever('SidebarPermissionList_Global_' . $domain, function () use ($domain) {
                        try {
                            $check = Permission::whereColumn('route', 'parent_route')->get();
                            if (count($check) > 0) {
                                foreach ($check as $c) {
                                    $c->parent_route = null;
                                    $c->save();
                                }
                            }
                            if (hasTable('permission_sections')) {

                                $query = PermissionSection::query();
                                if (!showEcommerce()) {
                                    $query->where('ecommerce', '!=', 1);
                                }
                                return $query->with('activeMenus.childs', 'activeSubmenus.childs', 'permissions', 'activeMenus', 'activeSubmenus')->orderBy('position')->get();

                            } else {
                                return [];
                            }
                        } catch (Exception $e) {
                            return [];
                        }
                    });
                }

                $view->with($data);
            });

            View::composer([
                theme('partials._dashboard_menu'),
                theme('pages.fullscreen_video'),
                theme('pages.index'),
                theme('pages.courses'),
                theme('pages.free_courses'),
                theme('partials._menu'),
                theme('pages.quizzes'),
                theme('pages.classes'),
                theme('pages.search'),
                theme('components.headernavbar'),
                theme('components.we-tech-dashboard-page-section'),
                theme('layouts.dashboard_master'),
                theme('components.home-page-course-section')
            ], function ($view) use ($domain) {

                $data['categories'] = Cache::rememberForever('categories_' . app()->getLocale() . $domain, function () {
                    return Category::select('id', 'name', 'title', 'description', 'image', 'thumbnail', 'parent_id')
                        ->where('status', 1)
                        ->whereNull('parent_id')
                        ->withCount('courses')
                        ->orderBy('position_order', 'ASC')->with('activeSubcategories', 'childs', 'subcategories')
                        ->get();
                });


                $data['languages'] = Cache::rememberForever('languages_' . app()->getLocale() . $domain, function () {
                    if (isModuleActive('LmsSaasMD')) {
                        return DB::connection('mysql')->table('languages')->select('id', 'name', 'code', 'rtl', 'status', 'native')
                            ->where('status', 1)
                            ->get();
                    } else {
                        return DB::table('languages')->select('id', 'name', 'code', 'rtl', 'status', 'native')
                            ->where('status', 1)
                            ->where('lms_id', SaasInstitute()->id)
                            ->get();
                    }

                });
                $data['menus'] = Cache::rememberForever('menus_' . app()->getLocale() . $domain, function () {
                    try {
                        return HeaderMenu::orderBy('position', 'asc')
                            ->select('id', 'type', 'element_id', 'title', 'link', 'parent_id', 'position', 'show', 'is_newtab', 'mega_menu', 'mega_menu_column')
                            ->with('childs', 'childs.childs')
                            ->get();
                    } catch (Exception $e) {
                        return collect();
                    }
                });
                $view->with($data);
            });
            View::composer([
                'frontend.*',
                'frontend.infixlmstheme.components.breadcrumb',
                'gift::*'
            ], function ($view) {

                $selectedHeader =(int)Settings('header_style');
                $selectedFooter =(int)Settings('footer_style');
                if (!$selectedFooter){
                    $selectedFooter=1;
                }
                if (!$selectedHeader){
                    $selectedHeader=1;
                }
                $data['header_style'] = $selectedHeader;
                $data['footer_style'] = $selectedFooter;

                $data['frontendContent'] = $data['homeContent'] = (object)$this->homeContents();
                $data['about_page'] = AboutPage::getData();
                $data['become_instructor'] = BecomeInstructor::getData();
                $data['work_progress'] = WorkProcess::getData();
                $view->with($data);
            });


        } catch (Exception $e) {
            Log::info($e->getMessage());
        }

        Builder::macro('whereLike', function (string $column, string $search) {
            $like = 'LIKE';
            if (config('database.default') == 'pgsql') {
                $like = 'ILIKE';
            }
            return $this->where($column, $like, '%' . $search . '%');
        });


        Translatable::fallback(
            fallbackAny: true,
        );

        $this->bootGoogleDriveSocialite();

    }

    private function registerLivewireTableComponentAliases(): void
    {
        Blade::component('livewire-tables::tailwind.components.table.table', 'livewire-tables::table');

        foreach (['row', 'cell', 'heading', 'footer'] as $component) {
            Blade::component(
                "livewire-tables::tailwind.components.table.{$component}",
                "livewire-tables::table.{$component}"
            );
        }

        foreach (['bs4' => 'bootstrap-4', 'bs5' => 'bootstrap-5'] as $alias => $theme) {
            Blade::component(
                "livewire-tables::{$theme}.components.table.table",
                "livewire-tables::{$alias}.table"
            );

            foreach (['table', 'row', 'cell', 'heading', 'footer'] as $component) {
                Blade::component(
                    "livewire-tables::{$theme}.components.table.{$component}",
                    "livewire-tables::{$alias}.table.{$component}"
                );
            }
        }
    }

    private function homeContents()
    {
        if (function_exists('SaasDomain')) {
            $domain = SaasDomain();
        } else {
            $domain = 'main';
        }
        return Cache::rememberForever('homeContents_' . app()->getLocale() . $domain, function () {
            if (\Illuminate\Support\Facades\Schema::hasColumn('home_contents', 'key')) {
                return \Modules\FrontendManage\Entities\HomeContent::select(['key', 'value'])->get()->pluck('value', 'key')->toArray();
            }
            return [];
        });
    }

    private function bootGoogleDriveSocialite()
    {
        $socialite = $this->app->make('Laravel\Socialite\Contracts\Factory');
        $socialite->extend(
            'google-drive',
            function ($app) use ($socialite) {
                $config = $app['config']['services.google-drive'];
                return $socialite->buildProvider(GoogleDriveProvider::class, $config);
            }
        );
    }
}
