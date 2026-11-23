import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:flutter/cupertino.dart';

class MDecoration {
  /// White surface with a hairline border. [showShadow] adds a faint
  /// navy-tinted lift for floating elements only.
  static BoxDecoration decoration1(
      {double radius = MyTheme.radius_card, bool showShadow = true}) {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      color: MyTheme.white,
      border: Border.all(color: MyTheme.hairline),
      boxShadow: [
        showShadow
            ? const BoxShadow(
                color: MyTheme.app_accent_shado,
                blurRadius: 16,
                offset: Offset(0.0, 6.0),
              )
            : const BoxShadow(color: MyTheme.noColor)
      ],
    );
  }
}
