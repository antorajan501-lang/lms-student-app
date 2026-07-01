import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/user_model.dart';
import '../../repositories/profile_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_widget.dart';

class ProfileEditScreen extends ConsumerStatefulWidget {
  const ProfileEditScreen({super.key});

  @override
  ConsumerState<ProfileEditScreen> createState() => _ProfileEditScreenState();
}

class _ProfileEditScreenState extends ConsumerState<ProfileEditScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _aboutCtrl = TextEditingController();
  final _jobTitleCtrl = TextEditingController();
  bool _isLoading = false;

  void _populateForm(UserModel user) {
    _nameCtrl.text = user.name;
    _aboutCtrl.text = user.about ?? '';
    _jobTitleCtrl.text = user.jobTitle ?? '';
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _aboutCtrl.dispose();
    _jobTitleCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final repo = ref.read(profileRepositoryProvider);

      // Single API call updates name, job_title, and about_me at once
      final updatedUser = await repo.updateBasicInfo(
        name: _nameCtrl.text.trim(),
        jobTitle: _jobTitleCtrl.text.trim(),
        aboutMe: _aboutCtrl.text.trim(),
      );

      // Sync the updated user profile into AuthState and SecureStorage
      ref.read(authProvider.notifier).updateUser(updatedUser);

      // Invalidate cache so profile page and edit page refresh automatically
      ref.invalidate(profileProvider);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Profile updated successfully!'),
            backgroundColor: AppColors.success,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.pop();
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Edit Profile'),
        leading: IconButton(
          icon: const Icon(Icons.close_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: profileAsync.when(
        data: (user) {
          // Populate once
          if (_nameCtrl.text.isEmpty) _populateForm(user);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Form(
              key: _formKey,
              child: Column(
                children: [

                  // User icon header (no profile photo)
                  Center(
                    child: Container(
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(color: AppColors.primary, width: 2),
                      ),
                      child: CircleAvatar(
                        radius: 48,
                        backgroundColor: AppColors.primary.withOpacity(0.10),
                        child: const Icon(
                          Icons.person_rounded,
                          size: 52,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user.name,
                    style: GoogleFonts.inter(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  Text(
                    user.email,
                    style: GoogleFonts.inter(
                      fontSize: 13,
                      color: AppColors.grey500,
                    ),
                  ),
                  const SizedBox(height: AppSizes.xl),

                  AppTextField(
                    label: 'Full Name',
                    controller: _nameCtrl,
                    prefixIcon: const Icon(Icons.person_outline_rounded, size: AppSizes.iconMd),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Name is required' : null,
                  ),
                  const SizedBox(height: AppSizes.md),

                  AppTextField(
                    label: 'Job Title',
                    controller: _jobTitleCtrl,
                    prefixIcon: const Icon(Icons.work_outline_rounded, size: AppSizes.iconMd),
                    validator: (v) => null,
                  ),
                  const SizedBox(height: AppSizes.md),

                  AppTextField(
                    label: 'About Me',
                    controller: _aboutCtrl,
                    maxLines: 4,
                    prefixIcon: const Icon(Icons.info_outline_rounded, size: AppSizes.iconMd),
                    validator: (v) => null,
                  ),
                  const SizedBox(height: AppSizes.xl),

                  AppButton(
                    label: 'Save Changes',
                    isLoading: _isLoading,
                    onPressed: _isLoading ? null : _save,
                  ),
                ],
              ),
            ),
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(message: e.toString()),
      ),
    );
  }
}
