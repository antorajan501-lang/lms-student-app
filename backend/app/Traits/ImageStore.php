<?php

namespace App\Traits;

use Brian2694\Toastr\Facades\Toastr;
use Carbon\Carbon;
use Illuminate\Http\UploadedFile;
use Illuminate\Support\Facades\File;
use Illuminate\Support\Facades\Log;
use Intervention\Image\Decoders\SplFileInfoImageDecoder;
use Intervention\Image\Drivers\Gd\Driver;
use Intervention\Image\ImageManager;
use Symfony\Component\Finder\SplFileInfo;
use Throwable;

trait ImageStore
{

    public function saveImage($image, $height = null, $width = null)
    {
        if (config('app.demo_mode')) {
            Toastr::warning('For Demo mode, some features are disabled');
            return 'assets/course/no_image.png';
        }

        if (!isset($image)) {
            return null;
        }

        try {
            $domain = SaasDomain();
            $current_date = Carbon::now()->format('d-m-Y');
            $upload_path = 'uploads/' . $domain . '/images/' . $current_date;

            // Ensure the directory exists
            File::ensureDirectoryExists(public_path($upload_path));

            // Save the image
            return $this->handleImageUpload($image, $upload_path, $height, $width);
        } catch (Throwable $e) {
            Log::error('Image saving failed: ' . $e->getMessage());
            return null;
        }
    }
    private function handleImageUpload($image, $upload_path, $height, $width)
    {
        $manager = $this->makeImageManager();
        $extension = $image->extension();
        $fileName = uniqid();

        if ($extension === 'svg') {
            // Handle SVG images
            $img_name = $upload_path . '/' . $fileName . '.' . $extension;
            $image->move(public_path($upload_path), $fileName . '.' . $extension);
        } else {
            if (!$manager) {
                $img_name = $upload_path . '/' . $fileName . '.' . $extension;
                $image->move(public_path($upload_path), $fileName . '.' . $extension);
                return $img_name;
            }

            $source = $image instanceof UploadedFile ? $image->getRealPath() : $image;
            $img = self::readManagedImage($manager, $source);
            // Resize image if dimensions are specified
            if ($height && $width) {
                $img = self::resizeManagedImage($img, $width, $height);
            }

            // Save the image with a unique filename
            $img_name = $upload_path . '/' . $fileName . '.' . $extension;
                $img->save(public_path($img_name));
        }

        return $img_name;
    }


    public function deleteImage($url)
    {
        if (isset($url)) {
            if (File::exists($url)) {
                File::delete($url);
                return true;
            } else {
                return false;
            }
        } else {
            return null;
        }
    }

    public function saveAvatar($image, $height = null, $lenght = null)
    {
        $manager = $this->makeImageManager();

        if (isset($image)) {

            $current_date = Carbon::now()->format('d-m-Y');

            if (!File::isDirectory('uploads/avatar/' . $current_date)) {

                File::makeDirectory('uploads/avatar/' . $current_date, 0777, true, true);

            }

            $image_extention = 'png';

            if (!$manager) {
                $img_name = 'uploads/avatar/' . $current_date . '/' . uniqid() . '.' . $image_extention;
                if ($image instanceof UploadedFile) {
                    $image->move(public_path('uploads/avatar/' . $current_date), basename($img_name));
                    return $img_name;
                }

                return null;
            }

            $source = $image instanceof UploadedFile ? $image->getRealPath() : $image;
            $img = self::readManagedImage($manager, $source);
            if ($height != null && $lenght != null) {
                $img = self::resizeManagedImage($img, $height, $lenght);
            }

            $img_name = 'uploads/avatar/' . $current_date . '/' . uniqid() . '.' . $image_extention;
            $img->save(public_path($img_name));

            return $img_name;

        } else {

            return null;
        }

    }

    public static function saveImageStatic($image, $height = null, $lenght = null)
    {
        $manager = self::makeImageManager();
        if (isset($image)) {
            $current_date = Carbon::now()->format('d-m-Y');

            if (!File::isDirectory('uploads/images/' . $current_date)) {
                File::makeDirectory('uploads/images/' . $current_date, 0777, true, true);
            }

            $image_extention = 'png';

            if (!$manager) {
                $img_name = 'uploads/images/' . $current_date . '/' . uniqid() . '.' . $image_extention;
                if ($image instanceof UploadedFile) {
                    $image->move(public_path('uploads/images/' . $current_date), basename($img_name));
                    return $img_name;
                }

                return null;
            }

            $source = $image instanceof UploadedFile ? $image->getRealPath() : $image;
            $img = self::readManagedImage($manager, $source);
            if ($height != null && $lenght != null) {
                $img = self::resizeManagedImage($img, $height, $lenght);
            }

            $img_name = 'uploads/images/' . $current_date . '/' . uniqid() . '.' . $image_extention;
            $img->save(public_path($img_name));
            return $img_name;
        } else {
            return null;
        }
    }

    public function saveFile(UploadedFile $file)
    {
        if (isset($file)) {
            $igonreFiles = ['php'];
            if (in_array($file->clientExtension(), $igonreFiles)) {
                return null;
            }
            $current_date = Carbon::now()->format('d-m-Y');
            $path = 'public/uploads/file/' . $current_date;
            if (!File::isDirectory($path)) {
                File::makeDirectory($path, 0777, true, true);
            }
            $fileName1 = md5(rand(0, 9999) . '_' . time()) . '.' . $file->clientExtension();
            $file_name = $path . '/' . $fileName1;
            $file->move(public_path(str_replace('public/', '', $path)), $fileName1);
            return $file_name;
        } else {
            return null;
        }
    }

    private static function makeImageManager()
    {
        try {
            if (class_exists(Driver::class)) {
                return new ImageManager(new Driver());
            }

            return new ImageManager(['driver' => 'gd']);
        } catch (Throwable $e) {
            Log::warning('Intervention Image manager fallback failed: ' . $e->getMessage());
            return null;
        }
    }

    private static function readManagedImage($manager, $source)
    {
        if (method_exists($manager, 'read')) {
            return $manager->read($source);
        }

        return $manager->make($source);
    }

    private static function resizeManagedImage($image, $width, $height)
    {
        if (method_exists($image, 'scaleDown')) {
            return $image->scaleDown((int)$width, (int)$height);
        }

        return $image->resize($width, $height, function ($constraint) {
            $constraint->aspectRatio();
            $constraint->upsize();
        });
    }

}
