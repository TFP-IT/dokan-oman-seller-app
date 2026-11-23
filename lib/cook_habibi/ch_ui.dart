import 'dart:io';

import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/cook_habibi/ch_api.dart';
import 'package:active_ecommerce_seller_app/custom/toast_component.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'package:toast/toast.dart';

/// `OMR 4.250` — three decimals (guide §9).
String chMoney(num? v, [String currency = "OMR"]) =>
    "$currency ${(v ?? 0).toStringAsFixed(3)}";

String chDateTime(DateTime? d) =>
    d == null ? "" : DateFormat("d MMM, h:mm a").format(d);

void chToast(String msg) =>
    ToastComponent.showDialog(msg, gravity: Toast.center, duration: 3);

/// Shows the safe message of an error (never raw server text).
void chToastError(Object e) => chToast(e is ChApiException
    ? e.message
    : "Something went wrong. Please try again.");

String chErrorText(Object e) => e is ChApiException
    ? e.message
    : "Something went wrong. Please try again.";

/// Picks a photo and checks the 5 MB limit. Returns the path or null.
Future<String?> chPickImage(BuildContext context) async {
  final source = await showModalBottomSheet<ImageSource>(
    context: context,
    builder: (ctx) => SafeArea(
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        ListTile(
            leading: const Icon(Icons.photo_camera_outlined),
            title: const Text("Camera"),
            onTap: () => Navigator.pop(ctx, ImageSource.camera)),
        ListTile(
            leading: const Icon(Icons.photo_library_outlined),
            title: const Text("Gallery"),
            onTap: () => Navigator.pop(ctx, ImageSource.gallery)),
      ]),
    ),
  );
  if (source == null) return null;
  final x = await ImagePicker()
      .pickImage(source: source, imageQuality: 80, maxWidth: 1600);
  if (x == null) return null;
  if (await File(x.path).length() > 5 * 1024 * 1024) {
    chToast("Image must be 5 MB or smaller.");
    return null;
  }
  return x.path;
}

class ChCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry padding;
  final VoidCallback? onTap;

  const ChCard(
      {super.key,
      required this.child,
      this.padding = const EdgeInsets.all(16),
      this.onTap});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_card),
          side: const BorderSide(color: MyTheme.hairline)),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
          onTap: onTap, child: Padding(padding: padding, child: child)),
    );
  }
}

class ChErrorView extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const ChErrorView({super.key, required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 40, color: MyTheme.grey_153),
          const SizedBox(height: 12),
          Text(message,
              textAlign: TextAlign.center,
              style: AppTheme.body(size: 14, color: MyTheme.font_grey)),
          const SizedBox(height: 12),
          OutlinedButton(onPressed: onRetry, child: const Text("Try again")),
        ]),
      ),
    );
  }
}

class ChEmptyView extends StatelessWidget {
  final String text;
  final IconData icon;

  const ChEmptyView(
      {super.key, required this.text, this.icon = Icons.inbox_outlined});

  @override
  Widget build(BuildContext context) {
    return ListView(children: [
      const SizedBox(height: 120),
      Icon(icon, size: 40, color: MyTheme.grey_153),
      const SizedBox(height: 12),
      Text(text,
          textAlign: TextAlign.center,
          style: AppTheme.body(size: 14, color: MyTheme.medium_grey)),
    ]);
  }
}

class ChPill extends StatelessWidget {
  final String text;
  final Color bg;
  final Color fg;

  const ChPill(this.text,
      {super.key, this.bg = MyTheme.blue_tint, this.fg = MyTheme.navy});

  factory ChPill.status(String status, String title) {
    switch (status) {
      case "placed":
        return ChPill(title, bg: MyTheme.amber_soft, fg: MyTheme.amber_ink);
      case "delivered":
      case "completed":
        return ChPill(title,
            bg: const Color(0xFFE2F3EC), fg: MyTheme.green);
      case "cancelled":
      case "rejected":
      case "refunded":
        return ChPill(title, bg: const Color(0xFFFBE7E4), fg: MyTheme.red);
      default:
        return ChPill(title);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration:
          BoxDecoration(color: bg, borderRadius: BorderRadius.circular(20)),
      child: Text(text,
          style: AppTheme.body(size: 12, weight: FontWeight.w600, color: fg)),
    );
  }
}

/// Full width button that shows a spinner and ignores taps while busy.
class ChButton extends StatelessWidget {
  final String label;
  final bool busy;
  final VoidCallback? onPressed;
  final Color color;
  final bool outlined;

  const ChButton(
      {super.key,
      required this.label,
      required this.onPressed,
      this.busy = false,
      this.color = MyTheme.navy,
      this.outlined = false});

  @override
  Widget build(BuildContext context) {
    final child = busy
        ? SizedBox(
            height: 20,
            width: 20,
            child: CircularProgressIndicator(
                strokeWidth: 2, color: outlined ? color : Colors.white))
        : Text(label,
            style: AppTheme.body(
                size: 15,
                weight: FontWeight.w600,
                color: outlined ? color : Colors.white));
    final shape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MyTheme.radius_control));
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: outlined
          ? OutlinedButton(
              onPressed: busy ? null : onPressed,
              style: OutlinedButton.styleFrom(
                  shape: shape, side: BorderSide(color: color)),
              child: child)
          : FilledButton(
              onPressed: busy ? null : onPressed,
              style: FilledButton.styleFrom(
                  backgroundColor: color,
                  disabledBackgroundColor: color.withValues(alpha: 0.6),
                  shape: shape),
              child: child),
    );
  }
}

AppBar chAppBar(BuildContext context, String title, {List<Widget>? actions}) {
  return AppBar(
    backgroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    elevation: 0,
    scrolledUnderElevation: 0,
    systemOverlayStyle: AppTheme.lightStatusBar,
    shape: const Border(bottom: BorderSide(color: MyTheme.hairline)),
    iconTheme: const IconThemeData(color: MyTheme.ink),
    title: Text(title,
        style: AppTheme.body(size: 18, weight: FontWeight.w600, color: MyTheme.ink)),
    actions: actions,
  );
}

InputDecoration chInput(String label, {String? hint, String? error}) =>
    InputDecoration(
      labelText: label,
      hintText: hint,
      errorText: error,
      isDense: true,
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
          borderSide: const BorderSide(color: MyTheme.hairline)),
      enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
          borderSide: const BorderSide(color: MyTheme.hairline)),
    );

class ChNetImage extends StatelessWidget {
  final String? url;
  final double size;
  final String fallback;

  const ChNetImage(
      {super.key, this.url, this.size = 56, this.fallback = "🍽"});

  @override
  Widget build(BuildContext context) {
    final box = Container(
      width: size,
      height: size,
      alignment: Alignment.center,
      decoration: BoxDecoration(
          color: MyTheme.paper, borderRadius: BorderRadius.circular(12)),
      child: Text(fallback.isEmpty ? "🍽" : fallback,
          style: TextStyle(fontSize: size * 0.45)),
    );
    if (url == null || url!.isEmpty) return box;
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(url!,
          width: size,
          height: size,
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => box),
    );
  }
}
