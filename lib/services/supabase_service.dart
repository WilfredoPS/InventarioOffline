import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseService {
  static final SupabaseService _instance = SupabaseService._internal();
  factory SupabaseService() => _instance;
  SupabaseService._internal();

  SupabaseClient? _client;

  Future<void> initialize(String url, String anonKey) async {
    await Supabase.initialize(
      url: url,
      anonKey: anonKey,
    );
    _client = Supabase.instance.client;
  }

  SupabaseClient get client {
    if (_client == null) {
      throw Exception('Supabase no ha sido inicializado');
    }
    return _client!;
  }

  bool get isAuthenticated => _client?.auth.currentUser != null;

  User? get currentUser => _client?.auth.currentUser;

  // Autenticación
  Future<AuthResponse> signIn(String email, String password) async {
    return await client.auth.signInWithPassword(
      email: email,
      password: password,
    );
  }

  Future<AuthResponse> signUp(String email, String password) async {
    return await client.auth.signUp(
      email: email,
      password: password,
    );
  }

  Future<void> signOut() async {
    await client.auth.signOut();
  }

  // Productos
  Future<List<Map<String, dynamic>>> getProductos() async {
    final response = await client
        .from('productos')
        .select()
        .eq('eliminado', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createProducto(Map<String, dynamic> data) async {
    final response = await client
        .from('productos')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateProducto(String id, Map<String, dynamic> data) async {
    await client
        .from('productos')
        .update(data)
        .eq('id', id);
  }

  // Almacenes
  Future<List<Map<String, dynamic>>> getAlmacenes() async {
    final response = await client
        .from('almacenes')
        .select()
        .eq('eliminado', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createAlmacen(Map<String, dynamic> data) async {
    final response = await client
        .from('almacenes')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateAlmacen(String id, Map<String, dynamic> data) async {
    await client
        .from('almacenes')
        .update(data)
        .eq('id', id);
  }

  // Tiendas
  Future<List<Map<String, dynamic>>> getTiendas() async {
    final response = await client
        .from('tiendas')
        .select()
        .eq('eliminado', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createTienda(Map<String, dynamic> data) async {
    final response = await client
        .from('tiendas')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateTienda(String id, Map<String, dynamic> data) async {
    await client
        .from('tiendas')
        .update(data)
        .eq('id', id);
  }

  // Empleados
  Future<List<Map<String, dynamic>>> getEmpleados() async {
    final response = await client
        .from('empleados')
        .select()
        .eq('eliminado', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createEmpleado(Map<String, dynamic> data) async {
    final response = await client
        .from('empleados')
        .insert(data)
        .select()
        .single();
    return response;
  }

  Future<void> updateEmpleado(String id, Map<String, dynamic> data) async {
    await client
        .from('empleados')
        .update(data)
        .eq('id', id);
  }

  // Inventarios
  Future<List<Map<String, dynamic>>> getInventarios() async {
    final response = await client
        .from('inventarios')
        .select();
    return List<Map<String, dynamic>>.from(response);
  }

  Future<void> updateInventario(String id, Map<String, dynamic> data) async {
    await client
        .from('inventarios')
        .upsert(data);
  }

  // Compras
  Future<List<Map<String, dynamic>>> getCompras() async {
    final response = await client
        .from('compras')
        .select('*, detalle_compras(*)')
        .eq('eliminado', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createCompra(
      Map<String, dynamic> compra,
      List<Map<String, dynamic>> detalles) async {
    final response = await client
        .from('compras')
        .insert(compra)
        .select()
        .single();
    
    for (var detalle in detalles) {
      detalle['compra_id'] = response['id'];
    }
    
    await client.from('detalle_compras').insert(detalles);
    
    return response;
  }

  // Ventas
  Future<List<Map<String, dynamic>>> getVentas() async {
    final response = await client
        .from('ventas')
        .select('*, detalle_ventas(*)')
        .eq('eliminado', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createVenta(
      Map<String, dynamic> venta,
      List<Map<String, dynamic>> detalles) async {
    final response = await client
        .from('ventas')
        .insert(venta)
        .select()
        .single();
    
    for (var detalle in detalles) {
      detalle['venta_id'] = response['id'];
    }
    
    await client.from('detalle_ventas').insert(detalles);
    
    return response;
  }

  // Transferencias
  Future<List<Map<String, dynamic>>> getTransferencias() async {
    final response = await client
        .from('transferencias')
        .select('*, detalle_transferencias(*)')
        .eq('eliminado', false);
    return List<Map<String, dynamic>>.from(response);
  }

  Future<Map<String, dynamic>> createTransferencia(
      Map<String, dynamic> transferencia,
      List<Map<String, dynamic>> detalles) async {
    final response = await client
        .from('transferencias')
        .insert(transferencia)
        .select()
        .single();
    
    for (var detalle in detalles) {
      detalle['transferencia_id'] = response['id'];
    }
    
    await client.from('detalle_transferencias').insert(detalles);
    
    return response;
  }
}






