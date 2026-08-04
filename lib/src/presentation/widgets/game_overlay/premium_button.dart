import 'package:flutter/material.dart';

class PremiumButton extends StatefulWidget {
  final VoidCallback onPressed;
  final IconData icon;
  final String label;
  final String subtitle;
  final Color backgroundColor;
  final Color glowColor;
  final bool isPrimary;
  final bool isCompact;

  const PremiumButton({
    super.key,
    required this.onPressed,
    required this.icon,
    required this.label,
    required this.subtitle,
    required this.backgroundColor,
    required this.glowColor,
    required this.isPrimary,
    this.isCompact = false,
  });

  @override
  State<PremiumButton> createState() => _PremiumButtonState();
}

class _PremiumButtonState extends State<PremiumButton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _hoverCtrl;
  late final Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _hoverCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 120),
      lowerBound: 0.96,
      upperBound: 1.0,
      value: 1.0,
    );
    _scaleAnim = _hoverCtrl;
  }

  @override
  void dispose() {
    _hoverCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: _scaleAnim,
      child: GestureDetector(
        onTapDown: (_) => _hoverCtrl.reverse(),
        onTapUp: (_) {
          _hoverCtrl.forward();
          widget.onPressed();
        },
        onTapCancel: () => _hoverCtrl.forward(),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
            vertical: widget.isCompact ? 9 : 14,
            horizontal: widget.isCompact ? 14 : 20,
          ),
          decoration: BoxDecoration(
            color: widget.isPrimary
                ? widget.backgroundColor
                : Colors.white.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isPrimary
                  ? widget.backgroundColor
                  : Colors.white.withOpacity(0.15),
              width: 1.5,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: widget.glowColor,
                      blurRadius: widget.isCompact ? 12 : 20,
                      spreadRadius: 2,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary
                    ? Colors.white
                    : Colors.white.withOpacity(0.7),
                size: widget.isCompact ? 18 : 22,
              ),
              SizedBox(width: widget.isCompact ? 6 : 10),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.label,
                    style: TextStyle(
                      color: widget.isPrimary
                          ? Colors.white
                          : Colors.white.withOpacity(0.75),
                      fontSize: widget.isCompact ? 12 : 14,
                      fontWeight: FontWeight.w900,
                      letterSpacing: widget.isCompact ? 1 : 1.5,
                    ),
                  ),
                  Text(
                    widget.subtitle,
                    style: TextStyle(
                      color: widget.isPrimary
                          ? Colors.white.withOpacity(0.65)
                          : Colors.white.withOpacity(0.4),
                      fontSize: widget.isCompact ? 9 : 11,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
