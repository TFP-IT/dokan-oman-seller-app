import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';

/// Money formatter following Dokan & Cook Habibi standard: `OMR 25.000`
String muskilaMoney(num? v, [String currency = "OMR"]) =>
    "$currency ${(v ?? 0).toStringAsFixed(3)}";

String muskilaDateTime(DateTime? d) =>
    d == null ? "" : DateFormat("d MMM, h:mm a").format(d);

void muskilaToast(String msg) =>
    ToastComponent.showDialog(msg, gravity: Toast.center, duration: 3);

/// Elevated modern card with subtle shadow and crisp hairline border.
class MuskilaCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;
  final Color? color;
  final Color? borderColor;

  const MuskilaCard({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.onTap,
    this.color,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: color ?? Colors.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: borderColor ?? MyTheme.hairline),
        boxShadow: const [
          BoxShadow(
            color: MyTheme.app_accent_shado,
            blurRadius: 12,
            offset: Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(padding: padding, child: child),
        ),
      ),
    );
  }
}

/// Soft tinted icon container for dashboard shortcuts, cards, and settings rows.
class MuskilaIconBadge extends StatelessWidget {
  final IconData icon;
  final Color bg;
  final Color fg;
  final double size;
  final double iconSize;

  const MuskilaIconBadge({
    super.key,
    required this.icon,
    this.bg = MyTheme.blue_tint,
    this.fg = MyTheme.navy,
    this.size = 42,
    this.iconSize = 20,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
      ),
      alignment: Alignment.center,
      child: Icon(icon, color: fg, size: iconSize),
    );
  }
}

/// Customer / Specialist initial avatar with soft gradient & optional badge.
class MuskilaAvatar extends StatelessWidget {
  final String name;
  final double size;
  final bool verified;

  const MuskilaAvatar({
    super.key,
    required this.name,
    this.size = 44,
    this.verified = false,
  });

  @override
  Widget build(BuildContext context) {
    final initial = name.trim().isNotEmpty ? name.trim()[0].toUpperCase() : "U";
    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          width: size,
          height: size,
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [MyTheme.blue_tint, Color(0xFFD5E4FA)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            shape: BoxShape.circle,
          ),
          alignment: Alignment.center,
          child: Text(
            initial,
            style: AppTheme.body(
              size: size * 0.38,
              weight: FontWeight.w700,
              color: MyTheme.navy,
            ),
          ),
        ),
        if (verified)
          Positioned(
            right: -2,
            bottom: -2,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.verified, size: 14, color: MyTheme.royal),
            ),
          ),
      ],
    );
  }
}

/// Section header with optional "See all" action.
class MuskilaSectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const MuskilaSectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 22, 16, 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              title,
              style: AppTheme.body(
                size: 17,
                weight: FontWeight.w700,
                color: MyTheme.navy,
              ),
            ),
          ),
          if (actionLabel != null && onAction != null)
            InkWell(
              onTap: onAction,
              borderRadius: BorderRadius.circular(20),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      actionLabel!,
                      style: AppTheme.body(
                        size: 13,
                        weight: FontWeight.w600,
                        color: MyTheme.royal,
                      ),
                    ),
                    const SizedBox(width: 2),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 12,
                      color: MyTheme.royal,
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }
}

