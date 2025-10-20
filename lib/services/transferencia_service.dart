import 'package:isar/isar.dart';
import '../models/transferencia.dart';
import 'database_service.dart';
import 'inventario_service.dart';

class TransferenciaService {
  final DatabaseService _dbService = DatabaseService();
  final InventarioService _inventarioService = InventarioService();

  Future<List<Transferencia>> getAll({bool incluirEliminados = false}) async {
    final isar = await _dbService.isar;
    if (incluirEliminados) {
      return await isar.transferencias.where().sortByFechaTransferenciaDesc().findAll();
    }
    return await isar.transferencias
        .filter()
        .eliminadoEqualTo(false)
        .sortByFechaTransferenciaDesc()
        .findAll();
  }

  Future<Transferencia?> getByNumero(String numeroTransferencia) async {
    final isar = await _dbService.isar;
    return await isar.transferencias
        .filter()
        .numeroTransferenciaEqualTo(numeroTransferencia)
        .findFirst();
  }

  Future<Transferencia?> getById(int id) async {
    final isar = await _dbService.isar;
    return await isar.transferencias.get(id);
  }

  Future<List<DetalleTransferencia>> getDetalles(String transferenciaId) async {
    final isar = await _dbService.isar;
    return await isar.detalleTransferencias
        .filter()
        .transferenciaIdEqualTo(transferenciaId)
        .findAll();
  }

  Future<List<Transferencia>> getByFechas(DateTime inicio, DateTime fin) async {
    final isar = await _dbService.isar;
    return await isar.transferencias
        .filter()
        .eliminadoEqualTo(false)
        .fechaTransferenciaBetween(inicio, fin)
        .sortByFechaTransferenciaDesc()
        .findAll();
  }

  Future<List<Transferencia>> getByOrigen(String origenTipo, String origenId) async {
    final isar = await _dbService.isar;
    return await isar.transferencias
        .filter()
        .eliminadoEqualTo(false)
        .origenTipoEqualTo(origenTipo)
        .origenIdEqualTo(origenId)
        .sortByFechaTransferenciaDesc()
        .findAll();
  }

  Future<List<Transferencia>> getByDestino(String destinoTipo, String destinoId) async {
    final isar = await _dbService.isar;
    return await isar.transferencias
        .filter()
        .eliminadoEqualTo(false)
        .destinoTipoEqualTo(destinoTipo)
        .destinoIdEqualTo(destinoId)
        .sortByFechaTransferenciaDesc()
        .findAll();
  }

  Future<String> generarNumeroTransferencia() async {
    final ahora = DateTime.now();
    final prefijo = 'TRF-${ahora.year}${ahora.month.toString().padLeft(2, '0')}';
    final isar = await _dbService.isar;
    
    final ultimaTransferencia = await isar.transferencias
        .filter()
        .numeroTransferenciaStartsWith(prefijo)
        .sortByNumeroTransferenciaDesc()
        .findFirst();

    if (ultimaTransferencia == null) {
      return '$prefijo-0001';
    }

    final partes = ultimaTransferencia.numeroTransferencia.split('-');
    final ultimoNumero = int.parse(partes.last);
    final nuevoNumero = ultimoNumero + 1;
    return '$prefijo-${nuevoNumero.toString().padLeft(4, '0')}';
  }

  Future<int> crear(Transferencia transferencia, List<DetalleTransferencia> detalles) async {
    final isar = await _dbService.isar;
    transferencia.createdAt = DateTime.now();
    transferencia.updatedAt = DateTime.now();
    transferencia.sincronizado = false;

    int transferenciaId = 0;

    await isar.writeTxn(() async {
      transferenciaId = await isar.transferencias.put(transferencia);
      
      // Guardar detalles
      for (var detalle in detalles) {
        detalle.transferenciaId = transferencia.numeroTransferencia;
        detalle.sincronizado = false;
        await isar.detalleTransferencias.put(detalle);
      }
    });

    return transferenciaId;
  }


  Future<void> actualizar(Transferencia transferencia) async {
    final isar = await _dbService.isar;
    transferencia.updatedAt = DateTime.now();
    transferencia.sincronizado = false;

    await isar.writeTxn(() async {
      await isar.transferencias.put(transferencia);
    });
  }

