import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventario_provider.dart';

class InventarioNotifier {
  static void notifyChange(BuildContext context) {
    try {
      final inventarioProvider = context.read<InventarioProvider>();
      inventarioProvider.refreshInventario();
    } catch (e) {
      print('InventarioNotifier.notifyChange: Error notificando cambio: $e');
    }
  }
}
