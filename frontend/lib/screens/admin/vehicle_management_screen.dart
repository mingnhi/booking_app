import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:frontend/models/vehicle.dart';

class VehicleManagementScreen extends StatefulWidget {
  const VehicleManagementScreen({Key? key}) : super(key: key);

  @override
  _VehicleManagementScreenState createState() =>
      _VehicleManagementScreenState();
}

class _VehicleManagementScreenState extends State<VehicleManagementScreen> {
  List<Vehicle> vehicles = [];
  bool isLoading = true;
  String searchQuery = '';
  final TextEditingController _searchController = TextEditingController();
  final TextEditingController _licensePlateController = TextEditingController();
  final TextEditingController _descriptionController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _loadVehicles();
  }

  @override
  void dispose() {
    _searchController.dispose();
    _licensePlateController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _loadVehicles() async {
    setState(() {
      isLoading = true;
    });

    try {
      final adminService = Provider.of<AdminService>(context, listen: false);
      final fetchedVehicles = await adminService.getVehicles();
      setState(() {
        vehicles = fetchedVehicles.map((v) => Vehicle.fromJson(v)).toList();
        isLoading = false;
      });
    } catch (e) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Lỗi khi tải danh sách xe: $e')));
      setState(() {
        isLoading = false;
      });
    }
  }

  List<Vehicle> get filteredVehicles {
    if (searchQuery.isEmpty) return vehicles;
    return vehicles.where((vehicle) {
      final licensePlate = vehicle.licensePlate.toLowerCase();
      final description = vehicle.description.toLowerCase();
      final searchLower = searchQuery.toLowerCase();
      return licensePlate.contains(searchLower) ||
          description.contains(searchLower);
    }).toList();
  }

  Future<void> _showAddEditDialog([Vehicle? vehicle]) async {
    if (vehicle != null) {
      _licensePlateController.text = vehicle.licensePlate;
      _descriptionController.text = vehicle.description;
    } else {
      _licensePlateController.clear();
      _descriptionController.clear();
    }

    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              vehicle == null ? 'Thêm xe mới' : 'Chỉnh sửa xe',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextFormField(
                    controller: _licensePlateController,
                    decoration: InputDecoration(
                      labelText: 'Biển số xe',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập biển số xe';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _descriptionController,
                    decoration: InputDecoration(
                      labelText: 'Mô tả',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Vui lòng nhập mô tả';
                      }
                      return null;
                    },
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () async {
                  if (_formKey.currentState!.validate()) {
                    try {
                      final adminService = Provider.of<AdminService>(
                        context,
                        listen: false,
                      );
                      if (vehicle == null) {
                        await adminService.createVehicle({
                          'license_plate': _licensePlateController.text,
                          'description': _descriptionController.text,
                        });
                      } else {
                        await adminService.updateVehicle(vehicle.id, {
                          'license_plate': _licensePlateController.text,
                          'description': _descriptionController.text,
                        });
                      }
                      Navigator.pop(context);
                      _loadVehicles();
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            vehicle == null
                                ? 'Thêm xe thành công'
                                : 'Cập nhật xe thành công',
                          ),
                        ),
                      );
                    } catch (e) {
                      ScaffoldMessenger.of(
                        context,
                      ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                    }
                  }
                },
                child: Text(
                  vehicle == null ? 'Thêm' : 'Cập nhật',
                  style: GoogleFonts.poppins(),
                ),
              ),
            ],
          ),
    );
  }

  Future<void> _showDeleteConfirmation(Vehicle vehicle) async {
    return showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
            title: Text(
              'Xác nhận xóa',
              style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
            ),
            content: Text(
              'Bạn có chắc chắn muốn xóa xe ${vehicle.licensePlate}?',
              style: GoogleFonts.poppins(),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text('Hủy', style: GoogleFonts.poppins()),
              ),
              ElevatedButton(
                onPressed: () async {
                  try {
                    final adminService = Provider.of<AdminService>(
                      context,
                      listen: false,
                    );
                    await adminService.deleteVehicle(vehicle.id);
                    Navigator.pop(context);
                    _loadVehicles();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Xóa xe thành công')),
                    );
                  } catch (e) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(SnackBar(content: Text('Lỗi: $e')));
                  }
                },
                style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
                child: Text('Xóa', style: GoogleFonts.poppins()),
              ),
            ],
          ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.directions_bus, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Chưa có xe nào',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVehicleList() {
    return RefreshIndicator(
      onRefresh: _loadVehicles,
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: filteredVehicles.length,
        itemBuilder: (context, index) {
          final vehicle = filteredVehicles[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 16),
            child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.directions_bus)),
              title: Text(
                vehicle.licensePlate,
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              subtitle: Text(vehicle.description, style: GoogleFonts.poppins()),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit),
                    onPressed: () => _showAddEditDialog(vehicle),
                    tooltip: 'Chỉnh sửa',
                  ),
                  IconButton(
                    icon: const Icon(Icons.delete),
                    onPressed: () => _showDeleteConfirmation(vehicle),
                    tooltip: 'Xóa',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Quản lý xe',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadVehicles,
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
                        hintText: 'Tìm kiếm theo biển số hoặc mô tả',
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
                        filteredVehicles.isEmpty
                            ? _buildEmptyState()
                            : _buildVehicleList(),
                  ),
                ],
              ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddEditDialog(),
        child: const Icon(Icons.add),
        tooltip: 'Thêm xe mới',
      ),
    );
  }
}
