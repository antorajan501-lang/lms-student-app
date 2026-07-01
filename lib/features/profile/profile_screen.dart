import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/routes/route_names.dart';
import '../../models/user_model.dart';
import '../../repositories/profile_repository.dart';
import '../../providers/auth_provider.dart';
import '../../providers/profile_provider.dart';
import '../../widgets/error_widget.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final profileAsync = ref.watch(profileProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Profile'),
      ),
      body: profileAsync.when(
        data: (user) => SingleChildScrollView(
          child: Column(
            children: [
              // Premium Modern Profile Card Header
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppSizes.screenPadding,
                  vertical: AppSizes.md,
                ),
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(AppSizes.cardRadius * 1.5),
                    border: Border.all(
                      color: Theme.of(context).dividerColor,
                    ),
                    gradient: LinearGradient(
                      colors: Theme.of(context).brightness == Brightness.dark
                          ? [
                              Theme.of(context).colorScheme.surface,
                              Theme.of(context).colorScheme.surface.withOpacity(0.8),
                            ]
                          : [
                              Colors.white,
                              AppColors.primary.withOpacity(0.03),
                            ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  padding: const EdgeInsets.all(AppSizes.lg),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Container(
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: AppColors.primary,
                                width: 2,
                              ),
                            ),
                            child: CircleAvatar(
                              radius: 36,
                              backgroundColor: AppColors.primary.withOpacity(0.12),
                              child: const Icon(
                                Icons.person_rounded,
                                size: 38,
                                color: AppColors.primary,
                              ),
                            ),
                          ),
                          const SizedBox(width: AppSizes.md),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  user.name,
                                  style: GoogleFonts.inter(
                                    fontSize: AppSizes.textLg,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  user.email,
                                  style: GoogleFonts.inter(
                                    color: AppColors.grey500,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: AppSizes.md),
                      const Divider(height: 1),
                      const SizedBox(height: AppSizes.md),
                      OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 36),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                          ),
                          side: BorderSide(
                            color: AppColors.primary.withOpacity(0.4),
                          ),
                        ),
                        onPressed: () => context.push(AppRoutes.profileEdit),
                        icon: const Icon(Icons.edit_rounded, size: 14, color: AppColors.primary),
                        label: Text(
                          'Edit Profile',
                          style: GoogleFonts.inter(
                            fontSize: 12,
                            fontWeight: FontWeight.w700,
                            color: AppColors.primary,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Menu items in requested order
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                child: Column(
                  children: [
                    _MenuItem(
                      icon: Icons.school_outlined,
                      label: 'My Enrolled Courses',
                      onTap: () => context.push(AppRoutes.myCourses),
                    ),
                    _MenuItem(
                      icon: Icons.favorite_border_rounded,
                      label: 'Wishlist',
                      onTap: () => context.push(AppRoutes.wishlist),
                    ),
                    _MenuItem(
                      icon: Icons.notifications_outlined,
                      label: 'Notifications',
                      onTap: () => context.push(AppRoutes.notifications),
                    ),
                    _MenuItem(
                      icon: Icons.workspace_premium_outlined,
                      label: 'My Certificates',
                      onTap: () => context.push(AppRoutes.certificates),
                    ),
                    _MenuItem(
                      icon: Icons.receipt_long_outlined,
                      label: 'Purchase History',
                      onTap: () => context.push(AppRoutes.purchaseHistory),
                    ),
                    _MenuItem(
                      icon: Icons.devices_outlined,
                      label: 'Logged In Devices',
                      onTap: () => context.push(AppRoutes.loggedDevices),
                    ),
                    _MenuItem(
                      icon: Icons.help_outline_rounded,
                      label: 'Help & Support',
                      onTap: () {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Help & Support center is coming soon!'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      },
                    ),
                    _MenuItem(
                      icon: Icons.settings_outlined,
                      label: 'Settings',
                      onTap: () => context.push(AppRoutes.settings),
                    ),
                    const Divider(height: AppSizes.xl),
                    _MenuItem(
                      icon: Icons.logout_rounded,
                      label: 'Logout',
                      color: AppColors.error,
                      onTap: () async {
                        await ref.read(authProvider.notifier).logout();
                        if (context.mounted) context.go(AppRoutes.login);
                      },
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(profileProvider),
        ),
      ),
    );
  }
}

class _MenuItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? color;

  const _MenuItem({
    required this.icon,
    required this.label,
    required this.onTap,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveColor = color ?? Theme.of(context).colorScheme.onSurface;

    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: (color ?? AppColors.primary).withOpacity(0.1),
          borderRadius: BorderRadius.circular(AppSizes.radiusMd),
        ),
        child: Icon(icon, color: color ?? AppColors.primary, size: AppSizes.iconMd),
      ),
      title: Text(
        label,
        style: GoogleFonts.inter(
          fontWeight: FontWeight.w600,
          fontSize: AppSizes.textMd,
          color: effectiveColor,
        ),
      ),
      trailing: Icon(Icons.chevron_right_rounded, color: AppColors.grey400),
      onTap: onTap,
    );
  }
}
