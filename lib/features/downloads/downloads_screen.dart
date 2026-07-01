import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/empty_state_widget.dart';

class DownloadsScreen extends StatelessWidget {
  const DownloadsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Downloads')),
      body: const EmptyStateWidget(
        title: 'No downloads yet',
        subtitle: 'Downloaded lessons will appear here for offline viewing.',
        icon: Icons.download_outlined,
      ),
    );
  }
}