/// Status pill matching Dokan & Cook Habibi style.
class MuskilaPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;
  final IconData? icon;

  const MuskilaPill(
    this.text, {
    super.key,
    this.bg = MyTheme.blue_tint,
    this.fg = MyTheme.navy,
    this.icon,
  });

  factory MuskilaPill.status(String status) {
    switch (status.toLowerCase()) {
      case "pending":
        return const MuskilaPill(
          "Pending",
          bg: MyTheme.amber_soft,
          fg: MyTheme.amber_ink,
          icon: Icons.schedule_rounded,
        );
      case "scheduled":
      case "accepted":
        return const MuskilaPill(
          "Scheduled",
          bg: MyTheme.blue_tint,
          fg: MyTheme.royal,
          icon: Icons.event_available_rounded,
        );
      case "on_the_way":
        return const MuskilaPill(
          "On The Way",
          bg: Color(0xFFE0E7FF),
          fg: Color(0xFF3730A3),
          icon: Icons.directions_car_outlined,
        );
      case "in_progress":
        return const MuskilaPill(
          "In Progress",
          bg: Color(0xFFE0E7FF),
          fg: Color(0xFF3730A3),
          icon: Icons.build_circle_outlined,
        );
      case "completed":
        return const MuskilaPill(
          "Completed",
          bg: Color(0xFFE2F3EC),
          fg: MyTheme.green,
          icon: Icons.check_circle_outline_rounded,
        );
      case "cancelled":
      case "rejected":
        return const MuskilaPill(
          "Cancelled",
          bg: Color(0xFFFBE7E4),
          fg: MyTheme.red,
          icon: Icons.cancel_outlined,
        );
      default:
        return MuskilaPill(status);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 13, color: fg),
            const SizedBox(width: 4),
          ],
          Text(
            text,
            style: AppTheme.body(size: 12, weight: FontWeight.w600, color: fg),
          ),
        ],
      ),
    );
  }
}

/// Full-width primary or outlined action button.
class MuskilaButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final Color color;
  final bool outlined;
  final IconData? icon;

  const MuskilaButton({
    super.key,
    required this.label,
    required this.onPressed,
    this.busy = false,
    this.color = MyTheme.navy,
    this.outlined = false,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final fg = outlined ? color : Colors.white;
    final child = busy
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: fg,
            ),
          )
        : Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (icon != null) ...[
                Icon(icon, size: 18, color: fg),
                const SizedBox(width: 8),
              ],
              Text(
                label,
                style: AppTheme.body(
                  size: 15,
                  weight: FontWeight.w600,
                  color: fg,
                ),
              ),
            ],
          );
    final shape = RoundedRectangleBorder(
      borderRadius: BorderRadius.circular(MyTheme.radius_control),
    );
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(
              onPressed: busy ? null : onPressed,
              style: OutlinedButton.styleFrom(
                shape: shape,
                side: BorderSide(color: color),
              ),
              child: child,
            )
          : FilledButton(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                backgroundColor: color,
                disabledBackgroundColor: color.withValues(alpha: 0.6),
                shape: shape,
              ),
              child: child,
            ),
    );
  }
}

/// Clean white AppBar with hairline border.
AppBar muskilaAppBar(
  BuildContext context,
  String title, {
  List<Widget>? actions,
  bool showBack = true,
}) {
  return AppBar(
    automaticallyImplyLeading: showBack,
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: AppTheme.lightStatusBar,
    shape: const Border(bottom: BorderSide(color: MyTheme.hairline)),
    iconTheme: const IconThemeData(color: MyTheme.ink),
    title: Text(
      title,
      style: AppTheme.body(size: 18, weight: FontWeight.w700, color: MyTheme.ink),
    ),
    actions: actions,
  );
}

/// Empty state widget.
class MuskilaEmptyView extends StatelessWidget {
  final String text;
  final IconData icon;

  const MuskilaEmptyView({
    super.key,
    required this.text,
    this.icon = Icons.inbox_outlined,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      children: [
        const SizedBox(height: 90),
        Center(
          child: Container(
            width: 72,
            height: 72,
            decoration: const BoxDecoration(
              color: MyTheme.blue_tint,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 34, color: MyTheme.navy),
          ),
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 32),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: AppTheme.body(size: 14, color: MyTheme.medium_grey),
          ),
        ),
      ],
    );
  }
}

/// Error view with retry.
class MuskilaErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const MuskilaErrorView({
    super.key,
    required this.message,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_rounded, size: 40, color: MyTheme.grey_153),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 14, color: MyTheme.font_grey),
            ),
            const SizedBox(height: 12),
            OutlinedButton(onPressed: onRetry, child: const Text("Try again")),
          ],
        ),
      ),
    );
  }
}
