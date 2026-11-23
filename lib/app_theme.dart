import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/cupertino.dart' show CupertinoPageTransitionsBuilder;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

/// Global Material theme for Dokan Seller App.
///
/// Type: Anek Bangla for everything (same as the delivery app).
/// Scale: 12 / 14 / 16 / 20 / 26 / 34.
class AppTheme {
  static const String family = 'AnekBangla';

  static TextStyle display(
          {double size = 20,
          FontWeight weight = FontWeight.w600,
          Color color = MyTheme.ink,
          double? height}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: weight,
        fontVariations: [FontVariation('wght', weight.value.toDouble())],
        color: color,
        height: height,
        letterSpacing: size >= 26 ? -0.6 : -0.2,
        fontFeatures: const [FontFeature.tabularFigures()],
      );

  static TextStyle body(
          {double size = 14,
          FontWeight weight = FontWeight.w400,
          Color color = MyTheme.font_grey,
          double? height}) =>
      TextStyle(
          fontFamily: family,
          fontSize: size,
          fontWeight: weight,
          fontVariations: [FontVariation('wght', weight.value.toDouble())],
          color: color,
          height: height);

  /// Condensed bold figures for big counts (same cut as the delivery app).
  static TextStyle figure(double size, {Color color = MyTheme.ink}) =>
      TextStyle(
        fontFamily: family,
        fontSize: size,
        fontWeight: FontWeight.w700,
        fontVariations: const [
          FontVariation('wght', 700),
          FontVariation('wdth', 78),
        ],
        color: color,
        height: 1.0,
        letterSpacing: -0.5,
        leadingDistribution: TextLeadingDistribution.even,
      );

