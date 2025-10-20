import 'package:flutter/foundation.dart';
import '../models/producto.dart';
import '../services/inventario_service.dart';

class InventarioProvider with ChangeNotifier {
  final InventarioService _inventarioService = InventarioService();
  
  List<Map<String, dynamic>> _inventarioDetallado = [];
  bool _isLoading = false;
  String _vistaActual = 'global';

  // Getters
  List<Map<String, dynamic>> get inventarioDetallado => _inventarioDetallado;
  bool get isLoading => _isLoading;
  String get vistaActual => _vistaActual;

  // Cargar inventario
  Future<void> loadInventario() async {
    _isLoading = true;
    notifyListeners();
    
    try {
      print('InventarioProvider.loadInventario: Cargando inventario...');
      _inventarioDetallado = await _inventarioService.getInventarioGlobal();
      print('InventarioProvider.loadInventario: Inventario cargado: ${_inventarioDetallado.length} productos');
    } catch (e) {
      print('InventarioProvider.loadInventario: Error: $e');
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // Cambiar vista
  void cambiarVista(String vista) {
    _vistaActual = vista;
    notifyListeners();
    loadInventario(); // Recargar con la nueva vista
  }

  // Actualizar inventario después de operaciones
  Future<void> refreshInventario() async {
    print('InventarioProvider.refreshInventario: Actualizando inventario...');
    await loadInventario();
  }

  // Obtener stock total de un producto
  double getStockTotal(String productoId) {
    final item = _inventarioDetallado.firstWhere(
      (item) => (item['producto'] as Producto).codigo == productoId,
      orElse: () => {'stockTotal': 0.0},
    );
    return item['stockTotal'] as double;
  }

  // Obtener stock en almacenes de un producto
  double getStockEnAlmacenes(String productoId) {
    final item = _inventarioDetallado.firstWhere(
      (item) => (item['producto'] as Producto).codigo == productoId,
      orElse: () => {'stockAlmacenes': 0.0},
    );
    return item['stockAlmacenes'] as double;
  }

  // Obtener stock en tiendas de un producto
  double getStockEnTiendas(String productoId) {
    final item = _inventarioDetallado.firstWhere(
      (item) => (item['producto'] as Producto).codigo == productoId,
      orElse: () => {'stockTiendas': 0.0},
    );
    return item['stockTiendas'] as double;
  }

  // Verificar si un producto está bajo stock
  bool isBajoStock(String productoId) {
    final item = _inventarioDetallado.firstWhere(
      (item) => (item['producto'] as Producto).codigo == productoId,
      orElse: () => {'bajoStock': false},
    );
    return item['bajoStock'] as bool;
  }
}
