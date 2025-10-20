import 'package:shared_preferences/shared_preferences.dart';
import '../models/empleado.dart';
import 'supabase_service.dart';
import 'empleado_service.dart';

class AuthService {
  static final AuthService _instance = AuthService._internal();
  factory AuthService() => _instance;
  AuthService._internal();

  final SupabaseService _supabaseService = SupabaseService();
  final EmpleadoService _empleadoService = EmpleadoService();

  Empleado? _currentEmpleado;
  
  Empleado? get currentEmpleado => _currentEmpleado;
  bool get isAuthenticated => _currentEmpleado != null;

  Future<void> initialize() async {
    print('AuthService.initialize: Iniciando servicio de autenticación...');
    
    // Intentar restaurar sesión guardada
    final prefs = await SharedPreferences.getInstance();
    final empleadoEmail = prefs.getString('empleado_email');
    
    print('AuthService.initialize: Email guardado: $empleadoEmail');
    
    if (empleadoEmail != null) {
      // Para modo desarrollo, restaurar sesión sin verificar Supabase
      _currentEmpleado = await _empleadoService.getByEmail(empleadoEmail);
      print('AuthService.initialize: Empleado encontrado: ${_currentEmpleado?.nombres} ${_currentEmpleado?.apellidos}');
      print('AuthService.initialize: Rol del empleado: ${_currentEmpleado?.rol}');
      
      // En producción, descomentar esta línea:
      // if (_supabaseService.isAuthenticated) {
      //   _currentEmpleado = await _empleadoService.getByEmail(empleadoEmail);
      // }
    } else {
      print('AuthService.initialize: No hay sesión guardada, usuario debe hacer login manual');
      _currentEmpleado = null;
    }
  }

  Future<bool> login(String email, String password) async {
    try {
      // Buscar empleado en la base de datos local primero
      final empleado = await _empleadoService.getByEmail(email);
      
      if (empleado == null) {
        throw Exception('Empleado no encontrado en el sistema local');
      }

      if (!empleado.activo) {
        throw Exception('Empleado desactivado');
      }

      // Para modo de desarrollo/testing, permitir login sin Supabase
      // En producción, descomentar las líneas de Supabase abajo
      
      /*
      // Intentar autenticar con Supabase
      final response = await _supabaseService.signIn(email, password);
      
      if (response.user != null) {
        // Usuario autenticado en Supabase
      } else {
        throw Exception('Credenciales inválidas en Supabase');
      }
      */

      _currentEmpleado = empleado;

      // Guardar sesión
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('empleado_email', email);

      return true;
    } catch (e) {
      print('Error en login: $e');
      rethrow;
    }
  }

  Future<void> logout() async {
    try {
      await _supabaseService.signOut();
    } catch (e) {
      print('Error al cerrar sesión en Supabase: $e');
    }

    _currentEmpleado = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('empleado_email');
  }

  bool hasPermission(String permission) {
    if (_currentEmpleado == null) {
      print('AuthService.hasPermission: No hay empleado autenticado');
      return false;
    }

    print('AuthService.hasPermission: Verificando permiso "$permission" para rol "${_currentEmpleado!.rol}"');

    // Definir permisos por rol
    final permisos = {
      'admin': [
        'ver_dashboard',
        'gestionar_productos',
        'gestionar_almacenes',
        'gestionar_tiendas',
        'gestionar_empleados',
        'realizar_compras',
        'realizar_ventas',
        'realizar_transferencias',
        'ver_reportes',
        'ver_inventario_global',
      ],
      'encargado_tienda': [
        'ver_dashboard',
        'gestionar_tiendas',
        'realizar_ventas',
        'solicitar_transferencias',
        'ver_inventario_tienda',
        'ver_reportes_tienda',
      ],
      'encargado_almacen': [
        'ver_dashboard',
        'gestionar_almacenes',
        'realizar_compras',
        'gestionar_transferencias',
        'ver_inventario_almacen',
        'ver_reportes_almacen',
      ],
      'vendedor': [
        'realizar_ventas',
        'ver_inventario_tienda',
      ],
    };

    final permisosRol = permisos[_currentEmpleado!.rol] ?? [];
    final tienePermiso = permisosRol.contains(permission);
    print('AuthService.hasPermission: Permisos del rol: $permisosRol');
    print('AuthService.hasPermission: Tiene permiso "$permission": $tienePermiso');
    return tienePermiso;
  }

  String? get tiendaActual => _currentEmpleado?.tiendaId;
  String? get almacenActual => _currentEmpleado?.almacenId;
}




