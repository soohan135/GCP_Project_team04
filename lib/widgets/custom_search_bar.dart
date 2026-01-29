import 'package:flutter/material.dart';
import 'package:lucide_icons/lucide_icons.dart';

class CustomSearchBar extends StatefulWidget {
  final Function(String)? onSearch;
  final Function(String)? onSubmitted;
  final Color? backgroundColor;
  final Color? borderColor;

  const CustomSearchBar({
    super.key,
    this.onSearch,
    this.onSubmitted,
    this.backgroundColor,
    this.borderColor,
  });

  @override
  State<CustomSearchBar> createState() => _CustomSearchBarState();
}

class _CustomSearchBarState extends State<CustomSearchBar> {
  final TextEditingController _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 50,
      decoration: BoxDecoration(
        color: widget.backgroundColor ?? Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: widget.borderColor ?? Theme.of(context).dividerColor,
          width: 1.5,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: TextField(
        controller: _controller,
        onChanged: (value) {
          if (widget.onSearch != null) {
            widget.onSearch!(value);
          }
          setState(() {});
        },
        onSubmitted: widget.onSubmitted,
        decoration: InputDecoration(
          hintText: '무엇을 도와드릴까요?',
          hintStyle: TextStyle(color: Theme.of(context).hintColor),
          prefixIcon: Icon(
            LucideIcons.search,
            size: 20,
            color: widget.borderColor != null ? Colors.orange.shade300 : null,
          ),
          suffixIcon: _controller.text.isNotEmpty
              ? IconButton(
                  icon: const Icon(LucideIcons.x, size: 18),
                  onPressed: () {
                    _controller.clear();
                    if (widget.onSearch != null) {
                      widget.onSearch!('');
                    }
                    setState(() {});
                  },
                )
              : null,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(vertical: 13),
        ),
      ),
    );
  }
}
