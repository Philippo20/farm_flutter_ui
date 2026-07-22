import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import '../theme/app_spacing.dart';
import '../providers/theme_provider.dart';
import '../providers/notification_provider.dart';
import '../models/dashboard_app_bar_models.dart';
import '../../constants/colors.dart';
import 'notification_center.dart';
import 'weather_info_chip.dart';

class ModernHeader extends ConsumerStatefulWidget
    implements PreferredSizeWidget {
  final String title;
  final String userName;
  final WeatherInfo? weatherInfo;
  final VoidCallback? onLogoTap;
  final List<String> tenants;
  final String? selectedTenant;
  final TenantChangedCallback? onTenantChanged;
  final List<GlobalSearchItem> searchItems;
  final String searchPlaceholder;
  final List<QuickActionItem> quickActions;
  final List<SystemStatusIndicator> systemStatuses;
  final VoidCallback? onSupportTap;

  const ModernHeader({
    super.key,
    required this.title,
    this.userName = 'Admin',
    this.weatherInfo,
    this.onLogoTap,
    this.tenants = const [],
    this.selectedTenant,
    this.onTenantChanged,
    this.searchItems = const [],
    this.searchPlaceholder = 'Search farms, users, sensors...',
    this.quickActions = const [],
    this.systemStatuses = const [],
    this.onSupportTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(104);

  @override
  ConsumerState<ModernHeader> createState() => _ModernHeaderState();
}

class _ModernHeaderState extends ConsumerState<ModernHeader> {
  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeProvider);
    final isDark = themeMode == ThemeMode.dark;
    final notifications = ref.watch(notificationProvider);
    final unreadCount = notifications.where((n) => !n.isRead).length;
    final greeting = _greetingMessage();
    final colorScheme = Theme.of(context).colorScheme;

    return AppBar(
      automaticallyImplyLeading: false,
      toolbarHeight: widget.preferredSize.height,
      titleSpacing: 0,
      flexibleSpace: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: AppSpacing.lg,
            vertical: AppSpacing.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  _LogoAndTenantSwitcher(
                    isDark: isDark,
                    tenants: widget.tenants,
                    selectedTenant: widget.selectedTenant,
                    onTenantChanged: widget.onTenantChanged,
                    onLogoTap: widget.onLogoTap,
                  ),
                  const SizedBox(width: AppSpacing.md),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          '$greeting, ${widget.userName}',
                          style: GoogleFonts.poppins(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          widget.title,
                          style: GoogleFonts.inter(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: colorScheme.onSurface.withOpacity(0.7),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  const _DateTimeBadge(),
                  if (widget.weatherInfo != null) ...[
                    const SizedBox(width: AppSpacing.md),
                    WeatherInfoChip(
                      condition: widget.weatherInfo!.condition,
                      temperature: widget.weatherInfo!.temperature,
                      isDark: isDark,
                    ),
                  ],
                ],
              ),
              const SizedBox(height: AppSpacing.md),
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  Expanded(
                    child: GlobalSearchField(
                      items: widget.searchItems,
                      placeholder: widget.searchPlaceholder,
                      isDark: isDark,
                    ),
                  ),
                  const SizedBox(width: AppSpacing.md),
                  if (widget.systemStatuses.isNotEmpty)
                    _StatusIndicatorsRow(
                      statuses: widget.systemStatuses,
                    ),
                  if (widget.systemStatuses.isNotEmpty)
                    const SizedBox(width: AppSpacing.md),
                  if (widget.quickActions.isNotEmpty)
                    QuickActionsButton(actions: widget.quickActions),
                  if (widget.quickActions.isNotEmpty)
                    const SizedBox(width: AppSpacing.sm),
                  _NotificationSummary(unreadCount: unreadCount),
                  const SizedBox(width: AppSpacing.sm),
                  if (widget.onSupportTap != null)
                    IconButton(
                      tooltip: 'Support & Docs',
                      icon: const Icon(Icons.help_outline),
                      onPressed: widget.onSupportTap,
                    ),
                  IconButton(
                    tooltip: themeMode == ThemeMode.dark
                        ? 'Switch to light mode'
                        : 'Switch to dark mode',
                    icon: Icon(
                      themeMode == ThemeMode.dark
                          ? Icons.light_mode
                          : Icons.dark_mode,
                    ),
                    onPressed: () =>
                        ref.read(themeProvider.notifier).toggleTheme(),
                  ),
                  PopupMenuButton(
                    icon: const CircleAvatar(
                      backgroundColor: AppColors.primary,
                      child: Icon(Icons.person, color: Colors.white),
                    ),
                    itemBuilder: (context) => const [
                      PopupMenuItem(
                        value: 'profile',
                        child: Text('Profile'),
                      ),
                      PopupMenuItem(
                        value: 'settings',
                        child: Text('Settings'),
                      ),
                      PopupMenuItem(
                        value: 'logout',
                        child: Text('Logout'),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _greetingMessage() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Good Morning';
    if (hour < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

class _LogoAndTenantSwitcher extends StatelessWidget {
  const _LogoAndTenantSwitcher({
    required this.isDark,
    required this.tenants,
    required this.selectedTenant,
    required this.onTenantChanged,
    required this.onLogoTap,
  });

  final bool isDark;
  final List<String> tenants;
  final String? selectedTenant;
  final TenantChangedCallback? onTenantChanged;
  final VoidCallback? onLogoTap;

  @override
  Widget build(BuildContext context) {
    final hasTenants = tenants.isNotEmpty;

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        GestureDetector(
          onTap: onLogoTap,
          child: Image.asset(
            isDark
                ? 'assets/logos/logo_white.png'
                : 'assets/logos/logo_black.png',
            height: 40,
            fit: BoxFit.contain,
          ),
        ),
        if (hasTenants) ...[
          const SizedBox(width: AppSpacing.sm),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
              border: Border.all(
                color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                value: selectedTenant ?? tenants.first,
                onChanged: (value) {
                  if (value != null) {
                    onTenantChanged?.call(value);
                  }
                },
                style: GoogleFonts.inter(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
                items: tenants
                    .map(
                      (tenant) => DropdownMenuItem<String>(
                        value: tenant,
                        child: Text(tenant),
                      ),
                    )
                    .toList(),
                icon: const Icon(Icons.arrow_drop_down),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _DateTimeBadge extends StatelessWidget {
  const _DateTimeBadge();

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return StreamBuilder<DateTime>(
      stream: Stream.periodic(
        const Duration(seconds: 30),
        (_) => DateTime.now(),
      ),
      initialData: DateTime.now(),
      builder: (context, snapshot) {
        final now = snapshot.data ?? DateTime.now();
        final timezone = now.timeZoneName;
        final formattedTime = TimeOfDay.fromDateTime(now).format(context);
        final formattedDate =
            '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';

        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
          decoration: BoxDecoration(
            color: colorScheme.surfaceVariant.withOpacity(0.4),
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.access_time, size: 18),
              const SizedBox(width: 6),
              Text(
                '$formattedTime - $timezone',
                style: GoogleFonts.inter(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                formattedDate,
                style: GoogleFonts.inter(
                  fontSize: 12,
                  color: colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _StatusIndicatorsRow extends StatelessWidget {
  const _StatusIndicatorsRow({required this.statuses});

  final List<SystemStatusIndicator> statuses;

  Color _backgroundForLevel(SystemStatusLevel level, ColorScheme scheme) {
    switch (level) {
      case SystemStatusLevel.ok:
        return scheme.primary.withOpacity(0.12);
      case SystemStatusLevel.warning:
        return AppColors.warning.withOpacity(0.15);
      case SystemStatusLevel.error:
        return AppColors.danger.withOpacity(0.15);
    }
  }

  Color _textForLevel(SystemStatusLevel level, ColorScheme scheme) {
    switch (level) {
      case SystemStatusLevel.ok:
        return scheme.primary;
      case SystemStatusLevel.warning:
        return AppColors.warning;
      case SystemStatusLevel.error:
        return AppColors.danger;
    }
  }

  IconData _iconForLevel(SystemStatusLevel level) {
    switch (level) {
      case SystemStatusLevel.ok:
        return Icons.check_circle_outline;
      case SystemStatusLevel.warning:
        return Icons.warning_amber_outlined;
      case SystemStatusLevel.error:
        return Icons.error_outline;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Wrap(
      spacing: AppSpacing.xs,
      children: statuses
          .map(
            (status) => Tooltip(
              message: status.tooltip ?? status.label,
              child: Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: _backgroundForLevel(status.level, colorScheme),
                  borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _iconForLevel(status.level),
                      size: 16,
                      color: _textForLevel(status.level, colorScheme),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      status.label,
                      style: GoogleFonts.inter(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: _textForLevel(status.level, colorScheme),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
          .toList(),
    );
  }
}

class QuickActionsButton extends StatelessWidget {
  const QuickActionsButton({required this.actions});

  final List<QuickActionItem> actions;

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton<QuickActionItem>(
      tooltip: 'Quick actions',
      icon: const Icon(Icons.bolt_outlined),
      onSelected: (action) => action.onSelected(),
      itemBuilder: (context) => actions
          .map(
            (action) => PopupMenuItem<QuickActionItem>(
              value: action,
              child: Row(
                children: [
                  Icon(action.icon, size: 18),
                  const SizedBox(width: AppSpacing.sm),
                  Text(action.label),
                ],
              ),
            ),
          )
          .toList(),
    );
  }
}

class _NotificationSummary extends StatelessWidget {
  const _NotificationSummary({required this.unreadCount});

  final int unreadCount;

  @override
  Widget build(BuildContext context) {
    final text = unreadCount > 0 ? '$unreadCount unread' : 'All caught up';

    return Row(
      children: [
        Text(
          text,
          style: GoogleFonts.inter(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
          ),
        ),
        const SizedBox(width: AppSpacing.xs),
        const NotificationCenter(),
      ],
    );
  }
}

class GlobalSearchField extends StatefulWidget {
  const GlobalSearchField({
    super.key,
    required this.items,
    required this.placeholder,
    required this.isDark,
  });

  final List<GlobalSearchItem> items;
  final String placeholder;
  final bool isDark;

  @override
  State<GlobalSearchField> createState() => _GlobalSearchFieldState();
}

class _GlobalSearchFieldState extends State<GlobalSearchField> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final LayerLink _layerLink = LayerLink();
  OverlayEntry? _overlayEntry;
  Timer? _debounce;
  List<GlobalSearchItem> _results = [];

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    _focusNode.removeListener(_handleFocusChange);
    _focusNode.dispose();
    _removeOverlay();
    super.dispose();
  }

  void _handleFocusChange() {
    if (!_focusNode.hasFocus) {
      _removeOverlay();
    } else if (_controller.text.isNotEmpty) {
      _updateResults(_controller.text);
    }
  }

  void _onQueryChanged(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 250), () {
      _updateResults(query);
    });
  }

  void _updateResults(String query) {
    if (query.isEmpty) {
      _results = [];
      _removeOverlay();
      return;
    }

    final lowercaseQuery = query.toLowerCase();
    _results = widget.items
        .where((item) => item.label.toLowerCase().contains(lowercaseQuery))
        .take(6)
        .toList();

    if (_results.isEmpty) {
      _removeOverlay();
      return;
    }

    _showOverlay();
  }

  void _showOverlay() {
    if (_overlayEntry == null) {
      _overlayEntry = _createOverlayEntry();
      Overlay.of(context, rootOverlay: true).insert(_overlayEntry!);
    } else {
      _overlayEntry!.markNeedsBuild();
    }
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  OverlayEntry _createOverlayEntry() {
    final renderBox = context.findRenderObject() as RenderBox?;
    final size = renderBox?.size ?? Size.zero;

    return OverlayEntry(
      builder: (context) => Positioned(
        width: size.width,
        child: CompositedTransformFollower(
          link: _layerLink,
          showWhenUnlinked: false,
          offset: Offset(0, size.height + 6),
          child: Material(
            elevation: 6,
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            clipBehavior: Clip.antiAlias,
            color: Theme.of(context).cardColor,
            child: ListView.separated(
              padding: EdgeInsets.zero,
              shrinkWrap: true,
              itemCount: _results.length,
              separatorBuilder: (_, __) => const Divider(height: 1),
              itemBuilder: (context, index) {
                final item = _results[index];
                return ListTile(
                  leading: Icon(item.icon, size: 20),
                  title: Text(item.label),
                  subtitle: item.description != null
                      ? Text(
                          item.description!,
                          style: const TextStyle(fontSize: 12),
                        )
                      : null,
                  onTap: () {
                    item.onSelected?.call();
                    _controller.clear();
                    _removeOverlay();
                    _focusNode.unfocus();
                  },
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        controller: _controller,
        focusNode: _focusNode,
        onChanged: _onQueryChanged,
        decoration: InputDecoration(
          prefixIcon:
              Icon(Icons.search, color: colorScheme.onSurface.withOpacity(0.6)),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () {
                    _controller.clear();
                    _removeOverlay();
                    setState(() {});
                  },
                )
              : null,
          hintText: widget.placeholder,
          filled: true,
          fillColor: widget.isDark
              ? colorScheme.surfaceVariant.withOpacity(0.3)
              : colorScheme.surfaceVariant.withOpacity(0.5),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radiusLg),
            borderSide: BorderSide.none,
          ),
          contentPadding: const EdgeInsets.symmetric(vertical: 12),
        ),
      ),
    );
  }
}
