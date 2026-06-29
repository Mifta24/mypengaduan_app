import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../../../../theme/app_theme.dart';
import '../announcement_detail_utils.dart';

/// Renders either an image grid (tap to view full-screen) or a downloadable
/// document list, depending on [isImageSection].
class AnnouncementMediaSection extends StatelessWidget {
  final String title;
  final List<Map<String, String>> items;
  final bool isImageSection;
  final void Function(String url, String name) onImageTap;
  final void Function(String url, String name) onDownloadAttachment;

  const AnnouncementMediaSection({
    super.key,
    required this.title,
    required this.items,
    required this.isImageSection,
    required this.onImageTap,
    required this.onDownloadAttachment,
  });

  @override
  Widget build(BuildContext context) {
    final displayItems = isImageSection
        ? items.where((item) => isAnnouncementImageFile(item['url'] ?? item['name'] ?? '')).toList()
        : items;

    if (displayItems.isEmpty) return const SizedBox.shrink();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppTheme.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: GoogleFonts.nunito(fontWeight: FontWeight.w700, color: AppTheme.textPrimary)),
          const SizedBox(height: 12),
          if (isImageSection)
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: displayItems.length,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                mainAxisSpacing: 12,
                crossAxisSpacing: 12,
                childAspectRatio: 1.2,
              ),
              itemBuilder: (context, index) {
                final item = displayItems[index];
                final name = item['name'] ?? '-';
                final url = item['url'] ?? '';

                return InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: url.isEmpty ? null : () => onImageTap(url, name),
                  child: Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                    ),
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          url.isEmpty
                              ? Container(
                                  color: Colors.grey.shade100,
                                  child: const Center(child: Icon(Icons.image_not_supported_outlined)),
                                )
                              : Image.network(
                                  url,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) => Container(
                                    color: Colors.grey.shade100,
                                    child: const Center(child: Icon(Icons.broken_image_outlined)),
                                  ),
                                ),
                          Positioned(
                            bottom: 0,
                            left: 0,
                            right: 0,
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.bottomCenter,
                                  end: Alignment.topCenter,
                                  colors: [Colors.black.withValues(alpha: 0.7), Colors.transparent],
                                ),
                              ),
                              child: Text(
                                name,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.nunito(fontSize: 10, color: Colors.white, fontWeight: FontWeight.w600),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            )
          else
            ...displayItems.map((item) {
              final name = item['name'] ?? '-';
              final url = item['url'] ?? '';

              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                decoration: BoxDecoration(
                  color: AppTheme.surface,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: AppTheme.border.withValues(alpha: 0.5)),
                ),
                child: ListTile(
                  dense: true,
                  leading: const Icon(Icons.description_outlined, color: AppTheme.primary),
                  title: Text(name, maxLines: 1, overflow: TextOverflow.ellipsis, style: GoogleFonts.nunito(fontWeight: FontWeight.w600)),
                  trailing: const Icon(Icons.download_rounded, size: 20, color: AppTheme.textSecondary),
                  onTap: () => onDownloadAttachment(url, name),
                ),
              );
            }),
        ],
      ),
    );
  }
}
