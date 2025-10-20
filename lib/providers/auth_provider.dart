import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../services/auth_service.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();

  Empleado? get currentEmpleado => _authService.currentEmpleado;
  bool get isAuthenticated => _authService.isAuthenticated;
  String? get tiendaActual => _authService.tiendaActual;
  String? get almacenActual => _authService.almacenActual;

  Future<void> initialize() async {
    print('AuthProvider.initialize: Iniciando autenticación...');
    await _authService.initialize();
    print('AuthProvider.initialize: Empleado actual: ${_authService.currentEmpleado?.nombres} ${_authService.currentEmpleado?.apellidos}');
    print('AuthProvider.initialize: Rol: ${_authService.currentEmpleado?.rol}');
    print('AuthProvider.initialize: Autenticado: ${_authService.isAuthenticated}');
    notifyListeners();
  }

  Future<bool> login(String email, String password) async {
    try {
      final result = await _authService.login(email, password);
      notifyListeners();
      return result;
    } catch (e) {
      rethrow;
    }
  }

  Future<void> logout() async {
    await _authService.logout();
    notifyListeners();
  }

  bool hasPermission(String permission) {
    return _authService.hasPermission(permission);
  }
}





