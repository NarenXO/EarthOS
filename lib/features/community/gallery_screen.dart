import 'package:flutter/material.dart';
import 'package:earthos/core/constants/app_colors.dart';
import 'package:earthos/features/report/services/report_service.dart';

class GalleryScreen extends StatefulWidget {
  const GalleryScreen({super.key});

  @override
  State<GalleryScreen> createState() => _GalleryScreenState();
}

class _GalleryScreenState extends State<GalleryScreen> {
  final ReportService _reportService = ReportService();
  List<Map<String, dynamic>> _transformations = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchTransformations();
  }

  Future<void> _fetchTransformations() async {
    final data = await _reportService.fetchTransformations();
    setState(() {
      _transformations = data;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text("Before/After Gallery"),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _transformations.isEmpty
              ? const Center(
                  child: Text(
                    "No transformations yet",
                    style: TextStyle(color: AppColors.textSecondary),
                  ),
                )
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 12,
                    mainAxisSpacing: 12,
                    childAspectRatio: 1,
                  ),
                  itemCount: _transformations.length,
                  itemBuilder: (context, index) {
                    final transformation = _transformations[index];
                    return _TransformationTile(
                      transformation: transformation,
                      onTap: () => _showTransformationDialog(transformation),
                    );
                  },
                ),
    );
  }

  void _showTransformationDialog(Map<String, dynamic> transformation) {
    final photoBefore = transformation['photo_before'] as String?;
    final photoAfter = transformation['photo_after'] as String?;
    final userName = transformation['created_by_name'] as String? ?? 'Anonymous';
    final carbon = transformation['carbon_estimate'] as num? ?? 0;

    showDialog(
      context: context,
      builder: (context) => Dialog(
        child: Container(
          constraints: const BoxConstraints(maxHeight: 600),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AppBar(
                title: const Text("Transformation"),
                automaticallyImplyLeading: false,
                actions: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              Expanded(
                child: PageView(
                  children: [
                    if (photoBefore != null)
                      _buildPhotoView(photoBefore, "Before"),
                    if (photoAfter != null)
                      _buildPhotoView(photoAfter, "After"),
                  ],
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Text(
                      'By $userName',
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                    if (carbon > 0) ...[
                      const SizedBox(height: 4),
                      Text(
                        '${carbon.toStringAsFixed(1)} kg CO₂e diverted',
                        style: const TextStyle(
                          color: Color(0xFF00C896),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhotoView(String photoUrl, String label) {
    return Column(
      children: [
        Expanded(
          child: Image.network(
            photoUrl,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return Container(
                color: AppColors.card,
                child: const Center(
                  child: Icon(Icons.broken_image, size: 64),
                ),
              );
            },
          ),
        ),
        Container(
          padding: const EdgeInsets.all(8),
          color: Colors.black54,
          child: Text(
            label,
            style: const TextStyle(color: Colors.white, fontSize: 18),
          ),
        ),
      ],
    );
  }
}

class _TransformationTile extends StatelessWidget {
  final Map<String, dynamic> transformation;
  final VoidCallback onTap;

  const _TransformationTile({
    required this.transformation,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final photoBefore = transformation['photo_before'] as String?;
    final userName = transformation['created_by_name'] as String? ?? 'Anonymous';
    final carbon = transformation['carbon_estimate'] as num? ?? 0;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppColors.card,
        ),
        child: Stack(
          children: [
            if (photoBefore != null)
              Positioned.fill(
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    photoBefore,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return Container(
                        color: AppColors.card,
                        child: const Center(
                          child: Icon(Icons.broken_image),
                        ),
                      );
                    },
                  ),
                ),
              ),
            Positioned.fill(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.transparent,
                      Colors.black.withOpacity(0.7),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: 8,
              left: 8,
              right: 8,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Tap to see after',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    userName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 11,
                    ),
                  ),
                  if (carbon > 0)
                    Text(
                      '${carbon.toStringAsFixed(1)} kg',
                      style: const TextStyle(
                        color: Color(0xFF00C896),
                        fontSize: 10,
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
