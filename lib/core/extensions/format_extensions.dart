//import 'package:flutter/material.dart';
extension CurrencyFormat on double {
  /// Formata como moeda brasileira: R$ 1.234,56
  String toBRL() => 'R\$ ${toStringAsFixed(2).replaceAll(".", ",")}';
}
extension DateTimeDisplay on DateTime {
  /// Ex.: 31/12/2025
  String toDisplayDate() {
    final d = day.toString().padLeft(2, '0');
    final m = month.toString().padLeft(2, '0');
    return '$d/$m/$year';
  }
  /// Ex.: 31/12/2025 23:59
  String toDisplayDateTime() {
    final h = hour.toString().padLeft(2, '0');
    final min = minute.toString().padLeft(2, '0');
    return '${toDisplayDate()} $h:$min';
  }
}
