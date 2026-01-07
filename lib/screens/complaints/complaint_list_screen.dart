import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';
import '../../providers/complaint_provider.dart';
import '../../models/complaint_model.dart';

class ComplaintListScreen extends StatefulWidget {
  const ComplaintListScreen({super.key});

  @override
  State<ComplaintListScreen> createState() => _ComplaintListScreenState();
}

class _ComplaintListScreenState extends State<ComplaintListScreen> {
  String? _selectedStatus;
  
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _loadComplaints();
    });
  }

  Future<void> _loadComplaints({bool refresh = false}) async {
    final complaintProvider = Provider.of<ComplaintProvider>(context, listen: false);
    await complaintProvider.loadComplaints(
      status: _selectedStatus,
      refresh: refresh,
    );
  }

  @override
  Widget build(BuildContext context) {
    final complaintProvider = Provider.of<ComplaintProvider>(context);
    
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pengaduan Saya'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list),
            onSelected: (value) {
              setState(() {
                _selectedStatus = value == 'all' ? null : value;
              });
              _loadComplaints(refresh: true);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('Semua')),
              const PopupMenuItem(value: 'pending', child: Text('Menunggu')),
              const PopupMenuItem(value: 'in_progress', child: Text('Diproses')),
              const PopupMenuItem(value: 'resolved', child: Text('Selesai')),
              const PopupMenuItem(value: 'rejected', child: Text('Ditolak')),
            ],
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => _loadComplaints(refresh: true),
        child: complaintProvider.isLoading && complaintProvider.complaints.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : complaintProvider.complaints.isEmpty
                ? Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.report_off,
                          size: 64,
                          color: Colors.grey[400],
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Tidak ada pengaduan',
                          style: TextStyle(
                            fontSize: 16,
                            color: Colors.grey[600],
                          ),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    itemCount: complaintProvider.complaints.length,
                    itemBuilder: (context, index) {
                      final complaint = complaintProvider.complaints[index];
                      return _buildComplaintItem(complaint);
                    },
                  ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // TODO: Navigate to create complaint screen
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Fitur buat pengaduan akan segera tersedia')),
          );
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildComplaintItem(Complaint complaint) {
    final dateFormat = DateFormat('dd MMM yyyy');
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: _getStatusColor(complaint.status),
          child: Icon(
            _getStatusIcon(complaint.status),
            color: Colors.white,
          ),
        ),
        title: Text(
          complaint.title,
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.category, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  complaint.category?.name ?? 'Tidak ada kategori',
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
            const SizedBox(height: 2),
            Row(
              children: [
                Icon(Icons.calendar_today, size: 14, color: Colors.grey[600]),
                const SizedBox(width: 4),
                Text(
                  dateFormat.format(complaint.reportDate),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                ),
              ],
            ),
          ],
        ),
        trailing: Chip(
          label: Text(
            complaint.statusText,
            style: const TextStyle(fontSize: 12, color: Colors.white),
          ),
          backgroundColor: _getStatusColor(complaint.status),
          padding: const EdgeInsets.symmetric(horizontal: 8),
        ),
        onTap: () {
          // TODO: Navigate to complaint detail
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Detail: ${complaint.title}')),
          );
        },
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.orange;
      case 'in_progress':
        return Colors.blue;
      case 'resolved':
        return Colors.green;
      case 'rejected':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'pending':
        return Icons.pending;
      case 'in_progress':
        return Icons.hourglass_empty;
      case 'resolved':
        return Icons.check_circle;
      case 'rejected':
        return Icons.cancel;
      default:
        return Icons.help;
    }
  }
}
