import 'package:flutter/material.dart';
import '../services/admin_service.dart';

class CategoryProvider extends ChangeNotifier {
  final AdminService _adminService;

  CategoryProvider() : _adminService = AdminService();

  List<dynamic> _categories = [];
  Map<String, dynamic>? _selectedCategory;

  bool _isLoading = false;
  String? _errorMessage;

  List<dynamic> get categories => _categories;
  Map<String, dynamic>? get selectedCategory => _selectedCategory;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // Load all categories
  Future<void> loadCategories({bool refresh = false}) async {
    if (_categories.isNotEmpty && !refresh) {
      return; // Skip if already loaded unless refresh requested
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _categories = await _adminService.getCategories();
      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
    }
  }

  // Load active categories only
  Future<List<dynamic>> loadActiveCategories() async {
    try {
      return await _adminService.getActiveCategories();
    } catch (e) {
      _errorMessage = e.toString();
      notifyListeners();
      return [];
    }
  }

  // Load category detail by ID
  Future<Map<String, dynamic>?> loadCategoryDetail(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.getCategory(id);
      final data = response['data'];
      if (data is Map<String, dynamic>) {
        _selectedCategory = data;
      } else if (data is Map) {
        _selectedCategory = Map<String, dynamic>.from(data);
      } else {
        _selectedCategory = response;
      }
      _isLoading = false;
      notifyListeners();
      return _selectedCategory;
    } catch (e) {
      _errorMessage = e.toString();
      _isLoading = false;
      notifyListeners();
      return null;
    }
  }

  // Get filtered categories (for local filtering)
  List<dynamic> getFilteredCategories({
    String? searchQuery,
    String? status,
  }) {
    var filtered = List<dynamic>.from(_categories);

    // Filter by search query
    if (searchQuery != null && searchQuery.isNotEmpty) {
      final query = searchQuery.toLowerCase();
      filtered = filtered.where((cat) {
        final name = cat['name']?.toString().toLowerCase() ?? '';
        final description = cat['description']?.toString().toLowerCase() ?? '';
        return name.contains(query) || description.contains(query);
      }).toList();
    }

    // Filter by status
    if (status != null && status != 'all') {
      filtered = filtered.where((cat) {
        final isActive = cat['is_active'] == true || cat['is_active'] == 1;
        if (status == 'active') return isActive;
        if (status == 'inactive') return !isActive;
        return true;
      }).toList();
    }

    return filtered;
  }

  // Get active categories only (for dropdowns)
  List<dynamic> getActiveCategories() {
    return _categories.where((cat) {
      return cat['is_active'] == true || cat['is_active'] == 1;
    }).toList();
  }

  // Get single category by ID
  void selectCategory(int id) {
    _selectedCategory = _categories.firstWhere(
      (cat) => cat['id'] == id,
      orElse: () => null,
    );
    notifyListeners();
  }

  // Create new category
  Future<bool> createCategory({
    required String name,
    required String description,
    bool isActive = true,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.createCategory({
        'name': name,
        'description': description,
        'is_active': isActive,
      });

      if (response.success) {
        // Refresh categories list
        await loadCategories(refresh: true);
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

  // Update existing category
  Future<bool> updateCategory({
    required int id,
    required String name,
    required String description,
    required bool isActive,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.updateCategory(id, {
        'name': name,
        'description': description,
        'is_active': isActive,
      });

      if (response.success) {
        // Refresh categories list
        await loadCategories(refresh: true);
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

  // Delete category
  Future<bool> deleteCategory(int id) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.deleteCategory(id);

      if (response.success) {
        // Remove from local list
        _categories.removeWhere((cat) => cat['id'] == id);
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

  // Toggle category status (active/inactive)
  Future<bool> toggleCategoryStatus(int id) async {
    try {
      final response = await _adminService.toggleCategoryStatus(id);

      if (response.success) {
        // Update local state
        final index = _categories.indexWhere((cat) => cat['id'] == id);
        if (index != -1) {
          _categories[index]['is_active'] =
              !(_categories[index]['is_active'] ?? false);
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

  // Bulk action for categories
  Future<bool> bulkAction({
    required List<int> ids,
    required String action,
    Map<String, dynamic>? payload,
  }) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final response = await _adminService.bulkActionCategories(
        ids: ids,
        action: action,
        payload: payload,
      );

      if (response.success) {
        await loadCategories(refresh: true);
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

  // Get category count
  int get categoryCount => _categories.length;

  // Get active category count
  int get activeCategoryCount {
    return _categories.where((cat) {
      return cat['is_active'] == true || cat['is_active'] == 1;
    }).length;
  }

  // Check if category name exists (for validation)
  bool categoryNameExists(String name, {int? excludeId}) {
    return _categories.any((cat) {
      if (excludeId != null && cat['id'] == excludeId) {
        return false; // Exclude current category when editing
      }
      return cat['name']?.toString().toLowerCase() == name.toLowerCase();
    });
  }

  // Clear error message
  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  // Clear all data
  void clear() {
    _categories = [];
    _selectedCategory = null;
    _isLoading = false;
    _errorMessage = null;
    notifyListeners();
  }
}
