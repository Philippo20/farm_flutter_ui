import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class OwnerProductionWidget extends StatefulWidget {
  final bool isDark;

  const OwnerProductionWidget({super.key, required this.isDark});

  @override
  State<OwnerProductionWidget> createState() => _OwnerProductionWidgetState();
}

class _OwnerProductionWidgetState extends State<OwnerProductionWidget> {
  final List<Map<String, dynamic>> _allProducts = [
    {
      "name": "Tomatoes",
      "batch": "B-2023-001",
      "quantity": "500 kg",
      "status": "Germinating",
      "assignee": "John Doe",
      "progress": 0.2
    },
    {
      "name": "Lettuce",
      "batch": "B-2023-002",
      "quantity": "200 kg",
      "status": "Transplanted",
      "assignee": "Jane Smith",
      "progress": 0.5
    },
    {
      "name": "Strawberries",
      "batch": "B-2023-003",
      "quantity": "150 kg",
      "status": "Harvesting",
      "assignee": "Mike Johnson",
      "progress": 0.8
    },
    {
      "name": "Carrots",
      "batch": "B-2023-004",
      "quantity": "300 kg",
      "status": "Harvested",
      "assignee": "Sarah Williams",
      "progress": 0.9
    },
    {
      "name": "Potatoes",
      "batch": "B-2023-005",
      "quantity": "400 kg",
      "status": "Delivered",
      "assignee": "David Brown",
      "progress": 1.0
    },
    {
      "name": "Cabbage",
      "batch": "B-2023-006",
      "quantity": "350 kg",
      "status": "Harvested",
      "assignee": "Linda Green",
      "progress": 0.95
    },
    {
      "name": "Peppers",
      "batch": "B-2023-007",
      "quantity": "250 kg",
      "status": "Transplanted",
      "assignee": "Sam Red",
      "progress": 0.4
    },
    {
      "name": "Onions",
      "batch": "B-2023-008",
      "quantity": "275 kg",
      "status": "Germinating",
      "assignee": "Anna Blue",
      "progress": 0.1
    },
  ];

  List<Map<String, dynamic>> _filteredProducts = [];
  final TextEditingController _searchController = TextEditingController();
  String _statusFilter = "All";
  int _currentPage = 0;
  int _rowsPerPage = 5;

