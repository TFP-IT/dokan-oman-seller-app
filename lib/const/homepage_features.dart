import 'package:active_ecommerce_seller_app/app_theme.dart';
import 'package:active_ecommerce_seller_app/custom/localization.dart';
import 'package:active_ecommerce_seller_app/custom/route_transaction.dart';
import 'package:active_ecommerce_seller_app/helpers/shared_value_helper.dart';
import 'package:active_ecommerce_seller_app/my_theme.dart';
import 'package:active_ecommerce_seller_app/screens/chat_list.dart';
import 'package:active_ecommerce_seller_app/screens/coupon/coupons.dart';
import 'package:active_ecommerce_seller_app/screens/money_withdraw.dart';
import 'package:active_ecommerce_seller_app/screens/payment_history.dart';
import 'package:active_ecommerce_seller_app/screens/refund_request.dart';
import 'package:flutter/material.dart';

/// Shortcut tiles shown on the dashboard under "Shortcuts".
class FeaturesList {
  BuildContext context;

  FeaturesList(this.context);

  Widget _tile(String icon, String label, VoidCallback onTap) {
    return InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(MyTheme.radius_control),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 2),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 40,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: MyTheme.blue_tint,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Image.asset(icon,
                    width: 18, height: 18, color: MyTheme.navy),
              ),
              const SizedBox(height: 6),
              Text(
                label,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTheme.body(
                    size: 10.5, weight: FontWeight.w500, color: MyTheme.ink,
                    height: 1.15),
              ),
            ],
          ),
        ),
    );
  }

  List<Widget> getFeatureList() {
    final l = LangText(context: context).getLocal();
    final push = MyTransaction(context: context).push;
    return [
      if (conversation_activation.$)
        _tile('assets/icon/chat.png', l.messages_ucf, () => push(ChatList())),
      if (refund_addon.$)
        _tile('assets/icon/refund.png', l.refund_requests_ucf, () {
          Navigator.push(context,
              MaterialPageRoute(builder: (context) => RefundRequest()));
        }),
      if (coupon_activation.$)
        _tile('assets/icon/coupon.png', l.coupons_ucf, () => push(Coupons())),
      _tile('assets/icon/withdraw.png', l.money_withdraw_ucf,
          () => push(MoneyWithdraw())),
      _tile('assets/icon/payment_history.png', l.payment_history_ucf,
          () => push(PaymentHistory())),
    ];
  }
}
