import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'dart:math' as math;
import '../../constants/colors.dart';
import '../../widgets/cards/admin_user_stat_card.dart';
import '../../core/widgets/modern_scaffold.dart';
import '../../core/widgets/adaptive_navigation.dart';

// Extended User Model
class User {
  final String id;
  String name;
  String email;
  String role;
  String status;
  String lastActive;
  String? avatar; // Made nullable for easier default handling
  String contactNumber;
  String department;
  List<String> permissions;

  User({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.status,
    required this.lastActive,
    this.avatar,
    this.contactNumber = '',
    this.department = '',
    this.permissions = const [],
  });

  User copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? status,
    String? lastActive,
    String? avatar,
    String? contactNumber,
    String? department,
    List<String>? permissions,
  }) {
    return User(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      status: status ?? this.status,
      lastActive: lastActive ?? this.lastActive,
      avatar: avatar ?? this.avatar,
      contactNumber: contactNumber ?? this.contactNumber,
      department: department ?? this.department,
      permissions: permissions ?? this.permissions,
    );
  }
}

class UsersScreen extends StatefulWidget {
  const UsersScreen({super.key});

  @override
  State<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends State<UsersScreen> with TickerProviderStateMixin {
  int _selectedNavIndex = 1;
  bool _isDark = false;
  bool get isDark => _isDark;
  final TextEditingController _searchController = TextEditingController();

  late TabController _insightsTabController; // Controller for the new insights tabs
  late TabController _editUserTabController; // Controller for the edit user dialog tabs

  int currentPage = 1;
  int itemsPerPage = 10;

  List<User> users = [
    User(
      id: '1',
      name: 'John Smith',
      email: 'john@example.com',
      role: 'Admin',
      status: 'Active',
      lastActive: '2 hours ago',
      avatar:
          'https://th.bing.com/th/id/OIP.Zvs5IHgOO5kip7A32UwZJgHaHa?rs=1&pid=ImgDetMain', // Sample avatar
      contactNumber: '+1 (555) 123-4567',
      department: 'IT',
      permissions: ['Manage Users', 'View Reports', 'Edit Settings'],
    ),
    User(
      id: '2',
      name: 'Sarah Johnson',
      email: 'sarah@example.com',
      role: 'Manager',
      status: 'Active',
      lastActive: '5 hours ago',
      avatar: 'https://i.pravatar.cc/150?img=47', // Sample avatar
      contactNumber: '+1 (555) 987-6543',
      department: 'Operations',
      permissions: ['View Reports', 'Manage Devices'],
    ),
    User(
      id: '3',
      name: 'David Kimani',
      email: 'david@example.com',
      role: 'Technician',
      status: 'Inactive',
      lastActive: '2 days ago',
      avatar: 'https://i.pravatar.cc/150?img=12', // Sample avatar
      contactNumber: '+254 712 345 678',
      department: 'Field',
      permissions: ['Maintain Equipment'],
    ),
    User(
      id: '4',
      name: 'Grace Omondi',
      email: 'grace@example.com',
      role: 'Viewer',
      status: 'Active',
      lastActive: '30 minutes ago',
      avatar: 'https://i.pravatar.cc/150?img=33', // Sample avatar
      contactNumber: '+254 723 456 789',
      department: 'Support',
      permissions: ['View Reports'],
    ),
    User(
      id: '5',
      name: 'Michael Brown',
      email: 'michael@example.com',
      role: 'Viewer',
      status: 'Active',
      lastActive: '1 hour ago',
      avatar: 'https://i.pravatar.cc/150?img=14',
      contactNumber: '+1 (555) 111-2222',
      department: 'Support',
      permissions: ['View Reports'],
    ),
    User(
      id: '6',
      name: 'Emily Davis',
      email: 'emily@example.com',
      role: 'Admin',
      status: 'Active',
      lastActive: '10 minutes ago',
      avatar: 'https://i.pravatar.cc/150?img=50',
      contactNumber: '+1 (555) 333-4444',
      department: 'IT',
      permissions: ['Manage Users', 'Edit Settings'],
    ),
    User(
      id: '7',
      name: 'Aisha Bello',
      email: 'aisha@example.com',
      role: 'Manager',
      status: 'Active',
      lastActive: '15 minutes ago',
      avatar: 'https://i.pravatar.cc/150?img=55',
      contactNumber: '+234 701 234 5678',
      department: 'Logistics',
      permissions: ['Manage Devices', 'View Reports'],
    ),
    User(
      id: '8',
      name: 'Carlos Ramirez',
      email: 'carlos@example.com',
      role: 'Technician',
      status: 'Inactive',
      lastActive: '3 days ago',
      avatar: 'https://i.pravatar.cc/150?img=22',
      contactNumber: '+57 321 456 7890',
      department: 'Field',
      permissions: ['Maintain Equipment'],
    ),
    User(
      id: '9',
      name: 'Linda Cheng',
      email: 'linda@example.com',
      role: 'Admin',
      status: 'Active',
      lastActive: '25 minutes ago',
      avatar: 'https://i.pravatar.cc/150?img=30',
      contactNumber: '+1 (555) 666-7777',
      department: 'IT',
      permissions: ['Manage Users', 'View Reports', 'Edit Settings'],
    ),
    User(
      id: '10',
      name: 'Nathan Lee',
      email: 'nathan@example.com',
      role: 'Viewer',
      status: 'Active',
      lastActive: '1 hour ago',
      avatar: 'https://i.pravatar.cc/150?img=31',
      contactNumber: '+1 (555) 444-3333',
      department: 'Finance',
      permissions: ['View Reports'],
    ),
    User(
      id: '11',
      name: 'Fatima Yusuf',
      email: 'fatima@example.com',
      role: 'Manager',
      status: 'Active',
      lastActive: '2 hours ago',
      avatar: 'https://i.pravatar.cc/150?img=28',
      contactNumber: '+254 733 999 888',
      department: 'Procurement',
      permissions: ['Manage Devices', 'View Reports'],
    ),
    User(
      id: '12',
      name: 'Jason Clark',
      email: 'jason@example.com',
      role: 'Technician',
      status: 'Inactive',
      lastActive: '1 week ago',
      avatar: 'https://i.pravatar.cc/150?img=41',
      contactNumber: '+1 (555) 777-8888',
      department: 'Maintenance',
      permissions: ['Maintain Equipment'],
    ),
  ];

  List<User> filteredUsers = [];
  String _selectedRoleFilter = 'All Users';

  final List<String> _availablePermissions = [
    'Manage Users',
    'Manage Farms',
    'View Reports',
    'View Alerts',
    'Edit Settings',
    'Access Logs',
    'Configure Alerts',
  ];

  @override
  void initState() {
    super.initState();
    filteredUsers = users;
    _searchController.addListener(_filterUsers);
    _insightsTabController =
        TabController(length: 2, vsync: this); // Initialize insights tab controller
    _editUserTabController =
        TabController(length: 2, vsync: this); // Initialize edit user tab controller
  }

  @override
  void dispose() {
    _searchController.dispose();
    _insightsTabController.dispose(); // Dispose insights tab controller
    _editUserTabController.dispose(); // Dispose edit user tab controller
    super.dispose();
  }

  void _filterUsers() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      filteredUsers = users.where((user) {
        final matchesSearch = user.name.toLowerCase().contains(query) ||
            user.email.toLowerCase().contains(query) ||
            user.role.toLowerCase().contains(query);
        final matchesRole = _selectedRoleFilter == 'All Users' || user.role == _selectedRoleFilter;
        return matchesSearch && matchesRole;
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;
    final theme = Theme.of(context);
    _isDark = theme.brightness == Brightness.dark;
    final textColor = _isDark ? AppColors.darkText : AppColors.text;
    final cardColor = _isDark ? AppColors.darkCard : AppColors.card;
    final secondaryTextColor =
        _isDark ? Colors.white.withOpacity(0.7) : Colors.black.withOpacity(0.6);

    final navigationItems = [
      NavigationItem(
        label: 'Dashboard',
        icon: Icons.dashboard_outlined,
        selectedIcon: Icons.dashboard,
        onTap: () {
          if (_selectedNavIndex != 0) {
            setState(() => _selectedNavIndex = 0);
            Navigator.pushNamed(context, '/dashboard');
          }
        },
      ),
      NavigationItem(
        label: 'Users',
        icon: Icons.people_outline,
        selectedIcon: Icons.people,
        onTap: () {
          if (_selectedNavIndex != 1) {
            setState(() => _selectedNavIndex = 1);
            Navigator.pushNamed(context, '/users');
          }
        },
      ),
      NavigationItem(
        label: 'Farms',
        icon: Icons.agriculture_outlined,
        selectedIcon: Icons.agriculture,
        onTap: () {
          if (_selectedNavIndex != 2) {
            setState(() => _selectedNavIndex = 2);
            Navigator.pushNamed(context, '/farms');
          }
        },
      ),
      NavigationItem(
        label: 'Sensors',
        icon: Icons.sensors_outlined,
        selectedIcon: Icons.sensors,
        onTap: () {
          if (_selectedNavIndex != 3) {
            setState(() => _selectedNavIndex = 3);
            Navigator.pushNamed(context, '/sensors');
          }
        },
      ),
      NavigationItem(
        label: 'Settings',
        icon: Icons.settings_outlined,
        selectedIcon: Icons.settings,
        onTap: () {
          if (_selectedNavIndex != 4) {
            setState(() => _selectedNavIndex = 4);
            Navigator.pushNamed(context, '/settings');
          }
        },
      ),
    ];

    return ModernScaffold(
      title: 'User Management',
      navigationItems: navigationItems,
      selectedNavigationIndex: _selectedNavIndex,
      body: SingleChildScrollView(
        child: Padding(
          padding: EdgeInsets.symmetric(
            horizontal: isMobile ? 16 : 32,
            vertical: 20,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeaderSection(isMobile, textColor),
              const SizedBox(height: 24),
              _buildStatsSection(isMobile),
              const SizedBox(height: 28),
              isMobile
                  ? Column(
                      children: [
                        _buildSearchAndFilter(cardColor, secondaryTextColor, textColor),
                        const SizedBox(height: 22),
                        _buildUsersTable(isMobile, cardColor, textColor, secondaryTextColor),
                        const SizedBox(height: 28),
                        _buildUserLogsCard(cardColor, textColor, secondaryTextColor),
                      ],
                    )
                  : Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          flex: 3,
                          child: Column(
                            children: [
                              _buildSearchAndFilter(cardColor, secondaryTextColor, textColor),
                              const SizedBox(height: 22),
                              _buildUsersTable(isMobile, cardColor, textColor, secondaryTextColor),
                            ],
                          ),
                        ),
                        const SizedBox(width: 28),
                        Expanded(
                          child: _buildUserLogsCard(cardColor, textColor, secondaryTextColor),
                        ),
                      ],
                    ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildHeaderSection(bool isMobile, Color textColor) {
    return Row(
      children: [
        Expanded(
          child: Text(
            'User Management',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddUserDialog,
          icon: const Icon(Icons.person_add_alt_1_rounded, size: 20),
          label: Text(isMobile ? 'Add' : 'Add User'),
          style: ElevatedButton.styleFrom(
            backgroundColor: AppColors.primary,
            foregroundColor: Colors.white,
            padding: EdgeInsets.symmetric(
              horizontal: isMobile ? 16 : 20,
              vertical: 14,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            textStyle: GoogleFonts.poppins(
              fontWeight: FontWeight.w600,
              fontSize: isMobile ? 14 : 15,
              letterSpacing: 0.2,
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(bool isMobile) {
    final totalUsers = users.length;
    final activeUsers = users.where((user) => user.status == 'Active').length;
    final inactiveUsers = users.where((user) => user.status == 'Inactive').length;

    return isMobile
        ? Column(
            children: [
              AdminUserStatCard(
                title: "Total Users",
                value: totalUsers.toString(),
                change: "+12%", // Placeholder
                isPositive: true,
                icon: Icons.people_alt_rounded,
                iconColor: Colors.green[600]!,
                isDark: _isDark,
              ),
              const SizedBox(height: 12),
              AdminUserStatCard(
                title: "Active Today",
                value: activeUsers.toString(),
                change: "+5%", // Placeholder
                isPositive: true,
                icon: Icons.check_circle_rounded,
                iconColor: Colors.deepPurple,
                isDark: _isDark,
              ),
              const SizedBox(height: 12),
              AdminUserStatCard(
                title: "Inactive Users",
                value: inactiveUsers.toString(),
                change: "-2%", // Placeholder
                isPositive: false,
                icon: Icons.remove_circle_outline,
                iconColor: Colors.orange,
                isDark: _isDark,
              ),
            ],
          )
        : Row(
            children: [
              Expanded(
                child: AdminUserStatCard(
                  title: "Total Users",
                  value: totalUsers.toString(),
                  change: "+12%",
                  isPositive: true,
                  icon: Icons.people_alt_rounded,
                  iconColor: Colors.green[600]!,
                  isDark: _isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminUserStatCard(
                  title: "Active Today",
                  value: activeUsers.toString(),
                  change: "+5%",
                  isPositive: true,
                  icon: Icons.check_circle_rounded,
                  iconColor: Colors.deepPurple,
                  isDark: _isDark,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: AdminUserStatCard(
                  title: "Inactive Users",
                  value: inactiveUsers.toString(),
                  change: "-2%",
                  isPositive: false,
                  icon: Icons.remove_circle_outline,
                  iconColor: Colors.orange,
                  isDark: _isDark,
                ),
              ),
            ],
          );
  }

  // Widget for User Logs Card (now separate from insights section)
  Widget _buildUserLogsCard(Color cardColor, Color textColor, Color secondaryTextColor) {
    return Card(
      color: cardColor,
      elevation: 5,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
      child: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Recent User Logs',
              style: GoogleFonts.inter(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: textColor,
              ),
            ),
            const Divider(height: 25, thickness: 1),
            // Placeholder for log entries
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildLogEntry(
                    'Admin John Smith logged in', '2024-06-21 14:30', secondaryTextColor),
                _buildLogEntry('Manager Sarah Johnson updated settings', '2024-06-21 13:15',
                    secondaryTextColor),
                _buildLogEntry('Technician David Kimani accessed device X', '2024-06-20 10:00',
                    secondaryTextColor),
                _buildLogEntry(
                    'Viewer Grace Omondi viewed reports', '2024-06-20 09:45', secondaryTextColor),
              ],
            ),
            const SizedBox(height: 10),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton(
                onPressed: () {
                  // TODO: Implement view all logs functionality
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Viewing all user logs...')),
                  );
                },
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  textStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
                ),
                child: const Text('View All Logs'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Helper widget for a single log entry
  Widget _buildLogEntry(String action, String timestamp, Color secondaryTextColor) {
    final isDark = _isDark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.history, size: 18, color: AppColors.primary.withOpacity(0.7)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  action,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white70 : Colors.black87,
                    fontSize: 13,
                  ),
                ),
                Text(
                  timestamp,
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.grey[500] : Colors.grey[600],
                    fontSize: 11,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(Color cardColor, Color secondaryTextColor, Color textColor) {
    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.12 : 0.04),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 2),
        child: Row(
          children: [
            Icon(Icons.search, color: secondaryTextColor),
            const SizedBox(width: 6),
            Expanded(
              child: TextField(
                controller: _searchController,
                onChanged: (_) => _filterUsers(),
                decoration: InputDecoration(
                  hintText: 'Search users',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(
                    color: secondaryTextColor,
                  ),
                ),
                style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
              ),
            ),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 8),
              height: 28,
              width: 1.5,
              color: secondaryTextColor.withOpacity(0.4),
            ),
            PopupMenuButton<String>(
              icon: Icon(Icons.filter_list_rounded, color: secondaryTextColor),
              initialValue: _selectedRoleFilter,
              onSelected: (String value) {
                setState(() {
                  _selectedRoleFilter = value;
                  _filterUsers();
                });
              },
              itemBuilder: (context) => <String>[
                'All Users',
                'Admin',
                'Manager',
                'Technician',
                'Viewer'
              ].map((String choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(
                    choice,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight:
                          _selectedRoleFilter == choice ? FontWeight.bold : FontWeight.normal,
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildUsersTable(
      bool isMobile, Color cardColor, Color textColor, Color secondaryTextColor) {
    final dividerColor = isDark ? Colors.white.withOpacity(0.09) : Colors.black.withOpacity(0.06);

    // Calculate paginated data
    final totalItems = filteredUsers.length;
    final totalPages = (totalItems / itemsPerPage).ceil();
    final startIndex = (currentPage - 1) * itemsPerPage;
    final endIndex =
        startIndex + itemsPerPage > totalItems ? totalItems : startIndex + itemsPerPage;
    final paginatedUsers = filteredUsers.sublist(startIndex, endIndex);

    return Container(
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.10 : 0.03),
            blurRadius: 14,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          // Table Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
            child: Row(
              children: [
                Expanded(
                  flex: 2,
                  child: Text('User',
                      style: GoogleFonts.inter(
                        fontWeight: FontWeight.w700,
                        color: secondaryTextColor,
                        letterSpacing: 0.2,
                        fontSize: 14,
                      )),
                ),
                if (!isMobile) ...[
                  Expanded(
                    child: Text('Role',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                          fontSize: 13,
                        )),
                  ),
                  Expanded(
                    child: Text('Status',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                          fontSize: 13,
                        )),
                  ),
                  Expanded(
                    child: Text('Last Active',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                          fontSize: 13,
                        )),
                  ),
                  Expanded(
                    child: Text('Department',
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w700,
                          color: secondaryTextColor,
                          fontSize: 13,
                        )),
                  ),
                ],
                const SizedBox(width: 50),
              ],
            ),
          ),
          Divider(height: 1, color: dividerColor, thickness: 1),

          // User Rows
          ...paginatedUsers
              .map((user) => _buildUserRow(user, isMobile, textColor, secondaryTextColor)),

          if (filteredUsers.isEmpty)
            Padding(
              padding: const EdgeInsets.all(24.0),
              child: Text(
                'No users found matching your criteria.',
                style: GoogleFonts.inter(color: secondaryTextColor),
              ),
            ),

          // Pagination Controls (only show if needed)
          if (filteredUsers.length > itemsPerPage) ...[
            Divider(height: 1, color: dividerColor, thickness: 1),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Items per page selector
                  Row(
                    children: [
                      Text(
                        'Items per page:',
                        style: GoogleFonts.inter(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 8),
                      DropdownButton<int>(
                        value: itemsPerPage,
                        dropdownColor: cardColor,
                        underline: Container(),
                        items: [5, 10, 20, 50, 100].map((int value) {
                          return DropdownMenuItem<int>(
                            value: value,
                            child: Text(
                              value.toString(),
                              style: GoogleFonts.inter(
                                color: textColor,
                                fontSize: 12,
                              ),
                            ),
                          );
                        }).toList(),
                        onChanged: (int? newValue) {
                          if (newValue != null) {
                            setState(() {
                              itemsPerPage = newValue;
                              currentPage = 1; // Reset to first page
                            });
                          }
                        },
                      ),
                    ],
                  ),

                  // Page navigation
                  Row(
                    children: [
                      Text(
                        '${startIndex + 1}-$endIndex of $totalItems',
                        style: GoogleFonts.inter(
                          color: secondaryTextColor,
                          fontSize: 12,
                        ),
                      ),
                      const SizedBox(width: 16),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_left,
                          size: 20,
                          color: currentPage > 1 ? textColor : secondaryTextColor.withOpacity(0.5),
                        ),
                        onPressed: currentPage > 1 ? () => setState(() => currentPage--) : null,
                      ),
                      IconButton(
                        icon: Icon(
                          Icons.chevron_right,
                          size: 20,
                          color: currentPage < totalPages
                              ? textColor
                              : secondaryTextColor.withOpacity(0.5),
                        ),
                        onPressed:
                            currentPage < totalPages ? () => setState(() => currentPage++) : null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildUserRow(User user, bool isMobile, Color textColor, Color secondaryTextColor) {
    final isDark = _isDark;
    final statusColor = user.status == 'Active' ? Colors.green : Colors.grey[600];

    return InkWell(
      onTap: () => _showUserDetailsDialog(user),
      child: Container(
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: secondaryTextColor.withOpacity(0.1))),
        ),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 14),
          child: Row(
            children: [
              Expanded(
                flex: 2,
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 20,
                      backgroundColor: AppColors.primary.withOpacity(0.09),
                      backgroundImage: user.avatar != null && user.avatar!.isNotEmpty
                          ? NetworkImage(user.avatar!)
                          : null,
                      child: user.avatar == null || user.avatar!.isEmpty
                          ? Text(
                              user.name[0].toUpperCase(),
                              style: GoogleFonts.poppins(
                                fontWeight: FontWeight.bold,
                                color: AppColors.primary,
                              ),
                            )
                          : null,
                    ),
                    const SizedBox(width: 13),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(user.name,
                            style: GoogleFonts.inter(
                              fontWeight: FontWeight.w700,
                              color: textColor,
                            )),
                        Text(user.email,
                            style: GoogleFonts.inter(
                              fontSize: 13,
                              color: secondaryTextColor,
                            )),
                      ],
                    ),
                  ],
                ),
              ),
              if (!isMobile) ...[
                Expanded(
                  child: Text(user.role,
                      style: GoogleFonts.inter(
                        color: textColor,
                        fontWeight: FontWeight.w500,
                      )),
                ),
                Expanded(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: statusColor!.withOpacity(0.09),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user.status,
                      style: GoogleFonts.inter(
                        color: statusColor,
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    user.lastActive,
                    style: GoogleFonts.inter(
                      color: secondaryTextColor,
                      fontSize: 13,
                    ),
                  ),
                ),
                Expanded(
                  child: Text(
                    user.department,
                    style: GoogleFonts.inter(
                      color: textColor,
                      fontWeight: FontWeight.w500,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
              PopupMenuButton<String>(
                icon: Icon(Icons.more_vert_rounded, color: secondaryTextColor),
                color: isDark ? AppColors.darkCard : AppColors.card,
                itemBuilder: (context) => [
                  PopupMenuItem<String>(
                    value: 'Edit User',
                    child: Text('Edit User', style: GoogleFonts.inter(color: textColor)),
                  ),
                  PopupMenuItem<String>(
                    value: 'Reset Password',
                    child: Text('Reset Password', style: GoogleFonts.inter(color: textColor)),
                  ),
                  PopupMenuItem<String>(
                    value: user.status == 'Active' ? 'Deactivate' : 'Activate',
                    child: Text(user.status == 'Active' ? 'Deactivate' : 'Activate',
                        style: GoogleFonts.inter(color: textColor)),
                  ),
                  PopupMenuItem<String>(
                    value: 'Delete',
                    child: Text('Delete', style: GoogleFonts.inter(color: Colors.red)),
                  ),
                ].toList(),
                onSelected: (value) => _handleUserAction(value, user),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddUserDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final emailController = TextEditingController();
    final contactController = TextEditingController();
    final avatarController = TextEditingController();

    String? selectedRole;
    String? selectedStatus;
    String? selectedDepartment;
    Set<String> selectedPermissions = {};
    int currentStep = 0;
    String tempPassword = '';

    showDialog(
      context: context,
      builder: (dialogContext) {
        return StatefulBuilder(
          builder: (context, setState) {
            return Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(20),
              child: Container(
                constraints: const BoxConstraints(maxWidth: 600),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkCard : AppColors.card,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
                      blurRadius: 20,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                      decoration: BoxDecoration(
                        gradient: AppColors.primaryGradient,
                        borderRadius: const BorderRadius.only(
                          topLeft: Radius.circular(16),
                          topRight: Radius.circular(16),
                        ),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Add New User',
                            style: GoogleFonts.poppins(
                              fontSize: 20,
                              fontWeight: FontWeight.w600,
                              color: Colors.white,
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.close, color: Colors.white),
                            onPressed: () => Navigator.of(dialogContext).pop(),
                          ),
                        ],
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Stepper(
                        currentStep: currentStep,
                        controlsBuilder: (context, ControlsDetails details) {
                          return Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (currentStep > 0)
                                OutlinedButton(
                                  onPressed: details.onStepCancel,
                                  child: const Text('Back'),
                                ),
                              const SizedBox(width: 8),
                              ElevatedButton(
                                onPressed: details.onStepContinue,
                                child: Text(currentStep == 2 ? 'Finish' : 'Next'),
                              ),
                            ],
                          );
                        },
                        onStepContinue: () {
                          if (currentStep == 0) {
                            if (!formKey.currentState!.validate() ||
                                selectedRole == null ||
                                selectedStatus == null ||
                                selectedDepartment == null) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields')),
                              );
                              return;
                            }
                          }

                          if (currentStep < 2) {
                            setState(() => currentStep++);
                          } else {
                            final newUser = User(
                              id: (users.length + 1).toString(),
                              name: nameController.text,
                              email: emailController.text,
                              role: selectedRole!,
                              status: selectedStatus!,
                              lastActive: 'Just now',
                              avatar:
                                  avatarController.text.isNotEmpty ? avatarController.text : null,
                              contactNumber: contactController.text,
                              department: selectedDepartment!,
                              permissions: selectedPermissions.toList(),
                            );

                            setState(() {
                              users.add(newUser);
                              _filterUsers();
                              tempPassword = _generateTempPassword();
                            });
                          }
                        },
                        onStepCancel: () {
                          if (currentStep > 0) {
                            setState(() => currentStep--);
                          } else {
                            Navigator.of(dialogContext).pop();
                          }
                        },
                        steps: [
                          Step(
                            title: Text('User Info',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.card : AppColors.darkCard,
                                )),
                            isActive: currentStep >= 0,
                            content: Form(
                              key: formKey,
                              child: Column(
                                children: [
                                  _buildModernTextField(
                                    controller: nameController,
                                    label: 'Full Name',
                                    icon: Icons.person_outline,
                                    isRequired: true,
                                    isDark: isDark,
                                    cardColor: isDark ? AppColors.card : AppColors.darkCard,
                                    textColor: isDark ? AppColors.card : AppColors.darkCard,
                                    secondaryTextColor: AppColors.text.withOpacity(0.7),
                                    primaryColor: AppColors.primary,
                                    dividerColor: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildModernTextField(
                                    controller: emailController,
                                    label: 'Email Address',
                                    icon: Icons.email_outlined,
                                    keyboardType: TextInputType.emailAddress,
                                    isRequired: true,
                                    isDark: isDark,
                                    cardColor: isDark ? AppColors.card : AppColors.darkCard,
                                    textColor: isDark ? AppColors.card : AppColors.darkCard,
                                    secondaryTextColor: AppColors.text.withOpacity(0.7),
                                    primaryColor: AppColors.primary,
                                    dividerColor: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildModernTextField(
                                    controller: contactController,
                                    label: 'Phone Number',
                                    icon: Icons.phone_outlined,
                                    keyboardType: TextInputType.phone,
                                    isDark: isDark,
                                    cardColor: isDark ? AppColors.card : AppColors.darkCard,
                                    textColor: isDark ? AppColors.card : AppColors.darkCard,
                                    secondaryTextColor: AppColors.text.withOpacity(0.7),
                                    primaryColor: AppColors.primary,
                                    dividerColor: Colors.grey,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildModernDropdown(
                                    label: 'User Role',
                                    value: selectedRole,
                                    items: const [
                                      'Admin',
                                      'Farm Owner',
                                      'Farm Manager',
                                      'Technician',
                                      'Field Worker'
                                    ],
                                    onChanged: (value) => setState(() => selectedRole = value),
                                    icon: Icons.badge_outlined,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildModernDropdown(
                                    label: 'Status',
                                    value: selectedStatus,
                                    items: const [
                                      'Active',
                                      'Inactive',
                                      'Suspended',
                                      'Onboarding',
                                      'Terminated'
                                    ],
                                    onChanged: (value) => setState(() => selectedStatus = value),
                                    icon: Icons.circle_outlined,
                                    isDark: isDark,
                                  ),
                                  const SizedBox(height: 12),
                                  _buildModernDropdown(
                                    label: 'Department',
                                    value: selectedDepartment,
                                    items: const ['Admin', 'IT', 'Operations', 'Field'],
                                    onChanged: (value) =>
                                        setState(() => selectedDepartment = value),
                                    icon: Icons.business_center_outlined,
                                    isDark: isDark,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          Step(
                            title: Text('Permissions',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.card : AppColors.darkCard,
                                )),
                            isActive: currentStep >= 1,
                            content: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: _availablePermissions.map((permission) {
                                return _buildPermissionChip(
                                  permission: permission,
                                  isSelected: selectedPermissions.contains(permission),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        selectedPermissions.add(permission);
                                      } else {
                                        selectedPermissions.remove(permission);
                                      }
                                    });
                                  },
                                  isDark: isDark,
                                  primaryColor: AppColors.primary,
                                  textColor: AppColors.text,
                                );
                              }).toList(),
                            ),
                          ),
                          Step(
                            title: Text('Congratulations',
                                style: TextStyle(
                                  fontWeight: FontWeight.w600,
                                  color: isDark ? AppColors.card : AppColors.darkCard,
                                )),
                            isActive: currentStep >= 2,
                            content: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '🎉 ${nameController.text} has been successfully added!',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                const SizedBox(height: 10),
                                Text(
                                  'A temporary password has been sent to their email.',
                                  style: TextStyle(color: AppColors.text.withOpacity(0.7)),
                                ),
                                const SizedBox(height: 10),
                                SelectableText(
                                  'Temporary Password: $tempPassword',
                                  style: const TextStyle(fontSize: 16),
                                ),
                                const SizedBox(height: 20),
                                /*
                              Align(
                                alignment: Alignment.centerRight,
                                child: ElevatedButton(
                                  onPressed: () => Navigator.of(dialogContext).pop(),
                                  child: const Text('Done'),
                                ),
                              ),
                              */
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  void _showUserDetailsDialog(User user) {
    final isSmallScreen = MediaQuery.of(context).size.width < 800;

    showDialog(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          elevation: 4,
          child: Container(
            constraints: BoxConstraints(
              maxWidth: isSmallScreen ? 600 : 700,
              maxHeight: MediaQuery.of(context).size.height * 0.9,
            ),
            decoration: BoxDecoration(
              gradient: isDark ? null : AppColors.greenGradient,
            ),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? AppColors.darkBackground.withOpacity(0.95)
                    : Colors.white.withOpacity(0.95),
                borderRadius: BorderRadius.circular(16),
              ),
              child: isSmallScreen
                  ? _buildMobileTabView(user, isDark)
                  : _buildDesktopView(user, isDark),
            ),
          ),
        );
      },
    );
  }

  Widget _buildDesktopView(User user, bool isDark) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // User Details Section
        Expanded(
          flex: 2,
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: _buildUserDetailsContent(user, isDark),
          ),
        ),

        // Performance Card Section
        Container(
          width: 300,
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(16),
              bottomRight: Radius.circular(16),
            ),
          ),
          child: _buildPerformanceContent(user, isDark),
        ),
      ],
    );
  }

  Widget _buildMobileTabView(User user, bool isDark) {
    return DefaultTabController(
      length: 2,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Tab Bar
          Container(
            decoration: BoxDecoration(
              color: isDark ? AppColors.darkCard : Colors.white,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(16),
                topRight: Radius.circular(16),
              ),
            ),
            child: TabBar(
              labelColor: AppColors.primary,
              unselectedLabelColor:
                  isDark ? AppColors.darkText.withOpacity(0.6) : AppColors.text.withOpacity(0.6),
              indicatorColor: AppColors.primary,
              indicatorSize: TabBarIndicatorSize.tab,
              labelStyle: GoogleFonts.inter(fontWeight: FontWeight.w600),
              tabs: const [
                Tab(text: 'User Details'),
                Tab(text: 'Performance'),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: Container(
              color: isDark ? AppColors.darkBackground : Colors.white,
              child: TabBarView(
                physics: const ClampingScrollPhysics(),
                children: [
                  // User Details Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildUserDetailsContent(user, isDark),
                  ),

                  // Performance Tab
                  SingleChildScrollView(
                    padding: const EdgeInsets.all(24),
                    child: _buildPerformanceContent(user, isDark),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserDetailsContent(User user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Header with avatar and name
        Row(
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: AppColors.primaryGradient,
              ),
              child: Center(
                child: CircleAvatar(
                  radius: 30,
                  backgroundColor: isDark ? AppColors.darkCard : Colors.white,
                  backgroundImage: user.avatar != null ? NetworkImage(user.avatar!) : null,
                  child: user.avatar == null
                      ? Icon(Icons.person, size: 30, color: AppColors.primary)
                      : null,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: GoogleFonts.poppins(
                      fontSize: 22,
                      fontWeight: FontWeight.w600,
                      color: isDark ? AppColors.darkText : AppColors.text,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user.role,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: isDark
                          ? AppColors.darkText.withOpacity(0.7)
                          : AppColors.text.withOpacity(0.7),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 24),

        // User Information
        _buildDetailItem(
          icon: Icons.email_outlined,
          label: 'Email',
          value: user.email,
          isDark: isDark,
        ),
        _buildDetailItem(
          icon: Icons.phone_outlined,
          label: 'Contact',
          value: user.contactNumber.isNotEmpty ? user.contactNumber : 'Not provided',
          isDark: isDark,
        ),
        _buildDetailItem(
          icon: Icons.badge_outlined,
          label: 'Role',
          value: user.role,
          isDark: isDark,
        ),
        _buildDetailItem(
          icon: Icons.circle_outlined,
          label: 'Status',
          value: user.status,
          valueColor: user.status == 'Active' ? AppColors.primary : AppColors.warning,
          isDark: isDark,
        ),
        _buildDetailItem(
          icon: Icons.update_outlined,
          label: 'Last Active',
          value: user.lastActive,
          isDark: isDark,
        ),
        _buildDetailItem(
          icon: Icons.business_outlined,
          label: 'Department',
          value: user.department.isNotEmpty ? user.department : 'Not assigned',
          isDark: isDark,
        ),

        // Permissions Section
        const SizedBox(height: 24),
        Text(
          'Permissions',
          style: GoogleFonts.poppins(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: isDark ? AppColors.darkText.withOpacity(0.8) : AppColors.text.withOpacity(0.8),
          ),
        ),
        const SizedBox(height: 8),
        Divider(
          color: isDark ? Colors.grey[700] : Colors.grey[300],
          height: 1,
        ),
        const SizedBox(height: 12),

        if (user.permissions.isNotEmpty)
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: user.permissions.map((permission) {
              return Chip(
                label: Text(permission),
                backgroundColor: AppColors.primary.withOpacity(isDark ? 0.2 : 0.1),
                labelStyle: GoogleFonts.inter(
                  color: AppColors.primary,
                  fontWeight: FontWeight.w500,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            }).toList(),
          )
        else
          Text(
            'No specific permissions assigned',
            style: GoogleFonts.inter(
              color: isDark ? AppColors.darkText.withOpacity(0.5) : AppColors.text.withOpacity(0.5),
            ),
          ),
      ],
    );
  }

  Widget _buildPerformanceContent(User user, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Performance Metrics',
          style: GoogleFonts.poppins(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: isDark ? AppColors.darkText : AppColors.text,
          ),
        ),
        const SizedBox(height: 16),

        // Performance Stats
        _buildPerformanceMetric(
          icon: Icons.task_outlined,
          label: 'Tasks Completed',
          value: '142',
          change: '+12%',
          isPositive: true,
          isDark: isDark,
        ),
        _buildPerformanceMetric(
          icon: Icons.timer_outlined,
          label: 'Avg. Response Time',
          value: '2.4h',
          change: '-5%',
          isPositive: true,
          isDark: isDark,
        ),
        _buildPerformanceMetric(
          icon: Icons.assignment_outlined,
          label: 'Open Tickets',
          value: '8',
          change: '+2',
          isPositive: false,
          isDark: isDark,
        ),
        _buildPerformanceMetric(
          icon: Icons.thumb_up_outlined,
          label: 'Satisfaction Rate',
          value: '94%',
          change: '+3%',
          isPositive: true,
          isDark: isDark,
        ),

        // Performance Chart (placeholder)
        const SizedBox(height: 24),
        Container(
          height: 160,
          decoration: BoxDecoration(
            color: isDark ? AppColors.darkCard : Colors.white,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: isDark ? Colors.grey[800]! : Colors.grey[200]!, width: 1),
          ),
          padding: const EdgeInsets.all(12),
          child: Center(
            child: Text(
              'Performance Trend Chart',
              style: GoogleFonts.inter(
                color:
                    isDark ? AppColors.darkText.withOpacity(0.6) : AppColors.text.withOpacity(0.6),
              ),
            ),
          ),
        ),

        // Action Buttons
        const Spacer(),
        SizedBox(
          width: double.infinity,
          child: ElevatedButton(
            onPressed: () => _showEditUserDialog(user),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.primary,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              elevation: 0,
            ),
            child: Text(
              'Edit Profile',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton(
            onPressed: () => Navigator.pop(context),
            style: OutlinedButton.styleFrom(
              side: BorderSide(
                color:
                    isDark ? AppColors.darkText.withOpacity(0.3) : AppColors.text.withOpacity(0.3),
              ),
              padding: const EdgeInsets.symmetric(vertical: 14),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            child: Text(
              'Close',
              style: GoogleFonts.inter(
                fontWeight: FontWeight.w600,
                color: isDark ? AppColors.darkText : AppColors.text,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDetailItem({
    required IconData icon,
    required String label,
    required String value,
    Color? valueColor,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 20,
            color: isDark ? AppColors.darkText.withOpacity(0.6) : AppColors.text.withOpacity(0.6),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkText.withOpacity(0.6)
                        : AppColors.text.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: GoogleFonts.inter(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                    color: valueColor ?? (isDark ? AppColors.darkText : AppColors.text),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPerformanceMetric({
    required IconData icon,
    required String label,
    required String value,
    required String change,
    required bool isPositive,
    required bool isDark,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: AppColors.primary.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              size: 18,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark
                        ? AppColors.darkText.withOpacity(0.6)
                        : AppColors.text.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      value,
                      style: GoogleFonts.inter(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: isDark ? AppColors.darkText : AppColors.text,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: isPositive
                            ? AppColors.primary.withOpacity(0.1)
                            : AppColors.danger.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        change,
                        style: GoogleFonts.inter(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: isPositive ? AppColors.primary : AppColors.danger,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Modified _showEditUserDialog for tabbed UI
  void _showEditUserDialog(User user) {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController(text: user.name);
    final emailController = TextEditingController(text: user.email);
    final contactController = TextEditingController(text: user.contactNumber);
    final avatarController = TextEditingController(text: user.avatar);

    String selectedRole = user.role;
    String selectedStatus = user.status;
    String selectedDepartment = user.department;
    Set<String> selectedPermissions = Set.from(user.permissions);

    showDialog(
      context: context,
      builder: (dialogContext) {
        final primaryColor = AppColors.primary;
        final cardColor = isDark ? AppColors.darkCard : AppColors.card;
        final textColor = isDark ? AppColors.darkText : AppColors.text;
        final secondaryTextColor =
            isDark ? AppColors.darkText.withOpacity(0.7) : AppColors.text.withOpacity(0.7);
        final dividerColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);
        final buttonTextColor = isDark ? Colors.black : Colors.white;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 600),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.2),
                  blurRadius: 20,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: Form(
              key: formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Header with gradient
                  Container(
                    padding: const EdgeInsets.fromLTRB(24, 20, 24, 16),
                    decoration: BoxDecoration(
                      gradient: AppColors.primaryGradient,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(16),
                        topRight: Radius.circular(16),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Edit User Profile',
                          style: GoogleFonts.poppins(
                            fontSize: 20,
                            fontWeight: FontWeight.w600,
                            color: Colors.white,
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.of(dialogContext).pop(),
                        ),
                      ],
                    ),
                  ),

                  // Tabs with indicator
                  Container(
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: dividerColor),
                      ),
                    ),
                    child: TabBar(
                      controller: _editUserTabController,
                      labelColor: primaryColor,
                      unselectedLabelColor: secondaryTextColor,
                      indicator: UnderlineTabIndicator(
                        borderSide: BorderSide(
                          width: 3,
                          color: primaryColor,
                        ),
                      ),
                      labelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w600,
                        fontSize: 14,
                      ),
                      unselectedLabelStyle: GoogleFonts.inter(
                        fontWeight: FontWeight.w500,
                      ),
                      tabs: const [
                        Tab(text: 'Basic Info'),
                        Tab(text: 'Permissions'),
                      ],
                    ),
                  ),

                  // Tab content
                  SizedBox(
                    height: 500,
                    child: TabBarView(
                      controller: _editUserTabController,
                      children: [
                        // Basic Info Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            children: [
                              // Avatar Section
                              _buildAvatarEditSection(
                                avatarController,
                                isDark,
                                primaryColor,
                                cardColor,
                                textColor,
                              ),
                              const SizedBox(height: 24),

                              // Form Fields
                              _buildModernTextField(
                                controller: nameController,
                                label: 'Full Name',
                                icon: Icons.person_outline,
                                isRequired: true,
                                isDark: isDark,
                                cardColor: cardColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                                primaryColor: primaryColor,
                                dividerColor: dividerColor,
                              ),
                              const SizedBox(height: 16),

                              _buildModernTextField(
                                controller: emailController,
                                label: 'Email Address',
                                icon: Icons.email_outlined,
                                keyboardType: TextInputType.emailAddress,
                                isRequired: true,
                                isDark: isDark,
                                cardColor: cardColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                                primaryColor: primaryColor,
                                dividerColor: dividerColor,
                              ),
                              const SizedBox(height: 16),

                              _buildModernTextField(
                                controller: contactController,
                                label: 'Phone Number',
                                icon: Icons.phone_outlined,
                                keyboardType: TextInputType.phone,
                                isDark: isDark,
                                cardColor: cardColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                                primaryColor: primaryColor,
                                dividerColor: dividerColor,
                              ),
                              const SizedBox(height: 16),

                              _buildModernTextField(
                                controller: avatarController,
                                label: 'Avatar URL',
                                icon: Icons.link_outlined,
                                isDark: isDark,
                                cardColor: cardColor,
                                textColor: textColor,
                                secondaryTextColor: secondaryTextColor,
                                primaryColor: primaryColor,
                                dividerColor: dividerColor,
                              ),
                              const SizedBox(height: 24),

                              // Dropdown Sections
                              _buildModernDropdown(
                                label: 'User Role',
                                value: selectedRole,
                                items: const ['Admin', 'Manager', 'Technician', 'Viewer'],
                                onChanged: (value) => selectedRole = value!,
                                icon: Icons.badge_outlined,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),

                              _buildModernDropdown(
                                label: 'Status',
                                value: selectedStatus,
                                items: const ['Active', 'Inactive'],
                                onChanged: (value) => selectedStatus = value!,
                                icon: Icons.circle_outlined,
                                isDark: isDark,
                              ),
                              const SizedBox(height: 16),

                              _buildModernDropdown(
                                  label: 'Department',
                                  value: selectedDepartment,
                                  items: const [
                                    'IT',
                                    'Operations',
                                    'Field',
                                    'Support',
                                    'HR',
                                    'Finance'
                                  ],
                                  onChanged: (value) => selectedDepartment = value!,
                                  icon: Icons.business_center_outlined,
                                  isDark: isDark),
                            ],
                          ),
                        ),

                        // Permissions Tab
                        SingleChildScrollView(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'User Permissions',
                                style: GoogleFonts.poppins(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w600,
                                  color: textColor,
                                ),
                              ),
                              const SizedBox(height: 8),
                              Text(
                                'Select the permissions this user should have',
                                style: GoogleFonts.inter(
                                  fontSize: 14,
                                  color: secondaryTextColor,
                                ),
                              ),
                              const SizedBox(height: 24),

                              // Permission Cards Grid
                              GridView.count(
                                shrinkWrap: true,
                                physics: const NeverScrollableScrollPhysics(),
                                crossAxisCount: 2,
                                crossAxisSpacing: 12,
                                mainAxisSpacing: 12,
                                childAspectRatio: 3,
                                children: _availablePermissions.map((permission) {
                                  return _buildPermissionCard(
                                    permission: permission,
                                    isSelected: selectedPermissions.contains(permission),
                                    onChanged: (selected) {
                                      if (selected) {
                                        selectedPermissions.add(permission);
                                      } else {
                                        selectedPermissions.remove(permission);
                                      }
                                      (dialogContext as Element).markNeedsBuild();
                                    },
                                    isDark: isDark,
                                    primaryColor: primaryColor,
                                    cardColor: cardColor,
                                    textColor: textColor,
                                    dividerColor: dividerColor,
                                    buttonTextColor: buttonTextColor,
                                  );
                                }).toList(),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Footer Buttons
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      border: Border(
                        top: BorderSide(color: dividerColor.withOpacity(0.1)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: secondaryTextColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            side: BorderSide(color: dividerColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              setState(() {
                                user.name = nameController.text;
                                user.email = emailController.text;
                                user.contactNumber = contactController.text;
                                user.role = selectedRole;
                                user.status = selectedStatus;
                                user.department = selectedDepartment;
                                user.permissions = selectedPermissions.toList();
                                user.avatar =
                                    avatarController.text.isNotEmpty ? avatarController.text : null;
                                _filterUsers();
                              });
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text('${user.name} updated successfully'),
                                  behavior: SnackBarBehavior.floating,
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                ),
                              );
                            }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: primaryColor,
                            foregroundColor: buttonTextColor,
                            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            elevation: 0,
                            shadowColor: Colors.transparent,
                          ),
                          child: const Text('Save Changes'),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

// Modern UI Components

  Widget _buildAvatarEditSection(
    TextEditingController controller,
    bool isDark,
    Color primaryColor,
    Color cardColor,
    Color textColor,
  ) {
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: isDark ? AppColors.darkCard : Colors.white,
              backgroundImage: controller.text.isNotEmpty ? NetworkImage(controller.text) : null,
              child: controller.text.isEmpty
                  ? Icon(Icons.person, size: 40, color: textColor.withOpacity(0.5))
                  : null,
            ),
            Container(
              decoration: BoxDecoration(
                color: primaryColor,
                shape: BoxShape.circle,
                border: Border.all(color: cardColor, width: 2),
              ),
              child: IconButton(
                icon: const Icon(Icons.edit, size: 16),
                color: isDark ? AppColors.text : Colors.white,
                onPressed: () {
                  // Implement avatar editing logic
                },
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildModernTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    bool isRequired = false,
    TextInputType? keyboardType,
    required bool isDark,
    required Color cardColor,
    required Color textColor,
    required Color secondaryTextColor,
    required Color primaryColor,
    required Color dividerColor,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      validator: (value) => isRequired && value!.isEmpty ? 'Required field' : null,
      style: GoogleFonts.inter(
        color: textColor,
        fontSize: 14,
      ),
      decoration: InputDecoration(
        labelText: label,
        prefixIcon:
            Icon(icon, color: isDark ? AppColors.darkText.withOpacity(0.7) : Colors.black54),
        filled: true,
        fillColor: isDark ? AppColors.darkCard : Colors.white,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: isDark ? AppColors.darkText.withOpacity(0.7) : Colors.black54,
        ),
      ),
    );
  }

  Widget _buildModernDropdown({
    required String label,
    required String? value,
    required List<String> items,
    required ValueChanged<String?> onChanged,
    required IconData icon,
    required bool isDark,
  }) {
    final primaryColor = AppColors.primary;
    final cardColor = isDark ? AppColors.darkCard : AppColors.card;
    final textColor = isDark ? AppColors.darkText : AppColors.text;
    final secondaryTextColor =
        isDark ? AppColors.darkText.withOpacity(0.7) : AppColors.text.withOpacity(0.7);
    final dividerColor = isDark ? Colors.white.withOpacity(0.1) : Colors.black.withOpacity(0.1);

    return DropdownButtonFormField<String>(
      value: value,
      items: items.map((String value) {
        return DropdownMenuItem<String>(
          value: value,
          child: Text(
            value,
            style: GoogleFonts.inter(
              color: textColor,
              fontSize: 14,
            ),
          ),
        );
      }).toList(),
      onChanged: onChanged,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: secondaryTextColor),
        filled: true,
        fillColor: cardColor,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: dividerColor),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: primaryColor, width: 1.5),
        ),
        labelStyle: GoogleFonts.inter(
          color: secondaryTextColor,
        ),
      ),
      dropdownColor: cardColor,
      icon: Icon(Icons.arrow_drop_down, color: secondaryTextColor),
      style: GoogleFonts.inter(
        color: textColor,
        fontSize: 14,
      ),
      borderRadius: BorderRadius.circular(8),
    );
  }

  Widget _buildPermissionCard({
    required String permission,
    required bool isSelected,
    required ValueChanged<bool> onChanged,
    required bool isDark,
    required Color primaryColor,
    required Color cardColor,
    required Color textColor,
    required Color dividerColor,
    required Color buttonTextColor,
  }) {
    return Card(
      elevation: 0,
      color: isSelected ? primaryColor.withOpacity(isDark ? 0.2 : 0.1) : cardColor,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
        side: BorderSide(
          color: isSelected ? primaryColor : dividerColor,
          width: 1,
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(8),
        onTap: () => onChanged(!isSelected),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Container(
                width: 24,
                height: 24,
                decoration: BoxDecoration(
                  color: isSelected ? primaryColor : cardColor,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: isSelected ? primaryColor : textColor.withOpacity(0.4),
                  ),
                ),
                child: isSelected ? Icon(Icons.check, size: 16, color: buttonTextColor) : null,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  permission,
                  style: GoogleFonts.inter(
                    color: textColor,
                    fontSize: 14,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
// Component Widgets

  void _handleUserAction(String action, User user) {
    switch (action) {
      case 'Edit User':
        _showEditUserDialog(user);
        break;
      case 'Reset Password':
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Reset password for ${user.name}')),
        );
        break;
      case 'Deactivate':
        setState(() {
          user.status = 'Inactive';
          _filterUsers();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} deactivated.')),
        );
        break;
      case 'Activate':
        setState(() {
          user.status = 'Active';
          _filterUsers();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${user.name} activated.')),
        );
        break;
      case 'Delete':
        _confirmDeleteUser(user);
        break;
    }
  }

  void _confirmDeleteUser(User user) {
    final dialogTextColor = isDark ? Colors.white : Colors.black87;
    final dialogCardColor = isDark ? AppColors.darkCard : AppColors.card;
    final dialogActiveColor = isDark ? Colors.tealAccent : Colors.green;

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          backgroundColor: dialogCardColor,
          title: Text(
            'Delete User',
            style: GoogleFonts.poppins(
              color: dialogTextColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          content: Text(
            'Are you sure you want to delete ${user.name}? This action cannot be undone.',
            style: GoogleFonts.inter(color: dialogTextColor),
          ),
          actions: <Widget>[
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text('Cancel', style: GoogleFonts.inter(color: dialogActiveColor)),
            ),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  users.removeWhere((u) => u.id == user.id);
                  _filterUsers();
                });
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${user.name} deleted successfully!')),
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red,
                foregroundColor: Colors.white,
              ),
              child: const Text('Delete'),
            ),
          ],
        );
      },
    );
  }
}

Widget _buildPermissionChip({
  required String permission,
  required bool isSelected,
  required ValueChanged<bool> onSelected,
  required bool isDark,
  required Color primaryColor,
  required Color textColor,
}) {
  return FilterChip(
    label: Text(
      permission,
      style: GoogleFonts.inter(
        color: isSelected ? (isDark ? Colors.black : Colors.white) : textColor,
      ),
    ),
    selected: isSelected,
    onSelected: onSelected,
    backgroundColor: isSelected ? primaryColor : (isDark ? Colors.grey[800] : Colors.grey[200]),
    selectedColor: primaryColor,
    checkmarkColor: isDark ? Colors.black : Colors.white,
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
      side: BorderSide(
        color: isSelected ? primaryColor : Colors.grey,
        width: 1,
      ),
    ),
  );
}

// Helper Classes

class DialogColors {
  final Color cardColor;
  final Color textColor;
  final Color secondaryTextColor;
  final Color primaryColor;
  final Color dividerColor;
  final Color buttonTextColor;

  DialogColors({
    required this.cardColor,
    required this.textColor,
    required this.secondaryTextColor,
    required this.primaryColor,
    required this.dividerColor,
    required this.buttonTextColor,
  });
}

String _generateTempPassword({int length = 8}) {
  const chars = 'abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789';
  final rand = math.Random();
  return List.generate(length, (index) => chars[rand.nextInt(chars.length)]).join();
}
