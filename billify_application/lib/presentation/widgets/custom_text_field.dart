import 'package:billify/core/constants/app_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Premium design-system input field with dynamic focus, error borders,
/// required-field markers, input formatters, and password toggles.
class CustomTextField extends StatefulWidget {
  final TextEditingController? controller;
  final String label;
  final String? hint;
  final String? helperText;
  final String? initialValue;
  final Function(String)? onChanged;
  final bool isPassword;
  final bool isRequired;
  final String? Function(String?)? validator;
  final TextInputType keyboardType;
  final TextInputAction? textInputAction;
  final ValueChanged<String>? onFieldSubmitted;
  final List<TextInputFormatter>? inputFormatters;
  final FocusNode? focusNode;
  final IconData? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final bool autofocus;
  final bool enabled;
  final bool readOnly;
  final int? maxLength;
  final TextAlign textAlign;
  final TextStyle? style;

  const CustomTextField({
    super.key,
    this.controller,
    required this.label,
    this.hint,
    this.helperText,
    this.initialValue,
    this.onChanged,
    this.isPassword = false,
    this.isRequired = false,
    this.validator,
    this.keyboardType = TextInputType.text,
    this.textInputAction,
    this.onFieldSubmitted,
    this.inputFormatters,
    this.focusNode,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.autofocus = false,
    this.enabled = true,
    this.readOnly = false,
    this.maxLength,
    this.textAlign = TextAlign.start,
    this.style,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField> {
  bool _obscureText = true;

  @override
  void initState() {
    super.initState();
    _obscureText = widget.isPassword;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              widget.label,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: widget.enabled ? null : Colors.grey,
              ),
            ),
            if (widget.isRequired)
              const Text(
                ' *',
                style: TextStyle(
                  color: Colors.redAccent,
                  fontWeight: FontWeight.bold,
                  fontSize: 14,
                ),
              ),
          ],
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: widget.controller,
          initialValue: widget.controller == null ? widget.initialValue : null,
          obscureText: widget.isPassword ? _obscureText : false,
          validator: widget.validator,
          keyboardType: widget.keyboardType,
          textInputAction: widget.textInputAction,
          onFieldSubmitted: widget.onFieldSubmitted,
          inputFormatters: widget.inputFormatters,
          focusNode: widget.focusNode,
          onChanged: widget.onChanged,
          maxLines: widget.isPassword ? 1 : widget.maxLines,
          autofocus: widget.autofocus,
          enabled: widget.enabled,
          readOnly: widget.readOnly,
          maxLength: widget.maxLength,
          textAlign: widget.textAlign,
          style: widget.style,
          decoration: InputDecoration(
            hintText: widget.hint,
            helperText: widget.helperText,
            prefixIcon: widget.prefixIcon != null
                ? Icon(widget.prefixIcon, size: 20)
                : null,
            suffixIcon: widget.isPassword
                ? IconButton(
                    icon: Icon(
                      _obscureText
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                      color: Colors.grey.shade600,
                      size: 20,
                    ),
                    onPressed: () {
                      setState(() {
                        _obscureText = !_obscureText;
                      });
                    },
                  )
                : widget.suffixIcon,
            counterText: "",
            filled: true,
            fillColor: widget.enabled
                ? theme.colorScheme.surface
                : theme.disabledColor.withValues(alpha: 0.05),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.15),
                width: 1,
              ),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(
                color: theme.dividerColor.withValues(alpha: 0.25),
                width: 1,
              ),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(
                color: theme.primaryColor,
                width: 2,
              ),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 1.5,
              ),
            ),
            focusedErrorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(AppConstants.borderRadius),
              borderSide: BorderSide(
                color: theme.colorScheme.error,
                width: 2,
              ),
            ),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 14,
            ),
          ),
        ),
      ],
    );
  }
}
