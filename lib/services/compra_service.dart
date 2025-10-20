import 'package:isar/isar.dart';
import '../models/compra.dart';
import 'database_service.dart';
import 'inventario_service.dart';

class CompraService {
  final DatabaseService _dbService = DatabaseService();
  final InventarioService _inventarioService = InventarioService();

  Future<List<Compra>> getAll({bool incluirEliminados = false}) async {
    final isar = await _dbService.isar;
    if (incluirEliminados) {
      return await isar.compras.where().sortByFechaCompraDesc().findAll();
    }
    return await isar.compras
        .filter()
        .eliminadoEqualTo(false)
        .sortByFechaCompraDesc()
        .findAll();
  }

  Future<Compra?> getByNumero(String numeroCompra) async {
    final isar = await _dbService.isar;
    return await isar.compras.filter().numeroCompraEqualTo(numeroCompra).findFirst();
  }

  Future<Compra?> getById(int id) async {
    final isar = await _dbService.isar;
    return await isar.compras.get(id);
  }

  Future<List<DetalleCompra>> getDetalles(String compraId) async {
    final isar = await _dbService.isar;
    return await isar.detalleCompras.filter().compraIdEqualTo(compraId).findAll();
  }

  Future<List<Compra>> getByFechas(DateTime inicio, DateTime fin) async {
    final isar = await _dbService.isar;
    return await isar.compras
        .filter()
        .eliminadoEqualTo(false)
        .fechaCompraBetween(inicio, fin)
        .sortByFechaCompraDesc()
        .findAll();
  }

  Future<List<Compra>> getByDestino(String destinoTipo, String destinoId) async {
    final isar = await _dbService.isar;
    return await isar.compras
        .filter()
        .eliminadoEqualTo(false)
        .destinoTipoEqualTo(destinoTipo)
        .destinoIdEqualTo(destinoId)
        .sortByFechaCompraDesc()
        .findAll();
  }

  Future<String> generarNumeroCompra() async {
    final ahora = DateTime.now();
    final prefijo = 'COM-${ahora.year}${ahora.month.toString().padLeft(2, '0')}';
    final isar = await _dbService.isar;
    
    final ultimaCompra = await isar.compras
        .filter()
        .numeroCompraStartsWith(prefijo)
        .sortByNumeroCompraDesc()
        .findFirst();

    if (ultimaCompra == null) {
      return '$prefijo-0001';
    }

    final partes = ultimaCompra.numeroCompra.split('-');
    final ultimoNumero = int.parse(partes.last);
    final nuevoNumero = ultimoNumero + 1;
    return '$prefijo-${nuevoNumero.toString().padLeft(4, '0')}';
  }

  Future<int> crear(Compra compra, List<DetalleCompra> detalles) async {
    final isar = await _dbService.isar;
    compra.createdAt = DateTime.now();
    compra.updatedAt = DateTime.now();
    compra.sincronizado = false;

    int compraId = 0;

    await isar.writeTxn(() async {
      compraId = await isar.compras.put(compra);
      
      // Guardar detalles
      for (var detalle in detalles) {
        detalle.sincronizado = false;
        await isar.detalleCompras.put(detalle);
      }
    });

    // Si la compra está completada, actualizar inventario
    if (compra.estado == 'completada') {
      for (var detalle in detalles) {
        await _inventarioService.ajustarStock(
          detalle.productoId,
          compra.destinoTipo,
          compra.destinoId,
          detalle.cantidad,
        );
      }
    }

    return compraId;
  }

  Future<void> actualizar(Compra compra) async {
    final isar = await _dbService.isar;
    compra.updatedAt = DateTime.now();
    compra.sincronizado = false;

    await isar.writeTxn(() async {
      await isar.compras.put(compra);
    });
  }

  Future<void> completarCompra(String compraId) async {
    final isar = await _dbService.isar;
    final compra = await isar.compras
        .filter()
        .numeroCompraEqualTo(compraId)
        .findFirst();

    if (compra != null && compra.estado == 'pendiente') {
      compra.estado = 'completada';
      await actualizar(compra);

      // Actualizar inventario
      final detalles = await getDetalles(compraId);
      for (var detalle in detalles) {
        await _inventarioService.ajustarStock(
          detalle.productoId,
          compra.destinoTipo,
          compra.destinoId,
          detalle.cantidad,
        );
      }
    }
  }

  Future<void> anularCompra(String compraId) async {
    final isar = await _dbService.isar;
    final compra = await isar.compras
        .filter()
        .numeroCompraEqualTo(compraId)
        .findFirst();

    if (compra != null) {
      final estadoAnterior = compra.estado;
      compra.estado = 'anulada';
      await actualizar(compra);

      // Si estaba completada, revertir inventario
      if (estadoAnterior == 'completada') {
        final detalles = await getDetalles(compraId);
        for (var detalle in detalles) {
          await _inventarioService.ajustarStock(
            detalle.productoId,
            compra.destinoTipo,
            compra.destinoId,
            -detalle.cantidad,
          );
        }
      }
    }
  }

  Future<List<Compra>> getNoSincronizados() async {
    final isar = await _dbService.isar;
    return await isar.compras.filter().sincronizadoEqualTo(false).findAll();
  }
}






