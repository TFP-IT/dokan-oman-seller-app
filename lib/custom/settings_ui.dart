import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

/// Shared building blocks for the settings screens, in the delivery-app look:
/// navy top bar, titled white panels, labelled fields and a save bar pinned
/// to the bottom.

PreferredSizeWidget settingsAppBar(BuildContext context, String title) {
  return AppBar(
    backgroundColor: MyTheme.navy,
    foregroundColor: Colors.white,
    surfaceTintColor: Colors.transparent,
    systemOverlayStyle: AppTheme.darkStatusBar,
    elevation: 0,
    scrolledUnderElevation: 0,
    shape: const Border(),
    titleSpacing: 0,
    leading: IconButton(
      tooltip: MaterialLocalizations.of(context).backButtonTooltip,
      icon: const BackButtonIcon(),
      color: Colors.white,
      onPressed: () => Navigator.of(context).maybePop(),
    ),
    title: Text(title,
        style: AppTheme.body(
            size: 18, weight: FontWeight.w600, color: Colors.white)),
  );
}

/// White panel with a title (and optional one-line explanation).
class SettingsSection extends StatelessWidget {
  const SettingsSection({
    super.key,
    required this.title,
    this.subtitle,
    required this.children,
    this.padding = const EdgeInsets.all(16),
  });

  final String title;
  final String? subtitle;
  final List<Widget> children;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(MyTheme.radius_card),
        border: Border.all(color: MyTheme.hairline),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: padding,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(title,
                style: AppTheme.body(
                    size: 18, weight: FontWeight.w600, color: MyTheme.navy)),
            if (subtitle != null && subtitle!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(subtitle!,
                  style: AppTheme.body(size: 13, color: MyTheme.dark_grey)),
            ],
            const SizedBox(height: 16),
            ...children,
          ],
        ),
      ),
    );
  }
}

/// Label above a control, with an optional red star and help line.
class SettingsField extends StatelessWidget {
  const SettingsField({
    super.key,
    required this.label,
    required this.child,
    this.required = false,
    this.help,
    this.bottomGap = 16,
  });

  final String label;
  final Widget child;
  final bool required;
  final String? help;
  final double bottomGap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: bottomGap),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text.rich(
            TextSpan(children: [
              TextSpan(text: label),
              if (required)
                TextSpan(
                    text: " *",
                    style: AppTheme.body(
                        size: 14, weight: FontWeight.w600, color: MyTheme.red)),
            ]),
            style: AppTheme.body(
                size: 14, weight: FontWeight.w600, color: MyTheme.navy),
          ),
          const SizedBox(height: 8),
          child,
          if (help != null && help!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(help!,
                style: AppTheme.body(size: 12, color: MyTheme.dark_grey)),
          ],
        ],
      ),
    );
  }
}

/// Themed text field for the settings forms.
class SettingsTextField extends StatelessWidget {
  const SettingsTextField({
    super.key,
    required this.controller,
    this.hint,
    this.keyboardType,
    this.maxLines = 1,
    this.minLines,
    this.onChanged,
    this.prefixIcon,
  });

  final TextEditingController controller;
  final String? hint;
  final TextInputType? keyboardType;
  final int maxLines;
  final int? minLines;
  final ValueChanged<String>? onChanged;
  final IconData? prefixIcon;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      minLines: minLines,
      onChanged: onChanged,
      style: AppTheme.body(size: 16, color: MyTheme.ink),
      decoration: InputDecoration(
        hintText: hint,
        prefixIcon: prefixIcon == null
            ? null
            : Icon(prefixIcon, size: 20, color: MyTheme.dark_grey),
      ),
    );
  }
}

/// A switch row: title on the left, switch on the right.
class SettingsSwitchRow extends StatelessWidget {
  const SettingsSwitchRow({
    super.key,
    required this.title,
    required this.value,
    required this.onChanged,
    this.icon,
  });

  final String title;
  final bool value;
  final ValueChanged<bool> onChanged;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return ConstrainedBox(
      constraints: const BoxConstraints(minHeight: 52),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 22, color: MyTheme.navy),
            const SizedBox(width: 12),
          ],
          Expanded(
            child: Text(title,
                style: AppTheme.body(
                    size: 16, weight: FontWeight.w500, color: MyTheme.ink)),
          ),
          Switch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