  Future<void> enviarTransferencia(String transferenciaId) async {
    final isar = await _dbService.isar;
    final transferencia = await isar.transferencias
        .filter()
        .numeroTransferenciaEqualTo(transferenciaId)
        .findFirst();

    if (transferencia != null && transferencia.estado == 'pendiente') {
      transferencia.estado = 'en_transito';
      await actualizar(transferencia);

      // Descontar del origen
      final detalles = await getDetalles(transferenciaId);
      for (var detalle in detalles) {
        await _inventarioService.ajustarStock(
          detalle.productoId,
          transferencia.origenTipo,
          transferencia.origenId,
          -detalle.cantidadEnviada,
        );
      }
    }
  }

  Future<void> recibirTransferencia(
      String transferenciaId, String empleadoRecepcionId) async {
    final isar = await _dbService.isar;
    final transferencia = await isar.transferencias
        .filter()
        .numeroTransferenciaEqualTo(transferenciaId)
        .findFirst();

    if (transferencia != null && transferencia.estado == 'en_transito') {
      transferencia.estado = 'recibida';
      transferencia.fechaRecepcion = DateTime.now();
      transferencia.empleadoRecepcionId = empleadoRecepcionId;
      await actualizar(transferencia);

      // Agregar al destino
      final detalles = await getDetalles(transferenciaId);
      for (var detalle in detalles) {
        await _inventarioService.ajustarStock(
          detalle.productoId,
          transferencia.destinoTipo,
          transferencia.destinoId,
          detalle.cantidadRecibida,
        );
      }
    }
  }

  Future<void> completarTransferencia(int transferenciaId) async {
    final isar = await _dbService.isar;
    final transferencia = await isar.transferencias.get(transferenciaId);

    if (transferencia != null && transferencia.estado == 'pendiente') {
      transferencia.estado = 'completada';
      transferencia.fechaRecepcion = DateTime.now();
      await actualizar(transferencia);

      // Obtener detalles de la transferencia
      final detalles = await getDetalles(transferencia.numeroTransferencia);
      
      // Descontar del origen y agregar al destino
      for (var detalle in detalles) {
        // Descontar del origen
        await _inventarioService.ajustarStock(
          detalle.productoId,
          transferencia.origenTipo,
          transferencia.origenId,
          -detalle.cantidadEnviada,
        );
        
        // Agregar al destino
        await _inventarioService.ajustarStock(
          detalle.productoId,
          transferencia.destinoTipo,
          transferencia.destinoId,
          detalle.cantidadRecibida,
        );
      }
    }
  }

  Future<void> anularTransferencia(int transferenciaId) async {
    final isar = await _dbService.isar;
    final transferencia = await isar.transferencias.get(transferenciaId);

    if (transferencia != null) {
      final estadoAnterior = transferencia.estado;
      transferencia.estado = 'anulada';
      await actualizar(transferencia);

      // Si estaba completada, devolver al origen
      if (estadoAnterior == 'completada') {
        final detalles = await getDetalles(transferencia.numeroTransferencia);
        for (var detalle in detalles) {
          // Devolver al origen
          await _inventarioService.ajustarStock(
            detalle.productoId,
            transferencia.origenTipo,
            transferencia.origenId,
            detalle.cantidadEnviada,
          );
          
          // Descontar del destino
          await _inventarioService.ajustarStock(
            detalle.productoId,
            transferencia.destinoTipo,
            transferencia.destinoId,
            -detalle.cantidadRecibida,
          );
        }
      }
    }
  }

  Future<void> anularTransferenciaPorNumero(String transferenciaId) async {
    final isar = await _dbService.isar;
    final transferencia = await isar.transferencias
        .filter()
        .numeroTransferenciaEqualTo(transferenciaId)
        .findFirst();

    if (transferencia != null) {
      final estadoAnterior = transferencia.estado;
      transferencia.estado = 'anulada';
      await actualizar(transferencia);

      // Si estaba en tránsito, devolver al origen
      if (estadoAnterior == 'en_transito') {
        final detalles = await getDetalles(transferenciaId);
        for (var detalle in detalles) {
          await _inventarioService.ajustarStock(
            detalle.productoId,
            transferencia.origenTipo,
            transferencia.origenId,
            detalle.cantidadEnviada,
          );
        }
      }
    }
  }

  Future<List<Transferencia>> getNoSincronizados() async {
    final isar = await _dbService.isar;
    return await isar.transferencias.filter().sincronizadoEqualTo(false).findAll();
  }
}





