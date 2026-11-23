import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/material.dart';

class InputDecorations {
  static InputDecoration buildInputDecoration_1(
      {hint_text = "",
      Color hintTextColor = MyTheme.grey_153,
      Color borderColor = MyTheme.app_accent_border,
      Color fillColor = const Color.fromRGBO(255, 255, 255, 0)}) {
    return InputDecoration(
        fillColor: fillColor,
        filled: fillColor.a > 0,
        hintText: hint_text,
        hintStyle: TextStyle(fontSize: 14.0, color: hintTextColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 1),
          borderRadius: const BorderRadius.all(
            Radius.circular(MyTheme.radius_control),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderSide: BorderSide(color: MyTheme.royal, width: 1.6),
          borderRadius: const BorderRadius.all(
            Radius.circular(MyTheme.radius_control),
          ),
        ),
        contentPadding: EdgeInsets.only(left: 14.0, right: 14.0));
  }

  static InputDecoration buildInputDecoration_phone
      //     ({hint_text = ""}) {
      //   return InputDecoration(
      //       fillColor: fillColor,
      //
      //       hintText: hint_text,
      //       hintStyle: TextStyle(fontSize: 12.0, color: MyTheme.app_accent_color),
      //       enabledBorder: OutlineInputBorder(
      //         borderSide: BorderSide(color: MyTheme.app_accent_color.withOpacity(0.8), width: 1.0),
      //         borderRadius: BorderRadius.only(
      //             topRight: Radius.circular(MyTheme.radius_control),
      //             bottomRight: Radius.circular(MyTheme.radius_control)),
      //       ),
      //       focusedBorder: OutlineInputBorder(
      //           borderSide: BorderSide(color: MyTheme.app_accent_color.withOpacity(0.8), width: 1.0),
      //           borderRadius: BorderRadius.only(
      //               topRight: Radius.circular(MyTheme.radius_control),
      //               bottomRight: Radius.circular(MyTheme.radius_control))),
      //       contentPadding: EdgeInsets.only(left: 14.0, right: 14.0));
      // }
      (
          {hint_text = "",
          Color hintTextColor = MyTheme.grey_153,
          Color borderColor = MyTheme.app_accent_border,
          Color fillColor = const Color.fromRGBO(255, 255, 255, 0)}) {
    return InputDecoration(
        fillColor: fillColor,
        filled: fillColor.a > 0,
        hintText: hint_text,
        hintStyle: TextStyle(fontSize: 14.0, color: hintTextColor),
        enabledBorder: OutlineInputBorder(
          borderSide: BorderSide(color: borderColor, width: 1),
          borderRadius: const BorderRadius.only(
              topRight: Radius.circular(MyTheme.radius_control),
              bottomRight: Radius.circular(MyTheme.radius_control)),
        ),
        focusedBorder: OutlineInputBorder(
            borderSide: BorderSide(color: MyTheme.royal, width: 1.6),
            borderRadius: BorderRadius.only(
                topRight: Radius.circular(MyTheme.radius_control),
                bottomRight: Radius.circular(MyTheme.radius_control))),
        contentPadding: EdgeInsets.only(left: 14.0, right: 14.0));
  }
}
