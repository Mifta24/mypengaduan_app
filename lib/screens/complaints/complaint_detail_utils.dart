import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../../config/app_config.dart';
import '../../models/complaint_model.dart';
import '../../theme/app_theme.dart';

class ComplaintStatusInfo {
  final String label;
  final Color color;
  final Color bg;
  const ComplaintStatusInfo(this.label, this.color, this.bg);
}

ComplaintStatusInfo complaintStatusInfo(String status) {
  switch (status) {
    case 'pending':
      return const ComplaintStatusInfo('Menunggu', Color(0xFFD97706), Color(0xFFFEF3C7));
    case 'in_progress':
      return const ComplaintStatusInfo('Diproses', Color(0xFF0891B2), Color(0xFFDBEAFE));
    case 'waiting_user_confirmation':
      return const ComplaintStatusInfo('Menunggu Konfirmasi', Color(0xFFEA580C), Color(0xFFFFF7ED));
    case 'resolved':
      return ComplaintStatusInfo('Selesai', AppTheme.primary, const Color(0xFFD1FAE5));
    case 'rejected':
      return const ComplaintStatusInfo('Ditolak', Color(0xFFDC2626), Color(0xFFFEE2E2));
    default:
      return ComplaintStatusInfo(status, Colors.grey, Colors.grey.shade100);
  }
}

// Returns 0=pending, 1=done, 2=active, -1=rejected-inactive
int complaintStepState(int step, String status) {
  const order = {
    'pending': 0,
    'in_progress': 2,
    'waiting_user_confirmation': 3,
    'resolved': 4,
    'rejected': -1,
  };
  final idx = order[status] ?? 0;
  if (status == 'rejected') return step == 0 ? 1 : -1;
  if (idx >= step + 1) return 1;
  if (idx == step) return 2;
  return 0;
}

String normalizeComplaintImageUrl(String rawUrl) {
  final t = rawUrl.trim();
  if (t.isEmpty) return '';
  if (t.startsWith('http://') || t.startsWith('https://')) return t;
  final base = AppConfig.baseUrl.replaceAll('/api', '');
  return t.startsWith('/') ? '$base$t' : '$base/$t';
}

List<String> extractResolutionPhotoUrls(dynamic source) {
  if (source is! Map) return const [];
  final data = Map<String, dynamic>.from(source);
  const keys = [
    'resolution_attachments', 'resolution_photos', 'resolved_photos',
    'documentation_photos', 'resolution_images', 'resolve_photos', 'photos',
  ];
  final results = <String>[];
  for (final key in keys) {
    final value = data[key];
    if (value is! List) continue;
    for (final item in value) {
      if (!_isResolutionAttachment(item, key)) continue;
      final url = normalizeComplaintImageUrl(_extractMediaUrl(item));
      if (url.isNotEmpty) results.add(url);
    }
    if (results.isNotEmpty) break;
  }
  final status = (data['status']?.toString() ?? '').toLowerCase();
  if (results.isEmpty && status == 'resolved') {
    final attachments = data['attachments'];
    if (attachments is List) {
      for (final item in attachments) {
        if (!_isResolutionAttachment(item, 'attachments')) continue;
        final url = normalizeComplaintImageUrl(_extractMediaUrl(item));
        if (url.isNotEmpty) results.add(url);
      }
    }
  }
  return results.toSet().toList();
}

String _extractMediaUrl(dynamic item) {
  if (item == null) return '';
  if (item is String) return item.trim();
  if (item is Map) {
    final m = Map<String, dynamic>.from(item);
    return (m['url'] ?? m['file_url'] ?? m['photo_url'] ??
            m['path'] ?? m['file_path'] ?? m['name'])
        ?.toString()
        .trim() ??
        '';
  }
  return '';
}

bool _isResolutionAttachment(dynamic item, String sourceKey) {
  if (sourceKey == 'resolution_attachments' || sourceKey == 'resolution_photos') return true;
  if (item is Map) {
    final type = Map<String, dynamic>.from(item)['attachment_type']
            ?.toString()
            .toLowerCase() ??
        '';
    if (type.isNotEmpty) return type == 'resolution';
  }
  return sourceKey != 'attachments' && sourceKey != 'complaint_attachments';
}

void showComplaintFullImage(BuildContext context, String imageUrl) {
  showDialog(
    context: context,
    builder: (_) => Dialog(
      backgroundColor: Colors.transparent,
      child: Stack(
        children: [
          Center(
            child: InteractiveViewer(
              child: CachedNetworkImage(imageUrl: imageUrl, fit: BoxFit.contain),
            ),
          ),
          Positioned(
            top: 40,
            right: 20,
            child: IconButton(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.close, color: Colors.white, size: 32),
            ),
          ),
        ],
      ),
    ),
  );
}

Future<void> exportComplaintPdf(Complaint complaint) async {
  final pdf = pw.Document();
  final generatedAt = DateTime.now();

  String statusText;
  switch (complaint.status) {
    case 'pending':
      statusText = 'Menunggu';
      break;
    case 'in_progress':
      statusText = 'Dalam Proses';
      break;
    case 'waiting_user_confirmation':
      statusText = 'Menunggu Konfirmasi';
      break;
    case 'resolved':
      statusText = 'Selesai';
      break;
    case 'rejected':
      statusText = 'Ditolak';
      break;
    default:
      statusText = complaint.status;
  }

  pdf.addPage(
    pw.MultiPage(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.all(32),
      build: (context) => [
        pw.Text('Laporan Pengaduan',
            style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
        pw.SizedBox(height: 4),
        pw.Text(
          'Dibuat: ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}',
          style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey700),
        ),
        pw.Divider(height: 24),
        pw.TableHelper.fromTextArray(
          headers: ['Field', 'Detail'],
          data: [
            ['Judul', complaint.title],
            ['Status', statusText],
            ['Kategori', complaint.category?.name ?? '-'],
            ['Lokasi', complaint.location],
            ['Tanggal Kejadian', DateFormat('dd/MM/yyyy').format(complaint.reportDate)],
            ['Tanggal Dibuat', DateFormat('dd/MM/yyyy HH:mm').format(complaint.createdAt)],
            ['Deskripsi', complaint.description],
          ],
          headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 10),
          cellStyle: const pw.TextStyle(fontSize: 9),
          headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
          cellAlignment: pw.Alignment.topLeft,
          columnWidths: {0: const pw.FixedColumnWidth(110)},
        ),
      ],
    ),
  );

  final bytes = Uint8List.fromList(await pdf.save());
  final fileName =
      'pengaduan_${complaint.id}_${DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}.pdf';
  await Share.shareXFiles(
    [XFile.fromData(bytes, name: fileName, mimeType: 'application/pdf')],
    text: 'Laporan Pengaduan: ${complaint.title}',
    subject: fileName,
  );
}

// Shared card decoration used by multiple complaint detail widgets
BoxDecoration get complaintCardDecoration => BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(color: AppTheme.border),
    );

// Shared section title style
TextStyle complaintSectionTitle(BuildContext context) =>
    GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.w700, color: AppTheme.textPrimary);
