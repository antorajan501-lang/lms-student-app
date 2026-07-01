import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../providers/auth_provider.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  final String email;
  final String otp;

  const ResetPasswordScreen({super.key, required this.email, required this.otp});

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();

  @override
  void dispose() {
    _passwordCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  Future<void> _reset() async {
    if (!_formKey.currentState!.validate()) return;
    final success = await ref.read(authProvider.notifier).resetPassword(
          email: widget.email,
          otp: widget.otp,
          password: _passwordCtrl.text,
          confirmPassword: _confirmCtrl.text,
        );
    if (success && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Password reset successfully! Please sign in.'),
          backgroundColor: AppColors.success,
        ),
      );
      context.go(AppRoutes.login);
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('New Password'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: () => context.pop(),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(AppSizes.screenPadding),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: AppSizes.xl),
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: AppColors.success.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.lock_open_rounded, size: 36, color: AppColors.success),
              ),
              const SizedBox(height: AppSizes.xl),
              Text(
                'Create new password',
                style: GoogleFonts.inter(fontSize: 24, fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 8),
              Text(
                'Your new password must be at least 8 characters.',
                style: GoogleFonts.inter(fontSize: AppSizes.textMd, color: AppColors.grey500),
              ),
              const SizedBox(height: AppSizes.xxl),

              if (authState.errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(AppSizes.md),
                  decoration: BoxDecoration(
                    color: AppColors.error.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                  ),
                  child: Text(
                    authState.errorMessage!,
                    style: GoogleFonts.inter(color: AppColors.error),
                  ),
                ),
                const SizedBox(height: AppSizes.lg),
              ],

              AppTextField(
                label: 'New Password',
                controller: _passwordCtrl,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: AppSizes.iconMd),
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Password is required';
                  if (v.length < 8) return 'Must be at least 8 characters';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.md),

              AppTextField(
                label: 'Confirm New Password',
                controller: _confirmCtrl,
                obscureText: true,
                prefixIcon: const Icon(Icons.lock_outline_rounded, size: AppSizes.iconMd),
                textInputAction: TextInputAction.done,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Please confirm password';
                  if (v != _passwordCtrl.text) return 'Passwords do not match';
                  return null;
                },
              ),
              const SizedBox(height: AppSizes.xl),

              AppButton(
                label: 'Reset Password',
                isLoading: authState.isLoading,
                onPressed: authState.isLoading ? null : _reset,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
