import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_sizes.dart';
import '../../widgets/app_button.dart';

class StudyMaterialsScreen extends ConsumerStatefulWidget {
  const StudyMaterialsScreen({super.key});

  @override
  ConsumerState<StudyMaterialsScreen> createState() => _StudyMaterialsScreenState();
}

class _StudyMaterialsScreenState extends ConsumerState<StudyMaterialsScreen> {
  String _searchQuery = '';
  String _selectedCategory = 'All';

  final List<StudyMaterial> _materials = [
    StudyMaterial(
      title: 'Introduction to Software Architecture Lecture Slides.pdf',
      category: 'PDF',
      courseName: 'Managerial Accounting Advance Course',
      size: '4.2 MB',
      url: 'http://10.100.10.29:8000/demo/materials/intro.pdf',
    ),
    StudyMaterial(
      title: 'Chapter 2 Financial Audits Guidebook.pdf',
      category: 'PDF',
      courseName: 'Financial Management Essentials',
      size: '8.7 MB',
      url: 'http://10.100.10.29:8000/demo/materials/audits.pdf',
    ),
    StudyMaterial(
      title: 'Database Normalization Explained (1080p).mp4',
      category: 'Video',
      courseName: 'Relational Database Design',
      size: '142 MB',
      url: 'http://10.100.10.29:8000/demo/materials/normalization.mp4',
    ),
    StudyMaterial(
      title: 'Spring Boot Microservices Boilerplate Codebase.zip',
      category: 'Document',
      courseName: 'Advanced Spring Boot Development',
      size: '12.4 MB',
      url: 'http://10.100.10.29:8000/demo/materials/boilerplate.zip',
    ),
    StudyMaterial(
      title: 'Quiz 2 Solutions & Review Notes.docx',
      category: 'Document',
      courseName: 'Software Engineering Fundamentals',
      size: '1.1 MB',
      url: 'http://10.100.10.29:8000/demo/materials/notes.docx',
    ),
  ];

  Map<String, double> _downloadProgress = {};

  Future<void> _startDownload(StudyMaterial material) async {
    if (_downloadProgress.containsKey(material.title)) return;

    setState(() {
      _downloadProgress[material.title] = 0.0;
    });

    // Simulate progress download
    for (var i = 1; i <= 10; i++) {
      await Future.delayed(const Duration(milliseconds: 250));
      if (!mounted) return;
      setState(() {
        _downloadProgress[material.title] = i / 10;
      });
    }

    if (!mounted) return;
    setState(() {
      _downloadProgress.remove(material.title);
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('"${material.title}" downloaded successfully! View in Downloads.'),
        backgroundColor: AppColors.success,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _materials.where((m) {
      final matchesSearch = m.title.toLowerCase().contains(_searchQuery.toLowerCase()) ||
          m.courseName.toLowerCase().contains(_searchQuery.toLowerCase());
      final matchesCategory = _selectedCategory == 'All' || m.category == _selectedCategory;
      return matchesSearch && matchesCategory;
    }).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Study Materials'),
      ),
      body: Column(
        children: [
          // Search & Filter Header
          Padding(
            padding: const EdgeInsets.all(AppSizes.screenPadding),
            child: Column(
              children: [
                TextField(
                  onChanged: (v) => setState(() => _searchQuery = v),
                  decoration: InputDecoration(
                    hintText: 'Search study materials...',
                    prefixIcon: const Icon(Icons.search_rounded, color: AppColors.grey400),
                    contentPadding: const EdgeInsets.symmetric(vertical: 0),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                    ),
                  ),
                ),
                const SizedBox(height: AppSizes.md),
                // Categories Chips
                SizedBox(
                  height: 38,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: ['All', 'PDF', 'Video', 'Document'].map((cat) {
                      final isSel = _selectedCategory == cat;
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSizes.sm),
                        child: ChoiceChip(
                          label: Text(cat),
                          selected: isSel,
                          onSelected: (selected) {
                            if (selected) {
                              setState(() => _selectedCategory = cat);
                            }
                          },
                          selectedColor: AppColors.primary,
                          labelStyle: TextStyle(
                            color: isSel ? Colors.white : Theme.of(context).colorScheme.onSurface,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
          ),

          // Materials List
          Expanded(
            child: filtered.isEmpty
                ? const Center(
                    child: Text(
                      'No matching materials found.',
                      style: TextStyle(color: AppColors.grey500),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: AppSizes.screenPadding),
                    itemCount: filtered.length,
                    itemBuilder: (context, index) {
                      final mat = filtered[index];
                      final isDownloading = _downloadProgress.containsKey(mat.title);
                      final progress = _downloadProgress[mat.title] ?? 0.0;

                      IconData typeIcon;
                      Color typeColor;
                      switch (mat.category) {
                        case 'PDF':
                          typeIcon = Icons.picture_as_pdf_rounded;
                          typeColor = AppColors.error;
                          break;
                        case 'Video':
                          typeIcon = Icons.play_circle_fill_rounded;
                          typeColor = AppColors.primary;
                          break;
                        default:
                          typeIcon = Icons.description_rounded;
                          typeColor = AppColors.accent;
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
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  // Leading File Icon
                                  Container(
                                    padding: const EdgeInsets.all(AppSizes.sm),
                                    decoration: BoxDecoration(
                                      color: typeColor.withOpacity(0.08),
                                      borderRadius: BorderRadius.circular(AppSizes.radiusMd),
                                    ),
                                    child: Icon(typeIcon, color: typeColor, size: 24),
                                  ),
                                  const SizedBox(width: AppSizes.md),
                                  // Detail info
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          mat.title,
                                          style: GoogleFonts.inter(
                                            fontWeight: FontWeight.w700,
                                            fontSize: AppSizes.textMd,
                                          ),
                                          maxLines: 2,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                        const SizedBox(height: 2),
                                        Text(
                                          mat.courseName,
                                          style: GoogleFonts.inter(
                                            color: AppColors.grey500,
                                            fontSize: 12,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSizes.md),
                              // Footer sizing & Download Action
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    '${mat.category} • ${mat.size}',
                                    style: GoogleFonts.inter(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: AppColors.grey400,
                                    ),
                                  ),
                                  isDownloading
                                      ? SizedBox(
                                          width: 100,
                                          child: Column(
                                            children: [
                                              ClipRRect(
                                                borderRadius: BorderRadius.circular(2),
                                                child: LinearProgressIndicator(
                                                  value: progress,
                                                  backgroundColor: AppColors.grey200,
                                                  color: AppColors.primary,
                                                  minHeight: 4,
                                                ),
                                              ),
                                              const SizedBox(height: 2),
                                              Text(
                                                '${(progress * 100).toInt()}%',
                                                style: const TextStyle(fontSize: 9),
                                              ),
                                            ],
                                          ),
                                        )
                                      : IconButton(
                                          icon: const Icon(Icons.download_for_offline_rounded,
                                              color: AppColors.primary, size: 26),
                                          onPressed: () => _startDownload(mat),
                                        ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}

class StudyMaterial {
  final String title;
  final String category;
  final String courseName;
  final String size;
  final String url;

  StudyMaterial({
    required this.title,
    required this.category,
    required this.courseName,
    required this.size,
    required this.url,
  });
}