  @override
  void initState() {
    super.initState();
    _filteredProducts = _allProducts;
    _searchController.addListener(_filterProducts);
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filterProducts() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      _filteredProducts = _allProducts.where((product) {
        final matchesSearch =
            product["name"].toString().toLowerCase().contains(query) ||
                product["batch"].toString().toLowerCase().contains(query) ||
                product["assignee"].toString().toLowerCase().contains(query);

        final matchesStatus = _statusFilter == "All" ||
            product["status"].toString() == _statusFilter;

        return matchesSearch && matchesStatus;
      }).toList();
      _currentPage = 0; // Reset to first page when filtering
    });
  }

  @override
  Widget build(BuildContext context) {
    final isDark = widget.isDark;
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    return Container(
      decoration: BoxDecoration(
        color: isDark ? Colors.grey[900] : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      padding: const EdgeInsets.all(16),
      constraints: const BoxConstraints(minHeight: 400),
      child: SingleChildScrollView(
        // Add this
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min, // Important change
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Production Overview",
                  style: GoogleFonts.poppins(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : Colors.black,
                  ),
                ),
                if (!isSmallScreen)
                  SizedBox(
                    width: 200,
                    child: DropdownButtonFormField<String>(
                      value: _statusFilter,
                      items: [
                        "All",
                        "Germinating",
                        "Transplanted",
                        "Harvesting",
                        "Harvested",
                        "Delivered"
                      ]
                          .map((status) => DropdownMenuItem(
                                value: status,
                                child: Text(status),
                              ))
                          .toList(),
                      onChanged: (value) {
                        setState(() {
                          _statusFilter = value!;
                          _filterProducts();
                        });
                      },
                      decoration: InputDecoration(
                        labelText: "Filter by Status",
                        labelStyle: GoogleFonts.inter(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                        contentPadding:
                            const EdgeInsets.symmetric(horizontal: 12),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: TextField(
                controller: _searchController,
                decoration: InputDecoration(
                  hintText: "Search products...",
                  hintStyle: GoogleFonts.inter(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                  prefixIcon: Icon(Icons.search,
                      color: isDark ? Colors.white70 : Colors.black54),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  filled: true,
                  fillColor: isDark ? Colors.grey[800] : Colors.grey[100],
                ),
              ),
            ),
            const SizedBox(height: 16),
            if (isSmallScreen)
              _buildMobileList(context, isDark)
            else
              ConstrainedBox(
                // Add this
                constraints: BoxConstraints(
                  minHeight: 300,
                  maxHeight: MediaQuery.of(context).size.height * 0.6,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Expanded(
                        child:
                            _buildDesktopTable(context, screenWidth, isDark)),
                    _buildPaginationControls(isDark),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildDesktopTable(
      BuildContext context, double maxWidth, bool isDark) {
    final start = _currentPage * _rowsPerPage;
    final end = (_currentPage + 1) * _rowsPerPage;
    final visibleRows = _filteredProducts.length > _rowsPerPage
        ? _filteredProducts.sublist(
            start,
            end > _filteredProducts.length ? _filteredProducts.length : end,
          )
        : _filteredProducts;

    return LayoutBuilder(
      builder: (context, constraints) {
        return SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: ConstrainedBox(
            constraints: BoxConstraints(minWidth: constraints.maxWidth),
            child: IntrinsicWidth(
              // Ensures table stretches to match column widths
              child: DataTable(
                showCheckboxColumn: false,
                headingRowColor: WidgetStateProperty.resolveWith(
                  (states) => isDark ? Colors.grey[800]! : Colors.grey[100]!,
                ),
                dataRowColor: WidgetStateProperty.resolveWith(
                  (states) => isDark ? Colors.grey[900]! : Colors.white,
                ),
                columnSpacing: 4,
                horizontalMargin: 16,
                dividerThickness: 1,
                columns: [
                  _buildColumn("Product Name", isDark, 100),
                  _buildColumn("Batch No.", isDark, 100),
                  _buildColumn("Quantity", isDark, 100),
                  _buildColumn("Status", isDark, 100),
                  _buildColumn("Assignee", isDark, 100),
                  _buildColumn("Progress", isDark, 100),
                ],
                rows: visibleRows
                    .map((product) => _buildDataRow(product, isDark))
                    .toList(),
              ),
            ),
          ),
        );
      },
    );
  }

  DataColumn _buildColumn(String title, bool isDark, double width) =>
      DataColumn(
        label: SizedBox(
          width: width,
          child: Text(
            title,
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
        ),
      );

  Widget _buildMobileList(BuildContext context, bool isDark) {
    return Column(
      children: [
        if (_filteredProducts.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              "No products found",
              style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : Colors.black54),
            ),
          )
        else
          ..._filteredProducts
              .map((product) => _buildMobileCard(product, isDark)),
        if (_filteredProducts.length > 5)
          _buildMobilePaginationControls(isDark),
      ],
    );
  }

  Widget _buildMobileCard(Map<String, dynamic> product, bool isDark) {
   return InkWell(
    onTap: () => _showProductDetails(context, product, isDark),
    borderRadius: BorderRadius.circular(12),
    child: Card(
      margin: const EdgeInsets.only(bottom: 12),
      color: isDark ? Colors.grey[800] : Colors.white,
      child: Padding(
        padding: const EdgeInsets.all(12),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product["name"] as String,
                        style: GoogleFonts.inter(
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        "Batch: ${product["batch"]}",
                        style: GoogleFonts.inter(
                          color: isDark ? Colors.white70 : Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                PopupMenuButton(
                  icon: Icon(Icons.more_vert,
                      color: isDark ? Colors.white70 : Colors.black54),
                  itemBuilder: (context) => [
                    PopupMenuItem(
                      child: Text("View Details"),
                      onTap: () => _showMobileDetails(context, product, isDark),
                    ),
                    PopupMenuItem(
                      onTap: () {
                        Navigator.pop(context); // Close the popup menu
                        WidgetsBinding.instance.addPostFrameCallback((_) {
                          _showStatusFilterDialog(context, widget.isDark);
                        });
                      },
                      child: Text(
                        "Filter by Status",
                        style: GoogleFonts.inter(
                          color: widget.isDark ? Colors.white : Colors.black,
                        ),
                      ),
                    )
                  ],
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
                    color: _getStatusColor(product["status"] as String),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    product["status"] as String,
                    style: GoogleFonts.inter(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
                const Spacer(),
                Text(
                  "${(((product["progress"] ?? 0.0) as double) * 100).toStringAsFixed(0)}% complete",
                  style: GoogleFonts.inter(
                    color: isDark ? Colors.white70 : Colors.black54,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            LinearProgressIndicator(
              value: product["progress"] as double,
              backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
              color: _getProgressColor(product["progress"] as double),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ],
        ),
      ),
    ),
   ),
   );
  }

  Widget _buildPaginationControls(bool isDark) {
    final totalPages = (_filteredProducts.length / _rowsPerPage).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          DropdownButton<int>(
            dropdownColor: isDark ? Colors.grey[800] : Colors.white,
            value: _rowsPerPage,
            items: [5, 10, 15, 20]
                .map((e) => DropdownMenuItem(
                      value: e,
                      child: Text(
                        "$e items per page",
                        style: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : Colors.black54,
                            fontSize: 12),
                      ),
                    ))
                .toList(),
            onChanged: (value) {
              if (value != null) {
                setState(() {
                  _rowsPerPage = value;
                  _currentPage = 0;
                });
              }
            },
          ),
          Row(
            children: [
              IconButton(
                icon: const Icon(Icons.first_page, size: 15),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage = 0)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.chevron_left, size: 15),
                onPressed: _currentPage > 0
                    ? () => setState(() => _currentPage--)
                    : null,
              ),
              Text(
                "Page ${_currentPage + 1} of ${totalPages == 0 ? 1 : totalPages}",
                style: GoogleFonts.inter(
                    fontSize: 12,
                    color: isDark ? Colors.white70 : Colors.black54),
              ),
              IconButton(
                icon: const Icon(Icons.chevron_right, size: 15),
                onPressed: _currentPage < totalPages - 1 && totalPages > 0
                    ? () => setState(() => _currentPage++)
                    : null,
              ),
              IconButton(
                icon: const Icon(Icons.last_page, size: 15),
                onPressed: _currentPage < totalPages - 1 && totalPages > 0
                    ? () => setState(() => _currentPage = totalPages - 1)
                    : null,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMobilePaginationControls(bool isDark) {
    final totalPages = (_filteredProducts.length / 5).ceil();
    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          IconButton(
            icon: const Icon(Icons.chevron_left),
            onPressed:
                _currentPage > 0 ? () => setState(() => _currentPage--) : null,
          ),
          Text(
            "${_currentPage + 1}/$totalPages",
            style: GoogleFonts.inter(),
          ),
          IconButton(
            icon: const Icon(Icons.chevron_right),
            onPressed: _currentPage < totalPages - 1
                ? () => setState(() => _currentPage++)
                : null,
          ),
        ],
      ),
    );
  }

  void _showMobileDetails(
      BuildContext context, Map<String, dynamic> product, bool isDark) {
    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[800] : Colors.white,
          title: Text(
            product["name"] as String,
            style:
                GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildDetailRow("Batch No.", product["batch"] as String, isDark),
              _buildDetailRow(
                  "Quantity", product["quantity"] as String, isDark),
              _buildDetailRow("Status", product["status"] as String, isDark),
              _buildDetailRow(
                  "Assignee", product["assignee"] as String, isDark),
              const SizedBox(height: 16),
              LinearProgressIndicator(
                value: product["progress"] as double,
                backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                color: _getProgressColor(product["progress"] as double),
                minHeight: 8,
                borderRadius: BorderRadius.circular(4),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  "${(((product["progress"] ?? 0.0) as double) * 100).toStringAsFixed(0)}% complete",
                  style: GoogleFonts.inter(
                      color: isDark ? Colors.white70 : Colors.black54),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              child: Text(
                "Close",
                style: GoogleFonts.inter(
                    color: isDark ? Colors.white : Colors.blue),
              ),
              onPressed: () => Navigator.pop(context),
            ),
          ],
        );
      },
    );
  }

  void _showStatusFilterDialog(BuildContext context, bool isDark) {
    final statusOptions = [
      "All",
      "Germinating",
      "Transplanted",
      "Harvesting",
      "Harvested",
      "Delivered"
    ];

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: isDark ? Colors.grey[900] : Colors.white,
          title: Text(
            "Filter by Status",
            style: GoogleFonts.inter(
              color: isDark ? Colors.white : Colors.black,
            ),
          ),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: statusOptions.map((status) {
                return ListTile(
                  title: Text(
                    status,
                    style: GoogleFonts.inter(
                      color: isDark ? Colors.white : Colors.black,
                    ),
                  ),
                  trailing: _statusFilter == status
                      ? Icon(Icons.check,
                          color: isDark ? Colors.blue[200] : Colors.blue)
                      : null,
                  onTap: () {
                    setState(() {
                      _statusFilter = status;
                      _filterProducts();
                    });
                    Navigator.pop(context);
                  },
                );
              }).toList(),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStatusFilterOption(String status, bool isDark) {
    return ListTile(
      title: Text(
        status,
        style: GoogleFonts.inter(color: isDark ? Colors.white : Colors.black),
      ),
      trailing: _statusFilter == status
          ? Icon(Icons.check, color: isDark ? Colors.white : Colors.blue)
          : null,
      onTap: () {
        setState(() {
          _statusFilter = status;
          _filterProducts();
        });
        Navigator.pop(context);
      },
    );
  }

  Widget _buildDetailRow(String label, String value, bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: GoogleFonts.inter(
              fontWeight: FontWeight.w600,
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: GoogleFonts.inter(
                color: isDark ? Colors.white70 : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  DataRow _buildDataRow(Map<String, dynamic> product, bool isDark) {
    final double progress = product["progress"] as double;
    

    return DataRow(
    onSelectChanged: (_) => _showProductDetails(context, product, isDark),
      cells: [
        DataCell(
          Text(
            product["name"] as String,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        DataCell(
          Text(
            product["batch"] as String,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        DataCell(
          Text(
            product["quantity"] as String,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        DataCell(
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: _getStatusColor(product["status"] as String),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              product["status"] as String,
              style: GoogleFonts.inter(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ),
        DataCell(
          Text(
            product["assignee"] as String,
            style: GoogleFonts.inter(
              color: isDark ? Colors.white70 : Colors.black87,
            ),
          ),
        ),
        DataCell(
          Row(
            children: [
              Expanded(
                child: LinearProgressIndicator(
                  value: progress,
                  backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                  color: _getProgressColor(progress),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              const SizedBox(width: 8),
              Text(
                "${(progress * 100).toStringAsFixed(0)}%",
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: isDark ? Colors.white70 : Colors.black54,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  void _showProductDetails(BuildContext context, Map<String, dynamic> product, bool isDark) {
    
  final statusColors = {
    'Germinating': Colors.blue[400]!,
    'Transplanted': Colors.orange,
    'Harvesting': Colors.purple,
    'Harvested': Colors.green,
    'Delivered': Colors.green[800]!,
  };

  final statusIcons = {
    'Germinating': Icons.spa,
    'Transplanted': Icons.agriculture,
    'Harvesting': Icons.grass,
    'Harvested': Icons.shopping_basket,
    'Delivered': Icons.local_shipping,
  };

  showDialog(
    context: context,
    builder: (context) {
      final screenWidth = MediaQuery.of(context).size.width;
      final isSmallScreen = screenWidth < 600; // Adjust breakpoint as needed

      return Dialog(
        backgroundColor: isDark ? Colors.grey[900] : Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
          side: BorderSide(color: isDark ? Colors.grey[700]! : Colors.grey[200]!),
        ),
        insetPadding: EdgeInsets.symmetric(
          horizontal: isSmallScreen ? 12 : 20,
          vertical: 12,
        ),
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxWidth: isSmallScreen ? screenWidth * 0.95 : 800,
            maxHeight: MediaQuery.of(context).size.height * 0.9,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Static section (title to progress bar)
              Padding(
                padding: EdgeInsets.all(isSmallScreen ? 16 : 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header with close button
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Flexible(
                          child: Text(
                            "Production Details",
                            style: GoogleFonts.poppins(
                              fontSize: isSmallScreen ? 18 : 22,
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : Colors.black,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, size: isSmallScreen ? 20 : 24),
                          color: isDark ? Colors.white70 : Colors.grey[600],
                          onPressed: () => Navigator.pop(context),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Product card with image and basic info
                    Card(
                      elevation: 2,
                      color: isDark ? Colors.grey[800] : Colors.grey[50],
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Padding(
                        padding: EdgeInsets.all(isSmallScreen ? 12 : 16),
                        child: isSmallScreen
                            ? Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProductImageSection(context, product, isDark, statusColors, isSmallScreen),
                                  const SizedBox(height: 12),
                                  _buildProductInfoSection(context, product, isDark, statusColors, statusIcons),
                                ],
                              )
                            : Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _buildProductImageSection(context, product, isDark, statusColors, isSmallScreen),
                                  const SizedBox(width: 20),
                                  Expanded(
                                    child: _buildProductInfoSection(context, product, isDark, statusColors, statusIcons),
                                  ),
                                ],
                              ),
                      ),
                    ),
                   SizedBox(height: isSmallScreen ? 16 : 24),

                    // Progress section
                    Text(
                      "Production Progress",
                      style: GoogleFonts.inter(
                        fontSize: isSmallScreen ? 16 : 18,
                        fontWeight: FontWeight.w600,
                        color: isDark ? Colors.white : Colors.black,
                      ),
                    ),
                    const SizedBox(height: 12),
                    LinearProgressIndicator(
                      value: product["progress"] as double,
                      backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
                      color: _getProgressColor(product["progress"] as double),
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(5),
                    ),
                    const SizedBox(height: 8),
                    isSmallScreen
                        ? Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                "${((product["progress"] ?? 0.0) * 100)}% Complete",
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                "Estimated completion: ${_formatDate(DateTime.now().add(const Duration(days: 3)))}",
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          )
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                "${((product["progress"] ?? 0.0) * 100)}% Complete",
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                              Text(
                                "Estimated completion: ${_formatDate(DateTime.now().add(const Duration(days: 3)))}",
                                style: GoogleFonts.inter(
                                  color: isDark ? Colors.white70 : Colors.grey[600],
                                ),
                              ),
                            ],
                          ),
                  ],
                ),
              ),

              // Scrollable section (timeline and notes)
              Expanded(
                child: SingleChildScrollView(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 16 : 24,
                    vertical: 8,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 8),
                      Text(
                        "Production Timeline",
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                       SizedBox(height: 12),
                      _buildTimeline(product["status"] as String, isDark, isSmallScreen),
                       SizedBox(height: isSmallScreen ? 16 : 24),

                      // Notes section
                      Text(
                        "Notes",
                        style: GoogleFonts.inter(
                          fontSize: isSmallScreen ? 16 : 18,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.white : Colors.black,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? Colors.grey[800] : Colors.grey[100],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "No additional notes for this production batch.",
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                        ),
                      ),
                      const SizedBox(height: 16), // Extra bottom padding
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

Widget _buildProductImageSection(BuildContext context, Map<String, dynamic> product, bool isDark, Map<String, Color> statusColors, bool isSmallScreen) {
  return Container(
    width: isSmallScreen ? double.infinity : 120,
    height: isSmallScreen ? 150 : 120,
    decoration: BoxDecoration(
      borderRadius: BorderRadius.circular(8),
      color: isDark ? Colors.grey[700] : Colors.grey[200],
    ),
    child: Center(
      child: Icon(
        Icons.eco,
        size: isSmallScreen ? 80 : 60,
        color: statusColors[product["status"]] ?? Colors.grey,
      ),
    ),
  );
}

Widget _buildProductInfoSection(BuildContext context, Map<String, dynamic> product, bool isDark, Map<String, Color> statusColors, Map<String, IconData> statusIcons) {
  final screenWidth = MediaQuery.of(context).size.width;
  final isSmallScreen = screenWidth < 600; 
  return Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        product["name"] as String,
        style: GoogleFonts.poppins(
          fontSize: isSmallScreen ? 18 : 20,
          fontWeight: FontWeight.w600,
          color: isDark ? Colors.white : Colors.black,
        ),
      ),
      const SizedBox(height: 8),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: _getStatusColor(product["status"] as String),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  statusIcons[product["status"]] ?? Icons.help_outline,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 6),
                Text(
                  product["status"] as String,
                  style: GoogleFonts.inter(
                    color: Colors.white,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.calendar_today,
                size: 16,
                color: isDark ? Colors.white70 : Colors.grey[600],
              ),
              const SizedBox(width: 4),
              Text(
                "Started: ${_formatDate(DateTime.now().subtract(const Duration(days: 7)))}",
                style: GoogleFonts.inter(
                  color: isDark ? Colors.white70 : Colors.grey[600],
                ),
              ),
            ],
          ),
        ],
      ),
      const SizedBox(height: 12),
      Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _buildInfoChip(
            "Batch: ${product["batch"]}",
            Icons.tag,
            isDark,
            isSmallScreen: isSmallScreen,
          ),
          _buildInfoChip(
            "Quantity: ${product["quantity"]}",
            Icons.scale,
            isDark,
            isSmallScreen: isSmallScreen,
          ),
          _buildInfoChip(
            "Assignee: ${product["assignee"]}",
            Icons.person,
            isDark,
            isSmallScreen: isSmallScreen,
          ),
        ],
      ),
    ],
  );
}

Widget _buildInfoChip(String text, IconData icon, bool isDark, {bool isSmallScreen = false}) {
  return Chip(
    avatar: Icon(
      icon,
      size: isSmallScreen ? 14 : 16,
      color: isDark ? Colors.white70 : Colors.grey[700],
    ),
    label: Text(
      text,
      style: GoogleFonts.inter(
        fontSize: isSmallScreen ? 12 : 13,
        color: isDark ? Colors.white : Colors.black87,
      ),
    ),
    backgroundColor: isDark ? Colors.grey[700] : Colors.grey[200],
    shape: RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(8),
    ),
    padding: isSmallScreen 
        ? const EdgeInsets.symmetric(horizontal: 8, vertical: 4)
        : null,
    materialTapTargetSize: isSmallScreen 
        ? MaterialTapTargetSize.shrinkWrap 
        : null,
  );
}

Widget _buildTimeline(String currentStatus, bool isDark, bool isSmallScreen) {
  final stages = [
    {"name": "Germinating", "icon": Icons.spa, "date": "2023-06-01"},
    {"name": "Transplanted", "icon": Icons.agriculture, "date": "2023-06-15"},
    {"name": "Harvesting", "icon": Icons.grass, "date": "2023-07-10"},
    {"name": "Harvested", "icon": Icons.shopping_basket, "date": "2023-07-20"},
    {"name": "Delivered", "icon": Icons.local_shipping, "date": "2023-07-25"},
  ];

  return Container(
    decoration: BoxDecoration(
      color: isDark ? Colors.grey[800] : Colors.grey[100],
      borderRadius: BorderRadius.circular(12),
    ),
    padding: const EdgeInsets.all(16),
    child: Column(
      children: stages.map((stage) {
        final isCompleted = stages.indexOf(stage) < stages.indexWhere((s) => s["name"] == currentStatus);
        final isCurrent = stage["name"] == currentStatus;
        final isLast = stages.last == stage;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Timeline indicator
                Column(
                  children: [
                    Container(
                      width: 24,
                      height: 24,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? _getStatusColor(currentStatus)
                            : (isCompleted
                                ? Colors.green
                                : (isDark ? Colors.grey[600] : Colors.grey[300])),
                      ),
                      child: Center(
                        child: Icon(
                          isCurrent
                              ? Icons.refresh
                              : (isCompleted ? Icons.check : null),
                          size: 14,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    if (!isLast)
                      Container(
                        width: 2,
                        height: 40,
                        color: isCompleted
                            ? Colors.green
                            : (isDark ? Colors.grey[600] : Colors.grey[300]),
                      ),
                  ],
                ),
                const SizedBox(width: 16),

                // Stage details
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        stage["name"] as String,
                        style: GoogleFonts.inter(
                          fontWeight: isCurrent ? FontWeight.w600 : FontWeight.w500,
                          color: isDark ? Colors.white : Colors.black,
                          fontSize: 15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today,
                            size: 14,
                            color: isDark ? Colors.white70 : Colors.grey[600],
                          ),
                          const SizedBox(width: 4),
                          Text(
                            stage["date"] as String,
                            style: GoogleFonts.inter(
                              color: isDark ? Colors.white70 : Colors.grey[600],
                              fontSize: 13,
                            ),
                          ),
                          if (isCurrent) ...[
                            const SizedBox(width: 12),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 8, vertical: 2),
                              decoration: BoxDecoration(
                                color: _getStatusColor(currentStatus)
                                    .withOpacity(0.2),
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                "Current Stage",
                                style: GoogleFonts.inter(
                                  color: _getStatusColor(currentStatus),
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      if (isCurrent) ...[
                        const SizedBox(height: 8),
                        Text(
                          _getStageDescription(stage["name"] as String),
                          style: GoogleFonts.inter(
                            color: isDark ? Colors.white70 : Colors.grey[600],
                            fontSize: 13,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
          ],
        );
      }).toList(),
    ),
  );
}

String _getStageDescription(String stage) {
  switch (stage) {
    case "Germinating":
      return "Seeds are currently germinating in controlled environment. Expected duration: 7-14 days.";
    case "Transplanted":
      return "Seedlings have been transplanted to the main growing area. Monitoring growth daily.";
    case "Harvesting":
      return "Active harvesting in progress. Quality control checks being performed.";
    case "Harvested":
      return "Harvest completed. Products being prepared for distribution.";
    case "Delivered":
      return "Products have been delivered to distribution centers.";
    default:
      return "Production stage in progress.";
  }
}

String _formatDate(DateTime date) {
  return "${date.day}/${date.month}/${date.year}";
}


  Color _getStatusColor(String status) {
    switch (status.toLowerCase()) {
      case 'germinating':
        return Colors.blue[400]!;
      case 'transplanted':
        return Colors.orange;
      case 'harvesting':
        return Colors.purple;
      case 'harvested':
        return Colors.green;
      case 'delivered':
        return Colors.green[800]!;
      default:
        return Colors.grey;
    }
  }

  Color _getProgressColor(double progress) {
    if (progress >= 0.75) return Colors.green;
    if (progress >= 0.5) return Colors.blue;
    if (progress >= 0.25) return Colors.orange;
    return Colors.red;
  }
}
