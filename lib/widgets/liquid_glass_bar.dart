import 'dart:ui';
import 'package:flutter/material.dart';

/// Navigation item model conforming to liquid_glass_bar: ^0.1.1 specification.
class LiquidGlassBarItem {
  final IconData? iconData;
  final Widget? iconWidget;
  final String label;

  const LiquidGlassBarItem({
    this.iconData,
    this.iconWidget,
    required this.label,
  }) : assert(
          iconData != null || iconWidget != null,
          'Either iconData or iconWidget must be provided.',
        );
}

/// Style configuration conforming to liquid_glass_bar: ^0.1.1 specification.
class LiquidGlassBarStyle {
  final Color activeColor;
  final Color inactiveColor;
  final Color? glassColor;
  final double borderRadius;
  final double height;
  final EdgeInsets padding;
  final Duration animationDuration;
  final Curve animationCurve;
  final double iconSize;
  final double selectedIconScale;
  final TextStyle? labelStyle;

  const LiquidGlassBarStyle({
    this.activeColor = const Color(0xFF2563EB),
    this.inactiveColor = const Color(0xFF94A3B8),
    this.glassColor,
    this.borderRadius = 32.0,
    this.height = 64.0,
    this.padding = const EdgeInsets.fromLTRB(16, 0, 16, 20),
    this.animationDuration = const Duration(milliseconds: 250),
    this.animationCurve = Curves.easeOutCubic,
    this.iconSize = 22.0,
    this.selectedIconScale = 1.18,
    this.labelStyle,
  });
}

/// Liquid Glass Navigation Bar with authentic glassmorphism, gesture sliding,
/// animated elastic icon bounce, and liquid indicator.
class LiquidGlassBar extends StatefulWidget {
  final List<LiquidGlassBarItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;
  final LiquidGlassBarStyle? style;

  const LiquidGlassBar({
    super.key,
    required this.items,
    required this.currentIndex,
    required this.onTap,
    this.style,
  }) : assert(items.length >= 2, 'LiquidGlassBar requires at least 2 items.');

  @override
  State<LiquidGlassBar> createState() => _LiquidGlassBarState();
}

class _LiquidGlassBarState extends State<LiquidGlassBar> {
  double? _dragAlignment;
  bool _isDragging = false;
  int? _highlightedIndex;

  LiquidGlassBarStyle get _style => widget.style ?? const LiquidGlassBarStyle();
  int get _lastIndex => widget.items.length - 1;

  double _getAlignment(int index) {
    if (_lastIndex == 0) return 0.0;
    return -1.0 + (index * 2 / _lastIndex);
  }

  void _updateHighlightedIndex() {
    if (!_isDragging || _dragAlignment == null) {
      _highlightedIndex = null;
      return;
    }
    final normalized = (_dragAlignment! + 1) / 2;
    final index = (normalized * _lastIndex).round();
    _highlightedIndex = index.clamp(0, _lastIndex);
  }

