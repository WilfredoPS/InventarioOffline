import '../models/empleado.dart';
import '../models/tienda.dart';
import '../models/almacen.dart';
import '../models/producto.dart';
import 'empleado_service.dart';
import 'tienda_service.dart';
import 'almacen_service.dart';
import 'producto_service.dart';
import 'supabase_service.dart';

class DataInitializer {
  static final DataInitializer _instance = DataInitializer._internal();
  factory DataInitializer() => _instance;
  DataInitializer._internal();

  final EmpleadoService _empleadoService = EmpleadoService();
  final TiendaService _tiendaService = TiendaService();
  final AlmacenService _almacenService = AlmacenService();
  final ProductoService _productoService = ProductoService();
  final SupabaseService _supabaseService = SupabaseService();

  Future<void> initializeData() async {
    try {
      print('Inicializando datos de prueba...');

      // 1. Crear tienda de prueba
      await _createTiendaPrueba();
      
      // 2. Crear almacén de prueba
      await _createAlmacenPrueba();
      
      // 3. Crear empleado admin de prueba
      await _createEmpleadoAdminPrueba();
      
      // 4. Crear productos de prueba
      await _createProductosPrueba();

      // 5. Crear usuario en Supabase (opcional, para testing)
      await _createSupabaseUserIfNeeded();

      print('Datos de prueba inicializados correctamente');
    } catch (e) {
      print('Error inicializando datos: $e');
    }
  }

  Future<void> _createSupabaseUserIfNeeded() async {
    try {
      // Intentar crear usuario admin en Supabase
      await createSupabaseUser('admin@ejemplo.com', 'admin123');
    } catch (e) {
      print('No se pudo crear usuario en Supabase (puede que ya exista): $e');
    }
  }

  Future<void> _createTiendaPrueba() async {
    final tienda = Tienda()
      ..codigo = 'TDA001'
      ..nombre = 'Tienda Central'
      ..direccion = 'Av. Principal #123'
      ..telefono = '5551234567'
      ..responsable = 'Juan Pérez'
      ..activo = true;

    await _tiendaService.crear(tienda);
    print('Tienda creada: ${tienda.nombre}');
  }

  Future<void> _createAlmacenPrueba() async {
    final almacen = Almacen()
      ..codigo = 'ALM001'
      ..nombre = 'Almacén Principal'
      ..direccion = 'Calle Industrial #456'
      ..telefono = '5557654321'
      ..responsable = 'María González'
      ..activo = true;

    await _almacenService.crear(almacen);
    print('Almacén creado: ${almacen.nombre}');
  }

  Future<void> _createEmpleadoAdminPrueba() async {
    final empleado = Empleado()
      ..codigo = 'EMP001'
      ..nombres = 'Admin'
      ..apellidos = 'Sistema'
      ..email = 'admin@ejemplo.com'
      ..telefono = '0000000000'
      ..rol = 'admin'
      ..tiendaId = 'TDA001'
      ..activo = true;

    await _empleadoService.crear(empleado);
    print('Empleado admin creado: ${empleado.email}');
  }

  Future<void> _createProductosPrueba() async {
    final productos = [
      {
        'codigo': 'ALFA001',
        'nombre': 'Alfombra Persa',
        'categoria': 'alfombras',
        'unidad_medida': 'm2',
        'precio_compra': 15.00,
        'precio_venta': 25.00,
        'stock_minimo': 10,
      },
      {
        'codigo': 'PISO001',
        'nombre': 'Piso Flotante Roble',
        'categoria': 'piso flotante',
        'unidad_medida': 'm2',
        'precio_compra': 12.00,
        'precio_venta': 20.00,
        'stock_minimo': 50,
      },
      {
        'codigo': 'PISO002',
        'nombre': 'Pisopak Premium',
        'categoria': 'pisopak',
        'unidad_medida': 'caja',
        'precio_compra': 30.00,
        'precio_venta': 45.00,
        'stock_minimo': 20,
      },
      {
        'codigo': 'CIEL001',
        'nombre': 'Cielo Falso Blanco',
        'categoria': 'cielo falso',
        'unidad_medida': 'm2',
        'precio_compra': 8.00,
        'precio_venta': 15.00,
        'stock_minimo': 30,
      },
      {
        'codigo': 'VINI001',
        'nombre': 'Viniles Decorativos',
        'categoria': 'viniles',
        'unidad_medida': 'rollo',
        'precio_compra': 20.00,
        'precio_venta': 35.00,
        'stock_minimo': 15,
      },
    ];

    for (var data in productos) {
      final producto = Producto()
        ..codigo = data['codigo'] as String
        ..nombre = data['nombre'] as String
        ..categoria = data['categoria'] as String
        ..unidadMedida = data['unidad_medida'] as String
        ..precioCompra = data['precio_compra'] as double
        ..precioVenta = data['precio_venta'] as double
        ..stockMinimo = data['stock_minimo'] as int;

      await _productoService.crear(producto);
    }
    print('Productos de prueba creados: ${productos.length}');
  }

  Future<void> createSupabaseUser(String email, String password) async {
    try {
      final response = await _supabaseService.signUp(email, password);
      if (response.user != null) {
        print('Usuario creado en Supabase: $email');
        
        // Actualizar el empleado con el ID de Supabase
        final empleado = await _empleadoService.getByEmail(email);
        if (empleado != null) {
          empleado.supabaseUserId = response.user!.id;
          await _empleadoService.actualizar(empleado);
          print('Empleado actualizado con ID de Supabase');
        }
      }
    } catch (e) {
      print('Error creando usuario en Supabase: $e');
    }
  }
}