/// A tappable row that opens another screen.
class SettingsLinkRow extends StatelessWidget {
  const SettingsLinkRow({
    super.key,
    required this.iconAsset,
    required this.title,
    required this.onTap,
  });

  final String iconAsset;
  final String title;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: 64),
        child: Padding(
          padding: const EdgeInsetsDirectional.fromSTEB(16, 10, 12, 10),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MyTheme.blue_tint,
                  borderRadius: BorderRadius.circular(MyTheme.radius_control),
                ),
                child: Image.asset(iconAsset,
                    width: 20, height: 20, color: MyTheme.navy),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Text(title,
                    style: AppTheme.body(
                        size: 16, weight: FontWeight.w500, color: MyTheme.ink)),
              ),
              Icon(Icons.chevron_right_rounded,
                  size: 22, color: MyTheme.dark_grey),
            ],
          ),
        ),
      ),
    );
  }
}

/// "Choose file | Browse" picker row.
class SettingsFilePicker extends StatelessWidget {
  const SettingsFilePicker({super.key, required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final l = LangText(context: context).getLocal();
    return Material(
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
        side: const BorderSide(color: MyTheme.hairline, width: 1.5),
      ),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: SizedBox(
          height: 48,
          child: Row(
            children: [
              const SizedBox(width: 16),
              Icon(Icons.image_outlined, size: 20, color: MyTheme.dark_grey),
              const SizedBox(width: 10),
              Expanded(
                child: Text(l.choose_file,
                    style: AppTheme.body(size: 15, color: MyTheme.dark_grey)),
              ),
              Container(
                width: 96,
                alignment: Alignment.center,
                color: MyTheme.blue_tint,
                child: Text(l.browse_ucf,
                    style: AppTheme.body(
                        size: 14, weight: FontWeight.w600, color: MyTheme.navy)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Picked image with a remove button in the corner.
class SettingsImageThumb extends StatelessWidget {
  const SettingsImageThumb({
    super.key,
    required this.child,
    required this.onRemove,
  });

  final Widget child;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
          child: child,
        ),
        PositionedDirectional(
          top: -8,
          end: -8,
          child: Material(
            color: Colors.white,
            shape: const CircleBorder(
                side: BorderSide(color: MyTheme.hairline)),
            child: InkWell(
              customBorder: const CircleBorder(),
              onTap: onRemove,
              child: const Padding(
                padding: EdgeInsets.all(4),
                child: Icon(Icons.close_rounded, size: 16, color: MyTheme.red),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// Red list of validation messages.
class SettingsErrors extends StatelessWidget {
  const SettingsErrors({super.key, required this.errors});

  final List<String> errors;

  @override
  Widget build(BuildContext context) {
    if (errors.isEmpty) return const SizedBox.shrink();
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: MyTheme.red.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in errors)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 2),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Padding(
                    padding: EdgeInsets.only(top: 2),
                    child: Icon(Icons.error_outline_rounded,
                        size: 16, color: MyTheme.red),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(e,
                        style: AppTheme.body(
                            size: 14,
                            weight: FontWeight.w500,
                            color: MyTheme.red)),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

/// Full-width primary button pinned to the bottom of the screen.
class SettingsSaveBar extends StatelessWidget {
  const SettingsSaveBar({
    super.key,
    required this.label,
    required this.onPressed,
  });

  final String label;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: MyTheme.hairline)),
      ),
      child: SafeArea(
        top: false,
        minimum: const EdgeInsets.fromLTRB(16, 12, 16, 12),
        child: SizedBox(
          height: 52,
          child: FilledButton(
            onPressed: onPressed,
            child: Text(label,
                style: AppTheme.body(
                    size: 16, weight: FontWeight.w700, color: Colors.white)),
          ),
        ),
      ),
    );
  }
}

/// Standard scroll padding for a settings body.
const EdgeInsets kSettingsBodyPadding = EdgeInsets.fromLTRB(16, 16, 16, 24);
