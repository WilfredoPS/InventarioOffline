import '../models/producto.dart';
import '../models/venta.dart';
import '../models/compra.dart';
import 'producto_service.dart';
import 'inventario_service.dart';
import 'compra_service.dart';
import 'database_service.dart';
import 'package:isar/isar.dart';

class SugerenciaCompraService {
  final ProductoService _productoService = ProductoService();
  final InventarioService _inventarioService = InventarioService();
  final DatabaseService _dbService = DatabaseService();

  /// Analiza las ventas de los últimos días y sugiere productos para comprar
  Future<List<Map<String, dynamic>>> generarSugerenciasCompra({
    int diasAtras = 7,
    double factorMultiplicador = 1.5,
    String? tiendaId,
  }) async {
    print('SugerenciaCompraService.generarSugerenciasCompra: Analizando ventas de los últimos $diasAtras días');
    
    final isar = await _dbService.isar;
    final fechaInicio = DateTime.now().subtract(Duration(days: diasAtras));
    
    // Obtener todas las ventas del período
    List<Venta> ventas;
    if (tiendaId != null) {
      ventas = await isar.ventas
          .filter()
          .eliminadoEqualTo(false)
          .tiendaIdEqualTo(tiendaId)
          .fechaVentaGreaterThan(fechaInicio)
          .findAll();
    } else {
      ventas = await isar.ventas
          .filter()
          .eliminadoEqualTo(false)
          .fechaVentaGreaterThan(fechaInicio)
          .findAll();
    }

    print('SugerenciaCompraService.generarSugerenciasCompra: Encontradas ${ventas.length} ventas');

    // Agrupar productos vendidos por cantidad
    Map<String, double> productosVendidos = {};
    Map<String, double> productosPrecioPromedio = {};
    
    for (var venta in ventas) {
      final detalles = await isar.detalleVentas
          .filter()
          .ventaIdEqualTo(venta.numeroVenta)
          .findAll();
      
      for (var detalle in detalles) {
        productosVendidos[detalle.productoId] = 
            (productosVendidos[detalle.productoId] ?? 0.0) + detalle.cantidad;
        
        // Calcular precio promedio
        final totalActual = (productosPrecioPromedio[detalle.productoId] ?? 0.0) + detalle.subtotal;
        productosPrecioPromedio[detalle.productoId] = totalActual;
      }
    }

    print('SugerenciaCompraService.generarSugerenciasCompra: Productos vendidos: ${productosVendidos.length}');

    // Obtener información de productos y stock actual
    final productos = await _productoService.getAll();
    final sugerencias = <Map<String, dynamic>>[];

    for (var producto in productos) {
      final cantidadVendida = productosVendidos[producto.codigo] ?? 0.0;
      
      if (cantidadVendida > 0) {
        // Calcular stock actual
        double stockActual = 0.0;
        if (tiendaId != null) {
          stockActual = await _inventarioService.getStockEnTiendas(producto.codigo);
        } else {
          stockActual = await _inventarioService.getStockTotal(producto.codigo);
        }

        // Calcular cantidad sugerida para comprar
        final cantidadSugerida = (cantidadVendida * factorMultiplicador).ceil().toDouble();
        final cantidadNecesaria = cantidadSugerida - stockActual;
        
        // Solo sugerir si necesitamos más stock
        if (cantidadNecesaria > 0) {
          // Calcular precio promedio de venta
          final precioPromedioVenta = productosPrecioPromedio[producto.codigo]! / cantidadVendida;
          
          sugerencias.add({
            'producto': producto,
            'cantidadVendida': cantidadVendida,
            'stockActual': stockActual,
            'cantidadSugerida': cantidadSugerida,
            'cantidadNecesaria': cantidadNecesaria,
            'precioPromedioVenta': precioPromedioVenta,
            'precioCompraSugerido': producto.precioCompra,
            'subtotalSugerido': cantidadNecesaria * producto.precioCompra,
            'prioridad': _calcularPrioridad(cantidadVendida, stockActual, producto.stockMinimo.toDouble()),
          });
        }
      }
    }

    // Ordenar por prioridad (mayor prioridad primero)
    sugerencias.sort((a, b) => (b['prioridad'] as double).compareTo(a['prioridad'] as double));

    print('SugerenciaCompraService.generarSugerenciasCompra: Generadas ${sugerencias.length} sugerencias');
    return sugerencias;
  }

  /// Calcula la prioridad de compra basada en ventas y stock
  double _calcularPrioridad(double cantidadVendida, double stockActual, double stockMinimo) {
    // Factor de velocidad de venta (cantidad vendida por día)
    final velocidadVenta = cantidadVendida / 7; // Asumiendo 7 días
    
    // Factor de urgencia basado en stock actual vs mínimo
    final urgenciaStock = stockActual <= stockMinimo ? 2.0 : 1.0;
    
    // Factor de rotación (cuánto se vende vs cuánto hay)
    final rotacion = stockActual > 0 ? cantidadVendida / stockActual : 10.0;
    
    return velocidadVenta * urgenciaStock * rotacion;
  }

