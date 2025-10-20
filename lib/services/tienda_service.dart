import 'package:isar/isar.dart';
import '../models/tienda.dart';
import 'database_service.dart';

class TiendaService {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Tienda>> getAll({bool incluirEliminados = false}) async {
    final isar = await _dbService.isar;
    if (incluirEliminados) {
      return await isar.tiendas.where().findAll();
    }
    return await isar.tiendas.filter().eliminadoEqualTo(false).findAll();
  }

  Future<List<Tienda>> getActivas() async {
    final isar = await _dbService.isar;
    return await isar.tiendas
        .filter()
        .eliminadoEqualTo(false)
        .activoEqualTo(true)
        .findAll();
  }

  Future<Tienda?> getByCodigo(String codigo) async {
    final isar = await _dbService.isar;
    return await isar.tiendas.filter().codigoEqualTo(codigo).findFirst();
  }

  Future<Tienda?> getById(int id) async {
    final isar = await _dbService.isar;
    return await isar.tiendas.get(id);
  }

  Future<int> crear(Tienda tienda) async {
    final isar = await _dbService.isar;
    tienda.createdAt = DateTime.now();
    tienda.updatedAt = DateTime.now();
    tienda.sincronizado = false;

    return await isar.writeTxn(() async {
      return await isar.tiendas.put(tienda);
    });
  }

  Future<void> actualizar(Tienda tienda) async {
    final isar = await _dbService.isar;
    tienda.updatedAt = DateTime.now();
    tienda.sincronizado = false;

    await isar.writeTxn(() async {
      await isar.tiendas.put(tienda);
    });
  }

  Future<void> eliminar(int id) async {
    final tienda = await getById(id);
    if (tienda != null) {
      tienda.eliminado = true;
      tienda.updatedAt = DateTime.now();
      tienda.sincronizado = false;
      await actualizar(tienda);
    }
  }

  Future<List<Tienda>> getNoSincronizados() async {
    final isar = await _dbService.isar;
    return await isar.tiendas.filter().sincronizadoEqualTo(false).findAll();
  }

  Future<void> marcarSincronizado(int id, String supabaseId) async {
    final isar = await _dbService.isar;
    final tienda = await getById(id);
    if (tienda != null) {
      tienda.sincronizado = true;
      tienda.supabaseId = supabaseId;
      await isar.writeTxn(() async {
        await isar.tiendas.put(tienda);
      });
    }
  }
}