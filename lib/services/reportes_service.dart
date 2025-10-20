import 'package:isar/isar.dart';
import '../models/venta.dart';
import '../models/compra.dart';
import '../models/transferencia.dart';
import '../models/tienda.dart';
import 'database_service.dart';
import 'producto_service.dart';
import 'tienda_service.dart';
import 'almacen_service.dart';
import 'empleado_service.dart';

class ReportesService {
  final DatabaseService _dbService = DatabaseService();
  final ProductoService _productoService = ProductoService();
  final TiendaService _tiendaService = TiendaService();
  final AlmacenService _almacenService = AlmacenService();
  final EmpleadoService _empleadoService = EmpleadoService();

  // Reportes de Ventas
  Future<List<Map<String, dynamic>>> getReporteVentas({
    String? tiendaId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
  }) async {
    final isar = await _dbService.isar;
    
    var ventas = await isar.ventas.where().findAll();
    
    // Filtrar por tienda
    if (tiendaId != null) {
      ventas = ventas.where((v) => v.tiendaId == tiendaId).toList();
    }
    
    // Filtrar por fecha
    if (fechaInicio != null) {
      ventas = ventas.where((v) => v.fechaVenta.isAfter(fechaInicio!) || v.fechaVenta.isAtSameMomentAs(fechaInicio!)).toList();
    }
    
    if (fechaFin != null) {
      final fechaFinAjustada = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);
      ventas = ventas.where((v) => v.fechaVenta.isBefore(fechaFinAjustada) || v.fechaVenta.isAtSameMomentAs(fechaFinAjustada)).toList();
    }
    
    // Filtrar por estado
    if (estado != null) {
      ventas = ventas.where((v) => v.estado == estado).toList();
    }
    final reporte = <Map<String, dynamic>>[];
    
    for (var venta in ventas) {
      final detalles = await isar.detalleVentas
          .filter()
          .ventaIdEqualTo(venta.numeroVenta)
          .findAll();
      
      final tienda = await _tiendaService.getByCodigo(venta.tiendaId);
      final empleado = await _empleadoService.getByCodigo(venta.empleadoId);
      
      reporte.add({
        'venta': venta,
        'detalles': detalles,
        'tienda': tienda,
        'empleado': empleado,
        'totalProductos': detalles.fold<int>(0, (sum, det) => sum + det.cantidad.toInt()),
        'totalVenta': venta.total,
      });
    }
    
