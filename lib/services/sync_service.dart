import 'package:connectivity_plus/connectivity_plus.dart';
import 'supabase_service.dart';
import 'producto_service.dart';
import 'almacen_service.dart';
import 'tienda_service.dart';
import 'empleado_service.dart';
import 'inventario_service.dart';
import 'compra_service.dart';
import 'venta_service.dart';
import 'transferencia_service.dart';

class SyncService {
  static final SyncService _instance = SyncService._internal();
  factory SyncService() => _instance;
  SyncService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final ProductoService _productoService = ProductoService();
  final AlmacenService _almacenService = AlmacenService();
  final TiendaService _tiendaService = TiendaService();
  final EmpleadoService _empleadoService = EmpleadoService();
  final InventarioService _inventarioService = InventarioService();
  final CompraService _compraService = CompraService();
  final VentaService _ventaService = VentaService();
  final TransferenciaService _transferenciaService = TransferenciaService();

  bool _isSyncing = false;
  DateTime? _lastSyncTime;

  bool get isSyncing => _isSyncing;
  DateTime? get lastSyncTime => _lastSyncTime;

  Future<bool> checkConnectivity() async {
    final connectivityResult = await Connectivity().checkConnectivity();
    return connectivityResult != ConnectivityResult.none;
  }

  Future<void> syncAll() async {
    if (_isSyncing) return;

    final hasConnection = await checkConnectivity();
    if (!hasConnection) {
      throw Exception('Sin conexión a internet');
    }

    _isSyncing = true;

    try {
      // Sincronizar en orden: datos maestros primero, luego transacciones
      await _syncProductos();
      await _syncAlmacenes();
      await _syncTiendas();
      await _syncEmpleados();
      await _syncInventarios();
      await _syncCompras();
      await _syncVentas();
      await _syncTransferencias();

      // Luego descargar cambios desde Supabase
      await _downloadFromSupabase();

      _lastSyncTime = DateTime.now();
    } finally {
      _isSyncing = false;
    }
  }

  Future<void> _syncProductos() async {
    final noSincronizados = await _productoService.getNoSincronizados();
    
    for (var producto in noSincronizados) {
      try {
        final data = {
          'codigo': producto.codigo,
          'nombre': producto.nombre,
          'descripcion': producto.descripcion,
          'categoria': producto.categoria,
          'unidad_medida': producto.unidadMedida,
          'precio_compra': producto.precioCompra,
          'precio_venta': producto.precioVenta,
          'stock_minimo': producto.stockMinimo,
          'eliminado': producto.eliminado,
          'updated_at': producto.updatedAt.toIso8601String(),
        };

        if (producto.supabaseId == null) {
          final response = await _supabaseService.createProducto(data);
          await _productoService.marcarSincronizado(producto.id, response['id']);
        } else {
          await _supabaseService.updateProducto(producto.supabaseId!, data);
          await _productoService.marcarSincronizado(producto.id, producto.supabaseId!);
        }
      } catch (e) {
        print('Error sincronizando producto ${producto.codigo}: $e');
      }
    }
  }

  Future<void> _syncAlmacenes() async {
    final noSincronizados = await _almacenService.getNoSincronizados();
    
    for (var almacen in noSincronizados) {
      try {
        final data = {
          'codigo': almacen.codigo,
          'nombre': almacen.nombre,
          'direccion': almacen.direccion,
          'telefono': almacen.telefono,
          'responsable': almacen.responsable,
          'activo': almacen.activo,
          'eliminado': almacen.eliminado,
          'updated_at': almacen.updatedAt.toIso8601String(),
        };

        if (almacen.supabaseId == null) {
          final response = await _supabaseService.createAlmacen(data);
          await _almacenService.marcarSincronizado(almacen.id, response['id']);
        } else {
          await _supabaseService.updateAlmacen(almacen.supabaseId!, data);
          await _almacenService.marcarSincronizado(almacen.id, almacen.supabaseId!);
        }
      } catch (e) {
        print('Error sincronizando almacén ${almacen.codigo}: $e');
      }
    }
  }

