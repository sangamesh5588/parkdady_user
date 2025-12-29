import 'package:flutter/material.dart';
import '../../core/colors.dart';
import '../../core/constants.dart';

enum CustomButtonVariant {
  filled,     // Primary filled button (gradient)
  tonal,      // Secondary filled button (solid)
  outlined,   // Outlined button
  text,       // Text-only button
}

class CustomButton extends StatefulWidget {
  final String text;
  final VoidCallback? onPressed;
  final bool isLoading;
  final CustomButtonVariant variant;
  final double? width;
  final double? height;
  final IconData? icon;
  final bool iconRight;

  const CustomButton({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.variant = CustomButtonVariant.filled,
    this.width,
    this.height,
    this.icon,
    this.iconRight = false,
  });

  // Legacy constructor for backward compatibility
  const CustomButton.outlined({
    super.key,
    required this.text,
    this.onPressed,
    this.isLoading = false,
    this.width,
    this.height,
    this.icon,
    this.iconRight = false,
  }) : variant = CustomButtonVariant.outlined;

  @override
  State<CustomButton> createState() => _CustomButtonState();
}

class _CustomButtonState extends State<CustomButton> with TickerProviderStateMixin {
  late AnimationController _scaleController;
  late Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _scaleController = AnimationController(
      duration: AppConstants.buttonAnimationDuration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(
      begin: 1.0,
      end: 0.95,
    ).animate(CurvedAnimation(
      parent: _scaleController,
      curve: Curves.easeInOut,
    ));
  }

  @override
  void dispose() {
    _scaleController.dispose();
    super.dispose();
  }

  void _onTapDown(TapDownDetails details) {
    if (!widget.isLoading && widget.onPressed != null) {
      _scaleController.forward();
    }
  }

  void _onTapUp(TapUpDetails details) {
    _scaleController.reverse();
  }

  void _onTapCancel() {
    _scaleController.reverse();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return AnimatedBuilder(
      animation: _scaleAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _scaleAnimation.value,
          child: ConstrainedBox(
            constraints: BoxConstraints(
              minWidth: 80, // Minimum touch target width
              minHeight: 44, // Minimum touch target height (Material Design)
              maxWidth: widget.width ?? double.infinity,
              maxHeight: widget.height ?? AppConstants.buttonHeight,
            ),
            child: Container(
              width: widget.width ?? double.infinity,
              height: widget.height ?? AppConstants.buttonHeight,
              decoration: _getDecoration(colorScheme),
              child: ElevatedButton(
                onPressed: widget.isLoading ? null : widget.onPressed,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _getBackgroundColor(colorScheme),
                  foregroundColor: _getForegroundColor(colorScheme),
                  elevation: 0, // We handle shadows in decoration
                  shadowColor: Colors.transparent,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(AppConstants.radius12),
                    side: _getBorderSide(colorScheme),
                  ),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppConstants.spacing16,
                    vertical: AppConstants.spacing12,
                  ),
                  minimumSize: const Size(80, 44), // Ensure minimum touch target
                ).copyWith(
                  overlayColor: WidgetStateProperty.resolveWith<Color?>(
                    (Set<WidgetState> states) {
                      if (states.contains(WidgetState.pressed)) {
                        return _getPressedOverlayColor(colorScheme);
                      }
                      return null;
                    },
                  ),
                ),
                child: GestureDetector(
                  onTapDown: _onTapDown,
                  onTapUp: _onTapUp,
                  onTapCancel: _onTapCancel,
                  child: widget.isLoading
                      ? _buildLoadingIndicator(colorScheme)
                      : _buildButtonContent(colorScheme),
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  BoxDecoration _getDecoration(ColorScheme colorScheme) {
    final shadows = _getBoxShadows(colorScheme);

    switch (widget.variant) {
      case CustomButtonVariant.filled:
        return BoxDecoration(
          color: AppColors.ctaPrimary, // Solid black for Airbnb style
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          boxShadow: shadows,
        );

      case CustomButtonVariant.tonal:
        return BoxDecoration(
          color: AppColors.secondaryBackground,
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          boxShadow: shadows,
        );

      case CustomButtonVariant.outlined:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radius12),
          border: Border.all(
            color: AppColors.borderLight,
            width: 1.5,
          ),
        );

      case CustomButtonVariant.text:
        return BoxDecoration(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(AppConstants.radius12),
        );
    }
  }

  List<BoxShadow> _getBoxShadows(ColorScheme colorScheme) {
    if (widget.variant == CustomButtonVariant.outlined ||
        widget.variant == CustomButtonVariant.text) {
      return [];
    }

    return [AppColors.lightShadow]; // Use Airbnb-style shadow
  }

  Color _getBackgroundColor(ColorScheme colorScheme) {
    switch (widget.variant) {
      case CustomButtonVariant.filled:
        return Colors.transparent; // Gradient handled in decoration
      case CustomButtonVariant.tonal:
        return Colors.transparent; // Color handled in decoration
      case CustomButtonVariant.outlined:
        return Colors.transparent;
      case CustomButtonVariant.text:
        return Colors.transparent;
    }
  }

  Color _getForegroundColor(ColorScheme colorScheme) {
    switch (widget.variant) {
      case CustomButtonVariant.filled:
        return AppColors.getButtonPrimaryText(context);
      case CustomButtonVariant.tonal:
        return colorScheme.onSecondaryContainer;
      case CustomButtonVariant.outlined:
        return colorScheme.onSurface;
      case CustomButtonVariant.text:
        return colorScheme.primary;
    }
  }

  BorderSide _getBorderSide(ColorScheme colorScheme) {
    if (widget.variant == CustomButtonVariant.outlined) {
      return BorderSide.none; // Border handled in decoration
    }
    return BorderSide.none;
  }

  Color _getPressedOverlayColor(ColorScheme colorScheme) {
    switch (widget.variant) {
      case CustomButtonVariant.filled:
        return Colors.white.withOpacity(0.1);
      case CustomButtonVariant.tonal:
        return colorScheme.onSecondaryContainer.withOpacity(0.1);
      case CustomButtonVariant.outlined:
        return colorScheme.onSurface.withOpacity(0.05);
      case CustomButtonVariant.text:
        return colorScheme.primary.withOpacity(0.05);
    }
  }

  Widget _buildLoadingIndicator(ColorScheme colorScheme) {
    return SizedBox(
      width: AppConstants.spacing20,
      height: AppConstants.spacing20,
      child: CircularProgressIndicator(
        strokeWidth: 2.5,
        valueColor: AlwaysStoppedAnimation<Color>(
          _getForegroundColor(colorScheme),
        ),
      ),
    );
  }

  Widget _buildButtonContent(ColorScheme colorScheme) {
    final children = <Widget>[];

    if (widget.icon != null && !widget.iconRight) {
      children.add(Icon(
        widget.icon,
        size: AppConstants.fontSize18,
        color: _getForegroundColor(colorScheme),
      ));
      children.add(SizedBox(width: AppConstants.spacing8));
    }

    children.add(Text(
      widget.text,
      style: TextStyle(
        fontSize: AppConstants.fontSize16,
        fontWeight: AppConstants.fontWeightSemiBold,
        letterSpacing: 0.5,
      ),
    ));

    if (widget.icon != null && widget.iconRight) {
      children.add(SizedBox(width: AppConstants.spacing8));
      children.add(Icon(
        widget.icon,
        size: AppConstants.fontSize18,
        color: _getForegroundColor(colorScheme),
      ));
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: children,
    );
  }
}
