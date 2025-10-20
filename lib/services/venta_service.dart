import 'package:isar/isar.dart';
import '../models/venta.dart';
import 'database_service.dart';
import 'inventario_service.dart';

class VentaService {
  final DatabaseService _dbService = DatabaseService();
  final InventarioService _inventarioService = InventarioService();

  Future<List<Venta>> getAll() async {
    final isar = await _dbService.isar;
    return await isar.ventas.filter().eliminadoEqualTo(false).findAll();
  }

  Future<List<Venta>> getByTienda(String tiendaId) async {
    final isar = await _dbService.isar;
    return await isar.ventas
        .filter()
        .eliminadoEqualTo(false)
        .tiendaIdEqualTo(tiendaId)
        .findAll();
  }

  Future<Venta?> getById(int id) async {
    final isar = await _dbService.isar;
    return await isar.ventas.get(id);
  }

  Future<Venta?> getByNumeroVenta(String numeroVenta) async {
    final isar = await _dbService.isar;
    return await isar.ventas
        .filter()
        .eliminadoEqualTo(false)
        .numeroVentaEqualTo(numeroVenta)
        .findFirst();
  }

  Future<double> getTotalVentasDelDia(String tiendaId) async {
    final isar = await _dbService.isar;
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    
    final ventas = await isar.ventas
        .filter()
        .eliminadoEqualTo(false)
        .tiendaIdEqualTo(tiendaId)
        .fechaVentaBetween(inicioDia, finDia)
        .findAll();
    
    return ventas.fold<double>(0.0, (sum, venta) => sum + venta.total);
  }

  Future<Map<String, double>> getTotalVentasGlobalDelDia() async {
    final isar = await _dbService.isar;
    final hoy = DateTime.now();
    final inicioDia = DateTime(hoy.year, hoy.month, hoy.day);
    final finDia = DateTime(hoy.year, hoy.month, hoy.day, 23, 59, 59);
    
    final ventas = await isar.ventas
        .filter()
        .eliminadoEqualTo(false)
        .fechaVentaBetween(inicioDia, finDia)
        .findAll();
    
    Map<String, double> ventasPorTienda = {};
    for (var venta in ventas) {
      ventasPorTienda[venta.tiendaId] = 
          (ventasPorTienda[venta.tiendaId] ?? 0.0) + venta.total;
    }
    
    return ventasPorTienda;
  }

  Future<String> generarNumeroVenta(String tiendaId) async {
    final isar = await _dbService.isar;
    final hoy = DateTime.now();
    final fecha = '${hoy.year}${hoy.month.toString().padLeft(2, '0')}${hoy.day.toString().padLeft(2, '0')}';
    
    // Intentar generar un número único con reintentos
    for (int intento = 0; intento < 10; intento++) {
      // Buscar el último número de venta del día para esta tienda
      final ventas = await isar.ventas
          .filter()
          .numeroVentaStartsWith('V$tiendaId$fecha')
          .eliminadoEqualTo(false)
          .findAll();
      
      print('VentaService.generarNumeroVenta: Encontradas ${ventas.length} ventas para $tiendaId en $fecha (intento ${intento + 1})');
      
      // Encontrar el número más alto
      int maxNumero = 0;
      for (var venta in ventas) {
        final numeroStr = venta.numeroVenta.substring(venta.numeroVenta.length - 4);
        final numero = int.tryParse(numeroStr) ?? 0;
        if (numero > maxNumero) {
          maxNumero = numero;
        }
      }
      
      // Agregar un pequeño delay aleatorio para evitar conflictos de concurrencia
      if (intento > 0) {
        await Future.delayed(Duration(milliseconds: 10 + (intento * 5)));
      }
      
      final siguienteNumero = maxNumero + 1 + intento;
      final numeroFormateado = siguienteNumero.toString().padLeft(4, '0');
      final numeroVenta = 'V$tiendaId$fecha$numeroFormateado';
      
      // Verificar si el número ya existe
      final existe = await isar.ventas
          .filter()
          .numeroVentaEqualTo(numeroVenta)
          .findFirst();
      
      if (existe == null) {
        print('VentaService.generarNumeroVenta: Generando número único: $numeroVenta (siguiente: $siguienteNumero)');
        return numeroVenta;
      } else {
        print('VentaService.generarNumeroVenta: Número $numeroVenta ya existe, reintentando...');
      }
    }
    
    // Si llegamos aquí, usar timestamp como fallback
    final timestamp = DateTime.now().millisecondsSinceEpoch.toString().substring(8);
    final numeroVenta = 'V$tiendaId$fecha$timestamp';
    print('VentaService.generarNumeroVenta: Usando timestamp como fallback: $numeroVenta');
    return numeroVenta;
  }

