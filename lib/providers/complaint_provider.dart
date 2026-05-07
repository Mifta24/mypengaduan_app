import 'package:flutter/material.dart';
import '../models/complaint_model.dart';
import '../services/complaint_service.dart';
import '../services/auth_service.dart';

class ComplaintProvider extends ChangeNotifier {
  final ComplaintService _complaintService;

  ComplaintProvider(AuthService authService)
      : _complaintService = ComplaintService(authService);

  List<Complaint> _complaints = [];
  List<Category> _categories = [];
  Map<String, dynamic>? _statistics;
  Complaint? _selectedComplaint;

  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  bool _hasMorePages = false;

  List<Complaint> get complaints => _complaints;
  List<Category> get categories => _categories;
  Map<String, dynamic>? get statistics => _statistics;
  Complaint? get selectedComplaint => _selectedComplaint;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;

  // Load complaints
  Future<void> loadComplaints({
    int page = 1,
    String? status,
    int? categoryId,
    String? search,
    bool refresh = false,
  }) async {
    if (page == 1 || refresh) {
      _isLoading = true;
      _complaints = [];
    }

    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _complaintService.getComplaints(
        page: page,
        status: status,
        categoryId: categoryId,
        search: search,
      );

      if (page == 1 || refresh) {
        _complaints = response.data;
      } else {
        _complaints.addAll(response.data);
      }

      _currentPage = page;
      _hasMorePages = response.meta.hasMorePages;

      print('Complaints loaded in provider: ${_complaints.length}');
      for (var c in _complaints) {
        print('Complaint: ${c.id} - ${c.title} - ${c.status}');
      }

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      print('Error in loadComplaints provider: $e');
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load next page
  Future<void> loadNextPage({
    String? status,
    int? categoryId,
    String? search,
  }) async {
    if (_hasMorePages && !_isLoading) {
      await loadComplaints(
        page: _currentPage + 1,
        status: status,
        categoryId: categoryId,
        search: search,
      );
    }
  }

  // Load complaint detail
  Future<void> loadComplaintDetail(int complaintId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedComplaint =
          await _complaintService.getComplaintDetail(complaintId);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Track complaint timeline/status
  Future<Map<String, dynamic>?> trackComplaint(int complaintId) async {
    return _complaintService.trackComplaint(complaintId);
  }

  // Create complaint
  Future<bool> createComplaint({
    required int categoryId,
    required String title,
    required String description,
    required String location,
    required DateTime reportDate,
    List<String>? attachments,
    List<String>? videos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload each video directly to Cloudinary, collect secure URLs
      final videoUrls = <String>[];
      if (videos != null && videos.isNotEmpty) {
        for (final path in videos) {
          final url = await _complaintService.uploadVideoToCloudinary(path);
          videoUrls.add(url);
        }
      }

      final response = await _complaintService.createComplaint(
        categoryId: categoryId,
        title: title,
        description: description,
        location: location,
        reportDate: reportDate,
        attachments: attachments,
        videoUrls: videoUrls.isEmpty ? null : videoUrls,
      );

      if (response.success) {
        // Refresh complaints list
        await loadComplaints(refresh: true);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Update existing complaint (only allowed while still pending on backend)
  Future<bool> updateComplaint({
    required int id,
    required int categoryId,
    required String title,
    required String description,
    required String location,
    required DateTime reportDate,
    List<String>? attachments,
    List<String>? videos,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // Upload each video directly to Cloudinary, collect secure URLs
      final videoUrls = <String>[];
      if (videos != null && videos.isNotEmpty) {
        for (final path in videos) {
          final url = await _complaintService.uploadVideoToCloudinary(path);
          videoUrls.add(url);
        }
      }

      final response = await _complaintService.updateComplaint(
        id: id,
        categoryId: categoryId,
        title: title,
        description: description,
        location: location,
        reportDate: reportDate,
        attachments: attachments,
        videoUrls: videoUrls.isEmpty ? null : videoUrls,
      );

      if (response.success) {
        // Refresh complaints list
        await loadComplaints(refresh: true);
        _isLoading = false;
        notifyListeners();
        return true;
      } else {
        _errorMessage = response.message;
        _isLoading = false;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Load categories
  Future<void> loadCategories() async {
    try {
      _categories = await _complaintService.getCategories();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Get categories - synchronous access
  Future<List<Category>> getCategories() async {
    if (_categories.isEmpty) {
      await loadCategories();
    }
    return _categories;
  }

  // Load statistics
  Future<void> loadStatistics() async {
    try {
      _statistics = await _complaintService.getStatistics();
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
    }
  }

  // Clear error
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear selected complaint
  void clearSelectedComplaint() {
    _selectedComplaint = null;
    notifyListeners();
  }

  // Delete complaint (user scope)
  Future<bool> deleteComplaint(int complaintId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _complaintService.deleteComplaint(complaintId);
      if (response.success) {
        _complaints.removeWhere((item) => item.id == complaintId);
        if (_selectedComplaint?.id == complaintId) {
          _selectedComplaint = null;
        }
        _isLoading = false;
        notifyListeners();
        return true;
      }

      _errorMessage = response.message;
      _isLoading = false;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Add response/message to complaint thread (user scope)
  Future<bool> addResponse(int complaintId, String message) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response =
          await _complaintService.addResponse(complaintId, message);
      _isLoading = false;
      if (!response.success) {
        _errorMessage = response.message;
      }
      notifyListeners();
      return response.success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Confirm complaint resolution (user scope)
  Future<bool> confirmResolution(int complaintId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _complaintService.confirmResolution(complaintId);
      _isLoading = false;
      if (!response.success) {
        _errorMessage = response.message;
      }
      notifyListeners();
      return response.success;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return false;
    }
  }

  // Clear all provider data (use on logout)
  void clear() {
    _complaints = [];
    _categories = [];
    _statistics = null;
    _selectedComplaint = null;
    _isLoading = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMorePages = false;
    notifyListeners();
    print('✅ [ComplaintProvider] State cleared');
  }
}
