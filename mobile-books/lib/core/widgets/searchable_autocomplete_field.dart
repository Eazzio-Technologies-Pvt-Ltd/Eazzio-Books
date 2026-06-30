import 'package:flutter/material.dart';
import 'package:mobile_books/core/theme/theme.dart';

/// A reusable autocomplete field that shows a filterable dropdown list.
/// Supports optional "Add New" entry at the bottom of the list.
class SearchableAutocompleteField<T extends Object> extends StatefulWidget {
  final String labelText;
  final T? initialValue;
  final List<T> items;
  final String Function(T) itemLabelBuilder;
  final bool Function(T, String) searchMatcher;
  final void Function(T?) onChanged;
  final String? Function(T?)? validator;
  final VoidCallback? onAddNew;
  final String? addNewLabel;

  const SearchableAutocompleteField({
    super.key,
    required this.labelText,
    required this.initialValue,
    required this.items,
    required this.itemLabelBuilder,
    required this.searchMatcher,
    required this.onChanged,
    this.validator,
    this.onAddNew,
    this.addNewLabel,
  });

  @override
  State<SearchableAutocompleteField<T>> createState() =>
      _SearchableAutocompleteFieldState<T>();
}

class _SearchableAutocompleteFieldState<T extends Object>
    extends State<SearchableAutocompleteField<T>> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  T? _selectedItem;

  /// Track whether we are in the middle of selecting from the list.
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialValue;
    final initialText =
        _selectedItem != null ? widget.itemLabelBuilder(_selectedItem!) : '';
    _controller = TextEditingController(text: initialText);

    _focusNode.addListener(_onFocusChange);
  }

  void _onFocusChange() {
    if (!_focusNode.hasFocus) {
      // Give the tap on an option time to fire first
      Future.delayed(const Duration(milliseconds: 200), () {
        if (!mounted) return;
        if (_isSelecting) return;

        final text = _controller.text.trim();

        // Exact match → keep it selected
        final matching = widget.items
            .where((item) =>
                widget.itemLabelBuilder(item).toLowerCase() ==
                text.toLowerCase())
            .firstOrNull;

        if (matching != null) {
          if (_selectedItem != matching) {
            setState(() {
              _selectedItem = matching;
              _controller.text = widget.itemLabelBuilder(matching);
            });
            widget.onChanged(matching);
          }
        } else {
          // No match — if user cleared the text or typed something wrong,
          // check if current _selectedItem text still matches; if not, clear.
          if (_selectedItem != null &&
              _controller.text ==
                  widget.itemLabelBuilder(_selectedItem!)) {
            // Keep the current selection — user didn't actually change anything.
          } else {
            setState(() {
              _selectedItem = null;
              _controller.clear();
            });
            widget.onChanged(null);
          }
        }
      });
    }
  }

  @override
  void didUpdateWidget(covariant SearchableAutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Sync selection when the parent passes a new initialValue
    // (e.g., after loading data or clearing a line item).
    if (widget.initialValue != oldWidget.initialValue) {
      final newSelection = widget.initialValue;
      setState(() {
        _selectedItem = newSelection;
        _controller.text =
            newSelection != null ? widget.itemLabelBuilder(newSelection) : '';
      });
    }
  }

  @override
  void dispose() {
    _focusNode.removeListener(_onFocusChange);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return RawAutocomplete<T>(
      textEditingController: _controller,
      focusNode: _focusNode,
      optionsBuilder: (TextEditingValue textEditingValue) {
        final query = textEditingValue.text.trim();
        // Show full list when query is empty OR matches exactly the selected item
        // (i.e., the user just opened it).
        if (query.isEmpty ||
            (_selectedItem != null &&
                query.toLowerCase() ==
                    widget.itemLabelBuilder(_selectedItem!).toLowerCase())) {
          return widget.items;
        }
        return widget.items
            .where((T item) => widget.searchMatcher(item, query));
      },
      displayStringForOption: widget.itemLabelBuilder,
      fieldViewBuilder:
          (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
          onTap: () {
            // Select all text on tap so user can immediately type to search
            if (textEditingController.text.isNotEmpty) {
              textEditingController.selection = TextSelection(
                baseOffset: 0,
                extentOffset: textEditingController.text.length,
              );
            }
          },
          decoration: InputDecoration(
            labelText: widget.labelText,
            suffixIcon: textEditingController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      textEditingController.clear();
                      setState(() {
                        _selectedItem = null;
                      });
                      widget.onChanged(null);
                    },
                  )
                : IconButton(
                    icon: const Icon(Icons.arrow_drop_down, size: 24),
                    onPressed: () {
                      if (focusNode.hasFocus) {
                        // Already open — close
                        focusNode.unfocus();
                      } else {
                        focusNode.requestFocus();
                      }
                    },
                  ),
          ),
          validator: (val) {
            if (widget.validator != null) {
              return widget.validator!(_selectedItem);
            }
            return null;
          },
        );
      },
      optionsViewBuilder: (context, onSelected, options) {
        return Align(
          alignment: Alignment.topLeft,
          child: Material(
            elevation: 4.0,
            borderRadius: BorderRadius.circular(8),
            color: isDark ? AppColors.surfaceDark : AppColors.surfaceLight,
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxHeight: 280),
              child: SizedBox(
                width: MediaQuery.of(context).size.width - 48,
                child: ListView.builder(
                  padding: EdgeInsets.zero,
                  shrinkWrap: true,
                  itemCount:
                      options.length + (widget.onAddNew != null ? 1 : 0),
                  itemBuilder: (BuildContext context, int index) {
                    if (index == options.length) {
                      // "Add New" entry
                      return ListTile(
                        leading:
                            const Icon(Icons.add, color: AppColors.primaryBlue),
                        title: Text(
                          widget.addNewLabel ?? 'Add New',
                          style: const TextStyle(
                              color: AppColors.primaryBlue,
                              fontWeight: FontWeight.bold),
                        ),
                        onTap: () {
                          _focusNode.unfocus();
                          if (widget.onAddNew != null) {
                            widget.onAddNew!();
                          }
                        },
                      );
                    }

                    final T option = options.elementAt(index);
                    final isSelected = _selectedItem == option;

                    return ListTile(
                      tileColor: isSelected
                          ? AppColors.primaryBlue.withValues(alpha: 0.08)
                          : null,
                      title: Text(
                        widget.itemLabelBuilder(option),
                        style: TextStyle(
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(Icons.check,
                              size: 16, color: AppColors.primaryBlue)
                          : null,
                      onTap: () {
                        _isSelecting = true;
                        setState(() {
                          _selectedItem = option;
                          _controller.text = widget.itemLabelBuilder(option);
                        });
                        onSelected(option);
                        widget.onChanged(option);
                        Future.delayed(const Duration(milliseconds: 150), () {
                          _isSelecting = false;
                        });
                      },
                    );
                  },
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}
