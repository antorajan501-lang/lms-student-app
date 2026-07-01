import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_currency.dart';
import '../../core/constants/app_sizes.dart';
import '../../core/api/api_client.dart';
import '../../core/api/endpoints.dart';
import '../../widgets/error_widget.dart';
import '../../widgets/shimmer_loader.dart';

final purchaseHistoryProvider = FutureProvider<List<PurchaseRecord>>((ref) async {
  final client = ref.watch(apiClientProvider);
  final response = await client.get(ApiEndpoints.purchaseHistory);
  final responseData = response.data;
  if (responseData['success'] == true) {
    final List list = responseData['data'] ?? [];
    return list.map((x) => PurchaseRecord.fromJson(x as Map<String, dynamic>)).toList();
  }
  return [];
});

class PurchaseHistoryScreen extends ConsumerWidget {
  const PurchaseHistoryScreen({super.key});

  void _showReceiptDialog(BuildContext context, PurchaseRecord record) {
    showDialog(
      context: context,
      builder: (context) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(AppSizes.cardRadius)),
        child: Padding(
          padding: const EdgeInsets.all(AppSizes.xl),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Payment Receipt', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: AppSizes.md),
              _ReceiptRow(label: 'Invoice ID', value: record.tracking),
              _ReceiptRow(label: 'Date', value: record.formattedDate),
              _ReceiptRow(label: 'Gateway', value: record.paymentMethod),
              _ReceiptRow(
                label: 'Status',
                value: record.status == 1 ? 'Approved' : 'Pending',
                valueColor: record.status == 1 ? AppColors.success : AppColors.warning,
              ),
              const SizedBox(height: AppSizes.md),
              const Divider(),
              const SizedBox(height: AppSizes.sm),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Total Amount', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  Text(
                    AppCurrency.format(record.price),
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18, color: AppColors.primary),
                  ),
                ],
              ),
              const SizedBox(height: AppSizes.xl),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size(double.infinity, 48),
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                onPressed: () {
                  Navigator.pop(context);
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('Receipt downloaded successfully!'),
                      backgroundColor: AppColors.success,
                      behavior: SnackBarBehavior.floating,
                    ),
                  );
                },
                icon: const Icon(Icons.download_rounded),
                label: const Text('Download PDF Receipt'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final historyAsync = ref.watch(purchaseHistoryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Purchase History'),
      ),
      body: historyAsync.when(
        data: (records) {
          if (records.isEmpty) {
            return const Center(
              child: Text(
                'No purchases found.',
                style: TextStyle(color: AppColors.grey500),
              ),
            );
          }
          return ListView.builder(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            itemCount: records.length,
            itemBuilder: (context, index) {
              final rec = records[index];
              return Card(
                elevation: 0,
                margin: const EdgeInsets.only(bottom: AppSizes.sm),
                color: Theme.of(context).cardColor,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(AppSizes.cardRadius),
                  side: BorderSide(color: Theme.of(context).dividerColor),
                ),
                child: ListTile(
                  contentPadding: const EdgeInsets.symmetric(horizontal: AppSizes.md, vertical: AppSizes.xs),
                  leading: Container(
                    padding: const EdgeInsets.all(AppSizes.sm),
                    decoration: BoxDecoration(
                      color: AppColors.primary.withOpacity(0.08),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.receipt_long_rounded, color: AppColors.primary),
                  ),
                  title: Text(
                    'Invoice ID: ${rec.tracking}',
                    style: GoogleFonts.inter(fontWeight: FontWeight.w700),
                  ),
                  subtitle: Text(
                    '${rec.formattedDate} • ${rec.paymentMethod}',
                    style: GoogleFonts.inter(fontSize: 12, color: AppColors.grey500),
                  ),
                  trailing: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        AppCurrency.format(rec.price),
                        style: GoogleFonts.inter(fontWeight: FontWeight.w800, fontSize: 16),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        rec.status == 1 ? 'Approved' : 'Pending',
                        style: GoogleFonts.inter(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: rec.status == 1 ? AppColors.success : AppColors.warning,
                        ),
                      ),
                    ],
                  ),
                  onTap: () => _showReceiptDialog(context, rec),
                ),
              );
            },
          );
        },
        loading: () => ListView.builder(
          padding: const EdgeInsets.all(AppSizes.screenPadding),
          itemCount: 4,
          itemBuilder: (_, __) => const Padding(
            padding: EdgeInsets.only(bottom: AppSizes.sm),
            child: ShimmerLoader(height: 72),
          ),
        ),
        error: (err, _) => AppErrorWidget(
          message: err.toString(),
          onRetry: () => ref.invalidate(purchaseHistoryProvider),
        ),
      ),
    );
  }
}

class _ReceiptRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _ReceiptRow({required this.label, required this.value, this.valueColor});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(color: AppColors.grey500, fontSize: 13)),
          Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: valueColor)),
        ],
      ),
    );
  }
}

class PurchaseRecord {
  final int id;
  final String tracking;
  final double price;
  final double purchasePrice;
  final String paymentMethod;
  final int status;
  final DateTime createdAt;

  PurchaseRecord({
    required this.id,
    required this.tracking,
    required this.price,
    required this.purchasePrice,
    required this.paymentMethod,
    required this.status,
    required this.createdAt,
  });

  factory PurchaseRecord.fromJson(Map<String, dynamic> json) {
    return PurchaseRecord(
      id: json['id'] as int,
      tracking: json['tracking'] as String? ?? '',
      price: (json['price'] as num?)?.toDouble() ?? 0.0,
      purchasePrice: (json['purchase_price'] as num?)?.toDouble() ?? 0.0,
      paymentMethod: json['payment_method'] as String? ?? 'None',
      status: json['status'] as int? ?? 0,
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at']) : DateTime.now(),
    );
  }

  String get formattedDate => DateFormat('dd MMM yyyy').format(createdAt);
}
