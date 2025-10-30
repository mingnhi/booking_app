import 'package:flutter/material.dart';
import 'package:frontend/services/admin_service.dart';
import 'package:provider/provider.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

class UserManagementScreen extends StatefulWidget {
  const UserManagementScreen({super.key});

  @override
  _UserManagementScreenState createState() => _UserManagementScreenState();
}

class _UserManagementScreenState extends State<UserManagementScreen> {
  List<dynamic> users = [];
  bool isLoading = true;
  String searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadUsers();
  }

  Future<void> _loadUsers() async {
    final adminService = Provider.of<AdminService>(context, listen: false);
    final fetchedUsers = await adminService.getUsers();
    setState(() {
      users = fetchedUsers;
      isLoading = false;
    });
  }

  List<dynamic> get filteredUsers {
    if (searchQuery.isEmpty) {
      return users;
    }
    return users.where((user) {
      final username = user['username']?.toString().toLowerCase() ?? '';
      final email = user['email']?.toString().toLowerCase() ?? '';
      final fullName = user['full_name']?.toString().toLowerCase() ?? '';
      final query = searchQuery.toLowerCase();
      return username.contains(query) ||
          email.contains(query) ||
          fullName.contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              decoration: InputDecoration(
                hintText: 'Tìm kiếm người dùng...',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                contentPadding: const EdgeInsets.symmetric(vertical: 0),
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
            isLoading
                ? const Center(child: CircularProgressIndicator())
                : users.isEmpty
                ? _buildEmptyState()
                : _buildUserList(),
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
          const Icon(Icons.people_outline, size: 80, color: Colors.grey),
          const SizedBox(height: 16),
          Text(
            'Chưa có người dùng nào',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserList() {
    final currentUsers = filteredUsers;

    if (currentUsers.isEmpty) {
      return Center(
        child: Text(
          'Không tìm thấy người dùng phù hợp',
          style: GoogleFonts.poppins(fontSize: 16),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: _loadUsers,
      child: ListView.builder(
        itemCount: currentUsers.length,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemBuilder: (context, index) {
          final user = currentUsers[index];
          final createdAt =
          user['createdAt'] != null
              ? DateTime.parse(user['createdAt'])
              : null;

          return Card(
            elevation: 2,
            margin: const EdgeInsets.only(bottom: 16),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        child: Text(
                          (user['full_name'] ?? user['username'] ?? 'U')[0]
                              .toUpperCase(),
                          style: GoogleFonts.poppins(
                            color: Colors.blue,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              user['full_name'] ?? 'Chưa cập nhật',
                              style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                            Text(
                              '@${user['username']}',
                              style: GoogleFonts.poppins(
                                fontSize: 14,
                                color: Colors.grey,
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color:
                          user['role'] == 'admin'
                              ? Colors.purple
                              : Colors.blue,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          user['role'] == 'admin' ? 'Admin' : 'User',
                          style: GoogleFonts.poppins(
                            color: Colors.white,
                            fontSize: 12,
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      PopupMenuButton(
                        itemBuilder:
                            (context) => [
                          const PopupMenuItem(
                            value: 'view',
                            child: Row(
                              children: [
                                Icon(Icons.visibility, color: Colors.blue),
                                SizedBox(width: 8),
                                Text('Xem chi tiết'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'edit',
                            child: Row(
                              children: [
                                Icon(Icons.edit, color: Colors.orange),
                                SizedBox(width: 8),
                                Text('Chỉnh sửa'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'block',
                            child: Row(
                              children: [
                                Icon(Icons.block, color: Colors.red),
                                SizedBox(width: 8),
                                Text('Khóa tài khoản'),
                              ],
                            ),
                          ),
                          const PopupMenuItem(
                            value: 'delete',
                            child: Row(
                              children: [
                                Icon(
                                  Icons.delete_forever,
                                  color: Colors.red,
                                ),
                                SizedBox(width: 8),
                                Text('Xóa người dùng'),
                              ],
                            ),
                          ),
                        ],
                        onSelected: (value) {
                          if (value == 'view') {
                            _showUserDetails(context, user);
                          } else if (value == 'edit') {
                            _showEditUserForm(context, user);
                          } else if (value == 'block') {
                            _showBlockConfirmation(context, user['_id']);
                          } else if (value == 'delete') {
                            _showDeleteConfirmation(
                              context,
                              user['_id'],
                              user['full_name'],
                            );
                          }
                        },
                      ),
                    ],
                  ),
                  const Divider(height: 24),
                  _buildInfoRow(
                    Icons.email,
                    user['email'] ?? 'Chưa cập nhật email',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.phone,
                    user['phone_number'] ?? 'Chưa cập nhật số điện thoại',
                  ),
                  const SizedBox(height: 8),
                  _buildInfoRow(
                    Icons.calendar_today,
                    createdAt != null
                        ? 'Tham gia: ${DateFormat('dd/MM/yyyy').format(createdAt)}'
                        : 'Ngày tham gia không xác định',
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.poppins(fontSize: 14),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  void _showUserDetails(BuildContext context, dynamic user) {
    final createdAt =
    user['created_at'] != null ? DateTime.parse(user['created_at']) : null;

    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text(
          'Thông tin người dùng',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: CircleAvatar(
                  radius: 40,
                  backgroundColor: Colors.blue.shade100,
                  child: Text(
                    (user['full_name'] != null &&
                        user['full_name'].toString().isNotEmpty)
                        ? user['full_name'][0].toUpperCase()
                        : '?',
                    style: GoogleFonts.poppins(
                      color: Colors.blue,
                      fontWeight: FontWeight.bold,
                      fontSize: 30,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _buildDetailRow(
                'Họ tên',
                user['full_name'] ?? 'Chưa cập nhật',
              ),
              // _buildDetailRow('Tên đăng nhập', user['username']),
              _buildDetailRow('Email', user['email'] ?? 'Chưa cập nhật'),
              _buildDetailRow(
                'Số điện thoại',
                user['phone_number'] ?? 'Chưa cập nhật',
              ),
              _buildDetailRow(
                'Vai trò',
                user['role'] == 'admin' ? 'Admin' : 'Người dùng',
              ),
              _buildDetailRow(
                'Ngày tham gia',
                createdAt != null
                    ? DateFormat('dd/MM/yyyy').format(createdAt)
                    : 'Không xác định',
              ),
              // _buildDetailRow(
              //   'Trạng thái',
              //   user['isBlocked'] ? 'Đã khóa' : 'Đang hoạt động',
              // ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Đóng', style: GoogleFonts.poppins()),
          ),
        ],
      ),
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: GoogleFonts.poppins(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 4),
          Text(value, style: GoogleFonts.poppins(fontSize: 16)),
          const Divider(),
        ],
      ),
    );
  }

  void _showEditUserForm(BuildContext context, dynamic user) {
    final formKey = GlobalKey<FormState>();

    final fullNameController = TextEditingController(
      text: user['full_name'] ?? '',
    );
    final emailController = TextEditingController(text: user['email'] ?? '');
    final phoneController = TextEditingController(
      text: user['phone_number'] ?? '',
    );
    String role = user['role'] ?? 'user';

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setState) {
            return AlertDialog(
              title: Text(
                'Chỉnh sửa người dùng',
                style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
              ),
              content: Form(
                key: formKey,
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextFormField(
                        controller: fullNameController,
                        decoration: const InputDecoration(
                          labelText: 'Họ tên',
                          prefixIcon: Icon(Icons.person),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập họ tên';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: emailController,
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return 'Vui lòng nhập email';
                          }
                          if (!value.contains('@')) {
                            return 'Email không hợp lệ';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      TextFormField(
                        controller: phoneController,
                        decoration: const InputDecoration(
                          labelText: 'Số điện thoại',
                          prefixIcon: Icon(Icons.phone),
                        ),
                      ),
                      const SizedBox(height: 16),
                      DropdownButtonFormField<String>(
                        value: role,
                        decoration: const InputDecoration(
                          labelText: 'Vai trò',
                          prefixIcon: Icon(Icons.admin_panel_settings),
                        ),
                        items: const [
                          DropdownMenuItem(
                            value: 'user',
                            child: Text('Người dùng'),
                          ),
                          DropdownMenuItem(
                            value: 'admin',
                            child: Text('Admin'),
                          ),
                        ],
                        onChanged: (value) {
                          if (value != null) {
                            setState(() {
                              role = value;
                            });
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                  child: Text('Hủy', style: GoogleFonts.poppins()),
                ),
                ElevatedButton(
                  onPressed: () async {
                    if (formKey.currentState!.validate()) {
                      Navigator.of(
                        context,
                      ).pop(); // Đóng dialog trước khi gọi API

                      final updatedUser = <String, dynamic>{
                        '_id': user['_id'],
                        'full_name': fullNameController.text.trim(),
                        'email': emailController.text.trim(),
                        'phone_number': phoneController.text.trim(),
                        'role': role,
                      };

                      try {
                        final adminService = Provider.of<AdminService>(
                          context,
                          listen: false,
                        );
                        await adminService.updateUser(updatedUser);
                        await _loadUsers();

                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cập nhật thông tin người dùng thành công',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.green,
                          ),
                        );
                      } catch (e) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              'Cập nhật thất bại: $e',
                              style: GoogleFonts.poppins(),
                            ),
                            backgroundColor: Colors.red,
                          ),
                        );
                      }
                    }
                  },
                  child: Text('Cập nhật', style: GoogleFonts.poppins()),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showBlockConfirmation(BuildContext context, String userId) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text(
          'Xác nhận khóa tài khoản',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn khóa tài khoản này không? Người dùng sẽ không thể đăng nhập cho đến khi được mở khóa.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Hủy', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () {
              // Khóa tài khoản người dùng
              Navigator.of(context).pop();
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Đã khóa tài khoản người dùng',
                    style: GoogleFonts.poppins(),
                  ),
                  backgroundColor: Colors.orange,
                ),
              );
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Khóa tài khoản',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  void _showDeleteConfirmation(
      BuildContext context,
      String userId,
      String username,
      ) {
    showDialog(
      context: context,
      builder:
          (context) => AlertDialog(
        title: Text(
          'Xác nhận xóa người dùng',
          style: GoogleFonts.poppins(fontWeight: FontWeight.bold),
        ),
        content: Text(
          'Bạn có chắc chắn muốn xóa người dùng "$username"? Hành động này không thể hoàn tác.',
          style: GoogleFonts.poppins(),
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: Text('Hủy', style: GoogleFonts.poppins()),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(context).pop();
              try {
                setState(() {
                  isLoading = true;
                });
                final adminService = Provider.of<AdminService>(
                  context,
                  listen: false,
                );
                await adminService.deleteUser(userId);

                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Đã xóa người dùng thành công',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.green,
                  ),
                );

                await _loadUsers();
              } catch (e) {
                setState(() {
                  isLoading = false;
                });
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      'Lỗi khi xóa người dùng: $e',
                      style: GoogleFonts.poppins(),
                    ),
                    backgroundColor: Colors.red,
                  ),
                );
              }
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: Text(
              'Xóa',
              style: GoogleFonts.poppins(color: Colors.white),
            ),
          ),
        ],
      ),
    );
  }
}
