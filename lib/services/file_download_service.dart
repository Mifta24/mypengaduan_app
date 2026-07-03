import 'package:dio/dio.dart';
import 'package:flutter/services.dart';

class FileDownloadService {
  static const MethodChannel _channel =
      MethodChannel('com.mif.mypengaduan/downloads');

  final Dio _dio = Dio();

  Future<String> downloadToDownloads({
    required String url,
    required String fileName,
  }) async {
    final safeFileName = _safeFileName(fileName);
    final response = await _dio.get<List<int>>(
      url,
      options: Options(responseType: ResponseType.bytes),
    );

    final bytes = response.data;
    if (bytes == null || bytes.isEmpty) {
      throw Exception('File kosong atau gagal diunduh');
    }

    final savedPath = await _channel.invokeMethod<String>('saveToDownloads', {
      'fileName': safeFileName,
      'mimeType': _mimeType(safeFileName),
      'bytes': Uint8List.fromList(bytes),
    });

    return savedPath ?? safeFileName;
  }

  String _safeFileName(String fileName) {
    final trimmed = fileName.trim();
    if (trimmed.isEmpty) return 'lampiran';
    return trimmed
        .replaceAll(RegExp(r'[\\/:*?"<>|]+'), '_')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  String _mimeType(String fileName) {
    final lower = fileName.toLowerCase();
    if (lower.endsWith('.pdf')) return 'application/pdf';
    if (lower.endsWith('.doc')) return 'application/msword';
    if (lower.endsWith('.docx')) {
      return 'application/vnd.openxmlformats-officedocument.wordprocessingml.document';
    }
    if (lower.endsWith('.xls')) return 'application/vnd.ms-excel';
    if (lower.endsWith('.xlsx')) {
      return 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
    }
    if (lower.endsWith('.png')) return 'image/png';
    if (lower.endsWith('.jpg') || lower.endsWith('.jpeg')) return 'image/jpeg';
    if (lower.endsWith('.webp')) return 'image/webp';
    return 'application/octet-stream';
  }
}
