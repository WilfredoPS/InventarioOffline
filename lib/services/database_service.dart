import 'package:isar/isar.dart';
import 'package:path_provider/path_provider.dart';
import '../models/producto.dart';
import '../models/almacen.dart';
import '../models/tienda.dart';
import '../models/empleado.dart';
import '../models/inventario.dart';
import '../models/compra.dart';
import '../models/venta.dart';
import '../models/transferencia.dart';

class DatabaseService {
  static final DatabaseService _instance = DatabaseService._internal();
  factory DatabaseService() => _instance;
  DatabaseService._internal();

  Isar? _isar;

  Future<Isar> get isar async {
    if (_isar != null) return _isar!;
    _isar = await _initIsar();
    return _isar!;
  }

  Future<Isar> _initIsar() async {
    final dir = await getApplicationDocumentsDirectory();
    return await Isar.open(
      [
        ProductoSchema,
        AlmacenSchema,
        TiendaSchema,
        EmpleadoSchema,
        InventarioSchema,
        CompraSchema,
        DetalleCompraSchema,
        VentaSchema,
        DetalleVentaSchema,
        TransferenciaSchema,
        DetalleTransferenciaSchema,
      ],
      directory: dir.path,
    );
  }

  Future<void> close() async {
    await _isar?.close();
    _isar = null;
  }
}