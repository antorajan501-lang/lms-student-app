# LMS Student App — Laravel Backend Reference

This folder contains **only the Laravel backend components required for the Student Mobile App**.
It is a reference copy extracted from `LMSTekQuoraClevera-main`.
The Flutter app communicates with the actual Laravel project via REST API.

---

## What Is Included

### 1. API Routes
- `routes/api2.php` — All V2 REST API routes

### 2. Controllers (app/Http/Controllers/Api/V2/)
| File | Key Methods |
|---|---|
| AuthController.php | login, signup, logout, userDetail, changePassword, sendOtp, verifyEmail, resetWithOtp |
| StudentDashboardController.php | dashboard, courseProgress |
| StudentWishlistController.php | index, toggle |
| UserNotificationController.php | notificationList, markAllRead |
| Course/CourseController.php | courses, detail, categories, search |
| Course/ChapterController.php | chapters |
| Course/LessonController.php | lessons, lessonDetail, lessonComplete |
| Quiz/QuizController.php | quizStart, quizSubmit, quizResult |
| User/BasicInformationController.php | basicInfoUpdate |
| GeneralSetting/GeneralSettingController.php | default settings |

### 3. Repositories — All DB Query Logic
| File | Queries |
|---|---|
| Eloquents/BaseRepository.php | Generic CRUD |
| Eloquents/AuthRepository.php | Login, OTP, token management |
| Eloquents/AuthUserRepository.php | Profile fetch/update |
| Eloquents/CourseRepository.php | Course list, detail, my-courses, search, certificates |
| Eloquents/ChapterRepository.php | Chapter list per course |
| Eloquents/LessonRepository.php | Lesson list, detail, completion tracking |
| Eloquents/QuizRepository.php | Quiz start, answer save, grading |
| Eloquents/UserNotificationRepository.php | Notification list, mark-read |
| Eloquents/GeneralSettingsRepository.php | App settings |
| Eloquents/LanguageRepository.php | Language list/switch |
| MyEnrollmentRepository.php | Enrolled courses + progress |

### 4. API Resources / JSON Transformers (app/Http/Resources/api/v2/)
Auth, Category, Certificate, Chapter, Course, Lesson, Notification, Quize, GeneralSettings, User, Student

### 5. Eloquent Models
User, LessonComplete, Course, Chapter, Lesson, CourseEnrolled, Category,
OnlineQuiz, QuestionBank, QuizTest, QuizTestDetails, Certificate, CertificateRecord

### 6. Database
- Core migrations: users, OAuth tables, lesson_completes, notifications
- CourseSetting module: 50 migrations + 13 seeders
- Quiz module: 38 migrations + 7 seeders
- Certificate module: 9 migrations + 1 seeder

### 7. Supporting Files
- `app/Traits/` — ImageStore, SendNotification, Tenantable, Filepond, etc.
- `app/Helpers/` — Helper.php, SaasHelper.php, Constant.php, helper1-5.php
- `app/Providers/` — RepositoryServiceProvider, AppServiceProvider, RouteServiceProvider

---

## Flutter to Laravel API Quick Reference

| Flutter Screen | HTTP | Endpoint | Repository |
|---|---|---|---|
| Splash | GET | /api/settings | GeneralSettingsRepository |
| Login | POST | /api/login | AuthRepository::login |
| Register | POST | /api/register | AuthRepository::signup |
| Forgot Password | POST | /api/forgot-password | AuthRepository::sendOtp |
| Verify OTP | POST | /api/verify-email | AuthRepository::verifyEmail |
| Reset Password | POST | /api/reset-otp-password | AuthRepository::resetWithOtp |
| Dashboard | GET | /api/student/dashboard | StudentDashboardController |
| My Courses | GET | /api/my-courses | CourseRepository::myCourses |
| Course Detail | GET | /api/course-detail?course_id=X | CourseRepository::courseDetail |
| Chapters | GET | /api/course-chapters?course_id=X | ChapterRepository::chapters |
| Lessons | GET | /api/lessons?chapter_id=X | LessonRepository::lessons |
| Complete Lesson | ANY | /api/lesson-complete | LessonRepository::lessonComplete |
| Quiz Start | POST | /api/quiz-start/{c}/{q} | QuizRepository::quizStart |
| Quiz Submit | POST | /api/quiz-final-submit | QuizRepository::quizSubmit |
| Quiz Result | POST | /api/quiz-result/{c}/{q} | QuizRepository::quizResult |
| Certificates | GET | /api/certificate-records | CourseRepository::certificateList |
| Notifications | GET | /api/notifications | UserNotificationRepository::list |
| Mark All Read | ANY | /api/NotificationMakeAllRead | UserNotificationRepository::markAllRead |
| Search | GET | /api/search-course?search=X | CourseRepository::courses |
| Profile | GET | /api/user-detail | AuthRepository::userDetail |
| Edit Profile | POST | /api/user-update-basicinfo | AuthUserRepository::basicInfoUpdate |
| Wishlist | GET | /api/wishlist | StudentWishlistController::index |
| Wishlist Toggle | POST | /api/wishlist/toggle | StudentWishlistController::toggle |
| Logout | ANY | /api/logout | AuthRepository::logout |
