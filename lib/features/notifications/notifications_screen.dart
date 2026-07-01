import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/notification_model.dart';
import '../../repositories/notification_repository.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/shimmer_loader.dart';

final _notificationsProvider = FutureProvider<List<NotificationModel>>((ref) async {
  final repo = ref.watch(notificationRepositoryProvider);
  return repo.getNotifications();
});

class NotificationsScreen extends ConsumerWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationsAsync = ref.watch(_notificationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton(
            onPressed: () async {
              final repo = ref.read(notificationRepositoryProvider);
              await repo.markAllRead();
              ref.invalidate(_notificationsProvider);
            },
            child: Text(
              'Mark all read',
              style: GoogleFonts.inter(
                color: AppColors.primary,
                fontWeight: FontWeight.w600,
                fontSize: AppSizes.textSm,
              ),
            ),
          ),
        ],
      ),
      body: notificationsAsync.when(
        data: (notifications) {
          if (notifications.isEmpty) {
            return const EmptyStateWidget(
              title: 'No notifications',
              subtitle: 'You\'re all caught up!',
              icon: Icons.notifications_none_rounded,
            );
          }
          return RefreshIndicator(
            onRefresh: () async => ref.invalidate(_notificationsProvider),
            child: ListView.separated(
              padding: const EdgeInsets.all(AppSizes.screenPadding),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, i) => _NotificationTile(notification: notifications[i]),
            ),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          itemCount: 6,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.md),
            child: ListTileShimmer(),
          ),
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(_notificationsProvider),
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final NotificationModel notification;

  const _NotificationTile({required this.notification});

  @override
  Widget build(BuildContext context) {
    final isRead = notification.isRead ?? false;

    return ListTile(
      contentPadding: const EdgeInsets.symmetric(vertical: AppSizes.sm),
      leading: Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: AppColors.primary.withOpacity(isRead ? 0.05 : 0.12),
          shape: BoxShape.circle,
        ),
        child: Icon(
          Icons.notifications_rounded,
          color: AppColors.primary.withOpacity(isRead ? 0.5 : 1),
          size: AppSizes.iconMd,
        ),
      ),
      title: Text(
        notification.title ?? '',
        style: GoogleFonts.inter(
          fontWeight: isRead ? FontWeight.w500 : FontWeight.w700,
          fontSize: AppSizes.textMd,
        ),
      ),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (notification.message != null)
            Text(
              notification.message!,
              style: GoogleFonts.inter(
                fontSize: AppSizes.textSm,
                color: AppColors.grey500,
              ),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          if (notification.createdAt != null)
            Text(
              notification.createdAt!.length > 10
                  ? notification.createdAt!.substring(0, 10)
                  : notification.createdAt!,
              style: GoogleFonts.inter(
                fontSize: 11,
                color: AppColors.grey400,
              ),
            ),
        ],
      ),
      trailing: !isRead
          ? Container(
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: AppColors.primary,
                shape: BoxShape.circle,
              ),
            )
          : null,
    );
  }
}
