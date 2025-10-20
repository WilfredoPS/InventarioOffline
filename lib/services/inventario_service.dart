import 'package:isar/isar.dart';
import '../models/inventario.dart';
import 'database_service.dart';
import 'producto_service.dart';

class InventarioService {
  final DatabaseService _dbService = DatabaseService();
  final ProductoService _productoService = ProductoService();

  Future<Inventario?> getInventario(
      String productoId, String ubicacionTipo, String ubicacionId) async {
    final isar = await _dbService.isar;
    return await isar.inventarios
        .filter()
        .productoIdEqualTo(productoId)
        .ubicacionTipoEqualTo(ubicacionTipo)
        .ubicacionIdEqualTo(ubicacionId)
        .findFirst();
  }

  Future<List<Inventario>> getInventarioPorUbicacion(
      String ubicacionTipo, String ubicacionId) async {
    final isar = await _dbService.isar;
    return await isar.inventarios
        .filter()
        .ubicacionTipoEqualTo(ubicacionTipo)
        .ubicacionIdEqualTo(ubicacionId)
        .findAll();
  }

  Future<List<Inventario>> getInventarioPorProducto(String productoId) async {
    final isar = await _dbService.isar;
    return await isar.inventarios
        .filter()
        .productoIdEqualTo(productoId)
        .findAll();
  }

  Future<double> getStockTotal(String productoId) async {
    final inventarios = await getInventarioPorProducto(productoId);
    return inventarios.fold<double>(0.0, (sum, inv) => sum + inv.cantidad);
  }

  Future<double> getStockEnUbicacion(
      String productoId, String ubicacionTipo, String ubicacionId) async {
    final inventario =
        await getInventario(productoId, ubicacionTipo, ubicacionId);
    return inventario?.cantidad ?? 0.0;
  }

  Future<void> actualizarStock(String productoId, String ubicacionTipo,
      String ubicacionId, double cantidad) async {
    final isar = await _dbService.isar;

    await isar.writeTxn(() async {
      var inventario =
          await getInventario(productoId, ubicacionTipo, ubicacionId);

      if (inventario == null) {
        inventario = Inventario()
          ..productoId = productoId
          ..ubicacionTipo = ubicacionTipo
          ..ubicacionId = ubicacionId
          ..cantidad = cantidad
          ..ultimaActualizacion = DateTime.now()
          ..sincronizado = false;
      } else {
        inventario.cantidad = cantidad;
        inventario.ultimaActualizacion = DateTime.now();
        inventario.sincronizado = false;
      }

      await isar.inventarios.put(inventario);
    });
  }

  Future<void> ajustarStock(String productoId, String ubicacionTipo,
      String ubicacionId, double ajuste) async {
    print('InventarioService.ajustarStock: Ajustando stock para $productoId en $ubicacionTipo:$ubicacionId por $ajuste');
    final stockActual =
        await getStockEnUbicacion(productoId, ubicacionTipo, ubicacionId);
    print('InventarioService.ajustarStock: Stock actual: $stockActual');
    final nuevoStock = stockActual + ajuste;
    print('InventarioService.ajustarStock: Nuevo stock: $nuevoStock');
    await actualizarStock(productoId, ubicacionTipo, ubicacionId, nuevoStock);
  }

  Future<void> transferirStock(
      String productoId,
      String origenTipo,
      String origenId,
      String destinoTipo,
      String destinoId,
      double cantidad) async {
    // Reducir en origen
    await ajustarStock(productoId, origenTipo, origenId, -cantidad);

    // Aumentar en destino
    await ajustarStock(productoId, destinoTipo, destinoId, cantidad);
  }

  Future<List<Inventario>> getInventarioBajo() async {
    // Esta función requeriría un join con productos para comparar con stockMinimo
    // Por simplicidad, retornamos todos y filtraremos en la capa de presentación
    final isar = await _dbService.isar;
    return await isar.inventarios.where().findAll();
  }

  Future<List<Inventario>> getNoSincronizados() async {
    final isar = await _dbService.isar;
    return await isar.inventarios.filter().sincronizadoEqualTo(false).findAll();
  }

  Future<void> marcarSincronizado(int id, String supabaseId) async {
    final isar = await _dbService.isar;
    final inventario = await isar.inventarios.get(id);
    if (inventario != null) {
      inventario.sincronizado = true;
      inventario.supabaseId = supabaseId;
      await isar.writeTxn(() async {
        await isar.inventarios.put(inventario);
      });
    }
  }

  Future<void> inicializarStockInicial() async {
    print('InventarioService.inicializarStockInicial: Inicializando stock por defecto');
    final isar = await _dbService.isar;
    
    // Crear stock inicial para todos los productos en el almacén principal
    final productos = await _productoService.getAll();
    print('InventarioService.inicializarStockInicial: Creando stock para ${productos.length} productos');
    
    await isar.writeTxn(() async {
      for (var producto in productos) {
        // Verificar si ya existe inventario para este producto
        final inventarioExistente = await getInventario(producto.codigo, 'almacen', 'ALM001');
        
        if (inventarioExistente == null) {
          // Crear nuevo inventario
          final inventario = Inventario()
            ..productoId = producto.codigo
            ..ubicacionTipo = 'almacen'
            ..ubicacionId = 'ALM001' // Almacén principal
            ..cantidad = 10.0 // Stock inicial de 10 unidades
            ..ultimaActualizacion = DateTime.now()
            ..sincronizado = false;
          
          await isar.inventarios.put(inventario);
          print('InventarioService.inicializarStockInicial: Creado stock inicial para ${producto.nombre}: 10 unidades');
        } else {
          // Actualizar stock existente a 10 unidades
          inventarioExistente.cantidad = 10.0;
          inventarioExistente.ultimaActualizacion = DateTime.now();
          inventarioExistente.sincronizado = false;
          await isar.inventarios.put(inventarioExistente);
          print('InventarioService.inicializarStockInicial: Actualizado stock para ${producto.nombre}: 10 unidades');
        }
      }
    });
  }

