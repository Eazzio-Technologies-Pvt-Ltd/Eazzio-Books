import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:mobile_books/core/theme/theme.dart';

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
  State<SearchableAutocompleteField<T>> createState() => _SearchableAutocompleteFieldState<T>();
}

class _SearchableAutocompleteFieldState<T extends Object> extends State<SearchableAutocompleteField<T>> {
  late TextEditingController _controller;
  final FocusNode _focusNode = FocusNode();
  T? _selectedItem;
  bool _isSelecting = false;

  @override
  void initState() {
    super.initState();
    _selectedItem = widget.initialValue;
    final initialText = _selectedItem != null ? widget.itemLabelBuilder(_selectedItem!) : '';
    _controller = TextEditingController(text: initialText);
    
    _focusNode.addListener(() {
      if (!_focusNode.hasFocus) {
        // Delay checking focus loss to allow onTap of options to execute first and set _selectedItem
        Future.delayed(const Duration(milliseconds: 200), () {
          if (!mounted) return;
          if (_isSelecting) return;
          
          final text = _controller.text;
          final matching = widget.items.where((item) => widget.itemLabelBuilder(item).toLowerCase() == text.toLowerCase()).firstOrNull;
          if (matching != null) {
            setState(() {
              _selectedItem = matching;
              _controller.text = widget.itemLabelBuilder(matching);
            });
            widget.onChanged(matching);
          } else {
            if (_selectedItem != null && _controller.text == widget.itemLabelBuilder(_selectedItem!)) {
              // Keep current selection
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
    });
  }

  @override
  void didUpdateWidget(covariant SearchableAutocompleteField<T> oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialValue != oldWidget.initialValue) {
      setState(() {
        _selectedItem = widget.initialValue;
        _controller.text = _selectedItem != null ? widget.itemLabelBuilder(_selectedItem!) : '';
      });
    }
  }

  @override
  void dispose() {
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
        final query = textEditingValue.text;
        if (query.length < 2) {
          return const Iterable.empty();
        }
        return widget.items.where((T item) {
          return widget.searchMatcher(item, query);
        });
      },
      displayStringForOption: widget.itemLabelBuilder,
      fieldViewBuilder: (context, textEditingController, focusNode, onFieldSubmitted) {
        return TextFormField(
          controller: textEditingController,
          focusNode: focusNode,
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
                : const Icon(Icons.search, size: 20),
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
            child: SizedBox(
              width: MediaQuery.of(context).size.width - 48,
              child: ListView.builder(
                padding: EdgeInsets.zero,
                shrinkWrap: true,
                itemCount: options.length + (widget.onAddNew != null ? 1 : 0),
                itemBuilder: (BuildContext context, int index) {
                  if (index == options.length) {
                    return ListTile(
                      leading: const Icon(Icons.add, color: AppColors.primaryBlue),
                      title: Text(
                         widget.addNewLabel ?? 'Add New',
                        style: const TextStyle(color: AppColors.primaryBlue, fontWeight: FontWeight.bold),
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
                  return ListTile(
                    title: Text(
                      widget.itemLabelBuilder(option),
                    ),
                    onTap: () {
                      setState(() {
                        _isSelecting = true;
                        _selectedItem = option;
                        _controller.text = widget.itemLabelBuilder(option);
                      });
                      onSelected(option);
                      widget.onChanged(option);
                      // Clear selecting flag after a brief moment
                      Future.delayed(const Duration(milliseconds: 100), () {
                        _isSelecting = false;
                      });
                    },
                  );
                },
              ),
            ),
          ),
        );
      },
    );
  }
}
