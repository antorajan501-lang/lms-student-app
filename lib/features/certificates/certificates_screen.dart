import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:share_plus/share_plus.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../models/certificate_model.dart';
import '../../repositories/certificate_repository.dart';
import '../../widgets/empty_state_widget.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/shimmer_loader.dart';

final _certificatesProvider = FutureProvider<List<CertificateModel>>((ref) async {
  final repo = ref.watch(certificateRepositoryProvider);
  return repo.getCertificates();
});

class CertificatesScreen extends ConsumerWidget {
  const CertificatesScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final certAsync = ref.watch(_certificatesProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('My Certificates')),
      body: certAsync.when(
        data: (certs) {
          if (certs.isEmpty) {
            return const EmptyStateWidget(
              title: 'No certificates yet',
              subtitle: 'Complete a course to earn your first certificate!',
              icon: Icons.workspace_premium_outlined,
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            itemCount: certs.length,
            itemBuilder: (context, i) => _CertificateCard(cert: certs[i], ref: ref),
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.md),
            child: ShimmerLoader(height: 100),
          ),
        ),
        error: (e, _) => AppErrorWidget(
          message: e.toString(),
          onRetry: () => ref.invalidate(_certificatesProvider),
        ),
      ),
    );
  }
}

class _CertificateCard extends StatelessWidget {
  final CertificateModel cert;
  final WidgetRef ref;

  const _CertificateCard({required this.cert, required this.ref});

  Future<void> _download(BuildContext context) async {
    try {
      final repo = ref.read(certificateRepositoryProvider);
      final url = await repo.getCertificateUrl(cert.courseId ?? 0);
      if (url.isNotEmpty) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: AppSizes.md),
      padding: const EdgeInsets.all(AppSizes.md),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF6C5CE7).withOpacity(0.08),
            const Color(0xFF6C5CE7).withOpacity(0.02),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(color: const Color(0xFF6C5CE7).withOpacity(0.3)),
        borderRadius: BorderRadius.circular(AppSizes.cardRadius),
      ),
      child: Row(
        children: [
          Container(
            width: 56,
            height: 56,
            decoration: const BoxDecoration(
              color: Color(0xFF6C5CE7),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.workspace_premium_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: AppSizes.md),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  cert.courseTitle ?? 'Certificate',
                  style: GoogleFonts.inter(
                    fontWeight: FontWeight.w700,
                    fontSize: AppSizes.textMd,
                  ),
                ),
                if (cert.completedAt != null) ...[
                  const SizedBox(height: 2),
                  Text(
                    'Completed: ${cert.completedAt!.substring(0, 10)}',
                    style: GoogleFonts.inter(
                      fontSize: AppSizes.textSm,
                      color: AppColors.grey500,
                    ),
                  ),
                ],
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.share_rounded, color: Color(0xFF6C5CE7)),
            onPressed: () async {
              try {
                final repo = ref.read(certificateRepositoryProvider);
                final url = await repo.getCertificateUrl(cert.courseId ?? 0);
                if (url.isNotEmpty) {
                  await Share.share('I just completed "${cert.courseTitle}"! Check out my certificate: $url');
                }
              } catch (e) {
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Error: $e')),
                );
              }
            },
            tooltip: 'Share Certificate',
          ),
          IconButton(
            icon: const Icon(Icons.download_rounded, color: Color(0xFF6C5CE7)),
            onPressed: () => _download(context),
            tooltip: 'Download Certificate',
          ),
        ],
      ),
    );
  }
}