  /// Obtiene productos con stock bajo (bajo el mínimo)
  Future<List<Map<String, dynamic>>> getProductosStockBajo({String? tiendaId}) async {
    print('SugerenciaCompraService.getProductosStockBajo: Buscando productos con stock bajo');
    
    final productos = await _productoService.getAll();
    final productosStockBajo = <Map<String, dynamic>>[];

    for (var producto in productos) {
      if (producto.stockMinimo > 0) {
        double stockActual = 0.0;
        if (tiendaId != null) {
          stockActual = await _inventarioService.getStockEnTiendas(producto.codigo);
        } else {
          stockActual = await _inventarioService.getStockTotal(producto.codigo);
        }

        if (stockActual <= producto.stockMinimo) {
          final cantidadNecesaria = (producto.stockMinimo * 2.0) - stockActual; // Comprar el doble del mínimo
          
          productosStockBajo.add({
            'producto': producto,
            'stockActual': stockActual,
            'stockMinimo': producto.stockMinimo,
            'cantidadNecesaria': cantidadNecesaria,
            'precioCompraSugerido': producto.precioCompra,
            'subtotalSugerido': cantidadNecesaria * producto.precioCompra,
            'prioridad': 10.0, // Máxima prioridad para stock bajo
            'motivo': 'Stock bajo el mínimo',
          });
        }
      }
    }

    print('SugerenciaCompraService.getProductosStockBajo: Encontrados ${productosStockBajo.length} productos con stock bajo');
    return productosStockBajo;
  }

  /// Crea una compra automática basada en las sugerencias
  Future<String?> crearCompraAutomatica({
    required List<Map<String, dynamic>> sugerencias,
    required String destinoTipo,
    required String destinoId,
    required String proveedor,
    String? numeroFactura,
    String? observaciones,
  }) async {
    print('SugerenciaCompraService.crearCompraAutomatica: Creando compra automática con ${sugerencias.length} productos');
    
    try {
      // Generar número de compra
      final compraService = CompraService();
      final numeroCompra = await compraService.generarNumeroCompra();
      
      // Calcular totales
      double subtotal = 0.0;
      for (var sugerencia in sugerencias) {
        subtotal += sugerencia['subtotalSugerido'] as double;
      }
      
      final impuesto = subtotal * 0.0; // Ajustar según necesidad
      final total = subtotal + impuesto;
      
      // Crear compra
      final compra = Compra()
        ..numeroCompra = numeroCompra
        ..fechaCompra = DateTime.now()
        ..proveedor = proveedor
        ..numeroFactura = numeroFactura
        ..destinoTipo = destinoTipo
        ..destinoId = destinoId
        ..empleadoId = 'SISTEMA' // Compra automática
        ..subtotal = subtotal
        ..impuesto = impuesto
        ..total = total
        ..estado = 'completada' // Completar automáticamente
        ..observaciones = observaciones ?? 'Compra automática generada por sugerencias de ventas';
      
      // Crear detalles
      final detalles = sugerencias.map((sugerencia) {
        final producto = sugerencia['producto'] as Producto;
        final cantidad = sugerencia['cantidadNecesaria'] as double;
        final precioUnitario = sugerencia['precioCompraSugerido'] as double;
        
        return DetalleCompra()
          ..compraId = numeroCompra
          ..productoId = producto.codigo
          ..cantidad = cantidad
          ..precioUnitario = precioUnitario
          ..subtotal = cantidad * precioUnitario;
      }).toList();
      
      // Guardar compra
      await compraService.crear(compra, detalles);
      
      print('SugerenciaCompraService.crearCompraAutomatica: Compra creada exitosamente: $numeroCompra');
      return numeroCompra;
      
    } catch (e) {
      print('SugerenciaCompraService.crearCompraAutomatica: Error creando compra: $e');
      return null;
    }
  }

  /// Obtiene estadísticas de ventas por producto
  Future<Map<String, dynamic>> getEstadisticasVentas({
    int diasAtras = 30,
    String? tiendaId,
  }) async {
    final isar = await _dbService.isar;
    final fechaInicio = DateTime.now().subtract(Duration(days: diasAtras));
    
    List<Venta> ventas;
    if (tiendaId != null) {
      ventas = await isar.ventas
          .filter()
          .eliminadoEqualTo(false)
          .tiendaIdEqualTo(tiendaId)
          .fechaVentaGreaterThan(fechaInicio)
          .findAll();
    } else {
      ventas = await isar.ventas
          .filter()
          .eliminadoEqualTo(false)
          .fechaVentaGreaterThan(fechaInicio)
          .findAll();
    }

    Map<String, double> productosVendidos = {};
    Map<String, double> productosIngresos = {};
    double totalVentas = 0.0;
    
    for (var venta in ventas) {
      totalVentas += venta.total;
      
      final detalles = await isar.detalleVentas
          .filter()
          .ventaIdEqualTo(venta.numeroVenta)
          .findAll();
      
      for (var detalle in detalles) {
        productosVendidos[detalle.productoId] = 
            (productosVendidos[detalle.productoId] ?? 0.0) + detalle.cantidad;
        productosIngresos[detalle.productoId] = 
            (productosIngresos[detalle.productoId] ?? 0.0) + detalle.subtotal;
      }
    }

    return {
      'totalVentas': totalVentas,
      'cantidadVentas': ventas.length,
      'productosVendidos': productosVendidos,
      'productosIngresos': productosIngresos,
      'productosUnicos': productosVendidos.length,
    };
  }
}
