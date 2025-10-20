import 'package:isar/isar.dart';
import '../models/producto.dart';
import 'database_service.dart';

class ProductoService {
  final DatabaseService _dbService = DatabaseService();

  Future<List<Producto>> getAll({bool incluirEliminados = false}) async {
    final isar = await _dbService.isar;
    List<Producto> productos;
    
    if (incluirEliminados) {
      productos = await isar.productos.where().findAll();
    } else {
      productos = await isar.productos.filter().eliminadoEqualTo(false).findAll();
    }
    
    print('ProductoService.getAll() - Encontrados ${productos.length} productos');
    for (var producto in productos) {
      print('Producto: ${producto.nombre} - imagenPath: ${producto.imagenPath}');
    }
    
    return productos;
  }

  Future<Producto?> getByCodigo(String codigo) async {
    final isar = await _dbService.isar;
    return await isar.productos.filter().codigoEqualTo(codigo).findFirst();
  }

  Future<Producto?> getById(int id) async {
    final isar = await _dbService.isar;
    return await isar.productos.get(id);
  }

  Future<List<Producto>> buscar(String query) async {
    final isar = await _dbService.isar;
    return await isar.productos
        .filter()
        .eliminadoEqualTo(false)
        .group((q) => q
            .nombreContains(query, caseSensitive: false)
            .or()
            .codigoContains(query, caseSensitive: false))
        .findAll();
  }

  Future<List<Producto>> getByCategoria(String categoria) async {
    final isar = await _dbService.isar;
    return await isar.productos
        .filter()
        .eliminadoEqualTo(false)
        .categoriaEqualTo(categoria)
        .findAll();
  }

  Future<int> crear(Producto producto) async {
    final isar = await _dbService.isar;
    producto.createdAt = DateTime.now();
    producto.updatedAt = DateTime.now();
    producto.sincronizado = false;

    return await isar.writeTxn(() async {
      return await isar.productos.put(producto);
    });
  }

  Future<void> actualizar(Producto producto) async {
    final isar = await _dbService.isar;
    producto.updatedAt = DateTime.now();
    producto.sincronizado = false;

    print('ProductoService.actualizar() - Actualizando producto: ${producto.nombre}');
    print('ProductoService.actualizar() - imagenPath: ${producto.imagenPath}');

    await isar.writeTxn(() async {
      await isar.productos.put(producto);
    });
    
    print('ProductoService.actualizar() - Producto actualizado exitosamente');
  }

  Future<void> eliminar(int id) async {
    final producto = await getById(id);
    if (producto != null) {
      producto.eliminado = true;
      producto.updatedAt = DateTime.now();
      producto.sincronizado = false;
      await actualizar(producto);
    }
  }

  Future<List<Producto>> getNoSincronizados() async {
    final isar = await _dbService.isar;
    return await isar.productos.filter().sincronizadoEqualTo(false).findAll();
  }

  Future<void> marcarSincronizado(int id, String supabaseId) async {
    final isar = await _dbService.isar;
    final producto = await getById(id);
    if (producto != null) {
      producto.sincronizado = true;
      producto.supabaseId = supabaseId;
      await isar.writeTxn(() async {
        await isar.productos.put(producto);
      });
    }
  }
}