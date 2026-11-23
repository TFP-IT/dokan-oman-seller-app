import 'package:flutter/material.dart';

/// Dokan Seller App palette — taken from the Dokan logo.
///
///   navy   #0A2350  structure, headers, primary text accents
///   royal  #0B63CE  interactive: links, focus, selected states
///   amber  #D9A257  attention only: pending, unverified, upgrade, key CTA
///   paper  #F2F5FA  app background (cool, never cream)
///   ink    #0A2350  body text
///
/// The legacy field names below are kept so every existing screen picks up
/// the new palette without code changes.
class MyTheme {
  // ---- brand -------------------------------------------------------------
  static const Color navy = Color(0xFF0A2350);
  static const Color navy_deep = Color(0xFF061936);
  static const Color royal = Color(0xFF0B63CE);
  static const Color amber = Color(0xFFD9A257);
  static const Color amber_soft = Color(0xFFFFF2DE);
  static const Color amber_ink = Color(0xFF8A4B00); // text on amber_soft
  static const Color paper = Color(0xFFF2F5FA);
  static const Color ink = Color(0xFF0A2350);
  static const Color blue_tint = Color(0xFFE3ECFA);
  static const Color hairline = Color(0xFFD3DBE8);

  // ---- radii (hierarchy: sheets > cards > controls) ----------------------
  static const double radius_sheet = 28;
  static const double radius_card = 16;
  static const double radius_control = 12;

  // ---- legacy names (mapped onto the brand palette) ----------------------
  static const Color app_accent_color = navy;
  static Color app_accent_color_extra_light = const Color(0xFFE3ECFA);

  static Color splash_screen_color = navy;
  static Color login_reg_screen_color = navy;

  static const Color app_accent_border = hairline;
  static const Color app_accent_shado = Color.fromRGBO(10, 35, 80, 0.07);
  static const Color app_accent_tranparent = Color.fromRGBO(6, 25, 54, 0.55);
  static Color white = const Color(0xFFFFFFFF);
  static const Color noColor = Color.fromRGBO(255, 255, 255, 0);
  static Color light_grey = const Color(0xFFF1F4F9);
  static Color dark_grey = const Color(0xFF55627A);
  static Color medium_grey = const Color(0xFF7A8597);
  static Color medium_grey_50 = const Color(0x807A8597);
  static const Color grey_153 = Color(0xFF8D97A8);
  static const Color font_grey = Color(0xFF26324A);
  static Color textfield_grey = const Color(0xFFD5DCE7);
  static Color golden = amber;
  static const Color red = Color(0xFFC7402E);
  static const Color green = Color(0xFF17805A);
  static Color shimmer_base = const Color(0xFFEFF3F8);
  static Color shimmer_highlighted = const Color(0xFFFAFBFD);
  static const black = ink;
}
