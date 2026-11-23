import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// The Dokan "wing": a single amber crescent sweeping across a navy panel,
/// echoing the winged D in the logo. Use it once per screen, on navy only.
enum WingStyle {
  /// Crescent rising from the bottom edge (splash, login).
  sweep,

  /// Crescent tucked into the top-right corner, leaving the lower half free
  /// for content (dashboard header).
  corner,
}

class BrandWing extends StatelessWidget {
  const BrandWing(
      {super.key, this.opacity = 1, this.style = WingStyle.sweep, this.child});

  final double opacity;
  final WingStyle style;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _WingPainter(opacity: opacity, style: style),
      child: child,
    );
  }
}

class _WingPainter extends CustomPainter {
  _WingPainter({required this.opacity, required this.style});
  final double opacity;
  final WingStyle style;

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width, h = size.height;

    // Navy base with a quiet lift toward royal in the top-right corner.
    // The corner style sits under a flat navy app bar, so its top edge must
    // be exactly MyTheme.navy.
    final base = Paint()
      ..shader = (style == WingStyle.corner
              ? const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [MyTheme.navy, MyTheme.navy_deep],
                )
              : const LinearGradient(
                  begin: Alignment.bottomLeft,
                  end: Alignment.topRight,
                  colors: [MyTheme.navy_deep, MyTheme.navy, Color(0xFF123F8E)],
                  stops: [0, .55, 1],
                ))
          .createShader(Offset.zero & size);
    canvas.drawRect(Offset.zero & size, base);

    final featherPaint = Paint()
      ..color = MyTheme.royal.withValues(alpha: 0.38 * opacity);
    final wingPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.bottomRight,
        end: Alignment.topLeft,
        colors: [
          MyTheme.amber.withValues(alpha: opacity),
          const Color(0xFFFFCB78).withValues(alpha: opacity),
        ],
      ).createShader(Offset.zero & size);

    if (style == WingStyle.corner) {
      final feather = Path()
        ..moveTo(w, h * 0.74)
        ..cubicTo(w * 0.88, h * 0.42, w * 0.70, h * 0.16, w * 0.40, -1)
        ..cubicTo(w * 0.72, h * 0.10, w * 0.92, h * 0.30, w, h * 0.46)
        ..close();
      canvas.drawPath(feather, featherPaint);
      final wing = Path()
        ..moveTo(w, h * 0.58)
        ..cubicTo(w * 0.90, h * 0.34, w * 0.76, h * 0.12, w * 0.56, -1)
        ..cubicTo(w * 0.80, h * 0.08, w * 0.94, h * 0.24, w, h * 0.40)
        ..close();
      canvas.drawPath(wing, wingPaint);
      return;
    }

    // Feather: a wide royal crescent behind the amber one.
    final feather = Path()
      ..moveTo(w * 0.28, h)
      ..cubicTo(w * 0.68, h * 0.88, w * 0.94, h * 0.46, w * 1.02, -h * 0.02)
      ..cubicTo(w * 0.94, h * 0.46, w * 0.74, h * 0.82, w * 0.50, h)
      ..close();
    canvas.drawPath(
        feather, Paint()..color = MyTheme.royal.withValues(alpha: 0.38 * opacity));

    // Wing: the amber crescent, thick at the base and tapering to a point.
    final wing = Path()
      ..moveTo(w * 0.52, h)
      ..cubicTo(w * 0.82, h * 0.90, w * 0.99, h * 0.56, w * 1.03, h * 0.12)
      ..cubicTo(w * 0.95, h * 0.54, w * 0.82, h * 0.84, w * 0.66, h)
      ..close();
    canvas.drawPath(
      wing,
      Paint()
        ..shader = LinearGradient(
          begin: Alignment.bottomCenter,
          end: Alignment.topRight,
          colors: [
            MyTheme.amber.withValues(alpha: opacity),
            const Color(0xFFFFCB78).withValues(alpha: opacity),
          ],
        ).createShader(Offset.zero & size),
    );
  }

  @override
  bool shouldRepaint(covariant _WingPainter old) => old.opacity != opacity;
}
