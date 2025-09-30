import 'package:flutter/material.dart';
import '../../widgets/headers/owner_header.dart';
import '../../widgets/sidebars/owner_sidebar.dart';
import '../../widgets/cards/farm/first_row.dart';
import '../../widgets/cards/farm/second_row.dart';
import '../../widgets/cards/farm/third_row.dart';
import '../../widgets/cards/farm/fourth_row.dart';

class ownerFarmsScreen extends StatefulWidget {
  const ownerFarmsScreen({super.key});

  @override
  State<ownerFarmsScreen> createState() => _ownerFarmsScreenState();
}

class _ownerFarmsScreenState extends State<ownerFarmsScreen> {
  int selectedIndex = 1;
  bool isDark = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final args = ModalRoute.of(context)?.settings.arguments as Map?;
      setState(() => isDark = args?['isDark'] ?? false);
    });
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = screenWidth < 600;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: SafeArea(
        child: Container(
          decoration: BoxDecoration(
            gradient: isDark
                ? AppBackgroundGradient.getDarkGradient()
                : AppBackgroundGradient.getLightGradient(),
          ),
          child: Column(
            children: [
              OwnerHeader(
                isDark: isDark,
                onToggleDarkMode: () => setState(() => isDark = !isDark),
                onMenuPressed: null,
              ),
              Expanded(
                child: Row(
                  children: [
                    if (!isMobile)
                      OwnerSidebar(
                        selectedIndex: selectedIndex,
                        onItemSelected: (idx) =>
                            setState(() => selectedIndex = idx),
                        isDark: isDark,
                        isMobile: false,
                      ),
                    Expanded(
                      child: SingleChildScrollView(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(5, 0, 5, 0),
                          child: LayoutBuilder(
                            builder: (context, constraints) {
                              // Large screens: Row with 4 Expanded containers
                              if (constraints.maxWidth > 900) {
                                final maxWidth = constraints.maxWidth;

                                return Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    _buildContainer(
                                        context, FirstRow(isDark: isDark),
                                        isRowLayout: true, maxWidth: maxWidth),
                                    _buildContainer(
                                        context, SecondRow(isDark: isDark),
                                        isRowLayout: true, maxWidth: maxWidth),
                                    _buildContainer(
                                        context, ThirdRow(isDark: isDark),
                                        isRowLayout: true, maxWidth: maxWidth),
                                    _buildContainer(
                                        context, FourthRow(isDark: isDark),
                                        isRowLayout: true, maxWidth: maxWidth),
                                  ],
                                );
                              }

                              // Medium screens: Wrap in 2x2 grid
                              else if (constraints.maxWidth > 600) {
                                return Wrap(
                                  spacing: 16,
                                  runSpacing: 16,
                                  children: [
                                    SizedBox(
                                      width: constraints.maxWidth / 2 - 12,
                                      child: FirstRow(isDark: isDark),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth / 2 - 12,
                                      child: SecondRow(isDark: isDark),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth / 2 - 12,
                                      child: ThirdRow(isDark: isDark),
                                    ),
                                    SizedBox(
                                      width: constraints.maxWidth / 2 - 12,
                                      child: FourthRow(isDark: isDark),
                                    ),
                                  ],
                                );
                              }

                              // Small screens: scrollable Column
                              else {
                                return SingleChildScrollView(
                                  child: Column(
                                    children: [
                                      _buildContainer(
                                          context,
                                          FirstRow(
                                            isDark: isDark,
                                          )),
                                      const SizedBox(height: 16),
                                      _buildContainer(
                                          context, SecondRow(isDark: isDark)),
                                      const SizedBox(height: 16),
                                      _buildContainer(
                                          context, ThirdRow(isDark: isDark)),
                                      const SizedBox(height: 16),
                                      _buildContainer(
                                          context, FourthRow(isDark: isDark)),
                                    ],
                                  ),
                                );
                              }
                            },
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      bottomNavigationBar: isMobile
          ? OwnerSidebar(
              selectedIndex: selectedIndex,
              onItemSelected: (idx) => setState(() => selectedIndex = idx),
              isDark: isDark,
              isMobile: true,
            )
          : null,
    );
  }

  Widget _buildContainer(
    BuildContext context,
    Widget child, {
    bool isRowLayout = false,
    double? maxWidth,
  }) {
    final screenWidth = MediaQuery.of(context).size.width;
    final isSmallScreen = screenWidth < 600;

    // If it's a row layout and we know the max width, divide equally by 4
    final calculatedWidth = (isRowLayout && maxWidth != null)
        ? (maxWidth / 4) // subtract spacing/margins
        : double.infinity;

    final container = Container(
      width: isSmallScreen ? double.infinity : calculatedWidth,
      padding: const EdgeInsets.all(5),
      child: child,
    );

    return isRowLayout && !isSmallScreen ? container : container;
  }
}

class AppBackgroundGradient {
  static LinearGradient getDarkGradient() {
    return LinearGradient(
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
      colors: [
        Colors.grey.shade900.withOpacity(0.9),
        Colors.grey.shade800.withOpacity(0.95),
        Colors.grey.shade700.withOpacity(0.97),
      ],
      stops: const [0.1, 0.5, 1.0],
      transform: const GradientRotation(0.1),
    );
  }

  static LinearGradient getLightGradient() {
    return LinearGradient(
      begin: Alignment.topCenter,
      end: Alignment.bottomCenter,
      colors: [
        Colors.blueGrey.shade50.withOpacity(0.98),
        Colors.blueGrey.shade100.withOpacity(0.95),
        Colors.blueGrey.shade200.withOpacity(0.93),
      ],
      stops: const [0.0, 0.6, 1.0],
    );
  }
}
