// ignore_for_file: deprecated_member_use

import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../constants/colors.dart';
import '../../core/widgets/modern_scaffold.dart';
import '../../core/widgets/adaptive_navigation.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
//import 'package:syncfusion_flutter_datepicker/datepicker.dart';

class Farm {
  final String id;
  final String name;
  final String location;
  final String size;
  final String status;
  final String lastActivity;
  final String imageUrl;

  Farm({
    required this.id,
    required this.name,
    required this.location,
    required this.size,
    required this.status,
    required this.lastActivity,
    required this.imageUrl,
  });
}

class FarmsScreen extends StatefulWidget {
  const FarmsScreen({super.key});

  @override
  State<FarmsScreen> createState() => _FarmsScreenState();
}

class _FarmsScreenState extends State<FarmsScreen> {
  int _selectedNavIndex = 2;
  bool _isDark = false;
  bool get isDark => _isDark;
  final TextEditingController _searchController = TextEditingController();

  List<Farm> farms = [
    Farm(
      id: '1',
      name: 'Green Valley Farm',
      location: 'Nairobi, Kenya',
      size: '12.5 acres',
      status: 'Active',
      lastActivity: '2 hours ago',
      imageUrl: "https://iqrorwxhniriml5q.ldycdn.com/cloud/omBppKiiRmiSorrimjlli/206822878926538318.jpg",
    ),
    Farm(
      id: '2',
      name: 'Sunshine Fields',
      location: 'Nakuru, Kenya',
      size: '8.2 acres',
      status: 'Active',
      lastActivity: '5 hours ago',
      imageUrl: "https://image.made-in-china.com/2f0j00fbjqYJURHtcn/Affordable-Agriculture-Polycarbonate-Greenhouse-with-Hydroponic-Growing-System-for-Mushrooms-Vegetables-Fruits-Flowers-Lettuce-and-Peppers.jpg",
    ),
    Farm(
      id: '3',
      name: 'Mountain View Farm',
      location: 'Eldoret, Kenya',
      size: '15.0 acres',
      status: 'Maintenance',
      lastActivity: '1 day ago',
      imageUrl: "https://cdn.mos.cms.futurecdn.net/WFB6T4D75sgSapDGpLPxHD.jpg",
    ),
    Farm(
      id: '4',
      name: 'River Side Farm',
      location: 'Kisumu, Kenya',
      size: '6.8 acres',
      status: 'Active',
      lastActivity: '30 minutes ago',
      imageUrl: "https://media.istockphoto.com/id/483721777/photo/tomatoes.jpg?s=612x612&w=0&k=20&c=Z6GqFTtOzvAKYjOAbr8knRLnn3UcEkRbkPTvzGhfF58=",
    ),
  ];

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
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
            Navigator.pushReplacementNamed(context, '/dashboard');
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
            Navigator.pushReplacementNamed(context, '/users');
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
            Navigator.pushReplacementNamed(context, '/farms');
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
            Navigator.pushReplacementNamed(context, '/sensors');
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
            Navigator.pushReplacementNamed(context, '/settings');
          }
        },
      ),
    ];

    return ModernScaffold(
      title: 'Farm Management',
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
              _buildSearchAndFilter(cardColor, secondaryTextColor),
              const SizedBox(height: 22),
              _buildFarmsGrid(
                isMobile,
                cardColor,
                textColor,
                secondaryTextColor,
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
            'Farm Management',
            style: GoogleFonts.poppins(
              fontSize: isMobile ? 24 : 28,
              fontWeight: FontWeight.w700,
              color: textColor,
              letterSpacing: 0.3,
            ),
          ),
        ),
        ElevatedButton.icon(
          onPressed: _showAddFarmDialog,
          icon: const Icon(Icons.add, size: 20),
          label: Text(isMobile ? 'Add' : 'Add Farm'),
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
    return isMobile
        ? Column(
            children: [
              _buildFarmStatCard('Total Farms', '24', '+5%', true,
                  Icons.agriculture, Colors.green),
              const SizedBox(height: 12),
              _buildFarmStatCard('Active Farms', '18', '+3%', true,
                  Icons.check_circle, Colors.blue),
              const SizedBox(height: 12),
              _buildFarmStatCard('In Maintenance', '6', '-2%', false,
                  Icons.engineering, Colors.orange),
            ],
          )
        : Row(
            children: [
              Expanded(
                  child: _buildFarmStatCard('Total Farms', '24', '+5%', true,
                      Icons.agriculture, Colors.green)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildFarmStatCard('Active Farms', '18', '+3%', true,
                      Icons.check_circle, Colors.blue)),
              const SizedBox(width: 16),
              Expanded(
                  child: _buildFarmStatCard('In Maintenance', '6', '-2%', false,
                      Icons.engineering, Colors.orange)),
            ],
          );
  }

  Widget _buildFarmStatCard(String title, String value, String change,
      bool isPositive, IconData icon, Color color) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[850] : Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(isDark ? 0.1 : 0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: isPositive
                      ? Colors.green.withOpacity(0.1)
                      : Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      isPositive ? Icons.trending_up : Icons.trending_down,
                      size: 16,
                      color: isPositive ? Colors.green : Colors.red,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      change,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isPositive ? Colors.green : Colors.red,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            title,
            style: GoogleFonts.inter(
              fontSize: 14,
              color: isDark
                  ? Colors.white.withOpacity(0.7)
                  : Colors.black.withOpacity(0.6),
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: GoogleFonts.poppins(
              fontSize: 24,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilter(Color cardColor, Color secondaryTextColor) {
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
                decoration: InputDecoration(
                  hintText: 'Search farms...',
                  border: InputBorder.none,
                  hintStyle: GoogleFonts.inter(
                    color: secondaryTextColor,
                  ),
                ),
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.black),
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
              itemBuilder: (context) => [
                'All Farms',
                'Active',
                'Maintenance',
                'By Location'
              ].map((choice) {
                return PopupMenuItem<String>(
                  value: choice,
                  child: Text(choice),
                );
              }).toList(),
              onSelected: (String value) {
                // Filter logic
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFarmsGrid(bool isMobile, Color cardColor, Color textColor,
      Color secondaryTextColor) {
    final crossAxisCount = isMobile ? 1 : 2;
    final childAspectRatio = isMobile ? 1.0 : 1.2;

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: crossAxisCount,
        childAspectRatio: childAspectRatio,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
      ),
      itemCount: farms.length,
      itemBuilder: (context, index) {
        final farm = farms[index];
        return _buildFarmCard(farm, cardColor, textColor, secondaryTextColor);
      },
    );
  }

  Widget _buildFarmCard(
      Farm farm, Color cardColor, Color textColor, Color secondaryTextColor) {
    final statusColor = farm.status == 'Active' ? Colors.green : Colors.orange;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      color: cardColor,
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          _showFarmDetailsModal(farm);
        },
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(12),
                    color: isDark ? Colors.grey[800] : Colors.grey[200],
                    image: farm.imageUrl.isNotEmpty
                        ? DecorationImage(
                            image: NetworkImage(farm.imageUrl),
                            fit: BoxFit.cover,
                          )
                        : null,
                  ),
                  child: farm.imageUrl.isEmpty
                      ? Center(
                          child: Icon(
                            Icons.agriculture,
                            size: 60,
                            color: isDark ? Colors.grey[500] : Colors.grey[400],
                          ),
                        )
                      : null,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                farm.name,
                style: GoogleFonts.poppins(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: textColor,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Icon(
                    Icons.location_on_outlined,
                    size: 16,
                    color: secondaryTextColor,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    farm.location,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: statusColor.withOpacity(0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      farm.status,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: statusColor,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    farm.size,
                    style: GoogleFonts.inter(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: textColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showAddFarmDialog() {
    final formKey = GlobalKey<FormState>();
    final nameController = TextEditingController();
    final locationController = TextEditingController();
    final sizeController = TextEditingController();
    String? selectedStatus = 'Active'; // Default status

    showDialog(
      context: context,
      builder: (dialogContext) {
        final cardColor = isDark ? AppColors.darkCard : AppColors.card;
        final textColor = isDark ? AppColors.darkText : AppColors.text;
        final secondaryTextColor = isDark
            ? Colors.white.withOpacity(0.7)
            : Colors.black.withOpacity(0.6);
        final primaryColor = AppColors.primary;

        return Dialog(
          backgroundColor: Colors.transparent,
          insetPadding: const EdgeInsets.all(20),
          child: Container(
            constraints: const BoxConstraints(maxWidth: 500),
            decoration: BoxDecoration(
              color: cardColor,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(isDark ? 0.3 : 0.1),
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
                  // Header
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
                          'Add New Farm',
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

                  // Content
                  Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Farm Name
                        TextFormField(
                          controller: nameController,
                          style: GoogleFonts.inter(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Farm Name',
                            labelStyle:
                                GoogleFonts.inter(color: secondaryTextColor),
                            prefixIcon:
                                Icon(Icons.agriculture, color: primaryColor),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey[900]!.withOpacity(0.5)
                                : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter farm name';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Location
                        TextFormField(
                          controller: locationController,
                          style: GoogleFonts.inter(color: textColor),
                          decoration: InputDecoration(
                            labelText: 'Location',
                            labelStyle:
                                GoogleFonts.inter(color: secondaryTextColor),
                            prefixIcon: Icon(Icons.location_on_outlined,
                                color: primaryColor),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey[900]!.withOpacity(0.5)
                                : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter location';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Size
                        TextFormField(
                          controller: sizeController,
                          style: GoogleFonts.inter(color: textColor),
                          keyboardType: TextInputType.number,
                          decoration: InputDecoration(
                            labelText: 'Size (acres)',
                            labelStyle:
                                GoogleFonts.inter(color: secondaryTextColor),
                            prefixIcon:
                                Icon(Icons.square_foot, color: primaryColor),
                            suffixText: 'acres',
                            suffixStyle:
                                GoogleFonts.inter(color: secondaryTextColor),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey[900]!.withOpacity(0.5)
                                : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          validator: (value) {
                            if (value == null || value.isEmpty) {
                              return 'Please enter farm size';
                            }
                            if (double.tryParse(value) == null) {
                              return 'Please enter a valid number';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),

                        // Status Dropdown
                        DropdownButtonFormField<String>(
                          value: selectedStatus,
                          items: ['Active', 'Maintenance'].map((String value) {
                            return DropdownMenuItem<String>(
                              value: value,
                              child: Text(
                                value,
                                style: GoogleFonts.inter(color: textColor),
                              ),
                            );
                          }).toList(),
                          onChanged: (String? newValue) {
                            selectedStatus = newValue;
                          },
                          decoration: InputDecoration(
                            labelText: 'Status',
                            labelStyle:
                                GoogleFonts.inter(color: secondaryTextColor),
                            prefixIcon: Icon(Icons.circle_outlined,
                                color: primaryColor),
                            filled: true,
                            fillColor: isDark
                                ? Colors.grey[900]!.withOpacity(0.5)
                                : Colors.grey[50],
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: BorderSide.none,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 14),
                          ),
                          dropdownColor: cardColor,
                          icon: Icon(Icons.arrow_drop_down,
                              color: secondaryTextColor),
                          style: GoogleFonts.inter(color: textColor),
                        ),
                        const SizedBox(height: 24),

                        // Image Upload (Optional)
                        GestureDetector(
                          onTap: () {
                            // Implement image picker
                          },
                          child: Container(
                            height: 120,
                            decoration: BoxDecoration(
                              color: isDark
                                  ? Colors.grey[800]!.withOpacity(0.5)
                                  : Colors.grey[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: secondaryTextColor.withOpacity(0.3),
                                width: 1.5,
                                style: BorderStyle.solid,
                              ),
                            ),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.cloud_upload_outlined,
                                  size: 32,
                                  color: secondaryTextColor,
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Upload Farm Image (Optional)',
                                  style: GoogleFonts.inter(
                                    color: secondaryTextColor,
                                    fontSize: 14,
                                  ),
                                ),
                              ],
                            ),
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
                        top: BorderSide(
                            color: secondaryTextColor.withOpacity(0.1)),
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.end,
                      children: [
                        OutlinedButton(
                          onPressed: () => Navigator.of(dialogContext).pop(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: secondaryTextColor,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            side: BorderSide(color: secondaryTextColor),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: const Text('Cancel'),
                        ),
                        const SizedBox(width: 12),
                        ElevatedButton(
                          onPressed: () {
                            if (formKey.currentState!.validate()) {
                              // Add the new farm
                              final newFarm = Farm(
                                id: DateTime.now()
                                    .millisecondsSinceEpoch
                                    .toString(),
                                name: nameController.text,
                                location: locationController.text,
                                size: '${sizeController.text} acres',
                                status: selectedStatus!,
                                lastActivity: 'Just now',
                                imageUrl: '', // Add image URL if uploaded
                              );

                              setState(() {
                                farms.add(newFarm);
                              });
                              Navigator.of(dialogContext).pop();
                              ScaffoldMessenger.of(dialogContext).showSnackBar(
                                SnackBar(
                                  content: Text(
                                      'Farm "${newFarm.name}" added successfully!'),
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
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(
                                horizontal: 24, vertical: 12),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                            elevation: 0,
                          ),
                          child: const Text('Add Farm'),
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

  //end of add farm

  // start of farm details
 void _showFarmDetailsModal(Farm farm) {
  showDialog(
    context: context,
    builder: (dialogContext) {
      final cardColor = isDark ? Colors.grey[900] : Colors.white;
      final textColor = isDark ? Colors.white : Colors.black;
      final secondaryTextColor = isDark ? Colors.grey[400] : Colors.grey[600];
      final primaryColor = AppColors.primary;
      final borderColor = isDark ? Colors.grey[800]! : Colors.grey[300]!;

      final leftTabController = TabController(length: 2, vsync: Navigator.of(dialogContext));
      final rightTabController = TabController(length: 2, vsync: Navigator.of(dialogContext));

      return Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(20),
        child: Container(
          constraints: const BoxConstraints(
            maxWidth: 1000,
            maxHeight: 700,
          ),
          decoration: BoxDecoration(
            color: cardColor,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: borderColor, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.2),
                blurRadius: 10,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Column(
            children: [
              // Header
              Container(
                height: 50,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  border: Border(bottom: BorderSide(color: borderColor)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  children: [
                    Text(
                      'Farm Details',
                      style: GoogleFonts.roboto(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: textColor,
                      ),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: Icon(Icons.close, size: 20, color: secondaryTextColor),
                      onPressed: () => Navigator.pop(dialogContext),
                    ),
                  ],
                ),
              ),

              // Main Content
              Expanded(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    /// LEFT PANEL
                    Container(
                      width: 300,
                      decoration: BoxDecoration(
                        border: Border(right: BorderSide(color: borderColor)),
                      ),
                      child: Column(
                        children: [
                          // Farm Image
                          Container(
                            height: 180,
                            width: double.infinity,
                            color: isDark ? Colors.grey[800] : Colors.grey[200],
                            child: farm.imageUrl.isNotEmpty
                                ? Image.network(farm.imageUrl, fit: BoxFit.cover)
                                : Icon(Icons.agriculture, size: 60, color: secondaryTextColor),
                          ),

                          // Left Tabs
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderColor)),
                            ),
                            child: TabBar(
                              controller: leftTabController,
                              indicatorColor: primaryColor,
                              labelColor: primaryColor,
                              unselectedLabelColor: secondaryTextColor,
                              labelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
                              tabs: const [
                                Tab(text: 'Overview'),
                                Tab(text: 'Production'),
                              ],
                            ),
                          ),

                          // Left Tab Content
                          Expanded(
                            child: TabBarView(
                              controller: leftTabController,
                              children: [
                                _buildClassicOverview(farm, textColor, secondaryTextColor!),
                                _buildClassicProduction(textColor, secondaryTextColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),

                    /// RIGHT PANEL
                    Expanded(
                      child: Column(
                        children: [
                          // Right Tabs
                          Container(
                            height: 40,
                            decoration: BoxDecoration(
                              border: Border(bottom: BorderSide(color: borderColor)),
                            ),
                            child: TabBar(
                              controller: rightTabController,
                              indicatorColor: primaryColor,
                              labelColor: primaryColor,
                              unselectedLabelColor: secondaryTextColor,
                              labelStyle: GoogleFonts.roboto(fontSize: 14, fontWeight: FontWeight.w500),
                              tabs: const [
                                Tab(text: 'Performance'),
                                Tab(text: 'Energy'),
                              ],
                            ),
                          ),

                          // Right Tab Content
                          Expanded(
                            child: TabBarView(
                              controller: rightTabController,
                              children: [
                                _buildClassicPerformance(textColor, secondaryTextColor),
                                _buildClassicEnergy(textColor, secondaryTextColor),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              // Footer
              Container(
                height: 60,
                decoration: BoxDecoration(
                  color: isDark ? Colors.grey[850] : Colors.grey[100],
                  border: Border(top: BorderSide(color: borderColor)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(dialogContext),
                      child: Text(
                        'Cancel',
                        style: GoogleFonts.roboto(
                          color: secondaryTextColor,
                          fontSize: 14,
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    ElevatedButton(
                      onPressed: () {
                        // Save functionality
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(2),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
                      ),
                      child: Text(
                        'Save Changes',
                        style: GoogleFonts.roboto(
                          color: Colors.white,
                          fontSize: 14,
                        ),
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
}


Widget _buildClassicOverview(Farm farm, Color textColor, Color secondaryTextColor) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Farm Information',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildClassicDetailRow(
          label: "Farm Name",
          value: farm.name,
          icon: Icons.business,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
        const Divider(height: 24),
        _buildClassicDetailRow(
          label: "Owner",
          value: "Farm Estates",
          icon: Icons.account_circle_sharp,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
        const Divider(height: 24),
        _buildClassicDetailRow(
          label: "Assigned Manager",
          value: "Farm Estates",
          icon: Icons.man,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
         const Divider(height: 24),
        _buildClassicDetailRow(
          label: "Assigned Care Taker",
          value: "Farm Estates",
          icon: Icons.person,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
        const Divider(height: 24),
        _buildClassicDetailRow(
          label: "Location",
          value: farm.location,
          icon: Icons.location_on,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
        const Divider(height: 24),
        _buildClassicDetailRow(
          label: "Status",
          value: farm.status,
          icon: Icons.info,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
        const Divider(height: 24),
        _buildClassicDetailRow(
          label: "Last Activity",
          value: farm.lastActivity,
          icon: Icons.update,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
      ],
    ),
  );
}

Widget _buildClassicProduction(Color textColor, Color secondaryTextColor) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Production Metrics',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        _buildClassicDetailRow(
          label: "Current Yield",
          value: "245 kWh",
          icon: Icons.assessment,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
        const Divider(height: 24),
        _buildClassicDetailRow(
          label: "Monthly Average",
          value: "7,350 kWh",
          icon: Icons.show_chart,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
        const Divider(height: 24),
        _buildClassicDetailRow(
          label: "Efficiency",
          value: "92%",
          icon: Icons.bar_chart,
          textColor: textColor,
          secondaryColor: secondaryTextColor,
        ),
      ],
    ),
  );
}

Widget _buildClassicPerformance(Color textColor, Color secondaryTextColor) {
  return StatefulBuilder(
    builder: (context, setState) {
      return SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Date Range Selector
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Performance Dashboard',
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                ),
                TextButton.icon(
                  onPressed: () async {
                    final DateTimeRange? picked = await showDateRangePicker(
                      context: context,
                      initialDateRange: _dateRange,
                      firstDate: DateTime(2020),
                      lastDate: DateTime.now(),
                      builder: (context, child) {
                        return Theme(
                          data: Theme.of(context).copyWith(
                            colorScheme: ColorScheme.light(
                              primary: AppColors.primary,
                              onPrimary: Colors.white,
                              surface: Theme.of(context).cardColor,
                              onSurface: textColor,
                            ),
                            dialogBackgroundColor: Theme.of(context).cardColor,
                          ),
                          child: child!,
                        );
                      },
                    );
                    if (picked != null) {
                      setState(() => _dateRange = picked);
                    }
                  },
                  icon: Icon(Icons.calendar_today, size: 16, color: secondaryTextColor),
                  label: Text(
                    '${DateFormat('MMM d').format(_dateRange.start)} - ${DateFormat('MMM d, y').format(_dateRange.end)}',
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Performance Metrics Grid
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              childAspectRatio: 2.5,
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              children: [
                _buildMetricCard(
                  title: "Crop Yield",
                  value: "12.5 t/ha",
                  icon: Icons.grass,
                  trend: Icons.trending_up,
                  trendColor: Colors.green,
                  textColor: textColor,
                  secondaryColor: secondaryTextColor,
                ),
                _buildMetricCard(
                  title: "Water Usage",
                  value: "3,200 L/day",
                  icon: Icons.water_drop,
                  trend: Icons.trending_down,
                  trendColor: Colors.red,
                  textColor: textColor,
                  secondaryColor: secondaryTextColor,
                ),
                _buildMetricCard(
                  title: "Soil Quality",
                  value: "8.2/10",
                  icon: Icons.terrain,
                  trend: Icons.trending_flat,
                  trendColor: Colors.orange,
                  textColor: textColor,
                  secondaryColor: secondaryTextColor,
                ),
                _buildMetricCard(
                  title: "Pest Control",
                  value: "95%",
                  icon: Icons.bug_report,
                  trend: Icons.trending_up,
                  trendColor: Colors.green,
                  textColor: textColor,
                  secondaryColor: secondaryTextColor,
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            // Yield Trend Chart
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: secondaryTextColor.withOpacity(0.2)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Crop Yield Trend',
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(height: 8),
                  SizedBox(
                    height: 200,
                    child: LineChart(
                      LineChartData(
                        gridData: FlGridData(show: false),
                        titlesData: FlTitlesData(
                          bottomTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                final date = _dateRange.start.add(Duration(days: value.toInt()));
                                return Padding(
                                  padding: const EdgeInsets.only(top: 8.0),
                                  child: Text(
                                    DateFormat('MMM d').format(date),
                                    style: GoogleFonts.roboto(
                                      fontSize: 10,
                                      color: secondaryTextColor,
                                    ),
                                  ),
                                );
                              },
                              reservedSize: 30,
                            ),
                          ),
                          leftTitles: AxisTitles(
                            sideTitles: SideTitles(
                              showTitles: true,
                              getTitlesWidget: (value, meta) {
                                return Text(
                                  '${value.toInt()} t/ha',
                                  style: GoogleFonts.roboto(
                                    fontSize: 10,
                                    color: secondaryTextColor,
                                  ),
                                );
                              },
                              reservedSize: 40,
                            ),
                          ),
                          rightTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                          topTitles: AxisTitles(
                            sideTitles: SideTitles(showTitles: false),
                          ),
                        ),
                        borderData: FlBorderData(
                          show: true,
                          border: Border.all(
                            color: secondaryTextColor.withOpacity(0.2),
                          ),
                        ),
                        lineBarsData: [
                          LineChartBarData(
                            spots: _generatePerformanceData(),
                            isCurved: true,
                            color: AppColors.primary,
                            barWidth: 2,
                            isStrokeCapRound: true,
                            dotData: FlDotData(show: false),
                            belowBarData: BarAreaData(
                              show: true,
                              color: AppColors.primary.withOpacity(0.1),
                            ),
                          ),
                        ],
                        minX: 0,
                        maxX: _dateRange.end.difference(_dateRange.start).inDays.toDouble(),
                        minY: 0,
                        maxY: 20,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 24),
            Text(
              'Recent Activities',
              style: GoogleFonts.roboto(
                fontSize: 16,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
            const SizedBox(height: 8),
            
            // Activity Timeline
            Column(
              children: [
                _buildActivityItem(
                  icon: Icons.water,
                  title: "Irrigation Completed",
                  time: "Today, 10:30 AM",
                  secondaryColor: secondaryTextColor,
                ),
                _buildActivityItem(
                  icon: Icons.agriculture,
                  title: "Fertilizer Applied",
                  time: "Yesterday, 3:45 PM",
                  secondaryColor: secondaryTextColor,
                ),
                _buildActivityItem(
                  icon: Icons.pest_control,
                  title: "Pest Control Spray",
                  time: "2 days ago",
                  secondaryColor: secondaryTextColor,
                ),
              ],
            ),
          ],
        ),
      );
    },
  );
}

// Add this to your state class
DateTimeRange _dateRange = DateTimeRange(
  start: DateTime.now().subtract(const Duration(days: 30)),
  end: DateTime.now(),
);

List<FlSpot> _generatePerformanceData() {
  final days = _dateRange.end.difference(_dateRange.start).inDays;
  return List.generate(days, (index) {
    final day = _dateRange.start.add(Duration(days: index));
    final progress = index / days;
    // Simulate some variation in the data
    final value = 10 + 5 * sin(progress * 2 * pi) + Random().nextDouble() * 3;
    return FlSpot(index.toDouble(), value);
  });
}

Widget _buildClassicEnergy(Color textColor, Color secondaryTextColor) {
  return SingleChildScrollView(
    padding: const EdgeInsets.all(16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'Energy Overview',
          style: GoogleFonts.roboto(
            fontSize: 18,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 16),
        
        // Energy Summary
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border.all(color: secondaryTextColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Current Power Generation",
                    style: GoogleFonts.roboto(
                      fontSize: 14,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    "24.5 kW",
                    style: GoogleFonts.roboto(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              LinearProgressIndicator(
                value: 0.82,
                backgroundColor: secondaryTextColor.withOpacity(0.1),
                color: Colors.green,
                minHeight: 8,
              ),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "82% of capacity",
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                  Text(
                    "Max: 30 kW",
                    style: GoogleFonts.roboto(
                      fontSize: 12,
                      color: secondaryTextColor,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        
        const SizedBox(height: 24),
        Text(
          'Energy Sources',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        
        // Energy Sources
        Column(
          children: [
            _buildEnergySourceItem(
              icon: Icons.solar_power,
              source: "Solar Panels",
              percentage: "65%",
              value: "15.9 kW",
              color: Colors.amber,
              textColor: textColor,
              secondaryColor: secondaryTextColor,
            ),
            _buildEnergySourceItem(
              icon: Icons.wind_power,
              source: "Wind Turbine",
              percentage: "25%",
              value: "6.1 kW",
              color: Colors.blue,
              textColor: textColor,
              secondaryColor: secondaryTextColor,
            ),
            _buildEnergySourceItem(
              icon: Icons.battery_charging_full,
              source: "Battery Storage",
              percentage: "10%",
              value: "2.5 kW",
              color: Colors.green,
              textColor: textColor,
              secondaryColor: secondaryTextColor,
            ),
          ],
        ),
        
        const SizedBox(height: 24),
        Text(
          'Daily Energy Production',
          style: GoogleFonts.roboto(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: textColor,
          ),
        ),
        const SizedBox(height: 8),
        
        // Energy Chart Placeholder
        Container(
          height: 200,
          decoration: BoxDecoration(
            border: Border.all(color: secondaryTextColor.withOpacity(0.2)),
            borderRadius: BorderRadius.circular(4),
          ),
          alignment: Alignment.center,
          child: Text(
            "Energy Production Chart",
            style: GoogleFonts.roboto(
              color: secondaryTextColor,
            ),
          ),
        ),
      ],
    ),
  );
}

Widget _buildMetricCard({
  required String title,
  required String value,
  required IconData icon,
  required IconData trend,
  required Color trendColor,
  required Color textColor,
  required Color secondaryColor,
}) {
  return Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      border: Border.all(color: secondaryColor.withOpacity(0.2)),
      borderRadius: BorderRadius.circular(4),
    ),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: secondaryColor.withOpacity(0.1),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: textColor),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 13,
                  color: secondaryColor,
                ),
              ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    value,
                    style: GoogleFonts.roboto(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: textColor,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Icon(trend, size: 20, color: trendColor),
                ],
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildActivityItem({
  required IconData icon,
  required String title,
  required String time,
  required Color secondaryColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 20, color: secondaryColor),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: secondaryColor,
                ),
              ),
              Text(
                time,
                style: GoogleFonts.roboto(
                  fontSize: 12,
                  color: secondaryColor,
                ),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

Widget _buildEnergySourceItem({
  required IconData icon,
  required String source,
  required String percentage,
  required String value,
  required Color color,
  required Color textColor,
  required Color secondaryColor,
}) {
  return Padding(
    padding: const EdgeInsets.symmetric(vertical: 8),
    child: Row(
      children: [
        Container(
          padding: const EdgeInsets.all(4),
          decoration: BoxDecoration(
            color: color.withOpacity(0.2),
            shape: BoxShape.circle,
          ),
          child: Icon(icon, size: 20, color: color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                source,
                style: GoogleFonts.roboto(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                  color: textColor,
                ),
              ),
              const SizedBox(height: 4),
              LinearProgressIndicator(
                value: double.parse(percentage.replaceAll('%', '')) / 100,
                backgroundColor: secondaryColor.withOpacity(0.1),
                color: color,
                minHeight: 4,
              ),
            ],
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          style: GoogleFonts.roboto(
            fontSize: 14,
            fontWeight: FontWeight.bold,
            color: textColor,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          percentage,
          style: GoogleFonts.roboto(
            fontSize: 14,
            color: secondaryColor,
          ),
        ),
      ],
    ),
  );
}

Widget _buildClassicDetailRow({
  required String label,
  required String value,
  required IconData icon,
  required Color textColor,
  required Color secondaryColor,
}) {
  return Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Icon(icon, size: 20, color: secondaryColor),
      const SizedBox(width: 12),
      Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: GoogleFonts.roboto(
                fontSize: 13,
                color: secondaryColor,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              value,
              style: GoogleFonts.roboto(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: textColor,
              ),
            ),
          ],
        ),
      ),
    ],
  );
}


void _showEditFarmDialog(Farm farm) {
  // Similar to add farm dialog but with pre-filled values
  // Implement edit functionality here
}
}

