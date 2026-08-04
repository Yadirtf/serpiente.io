import 'package:flutter/material.dart';

class GamingIcon extends StatefulWidget {
  final bool isNewRecord;
  final Color primaryColor;
  final bool isCompact;

  const GamingIcon({
    super.key,
    required this.isNewRecord,
    required this.primaryColor,
    this.isCompact = false,
  });

  @override
  State<GamingIcon> createState() => _GamingIconState();
}

class _GamingIconState extends State<GamingIcon>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulse;
  late final Animation<double> _pulseAnim;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
    _pulseAnim = Tween<double>(begin: 0.85, end: 1.0).animate(
      CurvedAnimation(parent: _pulse, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = widget.isCompact ? 54.0 : 80.0;
    final iconSize = widget.isCompact ? 28.0 : 38.0;

    return ScaleTransition(
      scale: _pulseAnim,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: widget.primaryColor.withOpacity(0.12),
          border: Border.all(
            color: widget.primaryColor.withOpacity(0.5),
            width: 2,
          ),
          boxShadow: [
            BoxShadow(
              color: widget.primaryColor.withOpacity(0.3),
              blurRadius: widget.isCompact ? 12 : 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          widget.isNewRecord
              ? Icons.emoji_events_rounded
              : Icons.videogame_asset_rounded,
          color: widget.primaryColor,
          size: iconSize,
        ),
      ),
    );
  }
}
