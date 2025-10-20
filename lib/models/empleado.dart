import 'package:isar/isar.dart';

part 'empleado.g.dart';

@collection
class Empleado {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String codigo;
  
  late String nombres;
  late String apellidos;
  
  @Index(unique: true)
  late String email;
  
  late String telefono;
  late String rol; // admin, encargado_tienda, encargado_almacen, vendedor
  
  // Referencias
  String? tiendaId; // Si es encargado de tienda o vendedor
  String? almacenId; // Si es encargado de almacén
  
  late bool activo;
  
  // Para autenticación
  String? supabaseUserId;
  
  // Para sincronización
  String? supabaseId;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool sincronizado = false;
  bool eliminado = false;
}