  Future<void> _syncTiendas() async {
    final noSincronizados = await _tiendaService.getNoSincronizados();
    
    for (var tienda in noSincronizados) {
      try {
        final data = {
          'codigo': tienda.codigo,
          'nombre': tienda.nombre,
          'direccion': tienda.direccion,
          'telefono': tienda.telefono,
          'responsable': tienda.responsable,
          'activo': tienda.activo,
          'eliminado': tienda.eliminado,
          'updated_at': tienda.updatedAt.toIso8601String(),
        };

        if (tienda.supabaseId == null) {
          final response = await _supabaseService.createTienda(data);
          await _tiendaService.marcarSincronizado(tienda.id, response['id']);
        } else {
          await _supabaseService.updateTienda(tienda.supabaseId!, data);
          await _tiendaService.marcarSincronizado(tienda.id, tienda.supabaseId!);
        }
      } catch (e) {
        print('Error sincronizando tienda ${tienda.codigo}: $e');
      }
    }
  }

  Future<void> _syncEmpleados() async {
    final noSincronizados = await _empleadoService.getNoSincronizados();
    
    for (var empleado in noSincronizados) {
      try {
        final data = {
          'codigo': empleado.codigo,
          'nombres': empleado.nombres,
          'apellidos': empleado.apellidos,
          'email': empleado.email,
          'telefono': empleado.telefono,
          'rol': empleado.rol,
          'tienda_id': empleado.tiendaId,
          'almacen_id': empleado.almacenId,
          'activo': empleado.activo,
          'supabase_user_id': empleado.supabaseUserId,
          'eliminado': empleado.eliminado,
          'updated_at': empleado.updatedAt.toIso8601String(),
        };

        if (empleado.supabaseId == null) {
          final response = await _supabaseService.createEmpleado(data);
          await _empleadoService.marcarSincronizado(empleado.id, response['id']);
        } else {
          await _supabaseService.updateEmpleado(empleado.supabaseId!, data);
          await _empleadoService.marcarSincronizado(empleado.id, empleado.supabaseId!);
        }
      } catch (e) {
        print('Error sincronizando empleado ${empleado.codigo}: $e');
      }
    }
  }

  Future<void> _syncInventarios() async {
    final noSincronizados = await _inventarioService.getNoSincronizados();
    
    for (var inventario in noSincronizados) {
      try {
        final data = {
          'producto_id': inventario.productoId,
          'ubicacion_tipo': inventario.ubicacionTipo,
          'ubicacion_id': inventario.ubicacionId,
          'cantidad': inventario.cantidad,
          'ultima_actualizacion': inventario.ultimaActualizacion.toIso8601String(),
        };

        if (inventario.supabaseId != null) {
          data['id'] = inventario.supabaseId!;
        }

        await _supabaseService.updateInventario(
          inventario.supabaseId ?? '',
          data,
        );
        
        final idSync = inventario.supabaseId ?? (data['id'] as String?) ?? '';
        await _inventarioService.marcarSincronizado(
          inventario.id,
          idSync,
        );
      } catch (e) {
        print('Error sincronizando inventario: $e');
      }
    }
  }

  Future<void> _syncCompras() async {
    final noSincronizados = await _compraService.getNoSincronizados();
    
    for (var compra in noSincronizados) {
      try {
        // TODO: Implementar sincronización de compras con detalles
        print('Sincronizando compra ${compra.numeroCompra}');
      } catch (e) {
        print('Error sincronizando compra ${compra.numeroCompra}: $e');
      }
    }
  }

  Future<void> _syncVentas() async {
    final noSincronizados = await _ventaService.getNoSincronizados();
    
    for (var venta in noSincronizados) {
      try {
        // TODO: Implementar sincronización de ventas con detalles
        print('Sincronizando venta ${venta.numeroVenta}');
      } catch (e) {
        print('Error sincronizando venta ${venta.numeroVenta}: $e');
      }
    }
  }

  Future<void> _syncTransferencias() async {
    final noSincronizados = await _transferenciaService.getNoSincronizados();
    
    for (var transferencia in noSincronizados) {
      try {
        // TODO: Implementar sincronización de transferencias con detalles
        print('Sincronizando transferencia ${transferencia.numeroTransferencia}');
      } catch (e) {
        print('Error sincronizando transferencia ${transferencia.numeroTransferencia}: $e');
      }
    }
  }

  Future<void> _downloadFromSupabase() async {
    // Descargar datos actualizados desde Supabase
    // TODO: Implementar descarga inteligente solo de datos modificados
    // usando timestamps para evitar sobrescribir cambios locales
  }
}

