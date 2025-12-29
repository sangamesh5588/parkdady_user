import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';

class CustomTextField extends StatefulWidget {
  final String label;
  final String? hintText;
  final String? initialValue;
  final bool obscureText;
  final bool enabled;
  final TextInputType keyboardType;
  final TextEditingController? controller;
  final String? Function(String?)? validator;
  final void Function(String)? onChanged;
  final Widget? prefixIcon;
  final Widget? suffixIcon;
  final int maxLines;
  final String? helperText;
  final bool showCounter;

  const CustomTextField({
    super.key,
    required this.label,
    this.hintText,
    this.initialValue,
    this.obscureText = false,
    this.enabled = true,
    this.keyboardType = TextInputType.text,
    this.controller,
    this.validator,
    this.onChanged,
    this.prefixIcon,
    this.suffixIcon,
    this.maxLines = 1,
    this.helperText,
    this.showCounter = false,
  });

  @override
  State<CustomTextField> createState() => _CustomTextFieldState();
}

class _CustomTextFieldState extends State<CustomTextField>
    with TickerProviderStateMixin {
  late AnimationController _borderAnimationController;
  late Animation<double> _borderWidthAnimation;
  late Animation<Color?> _borderColorAnimation;

  FocusNode? _focusNode;
  bool _hasFocus = false;
  bool _hasError = false;

  @override
  void initState() {
    super.initState();

    _borderAnimationController = AnimationController(
      duration: AppConstants.microAnimationDuration,
      vsync: this,
    );

    _borderWidthAnimation = Tween<double>(
      begin: 1.0,
      end: 2.0,
    ).animate(CurvedAnimation(
      parent: _borderAnimationController,
      curve: Curves.easeInOut,
    ));

    _borderColorAnimation = ColorTween(
      begin: null,
      end: null,
    ).animate(_borderAnimationController);

    _focusNode = FocusNode();
    _focusNode?.addListener(_handleFocusChange);
  }

  @override
  void dispose() {
    _borderAnimationController.dispose();
    _focusNode?.removeListener(_handleFocusChange);
    _focusNode?.dispose();
    super.dispose();
  }

  void _handleFocusChange() {
    setState(() {
      _hasFocus = _focusNode?.hasFocus ?? false;
    });

    if (_hasFocus) {
      _borderAnimationController.forward();
    } else {
      _borderAnimationController.reverse();
    }
  }

  void _updateBorderColor(ColorScheme colorScheme, bool hasError) {
    Color? targetColor;
    if (hasError) {
      targetColor = colorScheme.error;
    } else if (_hasFocus) {
      targetColor = AppColors.ctaPrimary;
    } else {
      targetColor = colorScheme.outline;
    }

    _borderColorAnimation = ColorTween(
      begin: _borderColorAnimation.value,
      end: targetColor,
    ).animate(_borderAnimationController);

    if (_hasFocus || hasError) {
      _borderAnimationController.forward();
    } else {
      _borderAnimationController.reverse();
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _borderAnimationController,
      builder: (context, child) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ConstrainedBox(
              constraints: BoxConstraints(
                minWidth: 200, // Minimum width for usability
                minHeight: AppConstants.textFieldHeight, // Minimum height
                maxHeight: widget.maxLines > 1
                    ? AppConstants.textFieldHeight * widget.maxLines * 1.2
                    : AppConstants.textFieldHeight, // Max height for multi-line
              ),
              child: Container(
                height: widget.maxLines > 1
                    ? null // Allow height to expand for multi-line
                    : AppConstants.textFieldHeight,
                decoration: BoxDecoration(
                  color: AppColors.secondaryBackground, // Light gray background for Airbnb style
                  borderRadius: BorderRadius.circular(AppConstants.radius12),
                  border: Border.all(
                    color: _hasFocus ? AppColors.ctaPrimary : AppColors.borderLight,
                    width: _hasFocus ? 2.0 : 1.0,
                  ),
                  boxShadow: _hasFocus ? [AppColors.lightShadow] : null,
                ),
              child: TextFormField(
                controller: widget.controller,
                focusNode: _focusNode,
                initialValue: widget.initialValue,
                obscureText: widget.obscureText,
                enabled: widget.enabled,
                keyboardType: widget.keyboardType,
                validator: (value) {
                  final error = widget.validator?.call(value);
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    setState(() {
                      _hasError = error != null;
                      _updateBorderColor(colorScheme, _hasError);
                    });
                  });
                  return error;
                },
                onChanged: (value) {
                  widget.onChanged?.call(value);
                  // Clear error state when user starts typing
                  if (_hasError) {
                    setState(() {
                      _hasError = false;
                      _updateBorderColor(colorScheme, false);
                    });
                  }
                },
                maxLines: widget.maxLines,
                style: TextStyle(
                  color: AppColors.getInputText(context),
                  fontSize: AppConstants.fontSize16,
                  fontWeight: AppConstants.fontWeightRegular,
                ),
                decoration: InputDecoration(
                  hintText: widget.hintText ?? widget.label,
                  helperText: widget.helperText,
                  counterText: widget.showCounter ? null : '',
                  hintStyle: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: AppConstants.fontSize16,
                    fontWeight: AppConstants.fontWeightRegular,
                  ),
                  prefixIcon: widget.prefixIcon != null
                      ? Container(
                          padding: EdgeInsets.all(AppConstants.spacing12),
                          child: IconTheme(
                            data: IconThemeData(
                              color: _hasFocus
                                  ? AppColors.ctaPrimary
                                  : AppColors.getTextMuted(context),
                              size: AppConstants.fontSize20,
                            ),
                            child: widget.prefixIcon!,
                          ),
                        )
                      : null,
                  suffixIcon: widget.suffixIcon != null
                      ? Container(
                          padding: EdgeInsets.all(AppConstants.spacing12),
                          child: IconTheme(
                            data: IconThemeData(
                              color: _hasFocus
                                  ? AppColors.ctaPrimary
                                  : AppColors.getTextMuted(context),
                              size: AppConstants.fontSize20,
                            ),
                            child: widget.suffixIcon!,
                          ),
                        )
                      : null,
                  contentPadding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing16,
                    vertical: AppConstants.spacing16,
                  ),
                  border: InputBorder.none,
                  enabledBorder: InputBorder.none,
                  focusedBorder: InputBorder.none,
                  errorBorder: InputBorder.none,
                  focusedErrorBorder: InputBorder.none,
                  disabledBorder: InputBorder.none,
                ),
              ),
              ),
            ),
            if (widget.helperText != null && !_hasError)
              Padding(
                padding: EdgeInsets.only(
                  top: AppConstants.spacing4,
                  left: AppConstants.spacing12,
                ),
                child: Text(
                  widget.helperText!,
                  style: TextStyle(
                    color: AppColors.getTextMuted(context),
                    fontSize: AppConstants.fontSize12,
                    fontWeight: AppConstants.fontWeightRegular,
                  ),
                ),
              ),
          ],
        );
      },
    );
  }
}
