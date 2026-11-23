import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:one_context/one_context.dart';
import 'package:toast/toast.dart';
import 'package:flutter/material.dart';

class ToastComponent {
  static showDialog(String msg,
      {duration = 0,
      gravity = 0,
      TextStyle? textStyle,
      Color bgColor = MyTheme.navy_deep}) {
    ToastContext().init(OneContext().context!);
    final light = bgColor.computeLuminance() > 0.5;
    Toast.show(
      msg,
      duration: duration != 0 ? duration : Toast.lengthLong,
      gravity: gravity != 0 ? gravity : Toast.bottom,
      backgroundColor: bgColor,
      textStyle: textStyle ??
          TextStyle(
              fontSize: 14,
              height: 1.35,
              color: light ? MyTheme.ink : Colors.white),
      border: light ? Border.all(color: MyTheme.hairline) : null,
      backgroundRadius: MyTheme.radius_control,
    );
  }
}
