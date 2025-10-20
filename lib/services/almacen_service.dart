import 'package:isar/isar.dart';
import '../models/almacen.dart';
import 'database_service.dart';

class AlmacenService {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Almacen>> getAll({bool incluirEliminados = false}) async {
    print('AlmacenService.getAll: Iniciando consulta de almacenes...');
    final isar = await _dbService.isar;
    List<Almacen> almacenes;
    if (incluirEliminados) {
      almacenes = await isar.almacens.where().findAll();
      print('AlmacenService.getAll: Consultando todos los almacenes (incluyendo eliminados)');
    } else {
      almacenes = await isar.almacens.filter().eliminadoEqualTo(false).findAll();
      print('AlmacenService.getAll: Consultando solo almacenes activos');
    }
    print('AlmacenService.getAll: Encontrados ${almacenes.length} almacenes');
    
    // Si no hay almacenes, crear uno por defecto
    if (almacenes.isEmpty) {
      print('AlmacenService.getAll: No hay almacenes, creando uno por defecto...');
      final almacenDefault = Almacen()
        ..codigo = 'ALM001'
        ..nombre = 'Almacén Principal'
        ..direccion = 'Calle Industrial #456'
        ..telefono = '5557654321'
        ..responsable = 'María González'
        ..activo = true
        ..createdAt = DateTime.now()
        ..updatedAt = DateTime.now();
      
      await isar.writeTxn(() async {
        await isar.almacens.put(almacenDefault);
      });
      
      almacenes = [almacenDefault];
      print('AlmacenService.getAll: Almacén por defecto creado');
    }
    
    for (int i = 0; i < almacenes.length; i++) {
      print('AlmacenService.getAll: [$i] ${almacenes[i].nombre} (${almacenes[i].codigo}) - Activo: ${almacenes[i].activo}');
    }
    return almacenes;
  }

  Future<List<Almacen>> getActivos() async {
    final isar = await _dbService.isar;
    return await isar.almacens
        .filter()
        .eliminadoEqualTo(false)
        .activoEqualTo(true)
        .findAll();
  }

  Future<Almacen?> getByCodigo(String codigo) async {
    final isar = await _dbService.isar;
    return await isar.almacens.filter().codigoEqualTo(codigo).findFirst();
  }

  Future<Almacen?> getById(int id) async {
    final isar = await _dbService.isar;
    return await isar.almacens.get(id);
  }

  Future<int> crear(Almacen almacen) async {
    final isar = await _dbService.isar;
    almacen.createdAt = DateTime.now();
    almacen.updatedAt = DateTime.now();
    almacen.sincronizado = false;

    return await isar.writeTxn(() async {
      return await isar.almacens.put(almacen);
    });
  }

  Future<void> actualizar(Almacen almacen) async {
    final isar = await _dbService.isar;
    almacen.updatedAt = DateTime.now();
    almacen.sincronizado = false;

    await isar.writeTxn(() async {
      await isar.almacens.put(almacen);
    });
  }

  Future<void> eliminar(int id) async {
    final almacen = await getById(id);
    if (almacen != null) {
      almacen.eliminado = true;
      almacen.updatedAt = DateTime.now();
      almacen.sincronizado = false;
      await actualizar(almacen);
    }
  }

  Future<List<Almacen>> getNoSincronizados() async {
    final isar = await _dbService.isar;
    return await isar.almacens.filter().sincronizadoEqualTo(false).findAll();
  }

  Future<void> marcarSincronizado(int id, String supabaseId) async {
    final isar = await _dbService.isar;
    final almacen = await getById(id);
    if (almacen != null) {
      almacen.sincronizado = true;
      almacen.supabaseId = supabaseId;
      await isar.writeTxn(() async {
        await isar.almacens.put(almacen);
      });
    }
  }
}


