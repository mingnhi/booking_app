import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:intl/intl.dart';

class LocationManagementScreen extends StatefulWidget {
  const LocationManagementScreen({Key? key}) : super(key: key);

  @override
  State<LocationManagementScreen> createState() =>
      _LocationManagementScreenState();
}

class _LocationManagementScreenState extends State<LocationManagementScreen> {
  List<dynamic> locations = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _contactPhoneController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadLocations();
  }

  @override
  void dispose() {
    _nameController.dispose();
    _descriptionController.dispose();
    _contactPhoneController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadLocations() async {
    setState(() {
      isLoading = true;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final fetchedLocations = await adminService.getLocations();
      setState(() {
        locations = fetchedLocations;
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Lỗi khi tải danh sách địa điểm: $e')),
      );
      setState(() {
        isLoading = false;
      });
    }
  }

  void _showAddLocationDialog() {
    _nameController.clear();
    _descriptionController.clear();
    _contactPhoneController.clear();
    _showLocationDialog(null);
  }

  void _showEditLocationDialog(dynamic location) {
    _nameController.text = location['name'] ?? '';
    _descriptionController.text = location['description'] ?? '';
    _contactPhoneController.text = location['contact_phone'] ?? '';
    _showLocationDialog(location);
  }

  void _showLocationDialog(dynamic location) {
    final isEditing = location != null;
    final title = isEditing ? 'Chỉnh sửa địa điểm' : 'Thêm địa điểm mới';

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              title,
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: _formKey,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    TextFormField(
                      controller: _nameController,
                      decoration: const InputDecoration(
                        labelText: 'Tên địa điểm',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Vui lòng nhập tên địa điểm';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _descriptionController,
                      decoration: const InputDecoration(
                        labelText: 'Mô tả',
                        border: OutlineInputBorder(),
                      ),
                      maxLines: 3,
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _contactPhoneController,
                      decoration: const InputDecoration(
                        labelText: 'Số điện thoại liên hệ',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.phone,
                    ),
                  ],
                ),
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed:
                    () => _saveLocation(isEditing ? location['_id'] : null),
                child: const Text('Lưu'),
              ),
            ],
          ),
    );
  }

  Future<void> _saveLocation(String? locationId) async {
    if (_formKey.currentState!.validate()) {
      Navigator.pop(context);
      setState(() {
        isLoading = true;
      });

      final adminService = Provider.of<AdminService>(context, listen: false);
      final locationData = {
        'name': _nameController.text,
        'description': _descriptionController.text,
        'contact_phone': _contactPhoneController.text,
      };

      try {
        if (locationId != null) {
          // Cập nhật địa điểm
          await adminService.updateLocation(locationId, locationData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Cập nhật địa điểm thành công')),
          );
        } else {
          // Thêm địa điểm mới
          await adminService.createLocation(locationData);
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Thêm địa điểm thành công')),
          );
        }
        _loadLocations();
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
      }
    }
  }

  Future<void> _confirmDeleteLocation(
    String locationId,
    String locationName,
  ) async {
    final result = await showDialog<bool>(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Xác nhận xóa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa địa điểm "$locationName"?',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Hủy'),
              ),
              ElevatedButton(
                onPressed: () => Navigator.pop(context, true),
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: const Text('Xóa'),
              ),
            ],
          ),
    );

    if (result == true) {
      setState(() {
        isLoading = true;
      });

      try {
        final adminService = Provider.of<AdminService>(context, listen: false);
        await adminService.deleteLocation(locationId);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Xóa địa điểm thành công')),
        );
        _loadLocations();
      } catch (e) {
        setState(() {
          isLoading = false;
        });
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Lỗi khi xóa địa điểm: $e')));
      }
    }
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.location_on, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Chưa có địa điểm nào',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Nhấn nút + để thêm địa điểm mới',
            style: GoogleFonts.poppins(color: Colors.grey),
          ),
        ],
      ),
    );
  }

  List<dynamic> get filteredLocations {
    if (searchQuery.isEmpty) return locations;
    return locations.where((location) {
      final name = location['name']?.toString().toLowerCase() ?? '';
      return name.contains(searchQuery.toLowerCase());
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý địa điểm',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadLocations,
            tooltip: 'Làm mới',
          ),
        ],
      ),
      body:
          isLoading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        hintText: 'Tìm kiếm theo tên địa điểm',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon:
                            searchQuery.isNotEmpty
                                ? IconButton(
                                  icon: const Icon(Icons.clear),
                                  onPressed: () {
                                    setState(() {
                                      _searchController.clear();
                                      searchQuery = '';
                                    });
                                  },
                                )
                                : null,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                      onChanged: (value) {
                        setState(() {
                          searchQuery = value;
                        });
                      },
                    ),
                  ),
                  Expanded(
                    child:
                        filteredLocations.isEmpty
                            ? _buildEmptyState()
                            : _buildLocationList(),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddLocationDialog,
        tooltip: 'Thêm địa điểm mới',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildLocationList() {
    return RefreshIndicator(
      onRefresh: _loadLocations,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredLocations.length,
        itemBuilder: (context, index) {
          final location = filteredLocations[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          location['name'] ?? 'Không có tên',
                          style: GoogleFonts.poppins(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blue),
                        onPressed: () => _showEditLocationDialog(location),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed:
                            () => _confirmDeleteLocation(
                              location['_id'],
                              location['name'] ?? 'Không có tên',
                            ),
                      ),
                    ],
                  ),
                  const Divider(),
                  if (location['description'] != null &&
                      location['description'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Mô tả: ${location['description']}',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  if (location['contact_phone'] != null &&
                      location['contact_phone'].isNotEmpty)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Liên hệ: ${location['contact_phone']}',
                        style: GoogleFonts.poppins(),
                      ),
                    ),
                  if (location['createdAt'] != null)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Ngày tạo: ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.parse(location['createdAt']))}',
                        style: GoogleFonts.poppins(
                          fontSize: 12,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
