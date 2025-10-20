import 'package:isar/isar.dart';
import '../models/empleado.dart';
import 'database_service.dart';

class EmpleadoService {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Empleado>> getAll({bool incluirEliminados = false}) async {
    final isar = await _dbService.isar;
    if (incluirEliminados) {
      return await isar.empleados.where().findAll();
    }
    return await isar.empleados.filter().eliminadoEqualTo(false).findAll();
  }

  Future<List<Empleado>> getActivos() async {
    final isar = await _dbService.isar;
    return await isar.empleados
        .filter()
        .eliminadoEqualTo(false)
        .activoEqualTo(true)
        .findAll();
  }

  Future<Empleado?> getByEmail(String email) async {
    final isar = await _dbService.isar;
    return await isar.empleados.filter().emailEqualTo(email).findFirst();
  }

  Future<Empleado?> getByCodigo(String codigo) async {
    final isar = await _dbService.isar;
    return await isar.empleados.filter().codigoEqualTo(codigo).findFirst();
  }

  Future<Empleado?> getById(int id) async {
    final isar = await _dbService.isar;
    return await isar.empleados.get(id);
  }

  Future<List<Empleado>> getByRol(String rol) async {
    final isar = await _dbService.isar;
    return await isar.empleados
        .filter()
        .eliminadoEqualTo(false)
        .rolEqualTo(rol)
        .findAll();
  }

  Future<List<Empleado>> getByTienda(String tiendaId) async {
    final isar = await _dbService.isar;
    return await isar.empleados
        .filter()
        .eliminadoEqualTo(false)
        .tiendaIdEqualTo(tiendaId)
        .findAll();
  }

  Future<List<Empleado>> getByAlmacen(String almacenId) async {
    final isar = await _dbService.isar;
    return await isar.empleados
        .filter()
        .eliminadoEqualTo(false)
        .almacenIdEqualTo(almacenId)
        .findAll();
  }

  Future<int> crear(Empleado empleado) async {
    final isar = await _dbService.isar;
    empleado.createdAt = DateTime.now();
    empleado.updatedAt = DateTime.now();
    empleado.sincronizado = false;

    return await isar.writeTxn(() async {
      return await isar.empleados.put(empleado);
    });
  }

  Future<void> actualizar(Empleado empleado) async {
    final isar = await _dbService.isar;
    empleado.updatedAt = DateTime.now();
    empleado.sincronizado = false;

    await isar.writeTxn(() async {
      await isar.empleados.put(empleado);
    });
  }

  Future<void> eliminar(int id) async {
    final empleado = await getById(id);
    if (empleado != null) {
      empleado.eliminado = true;
      empleado.updatedAt = DateTime.now();
      empleado.sincronizado = false;
      await actualizar(empleado);
    }
  }

  Future<List<Empleado>> getNoSincronizados() async {
    final isar = await _dbService.isar;
    return await isar.empleados.filter().sincronizadoEqualTo(false).findAll();
  }

  Future<void> marcarSincronizado(int id, String supabaseId) async {
    final isar = await _dbService.isar;
    final empleado = await getById(id);
    if (empleado != null) {
      empleado.sincronizado = true;
      empleado.supabaseId = supabaseId;
      await isar.writeTxn(() async {
        await isar.empleados.put(empleado);
      });
    }
  }
}