  static const SystemUiOverlayStyle lightStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
    statusBarBrightness: Brightness.light,
  );

  static const SystemUiOverlayStyle darkStatusBar = SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    statusBarBrightness: Brightness.dark,
  );

  /// Anek Bangla is a variable font: map each style's weight onto its
  /// 'wght' axis so bold text actually renders bold.
  static TextStyle? _axis(TextStyle? t) => t?.copyWith(fontVariations: [
        FontVariation(
            'wght', (t.fontWeight ?? FontWeight.w400).value.toDouble())
      ]);

  static TextTheme _withWeightAxis(TextTheme t) => t.copyWith(
        displayLarge: _axis(t.displayLarge),
        displayMedium: _axis(t.displayMedium),
        displaySmall: _axis(t.displaySmall),
        headlineLarge: _axis(t.headlineLarge),
        headlineMedium: _axis(t.headlineMedium),
        headlineSmall: _axis(t.headlineSmall),
        titleLarge: _axis(t.titleLarge),
        titleMedium: _axis(t.titleMedium),
        titleSmall: _axis(t.titleSmall),
        bodyLarge: _axis(t.bodyLarge),
        bodyMedium: _axis(t.bodyMedium),
        bodySmall: _axis(t.bodySmall),
        labelLarge: _axis(t.labelLarge),
        labelMedium: _axis(t.labelMedium),
        labelSmall: _axis(t.labelSmall),
      );

  static ThemeData light() {
    final base = ThemeData(
        useMaterial3: true, brightness: Brightness.light, fontFamily: family);
    final body = base.textTheme
        .apply(bodyColor: MyTheme.font_grey, displayColor: MyTheme.ink);
    final sora = body;

    final textTheme = _withWeightAxis(body.copyWith(
      displayLarge: sora.displayLarge!
          .copyWith(fontSize: 34, fontWeight: FontWeight.w700, color: MyTheme.ink),
      displayMedium: sora.displayMedium!
          .copyWith(fontSize: 26, fontWeight: FontWeight.w700, color: MyTheme.ink),
      headlineSmall: sora.headlineSmall!
          .copyWith(fontSize: 20, fontWeight: FontWeight.w600, color: MyTheme.ink),
      titleLarge: sora.titleLarge!
          .copyWith(fontSize: 17, fontWeight: FontWeight.w600, color: MyTheme.ink),
      titleMedium: body.titleMedium!
          .copyWith(fontSize: 16, fontWeight: FontWeight.w600),
      bodyLarge: body.bodyLarge!.copyWith(fontSize: 16),
      bodyMedium: body.bodyMedium!.copyWith(fontSize: 14),
      bodySmall: body.bodySmall!.copyWith(fontSize: 12, color: MyTheme.dark_grey),
      labelLarge: body.labelLarge!
          .copyWith(fontSize: 15, fontWeight: FontWeight.w600),
    ));

    final controlShape = RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(MyTheme.radius_control));

    OutlineInputBorder outline(Color c, [double w = 1]) => OutlineInputBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_control),
          borderSide: BorderSide(color: c, width: w),
        );

    return base.copyWith(
      colorScheme: ColorScheme.fromSeed(
        seedColor: MyTheme.navy,
        primary: MyTheme.navy,
        onPrimary: Colors.white,
        secondary: MyTheme.amber,
        onSecondary: MyTheme.ink,
        tertiary: MyTheme.royal,
        surface: Colors.white,
        onSurface: MyTheme.ink,
        error: MyTheme.red,
      ),
      primaryColor: MyTheme.navy,
      scaffoldBackgroundColor: MyTheme.paper,
      canvasColor: MyTheme.paper,
      dividerColor: MyTheme.hairline,
      visualDensity: VisualDensity.adaptivePlatformDensity,
      textTheme: textTheme,
      splashFactory: InkSparkle.splashFactory,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        foregroundColor: MyTheme.navy,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        systemOverlayStyle: lightStatusBar,
        titleTextStyle: textTheme.titleLarge,
        iconTheme: const IconThemeData(color: MyTheme.navy),
        shape: const Border(bottom: BorderSide(color: MyTheme.hairline)),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        margin: EdgeInsets.zero,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(MyTheme.radius_card),
          side: const BorderSide(color: MyTheme.hairline),
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: MyTheme.navy,
          foregroundColor: Colors.white,
          disabledBackgroundColor: MyTheme.hairline,
          elevation: 0,
          shadowColor: Colors.transparent,
          minimumSize: const Size(64, 48),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      filledButtonTheme: FilledButtonThemeData(
        style: FilledButton.styleFrom(
          backgroundColor: MyTheme.navy,
          minimumSize: const Size(64, 48),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: MyTheme.navy,
          side: const BorderSide(color: MyTheme.hairline, width: 1.2),
          minimumSize: const Size(64, 48),
          shape: controlShape,
          textStyle: textTheme.labelLarge,
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(foregroundColor: MyTheme.royal),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: MyTheme.amber,
        foregroundColor: MyTheme.ink,
        elevation: 2,
        shape: StadiumBorder(),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        isDense: true,
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        hintStyle: textTheme.bodyMedium!.copyWith(color: MyTheme.grey_153),
        labelStyle: textTheme.bodyMedium!.copyWith(color: MyTheme.dark_grey),
        border: outline(MyTheme.hairline, 1.5),
        enabledBorder: outline(MyTheme.hairline, 1.5),
        focusedBorder: outline(MyTheme.royal, 2),
        errorBorder: outline(MyTheme.red, 1.5),
        focusedErrorBorder: outline(MyTheme.red, 2),
      ),
      checkboxTheme: CheckboxThemeData(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(5)),
        side: const BorderSide(color: MyTheme.grey_153, width: 1.4),
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? MyTheme.royal : null),
      ),
      radioTheme: RadioThemeData(
        fillColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? MyTheme.royal : MyTheme.grey_153),
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? Colors.white : MyTheme.grey_153),
        trackColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? MyTheme.royal : MyTheme.light_grey),
        trackOutlineColor: WidgetStateProperty.resolveWith((s) =>
            s.contains(WidgetState.selected) ? MyTheme.royal : MyTheme.hairline),
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: MyTheme.royal,
        linearTrackColor: MyTheme.hairline,
        circularTrackColor: Colors.transparent,
      ),
      tabBarTheme: TabBarThemeData(
        labelColor: MyTheme.navy,
        unselectedLabelColor: MyTheme.grey_153,
        indicatorColor: MyTheme.amber,
        indicatorSize: TabBarIndicatorSize.label,
        dividerColor: MyTheme.hairline,
        labelStyle: textTheme.labelLarge,
        unselectedLabelStyle:
            textTheme.labelLarge!.copyWith(fontWeight: FontWeight.w500),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: MyTheme.light_grey,
        selectedColor: MyTheme.navy,
        side: BorderSide.none,
        shape: const StadiumBorder(),
        labelStyle: textTheme.bodySmall!.copyWith(color: MyTheme.font_grey),
        secondaryLabelStyle: textTheme.bodySmall!.copyWith(color: Colors.white),
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MyTheme.radius_sheet - 8)),
        titleTextStyle: textTheme.headlineSmall,
        contentTextStyle: textTheme.bodyMedium,
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        showDragHandle: true,
        shape: RoundedRectangleBorder(
            borderRadius:
                BorderRadius.vertical(top: Radius.circular(MyTheme.radius_sheet))),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: MyTheme.navy_deep,
        contentTextStyle: textTheme.bodyMedium!.copyWith(color: Colors.white),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MyTheme.radius_control)),
      ),
      dividerTheme: const DividerThemeData(
          color: MyTheme.hairline, thickness: 1, space: 1),
      listTileTheme: ListTileThemeData(
        iconColor: MyTheme.navy,
        titleTextStyle: textTheme.bodyLarge!.copyWith(color: MyTheme.ink),
        subtitleTextStyle: textTheme.bodySmall,
      ),
      popupMenuTheme: PopupMenuThemeData(
        color: Colors.white,
        surfaceTintColor: Colors.transparent,
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(MyTheme.radius_control),
            side: const BorderSide(color: MyTheme.hairline)),
      ),
      datePickerTheme: const DatePickerThemeData(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        headerBackgroundColor: MyTheme.navy,
        headerForegroundColor: Colors.white,
      ),
      pageTransitionsTheme: const PageTransitionsTheme(builders: {
        TargetPlatform.android: CupertinoPageTransitionsBuilder(),
        TargetPlatform.iOS: CupertinoPageTransitionsBuilder(),
      }),
    );
  }
}
