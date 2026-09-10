import 'package:flutter/material.dart';
import '../theme/app_colors.dart';

class UserSearchField extends StatefulWidget {
  const UserSearchField(
      {super.key, required this.onChanged, required this.value});
  final ValueChanged<String> onChanged;
  final String value;

  @override
  State<UserSearchField> createState() => _UserSearchFieldState();
}

class _UserSearchFieldState extends State<UserSearchField> {
  late final _controller = TextEditingController(text: widget.value);

  @override
  void didUpdateWidget(covariant UserSearchField oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (_controller.text != widget.value) {
      _controller.value = TextEditingValue(
          text: widget.value,
          selection: TextSelection.collapsed(offset: widget.value.length));
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    return TextField(
      controller: _controller,
      textInputAction: TextInputAction.search,
      onChanged: (value) {
        setState(() {});
        widget.onChanged(value);
      },
      style: TextStyle(
          fontSize: 13, color: dark ? Colors.white : AppColors.textPrimary),
      decoration: InputDecoration(
        labelText: 'Search users',
        hintText: 'Name, email, role or phone',
        hintStyle: const TextStyle(fontSize: 12),
        prefixIcon: const Icon(Icons.search_rounded, size: 20),
        suffixIcon: _controller.text.isEmpty
            ? null
            : IconButton(
                tooltip: 'Clear user search',
                icon: const Icon(Icons.close_rounded, size: 18),
                onPressed: () {
                  _controller.clear();
                  setState(() {});
                  widget.onChanged('');
                },
              ),
        filled: true,
        fillColor: dark ? AppColors.surfaceDark : Colors.white,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
        enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(
                color: dark ? Colors.white12 : AppColors.neutral200)),
        focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
            borderSide: BorderSide(color: AppColors.primary, width: 1.5)),
      ),
    );
  }
}