  @override
  Widget build(BuildContext context) {
    final style = _style;
    final itemCount = widget.items.length;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final baseGlassColor = style.glassColor ??
        (isDark
            ? const Color(0xFF0F172A).withOpacity(0.68)
            : Colors.white.withOpacity(0.72));

    return Padding(
      padding: style.padding,
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          // 1. Neumorphic Ambient Shadow
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(style.borderRadius),
                boxShadow: [
                  BoxShadow(
                    color: isDark
                        ? Colors.black.withOpacity(0.55)
                        : const Color(0xFF0F172A).withOpacity(0.16),
                    blurRadius: 28,
                    offset: const Offset(0, 10),
                    spreadRadius: 2,
                  ),
                  BoxShadow(
                    color: isDark
                        ? Colors.white.withOpacity(0.08)
                        : Colors.white.withOpacity(0.9),
                    blurRadius: 6,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
            ),
          ),

          // 2. Realtime Frosted Glass Layer
          ClipRRect(
            borderRadius: BorderRadius.circular(style.borderRadius),
            child: BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 25, sigmaY: 25),
              child: Container(
                color: baseGlassColor,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    final itemWidth = constraints.maxWidth / itemCount;
                    final totalDragWidth = constraints.maxWidth - itemWidth;

                    return GestureDetector(
                      onHorizontalDragStart: (details) {
                        setState(() {
                          _isDragging = true;
                          _dragAlignment = _getAlignment(widget.currentIndex);
                          _updateHighlightedIndex();
                        });
                      },
                      onHorizontalDragUpdate: (details) {
                        if (!_isDragging) return;
                        setState(() {
                          final deltaAlignment =
                              (details.primaryDelta! / totalDragWidth) * 2.0;
                          _dragAlignment = (_dragAlignment! + deltaAlignment)
                              .clamp(-1.0, 1.0);
                          _updateHighlightedIndex();
                        });
                      },
                      onHorizontalDragEnd: (details) {
                        setState(() {
                          _isDragging = false;
                          _highlightedIndex = null;
                          final currentA = _dragAlignment!;
                          final normalized = (currentA + 1) / 2;
                          final nearestIndex =
                              (normalized * _lastIndex).round();
                          widget.onTap(nearestIndex);
                        });
                      },
                      onHorizontalDragCancel: () {
                        setState(() {
                          _isDragging = false;
                          _highlightedIndex = null;
                        });
                      },
                      child: SizedBox(
                        height: style.height,
                        child: Stack(
                          alignment: Alignment.center,
                          children: [
                            // 3. Sliding Liquid Pill Indicator
                            AnimatedAlign(
                              duration: _isDragging
                                  ? Duration.zero
                                  : style.animationDuration,
                              curve: style.animationCurve,
                              alignment: Alignment(
                                _isDragging
                                    ? _dragAlignment!
                                    : _getAlignment(widget.currentIndex),
                                0,
                              ),
                              child: Container(
                                width: itemWidth * 0.88,
                                height: style.height * 0.84,
                                decoration: BoxDecoration(
                                  color: isDark
                                      ? style.activeColor.withOpacity(0.20)
                                      : const Color(0xFFEFF6FF),
                                  borderRadius: BorderRadius.circular(22),
                                  border: Border.all(
                                    color: isDark
                                        ? style.activeColor.withOpacity(0.35)
                                        : const Color(0xFFDBEAFE),
                                    width: 1.0,
                                  ),
                                ),
                              ),
                            ),

                            // 4. Navigation Tab Items
                            Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                              children: [
                                for (int i = 0; i < itemCount; i++)
                                  _GlassItemWidget(
                                    item: widget.items[i],
                                    isSelected: widget.currentIndex == i,
                                    isHighlighted: _highlightedIndex == i,
                                    onTap: () => widget.onTap(i),
                                    style: style,
                                  ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ),

          // 5. Specular Border Overlay
          Positioned.fill(
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(style.borderRadius),
                  border: Border.all(
                    color: isDark
                        ? Colors.white.withOpacity(0.18)
                        : Colors.white.withOpacity(0.85),
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _GlassItemWidget extends StatelessWidget {
  final LiquidGlassBarItem item;
  final bool isSelected;
  final bool isHighlighted;
  final VoidCallback onTap;
  final LiquidGlassBarStyle style;

  const _GlassItemWidget({
    required this.item,
    required this.isSelected,
    required this.isHighlighted,
    required this.onTap,
    required this.style,
  });

  @override
  Widget build(BuildContext context) {
    final isActive = isSelected || isHighlighted;
    final color = isActive ? style.activeColor : style.inactiveColor;

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: onTap,
        child: AnimatedContainer(
          duration: style.animationDuration,
          curve: style.animationCurve,
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              AnimatedScale(
                scale: isSelected ? style.selectedIconScale : 1.0,
                duration: const Duration(milliseconds: 350),
                curve: Curves.elasticOut,
                child: item.iconWidget ??
                    Icon(
                      item.iconData,
                      size: style.iconSize,
                      color: color,
                    ),
              ),
              const SizedBox(height: 3),
              Text(
                item.label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: style.labelStyle ??
                    TextStyle(
                      color: color,
                      fontSize: 11,
                      fontWeight:
                          isActive ? FontWeight.w700 : FontWeight.w500,
                      letterSpacing: 0.1,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
