import 'dart:typed_data';

import 'package:excel/excel.dart' as ex;
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import 'admin_service.dart';

class ReportsService {
  final AdminService _adminService;

  ReportsService({AdminService? adminService})
      : _adminService = adminService ?? AdminService();

  Future<Map<String, dynamic>> fetchReportsData() async {
    final overview = await _adminService.getReportOverview();
    final statistics = await _adminService.getComplaintStatistics();
    final reports = await Future.wait([
      _adminService.getComplaintsReport(),
      _adminService.getUsersReport(),
    ]);

    return {
      'overview': overview,
      'statistics': statistics,
      'complaintsReport': reports[0],
      'usersReport': reports[1],
    };
  }

  Future<Map<String, dynamic>> fetchComplaintsReport({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? status,
    int? categoryId,
    int? userId,
    String? priority,
    int perPage = 100,
    int page = 1,
  }) {
    return _adminService.getComplaintsReport(
      dateFrom: _asApiDate(dateFrom),
      dateTo: _asApiDate(dateTo),
      status: status,
      categoryId: categoryId,
      userId: userId,
      priority: priority,
      perPage: perPage,
      page: page,
    );
  }

  Future<Map<String, dynamic>> fetchUsersReport({
    DateTime? dateFrom,
    DateTime? dateTo,
    String? role,
    bool? isActive,
    String? search,
    int perPage = 100,
    int page = 1,
  }) {
    return _adminService.getUsersReport(
      dateFrom: _asApiDate(dateFrom),
      dateTo: _asApiDate(dateTo),
      role: role,
      isActive: isActive,
      search: search,
      perPage: perPage,
      page: page,
    );
  }

  List<Map<String, dynamic>> extractItems(Map<String, dynamic>? response) {
    if (response == null) return const [];

    final direct = response['data'];
    if (direct is List) {
      return direct.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
    }

    if (direct is Map) {
      final nested = direct['data'];
      if (nested is List) {
        return nested.whereType<Map>().map((e) => Map<String, dynamic>.from(e)).toList();
      }
    }

    return const [];
  }

  Future<List<Map<String, dynamic>>> fetchComplaintsByUser(int userId) async {
    final rows = <Map<String, dynamic>>[];
    var page = 1;
    var lastPage = 1;

    do {
      final response = await _adminService.getComplaints(
        page: page,
        perPage: 100,
        userId: userId,
      );

      final list = (response['data'] as List?) ?? const [];
      rows.addAll(
        list
            .whereType<Map>()
            .where((item) => item['deleted_at'] == null) // skip trashed
            .map((item) => Map<String, dynamic>.from(item)),
      );

      final currentPageRaw = response['current_page'] ?? response['meta']?['current_page'];
      final lastPageRaw = response['last_page'] ?? response['meta']?['last_page'];

      final currentPage = currentPageRaw is num
          ? currentPageRaw.toInt()
          : int.tryParse(currentPageRaw?.toString() ?? '1') ?? page;
      lastPage = lastPageRaw is num
          ? lastPageRaw.toInt()
          : int.tryParse(lastPageRaw?.toString() ?? '$currentPage') ?? currentPage;

      page = currentPage + 1;
    } while (page <= lastPage);

    return rows;
  }

  Future<String> exportReport({
    required String reportType,
    required String format,
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
  }) async {
    if (rows.isEmpty) {
      throw Exception('File export kosong');
    }

    final generatedAt = DateTime.now();
    final normalizedFormat = format.toLowerCase();

    late final Uint8List bytes;
    late final String extension;
    late final String mimeType;

    if (normalizedFormat == 'pdf') {
      bytes = await _generatePdfReport(
        title: title,
        headers: headers,
        rows: rows,
        generatedAt: generatedAt,
      );
      extension = 'pdf';
      mimeType = 'application/pdf';
    } else if (normalizedFormat == 'excel') {
      bytes = _generateExcelReport(
        title: title,
        headers: headers,
        rows: rows,
        generatedAt: generatedAt,
      );
      extension = 'xlsx';
      mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    } else {
      throw Exception('Format export tidak didukung');
    }

    final fileName = '${reportType}_report_${DateFormat('yyyyMMdd_HHmmss').format(generatedAt)}.$extension';

    await Share.shareXFiles(
      [
        XFile.fromData(
          bytes,
          name: fileName,
          mimeType: mimeType,
        ),
      ],
      text: 'Laporan $reportType ($format)',
      subject: fileName,
    );

    return 'Export ${format.toUpperCase()} siap disimpan/dibagikan';
  }

  Future<Uint8List> _generatePdfReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required DateTime generatedAt,
  }) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        margin: const pw.EdgeInsets.all(24),
        build: (context) => [
          pw.Text(title, style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 4),
          pw.Text('Dibuat: ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}'),
          pw.SizedBox(height: 12),
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows,
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 9),
            cellStyle: const pw.TextStyle(fontSize: 8),
            headerDecoration: const pw.BoxDecoration(color: PdfColors.grey300),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    return Uint8List.fromList(await pdf.save());
  }

  Uint8List _generateExcelReport({
    required String title,
    required List<String> headers,
    required List<List<String>> rows,
    required DateTime generatedAt,
  }) {
    final excel = ex.Excel.createExcel();
    final defaultSheetName = excel.getDefaultSheet();
    const sheetName = 'Report';

    if (defaultSheetName != null && defaultSheetName != sheetName) {
      excel.rename(defaultSheetName, sheetName);
    }

    final sheet = excel[sheetName];
    sheet.appendRow([ex.TextCellValue(title)]);
    sheet.appendRow([
      ex.TextCellValue('Dibuat: ${DateFormat('dd/MM/yyyy HH:mm').format(generatedAt)}'),
    ]);
    sheet.appendRow(const <ex.CellValue?>[]);
    sheet.appendRow(headers.map((h) => ex.TextCellValue(h)).toList());

    for (final row in rows) {
      sheet.appendRow(row.map((value) => ex.TextCellValue(value)).toList());
    }

    final encoded = excel.encode();
    if (encoded == null || encoded.isEmpty) {
      throw Exception('Gagal membuat file Excel');
    }

    return Uint8List.fromList(encoded);
  }

  String? _asApiDate(DateTime? value) {
    if (value == null) return null;
    return DateFormat('yyyy-MM-dd').format(value);
  }
}
