import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../widgets/app_button.dart';
import '../../widgets/app_text_field.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/shimmer_loader.dart';

final loggedDevicesProvider = FutureProvider<List<DeviceRecord>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.loggedDevices);
  final responseData = response.data;
  if (responseData['success'] == true) {
    final List list = responseData['data'] ?? [];
    return list.map((x) => DeviceRecord.fromJson(x as Map<String, dynamic>)).toList();
  }
  return [];
});

class DevicesScreen extends ConsumerStatefulWidget {
  const DevicesScreen({super.key});

  @override
  ConsumerState<DevicesScreen> createState() => _DevicesScreenState();
}

class _DevicesScreenState extends ConsumerState<DevicesScreen> {
  final _passwordCtrl = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;

  @override
  void dispose() {
    _passwordCtrl.dispose();
    super.dispose();
  }

  void _showLogoutConfirmation(DeviceRecord device) {
    _passwordCtrl.clear();
    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
              title: const Text('Log Out Device'),
              content: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Are you sure you want to log out from this device?\n\n'
                      'Device: ${device.device} (${device.os})\n'
                      'Location: ${device.ip}\n',
                      style: GoogleFonts.inter(fontSize: 13, color: AppColors.grey600),
                    ),
                    const SizedBox(height: AppSizes.md),
                    AppTextField(
                      label: 'Confirm Password',
                      controller: _passwordCtrl,
                      obscureText: true,
                      prefixIcon: const Icon(Icons.lock_outline_rounded, size: 20),
                      validator: (v) => (v == null || v.isEmpty) ? 'Password is required' : null,
                    ),
                  ],
                ),
              ),
              actions: [
                TextButton(
                  onPressed: _isLoading ? null : () => Navigator.pop(context),
                  child: const Text('Cancel'),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.error,
                    foregroundColor: Colors.white,
                  ),
                  onPressed: _isLoading
                      ? null
                      : () async {
                          if (!_formKey.currentState!.validate()) return;
                          setDialogState(() => _isLoading = true);
                          try {
                            final client = ref.read(apiClientProvider);
                            final response = await client.post(
                              ApiEndpoints.logoutDevice,
                              data: {
                                'password': _passwordCtrl.text,
                                'type': 'logout',
                                'id': device.id,
                              },
                            );
                            if (response.data['success'] == true) {
                              if (mounted) {
                                Navigator.pop(context);
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                    content: Text('Device logged out successfully!'),
                                    backgroundColor: AppColors.success,
                                    behavior: SnackBarBehavior.floating,
                                  ),
                                );
                                ref.invalidate(loggedDevicesProvider);
                              }
                            } else {
                              if (mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(response.data['message'] ?? 'Failed to log out device'),
                                    backgroundColor: AppColors.error,
                                  ),
                                );
                              }
                            }
                          } catch (e) {
                            if (mounted) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Error: $e'), backgroundColor: AppColors.error),
                              );
                            }
                          } finally {
                            setDialogState(() => _isLoading = false);
                          }
                        },
                  child: _isLoading
                      ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Confirm Logout'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final devicesAsync = ref.watch(loggedDevicesProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Logged In Devices'),
      ),
      body: devicesAsync.when(
        data: (devices) {
          if (devices.isEmpty) {
            return const Center(
              child: Text(
                'No active devices found.',
                style: TextStyle(color: AppColors.grey500),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            itemCount: devices.length,
            itemBuilder: (context, index) {
              final dev = devices[index];

              // Guess current device (e.g. status == 1 or check IP)
              final isCurrent = index == 0; // The first device returned is typically current

              IconData platformIcon;
              switch (dev.os.toLowerCase()) {
                case 'windows':
                  platformIcon = Icons.laptop_windows_rounded;
                  break;
                case 'android':
                case 'ios':
                  platformIcon = Icons.phone_android_rounded;
                  break;
                default:
                  platformIcon = Icons.devices_other_rounded;
              }

              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(AppSizes.md),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(AppSizes.sm),
                        decoration: BoxDecoration(
                          color: AppColors.primary.withOpacity(0.08),
                          shape: BoxShape.circle,
                        ),
                        child: Icon(platformIcon, color: AppColors.primary, size: 24),
                      ),
                      const SizedBox(width: AppSizes.md),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Text(
                                  dev.device,
                                  style: GoogleFonts.inter(fontWeight: FontWeight.w700, fontSize: AppSizes.textMd),
                                ),
                                if (isCurrent) ...[
                                  const SizedBox(width: 8),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: AppColors.success.withOpacity(0.1),
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                    child: const Text(
                                      'Current',
                                      style: TextStyle(color: AppColors.success, fontSize: 9, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'IP: ${dev.ip} • Browser: ${dev.browser}',
                              style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey500),
                            ),
                            Text(
                              'Login: ${dev.formattedLoginTime}',
                              style: GoogleFonts.inter(fontSize: 11, color: AppColors.grey400),
                            ),
                          ],
                        ),
                      ),
                      if (!isCurrent)
                        IconButton(
                          icon: const Icon(Icons.logout_rounded, color: AppColors.error),
                          onPressed: () => _showLogoutConfirmation(dev),
                        ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          itemCount: 3,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.sm),
            child: ShimmerLoader(height: 80),
          ),
        ),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(loggedDevicesProvider),
        ),
      ),
    );
  }
}

class DeviceRecord {
  final int id;
  final String device;
  final String os;
  final String browser;
  final String ip;
  final DateTime loginAt;

  DeviceRecord({
    required this.id,
    required this.device,
    required this.os,
    required this.browser,
    required this.ip,
    required this.loginAt,
  });

  factory DeviceRecord.fromJson(Map<String, dynamic> json) {
    return DeviceRecord(
      id: json['id'] as int,
      device: json['device'] as String? ?? 'Unknown Device',
      os: json['os'] as String? ?? 'Unknown OS',
      browser: json['browser'] as String? ?? 'Unknown Browser',
      ip: json['ip_address'] as String? ?? '0.0.0.0',
      loginAt: json['login_at'] != null ? DateTime.parse(json['login_at']) : DateTime.now(),
    );
  }

  String get formattedLoginTime => DateFormat('dd MMM yyyy, hh:mm a').format(loginAt);
}