  Future<int> crear(Venta venta, List<DetalleVenta> detalles) async {
    final isar = await _dbService.isar;
    
    try {
      print('VentaService.crear: Iniciando creación de venta ${venta.numeroVenta}');
      print('VentaService.crear: Detalles a crear: ${detalles.length}');
      
      final ventaId = await isar.writeTxn(() async {
        // Crear venta
        venta.createdAt = DateTime.now();
        venta.updatedAt = DateTime.now();
        venta.sincronizado = false;
        
        print('VentaService.crear: Guardando venta en Isar...');
        final ventaId = await isar.ventas.put(venta);
        print('VentaService.crear: Venta guardada con ID: $ventaId');
        
        // Crear detalles
        for (int i = 0; i < detalles.length; i++) {
          final detalle = detalles[i];
          print('VentaService.crear: Guardando detalle ${i + 1}: ${detalle.productoId} - ${detalle.cantidad}');
          await isar.detalleVentas.put(detalle);
        }
        
        print('VentaService.crear: Todos los detalles guardados exitosamente');
        return ventaId;
      });
      
      print('VentaService.crear: Transacción completada, actualizando inventario...');
      
      // Actualizar inventario después de la transacción exitosa
      for (var detalle in detalles) {
        print('VentaService.crear: Ajustando stock para ${detalle.productoId}: -${detalle.cantidad}');
        await _inventarioService.ajustarStock(
          detalle.productoId,
          'tienda',
          venta.tiendaId,
          -detalle.cantidad, // Descontar del stock
        );
      }
      
      print('VentaService.crear: Venta creada exitosamente con ID: $ventaId');
      return ventaId;
    } catch (e) {
      print('VentaService.crear: Error creando venta: $e');
      print('VentaService.crear: Stack trace: ${StackTrace.current}');
      rethrow;
    }
  }

  Future<void> actualizar(Venta venta) async {
    final isar = await _dbService.isar;
    venta.updatedAt = DateTime.now();
    venta.sincronizado = false;

    await isar.writeTxn(() async {
      await isar.ventas.put(venta);
    });
  }

  Future<void> eliminar(int id) async {
    final venta = await getById(id);
    if (venta != null) {
      venta.eliminado = true;
      venta.updatedAt = DateTime.now();
      venta.sincronizado = false;
      await actualizar(venta);
    }
  }

  Future<void> anularVenta(String numeroVenta) async {
    final isar = await _dbService.isar;
    final venta = await isar.ventas
        .filter()
        .numeroVentaEqualTo(numeroVenta)
        .findFirst();

    if (venta != null) {
      venta.estado = 'anulada';
      venta.updatedAt = DateTime.now();
      venta.sincronizado = false;
      await actualizar(venta);

      // Restaurar inventario
      final detalles = await isar.detalleVentas
          .filter()
          .ventaIdEqualTo(numeroVenta)
          .findAll();
      
      for (var detalle in detalles) {
        await _inventarioService.ajustarStock(
          detalle.productoId,
          'tienda',
          venta.tiendaId,
          detalle.cantidad, // Restaurar stock
        );
      }
    }
  }

  Future<List<Venta>> getNoSincronizados() async {
    final isar = await _dbService.isar;
    return await isar.ventas.filter().sincronizadoEqualTo(false).findAll();
  }

  Future<void> marcarSincronizado(int id, String supabaseId) async {
    final venta = await getById(id);
    if (venta != null) {
      venta.sincronizado = true;
      venta.supabaseId = supabaseId;
      await actualizar(venta);
    }
  }
}