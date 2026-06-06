import 'package:flutter/material.dart';
import '../../data/models/order_model.dart';
import '../constants/app_colors.dart';
extension OrderStatusUiExtension on OrderStatus {
  Color get color {
    switch (this) {
      case OrderStatus.awaitingPayment:
        return AppColors.warning;
      case OrderStatus.pending:
        return AppColors.warning;
      case OrderStatus.confirmed:
        return AppColors.info;
      case OrderStatus.shipped:
        return AppColors.pink;
      case OrderStatus.delivered:
        return AppColors.success;
      case OrderStatus.cancelled:
        return AppColors.error;
    }
  }
  IconData get icon {
    switch (this) {
      case OrderStatus.awaitingPayment:
        return Icons.payments_outlined;
      case OrderStatus.pending:
        return Icons.hourglass_empty;
      case OrderStatus.confirmed:
        return Icons.check;
      case OrderStatus.shipped:
        return Icons.local_shipping_outlined;
      case OrderStatus.delivered:
        return Icons.done_all;
      case OrderStatus.cancelled:
        return Icons.cancel_outlined;
    }
  }
}
