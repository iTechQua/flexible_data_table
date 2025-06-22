import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flexible_data_table/flexible_data_table.dart'; // Assuming the package is imported

class UserModel {
  final int id;
  final String name;
  final String mobileNumber;
  final String email;
  final bool isActive;
  final DateTime registrationDate;

  UserModel({
    required this.id,
    required this.name,
    required this.mobileNumber,
    required this.email,
    required this.isActive,
    required this.registrationDate,
  });

  Map<String, dynamic> toTableDataMap() {
    return {
      'ID': id,
      'Name': name,
      'Mobile Number': mobileNumber,
      'Email': email,
      'Status': isActive ? 'Active' : 'Inactive',
      'Created At': registrationDate,
    };
  }
}

class UserTableExample extends StatelessWidget {
  final List<UserModel> users = [
    UserModel(
      id: 1,
      name: 'John Doe',
      mobileNumber: '1234567890',
      email: 'john@example.com',
      isActive: true,
      registrationDate: DateTime.now().subtract(Duration(days: 1)),
    ),
    UserModel(
      id: 2,
      name: 'Jane Smith',
      mobileNumber: '0987654321',
      email: 'jane@example.com',
      isActive: false,
      registrationDate: DateTime.now().subtract(Duration(days: 2)),
    ),
    // Add more users here
  ];

  UserTableExample({super.key});

  void onEdit(UserModel user) {
    print('Edit user: ${user.name}');
  }

  void onToggleStatus(UserModel user) {
    print('Toggle status for user: ${user.name}');
  }

  void onAddUser() {
    print('Add new user');
  }

  Widget _heading(bool isDark, Color primaryColor) {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Text(
            'All Users',
            style: GoogleFonts.poppins(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const Spacer(),
          Padding(
            padding: const EdgeInsets.only(right: 8.0),
            child: ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: primaryColor),
              onPressed: onAddUser,
              child: Text(
                'Add New user',
                style: GoogleFonts.poppins(fontSize: 12, color: Colors.white),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required Color color,
    required String tooltip,
    required VoidCallback onPressed,
  }) {
    return IconButton(
      icon: Icon(icon, size: 20, color: color),
      tooltip: tooltip,
      onPressed: onPressed,
      constraints: const BoxConstraints(
        minWidth: 40,
        minHeight: 40,
      ),
      padding: EdgeInsets.zero,
    );
  }

  @override
  Widget build(BuildContext context) {
    final bool isDark = Theme.of(context).brightness == Brightness.dark;
    final Color primaryColor = Theme.of(context).primaryColor;

    return Scaffold(
      appBar: AppBar(title: Text('Custom Data Table Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: SizedBox(
          height: 550,
          child: FlexibleDataTable<UserModel>(
            heading: _heading(isDark, primaryColor),
            isServerSide: false,
            data: users,
            fileName: 'User List',
            toTableDataMap: (UserModel user) => user.toTableDataMap(),
            cellBuilders: {
              'Status': (value, UserModel user) => Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: user.isActive ? Colors.green.withOpacity(0.1) : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: user.isActive ? Colors.green : Colors.red,
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      user.isActive ? Icons.check_circle : Icons.cancel_outlined,
                      size: 16,
                      color: user.isActive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      value.toString(),
                      style: GoogleFonts.poppins(
                        fontSize: 12,
                        color: user.isActive ? Colors.green : Colors.red,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              'Created At': (value, UserModel user) => Text(user.registrationDate.toString(),
                style: GoogleFonts.poppins(fontSize: 13),
              ),
            },
            columnSizes: {
              'ID': 60,
              'Name': 150.0,
              'Mobile Number': 150.0,
              'Email': 200.0,
              'Status': 120.0,
              'Created At': 180.0,
            },
            // Optional: Use columnFlex instead of columnSizes for flexible widths
            // columnFlex: {
            //   'ID': 1,
            //   'Name': 2,
            //   'Mobile Number': 2,
            //   'Email': 3,
            //   'Status': 1,
            //   'Created At': 2,
            // },
            actionBuilder: (UserModel user) => SizedBox(
              width: 120,
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _buildActionButton(
                    icon: Icons.edit,
                    color: Colors.deepPurple,
                    tooltip: 'Edit User',
                    onPressed: () => onEdit(user),
                  ),
                  _buildActionButton(
                    icon: user.isActive ? Icons.block_outlined : Icons.check_circle_outline,
                    color: user.isActive ? Colors.red : Colors.green,
                    tooltip: user.isActive ? 'Deactivate User' : 'Activate User',
                    onPressed: () => onToggleStatus(user),
                  ),
                ],
              ),
            ),
            customHeaderBuilders: {
              'Status': (columnName) => Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.toggle_on_outlined,
                    size: 16,
                    color: Colors.white,
                  ),
                  const SizedBox(width: 4),
                  Flexible(
                    child: Text(
                      columnName,
                      style: GoogleFonts.poppins(
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                        color: Colors.white,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            },
            minWidth: 1170,
            headerColor: const Color(0xFF6D28D9),
            rowHeight: 30,
            headerHeight: 40,
            actionColumnWidth: 100,
            actionColumnName: 'Actions',
            loader: CircularProgressIndicator(),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(
    debugShowCheckedModeBanner: false,
    theme: ThemeData.light(),
    darkTheme: ThemeData.dark(),
    home: UserTableExample(),
  ));
}
