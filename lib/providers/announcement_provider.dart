import 'package:flutter/material.dart';
import '../models/announcement_model.dart';
import '../models/api_response.dart';
import '../services/admin_service.dart';
import '../services/announcement_service.dart';
import '../services/auth_service.dart';

class AnnouncementProvider extends ChangeNotifier {
  final AdminService _adminService;
  final AnnouncementService _announcementService;
  final AuthService _authService;

  AnnouncementProvider(this._authService)
      : _adminService = AdminService(),
        _announcementService = AnnouncementService();

  List<dynamic> _announcements = [];
  List<Announcement> _homeAnnouncements = [];
  Map<String, dynamic>? _selectedAnnouncement;

  bool _isLoading = false;
  String? _errorMessage;

  int _currentPage = 1;
  bool _hasMorePages = false;

  List<dynamic> get announcements => _announcements;
  List<Announcement> get homeAnnouncements => _homeAnnouncements;
  Map<String, dynamic>? get selectedAnnouncement => _selectedAnnouncement;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get hasMorePages => _hasMorePages;

  // Load announcements for home screen using the USER endpoint (not admin)
  Future<void> loadPublicAnnouncements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final result = await _announcementService.getAnnouncements(
        page: 1,
        perPage: 5,
      );
      _homeAnnouncements = result.data;
    } catch (e) {
      // Silently fail – home should not block on this
      print('⚠️ [AnnouncementProvider] loadPublicAnnouncements error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load all announcements (for admin)
  Future<void> loadAnnouncements({
    int page = 1,
    String? search,
    String? status,
    bool refresh = false,
  }) async {
    if (page == 1 || refresh) {
      _isLoading = true;
      _announcements = [];
    }
    
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.getAnnouncements(
        page: page,
        search: search,
        status: status,
      );

      _announcements = response['data'] ?? [];
      _currentPage = response['current_page'] ?? page;
      _hasMorePages = (response['current_page'] ?? page) < (response['last_page'] ?? page);
      
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Get single announcement by ID
  Future<void> loadAnnouncementById(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _selectedAnnouncement = await _adminService.getAnnouncement(id);
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Create new announcement
  Future<bool> createAnnouncement({
    required String title,
    required String summary,
    required String content,
    required String priority,
    bool isSticky = false,
    bool isPublished = false,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.createAnnouncement({
        'title': title,
        'summary': summary,
        'content': content,
        'priority': priority,
        'is_sticky': isSticky,
        'is_published': isPublished,
      });

      if (response.success) {
        // Refresh announcements list
        await loadAnnouncements(refresh: true);
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

  // Update existing announcement
  Future<bool> updateAnnouncement({
    required int id,
    required String title,
    required String summary,
    required String content,
    required String priority,
    required bool isSticky,
    required bool isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.updateAnnouncement(id, {
        'title': title,
        'summary': summary,
        'content': content,
        'priority': priority,
        'is_sticky': isSticky,
        'is_active': isActive,
      });

      if (response.success) {
        // Refresh announcements list
        await loadAnnouncements(refresh: true);
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

  // Delete announcement
  Future<bool> deleteAnnouncement(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.deleteAnnouncement(id);

      if (response.success) {
        // Remove from local list
        _announcements.removeWhere((ann) => ann['id'] == id);
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

  // Toggle announcement status (active/inactive)
  Future<bool> toggleAnnouncementStatus(int id) async {
    try {
      final response = await _adminService.toggleAnnouncementStatus(id);

      if (response.success) {
        // Update local state
        final index = _announcements.indexWhere((ann) => ann['id'] == id);
        if (index != -1) {
          _announcements[index]['is_active'] = !(_announcements[index]['is_active'] ?? false);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Toggle announcement sticky
  Future<bool> toggleAnnouncementSticky(int id) async {
    try {
      final response = await _adminService.toggleAnnouncementSticky(id);

      if (response.success) {
        // Update local state
        final index = _announcements.indexWhere((ann) => ann['id'] == id);
        if (index != -1) {
          _announcements[index]['is_sticky'] = !(_announcements[index]['is_sticky'] ?? false);
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Publish announcement
  Future<bool> publishAnnouncement(int id) async {
    try {
      final response = await _adminService.publishAnnouncement(id);

      if (response.success) {
        // Update local state
        final index = _announcements.indexWhere((ann) => ann['id'] == id);
        if (index != -1) {
          _announcements[index]['is_published'] = true;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Unpublish announcement
  Future<bool> unpublishAnnouncement(int id) async {
    try {
      final response = await _adminService.unpublishAnnouncement(id);

      if (response.success) {
        // Update local state
        final index = _announcements.indexWhere((ann) => ann['id'] == id);
        if (index != -1) {
          _announcements[index]['is_published'] = false;
          notifyListeners();
        }
        return true;
      } else {
        _errorMessage = response.message;
        notifyListeners();
        return false;
      }
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return false;
    }
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _announcements = [];
    _selectedAnnouncement = null;
    _isLoading = false;
    _errorMessage = null;
    _currentPage = 1;
    _hasMorePages = false;
    notifyListeners();
    print('✅ [AnnouncementProvider] State cleared');
  }
}