  // Métodos para inventario detallado por ubicación
  Future<List<Map<String, dynamic>>> getInventarioGlobal() async {
    print('InventarioService.getInventarioGlobal: Iniciando cálculo de inventario global');
    final productos = await _productoService.getAll();
    final inventarioGlobal = <Map<String, dynamic>>[];

    for (var producto in productos) {
      final stockTotal = await getStockTotal(producto.codigo);
      final stockAlmacenes = await getStockEnAlmacenes(producto.codigo);
      final stockTiendas = await getStockEnTiendas(producto.codigo);
      
      print('InventarioService.getInventarioGlobal: ${producto.nombre} - Total: $stockTotal, Almacenes: $stockAlmacenes, Tiendas: $stockTiendas');
      
      inventarioGlobal.add({
        'producto': producto,
        'stockTotal': stockTotal,
        'stockAlmacenes': stockAlmacenes,
        'stockTiendas': stockTiendas,
        'bajoStock': stockTotal <= producto.stockMinimo && producto.stockMinimo > 0,
      });
    }

    print('InventarioService.getInventarioGlobal: Inventario global calculado para ${inventarioGlobal.length} productos');
    return inventarioGlobal;
  }

  Future<List<Map<String, dynamic>>> getInventarioPorAlmacen(String almacenId) async {
    final productos = await _productoService.getAll();
    final inventarioAlmacen = <Map<String, dynamic>>[];

    for (var producto in productos) {
      final stock = await getStockEnUbicacion(producto.codigo, 'almacen', almacenId);
      
      if (stock > 0) {
        inventarioAlmacen.add({
          'producto': producto,
          'stock': stock,
          'bajoStock': stock <= producto.stockMinimo && producto.stockMinimo > 0,
        });
      }
    }

    return inventarioAlmacen;
  }

  Future<List<Map<String, dynamic>>> getInventarioPorTienda(String tiendaId) async {
    final productos = await _productoService.getAll();
    final inventarioTienda = <Map<String, dynamic>>[];

    for (var producto in productos) {
      final stock = await getStockEnUbicacion(producto.codigo, 'tienda', tiendaId);
      
      if (stock > 0) {
        inventarioTienda.add({
          'producto': producto,
          'stock': stock,
          'bajoStock': stock <= producto.stockMinimo && producto.stockMinimo > 0,
        });
      }
    }

    return inventarioTienda;
  }

  Future<double> getStockEnAlmacenes(String productoId) async {
    final isar = await _dbService.isar;
    final inventarios = await isar.inventarios
        .filter()
        .productoIdEqualTo(productoId)
        .ubicacionTipoEqualTo('almacen')
        .findAll();
    final stock = inventarios.fold<double>(0.0, (sum, inv) => sum + inv.cantidad);
    print('InventarioService.getStockEnAlmacenes: $productoId - Encontrados ${inventarios.length} registros, stock total: $stock');
    return stock;
  }

  Future<double> getStockEnTiendas(String productoId) async {
    final isar = await _dbService.isar;
    final inventarios = await isar.inventarios
        .filter()
        .productoIdEqualTo(productoId)
        .ubicacionTipoEqualTo('tienda')
        .findAll();
    final stock = inventarios.fold<double>(0.0, (sum, inv) => sum + inv.cantidad);
    print('InventarioService.getStockEnTiendas: $productoId - Encontrados ${inventarios.length} registros, stock total: $stock');
    return stock;
  }

  Future<Map<String, double>> getStockDetalladoPorUbicacion(String productoId) async {
    final inventarios = await getInventarioPorProducto(productoId);
    final stockDetallado = <String, double>{};

    for (var inventario in inventarios) {
      final key = '${inventario.ubicacionTipo}:${inventario.ubicacionId}';
      stockDetallado[key] = inventario.cantidad;
    }

    return stockDetallado;
  }

  Future<List<Map<String, dynamic>>> getInventarioBajoStock() async {
    final productos = await _productoService.getAll();
    final inventarioBajo = <Map<String, dynamic>>[];

    for (var producto in productos) {
      if (producto.stockMinimo > 0) {
        final stockTotal = await getStockTotal(producto.codigo);
        if (stockTotal <= producto.stockMinimo) {
          final stockDetallado = await getStockDetalladoPorUbicacion(producto.codigo);
          
          inventarioBajo.add({
            'producto': producto,
            'stockTotal': stockTotal,
            'stockMinimo': producto.stockMinimo,
            'stockDetallado': stockDetallado,
            'diferencia': producto.stockMinimo - stockTotal,
          });
        }
      }
    }

    return inventarioBajo;
  }
}

