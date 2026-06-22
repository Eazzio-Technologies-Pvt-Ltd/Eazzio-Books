import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class AppTextField extends StatefulWidget {
  final String label;
  final String? placeholder;
  final TextEditingController? controller;
  final bool isPassword;
  final TextInputType keyboardType;
  final String? Function(String?)? validator;
  final IconData? prefixIcon;
  final void Function(String)? onChanged;
  final bool autofocus;

  const AppTextField({
    super.key,
    required this.label,
    this.placeholder,
    this.controller,
    this.isPassword = false,
    this.keyboardType = TextInputType.text,
    this.validator,
    this.prefixIcon,
    this.onChanged,
    this.autofocus = false,
  });

  @override
  State<AppTextField> createState() => _AppTextFieldState();
}

class _AppTextFieldState extends State<AppTextField> {
  bool _obscureText = true;
  bool _isFocused = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  void _onFocusChanged(bool hasFocus) {
    setState(() {
      _isFocused = hasFocus;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Label above field (static, not floating)
        Text(
          widget.label,
          style: AppTextStyles.bodyLarge.copyWith(
            fontWeight: FontWeight.w600,
            color: AppColors.textPrimary,
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        // Input text box
        Focus(
          onFocusChange: _onFocusChanged,
          child: FormField<String>(
            validator: widget.validator,
            builder: (FormFieldState<String> state) {
              // Update error text if validation fails
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (state.hasError && _errorText != state.errorText) {
                  setState(() {
                    _errorText = state.errorText;
                  });
                } else if (!state.hasError && _errorText != null) {
                  setState(() {
                    _errorText = null;
                  });
                }
              });

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: 52, // Min tap target height: 52px
                    decoration: BoxDecoration(
                      color: AppColors.bgCard,
                      borderRadius: BorderRadius.circular(AppRadius.sm),
                      border: Border.all(
                        color: _errorText != null
                            ? AppColors.error
                            : (_isFocused ? AppColors.primary : AppColors.border),
                        width: _isFocused || _errorText != null ? 1.8 : 1.0,
                      ),
                      boxShadow: _isFocused && _errorText == null
                          ? [
                              BoxShadow(
                                color: AppColors.primary.withOpacity(0.08),
                                blurRadius: 4,
                                offset: const Offset(0, 2),
                              )
                            ]
                          : null,
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    alignment: Alignment.center,
                    child: Row(
                      children: [
                        if (widget.prefixIcon != null) ...[
                          Icon(
                            widget.prefixIcon,
                            color: AppColors.textHint,
                            size: 20,
                          ),
                          const SizedBox(width: 10),
                        ],
                        Expanded(
                          child: TextField(
                            controller: widget.controller,
                            obscureText: widget.isPassword && _obscureText,
                            keyboardType: widget.keyboardType,
                            autofocus: widget.autofocus,
                            style: AppTextStyles.bodyMedium.copyWith(
                              color: AppColors.textPrimary,
                            ),
                            decoration: InputDecoration(
                              hintText: widget.placeholder,
                              hintStyle: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.textHint,
                              ),
                              border: InputBorder.none,
                              contentPadding: EdgeInsets.zero,
                              isDense: true,
                            ),
                            onChanged: (val) {
                              state.didChange(val);
                              if (widget.onChanged != null) {
                                widget.onChanged!(val);
                              }
                            },
                          ),
                        ),
                        if (widget.isPassword) ...[
                          IconButton(
                            icon: Icon(
                              _obscureText ? Icons.visibility : Icons.visibility_off,
                              color: AppColors.textHint,
                              size: 20,
                            ),
                            onPressed: () {
                              setState(() {
                                _obscureText = !_obscureText;
                              });
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                        ] else if (widget.controller != null && widget.controller!.text.isNotEmpty) ...[
                          IconButton(
                            icon: const Icon(
                              Icons.clear,
                              color: AppColors.textHint,
                              size: 20,
                            ),
                            onPressed: () {
                              widget.controller!.clear();
                              state.didChange('');
                              if (widget.onChanged != null) {
                                widget.onChanged!('');
                              }
                              setState(() {});
                            },
                            padding: EdgeInsets.zero,
                            constraints: const BoxConstraints(),
                            splashRadius: 20,
                          ),
                        ],
                      ],
                    ),
                  ),
                  if (_errorText != null) ...[
                    const SizedBox(height: 6),
                    Text(
                      _errorText!,
                      style: AppTextStyles.caption.copyWith(
                        color: AppColors.error,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }
}