    return reporte;
  }

  // Reportes de Compras
  Future<List<Map<String, dynamic>>> getReporteCompras({
    String? tiendaId,
    String? almacenId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
  }) async {
    final isar = await _dbService.isar;
    
    var compras = await isar.compras.where().findAll();
    
    // Filtrar por destino
    if (tiendaId != null) {
      compras = compras.where((c) => c.destinoTipo == 'tienda' && c.destinoId == tiendaId).toList();
    } else if (almacenId != null) {
      compras = compras.where((c) => c.destinoTipo == 'almacen' && c.destinoId == almacenId).toList();
    }
    
    // Filtrar por fecha
    if (fechaInicio != null) {
      compras = compras.where((c) => c.fechaCompra.isAfter(fechaInicio!) || c.fechaCompra.isAtSameMomentAs(fechaInicio!)).toList();
    }
    
    if (fechaFin != null) {
      final fechaFinAjustada = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);
      compras = compras.where((c) => c.fechaCompra.isBefore(fechaFinAjustada) || c.fechaCompra.isAtSameMomentAs(fechaFinAjustada)).toList();
    }
    
    // Filtrar por estado
    if (estado != null) {
      compras = compras.where((c) => c.estado == estado).toList();
    }
    final reporte = <Map<String, dynamic>>[];
    
    for (var compra in compras) {
      final detalles = await isar.detalleCompras
          .filter()
          .compraIdEqualTo(compra.numeroCompra)
          .findAll();
      
      final destino = compra.destinoTipo == 'tienda' 
          ? await _tiendaService.getByCodigo(compra.destinoId)
          : await _almacenService.getByCodigo(compra.destinoId);
      
      final empleado = await _empleadoService.getByCodigo(compra.empleadoId);
      
      reporte.add({
        'compra': compra,
        'detalles': detalles,
        'destino': destino,
        'empleado': empleado,
        'totalProductos': detalles.fold<int>(0, (sum, det) => sum + det.cantidad.toInt()),
        'totalCompra': compra.total,
      });
    }
    
    return reporte;
  }

  // Reportes de Transferencias
  Future<List<Map<String, dynamic>>> getReporteTransferencias({
    String? origenTipo,
    String? origenId,
    String? destinoTipo,
    String? destinoId,
    DateTime? fechaInicio,
    DateTime? fechaFin,
    String? estado,
  }) async {
    final isar = await _dbService.isar;
    
    var transferencias = await isar.transferencias.where().findAll();
    
    // Filtrar por origen
    if (origenTipo != null) {
      transferencias = transferencias.where((t) => t.origenTipo == origenTipo).toList();
    }
    
    if (origenId != null) {
      transferencias = transferencias.where((t) => t.origenId == origenId).toList();
    }
    
    // Filtrar por destino
    if (destinoTipo != null) {
      transferencias = transferencias.where((t) => t.destinoTipo == destinoTipo).toList();
    }
    
    if (destinoId != null) {
      transferencias = transferencias.where((t) => t.destinoId == destinoId).toList();
    }
    
    // Filtrar por fecha
    if (fechaInicio != null) {
      transferencias = transferencias.where((t) => t.fechaTransferencia.isAfter(fechaInicio!) || t.fechaTransferencia.isAtSameMomentAs(fechaInicio!)).toList();
    }
    
    if (fechaFin != null) {
      final fechaFinAjustada = DateTime(fechaFin.year, fechaFin.month, fechaFin.day, 23, 59, 59);
      transferencias = transferencias.where((t) => t.fechaTransferencia.isBefore(fechaFinAjustada) || t.fechaTransferencia.isAtSameMomentAs(fechaFinAjustada)).toList();
    }
    
    // Filtrar por estado
    if (estado != null) {
      transferencias = transferencias.where((t) => t.estado == estado).toList();
    }
    final reporte = <Map<String, dynamic>>[];
    
    for (var transferencia in transferencias) {
      final detalles = await isar.detalleTransferencias
          .filter()
          .transferenciaIdEqualTo(transferencia.numeroTransferencia)
          .findAll();
      
      final origen = transferencia.origenTipo == 'tienda' 
          ? await _tiendaService.getByCodigo(transferencia.origenId)
          : await _almacenService.getByCodigo(transferencia.origenId);
      
      final destino = transferencia.destinoTipo == 'tienda' 
          ? await _tiendaService.getByCodigo(transferencia.destinoId)
          : await _almacenService.getByCodigo(transferencia.destinoId);
      
      final empleado = await _empleadoService.getByCodigo(transferencia.empleadoId);
      
      reporte.add({
        'transferencia': transferencia,
        'detalles': detalles,
        'origen': origen,
        'destino': destino,
        'empleado': empleado,
        'totalProductos': detalles.fold<int>(0, (sum, det) => sum + det.cantidadEnviada.toInt()),
        'totalTransferencia': detalles.fold<double>(0, (sum, det) => sum + det.cantidadEnviada),
      });
    }
    
    return reporte;
  }

  // Reporte de Venta Global del Día
  Future<Map<String, dynamic>> getReporteVentaGlobalDia(DateTime fecha) async {
    final fechaInicio = DateTime(fecha.year, fecha.month, fecha.day, 0, 0, 0);
    final fechaFin = DateTime(fecha.year, fecha.month, fecha.day, 23, 59, 59);
    
    final ventas = await getReporteVentas(
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: 'completada',
    );
    
    double totalVentas = 0;
    int totalTransacciones = 0;
    int totalProductos = 0;
    Map<String, int> ventasPorTienda = {};
    Map<String, double> ingresosPorTienda = {};
    
    for (var item in ventas) {
      final venta = item['venta'] as Venta;
      final totalVenta = item['totalVenta'] as double;
      final totalProductosVenta = item['totalProductos'] as int;
      final tienda = item['tienda'] as Tienda?;
      
      totalVentas += totalVenta;
      totalTransacciones++;
      totalProductos += totalProductosVenta;
      
      if (tienda != null) {
        ventasPorTienda[tienda.nombre] = (ventasPorTienda[tienda.nombre] ?? 0) + 1;
        ingresosPorTienda[tienda.nombre] = (ingresosPorTienda[tienda.nombre] ?? 0) + totalVenta;
      }
    }
    
    return {
      'fecha': fecha,
      'totalVentas': totalVentas,
      'totalTransacciones': totalTransacciones,
      'totalProductos': totalProductos,
      'ventasPorTienda': ventasPorTienda,
      'ingresosPorTienda': ingresosPorTienda,
      'promedioVenta': totalTransacciones > 0 ? totalVentas / totalTransacciones : 0,
      'detalleVentas': ventas,
    };
  }

  // Resumen de Ventas por Período
  Future<Map<String, dynamic>> getResumenVentasPeriodo({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? tiendaId,
  }) async {
    final ventas = await getReporteVentas(
      tiendaId: tiendaId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: 'completada',
    );
    
    double totalVentas = 0;
    int totalTransacciones = 0;
    int totalProductos = 0;
    Map<String, double> ventasPorDia = {};
    Map<String, int> productosVendidos = {};
    
    for (var item in ventas) {
      final venta = item['venta'] as Venta;
      final totalVenta = item['totalVenta'] as double;
      final totalProductosVenta = item['totalProductos'] as int;
      final detalles = item['detalles'] as List<DetalleVenta>;
      
      totalVentas += totalVenta;
      totalTransacciones++;
      totalProductos += totalProductosVenta;
      
      final fecha = venta.fechaVenta;
      final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
      ventasPorDia[fechaStr] = (ventasPorDia[fechaStr] ?? 0) + totalVenta;
      
      for (var detalle in detalles) {
        final producto = await _productoService.getByCodigo(detalle.productoId);
        if (producto != null) {
          productosVendidos[producto.nombre] = (productosVendidos[producto.nombre] ?? 0) + detalle.cantidad.toInt();
        }
      }
    }
    
    return {
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'totalVentas': totalVentas,
      'totalTransacciones': totalTransacciones,
      'totalProductos': totalProductos,
      'ventasPorDia': ventasPorDia,
      'productosVendidos': productosVendidos,
      'promedioVenta': totalTransacciones > 0 ? totalVentas / totalTransacciones : 0,
    };
  }

  // Resumen de Compras por Período
  Future<Map<String, dynamic>> getResumenComprasPeriodo({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? tiendaId,
    String? almacenId,
  }) async {
    final compras = await getReporteCompras(
      tiendaId: tiendaId,
      almacenId: almacenId,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: 'completada',
    );
    
    double totalCompras = 0;
    int totalTransacciones = 0;
    int totalProductos = 0;
    Map<String, double> comprasPorDia = {};
    Map<String, int> productosComprados = {};
    
    for (var item in compras) {
      final compra = item['compra'] as Compra;
      final totalCompra = item['totalCompra'] as double;
      final totalProductosCompra = item['totalProductos'] as int;
      final detalles = item['detalles'] as List<DetalleCompra>;
      
      totalCompras += totalCompra;
      totalTransacciones++;
      totalProductos += totalProductosCompra;
      
      final fecha = compra.fechaCompra;
      final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
      comprasPorDia[fechaStr] = (comprasPorDia[fechaStr] ?? 0) + totalCompra;
      
      for (var detalle in detalles) {
        final producto = await _productoService.getByCodigo(detalle.productoId);
        if (producto != null) {
          productosComprados[producto.nombre] = (productosComprados[producto.nombre] ?? 0) + detalle.cantidad.toInt();
        }
      }
    }
    
    return {
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'totalCompras': totalCompras,
      'totalTransacciones': totalTransacciones,
      'totalProductos': totalProductos,
      'comprasPorDia': comprasPorDia,
      'productosComprados': productosComprados,
      'promedioCompra': totalTransacciones > 0 ? totalCompras / totalTransacciones : 0,
    };
  }

  // Resumen de Transferencias por Período
  Future<Map<String, dynamic>> getResumenTransferenciasPeriodo({
    required DateTime fechaInicio,
    required DateTime fechaFin,
    String? origenTipo,
    String? destinoTipo,
  }) async {
    final transferencias = await getReporteTransferencias(
      origenTipo: origenTipo,
      destinoTipo: destinoTipo,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      estado: 'completada',
    );
    
    int totalTransferencias = 0;
    int totalProductos = 0;
    Map<String, int> transferenciasPorDia = {};
    Map<String, int> transferenciasPorTipo = {};
    
    for (var item in transferencias) {
      final transferencia = item['transferencia'] as Transferencia;
      final totalProductosTransferencia = item['totalProductos'] as int;
      
      totalTransferencias++;
      totalProductos += totalProductosTransferencia;
      
      final fecha = transferencia.fechaTransferencia;
      final fechaStr = '${fecha.day}/${fecha.month}/${fecha.year}';
      transferenciasPorDia[fechaStr] = (transferenciasPorDia[fechaStr] ?? 0) + 1;
      
      final tipoTransferencia = '${transferencia.origenTipo} → ${transferencia.destinoTipo}';
      transferenciasPorTipo[tipoTransferencia] = (transferenciasPorTipo[tipoTransferencia] ?? 0) + 1;
    }
    
    return {
      'fechaInicio': fechaInicio,
      'fechaFin': fechaFin,
      'totalTransferencias': totalTransferencias,
      'totalProductos': totalProductos,
      'transferenciasPorDia': transferenciasPorDia,
      'transferenciasPorTipo': transferenciasPorTipo,
    };
  }
}
