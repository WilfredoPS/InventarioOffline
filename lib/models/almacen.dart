import 'package:isar/isar.dart';

part 'almacen.g.dart';

@collection
class Almacen {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String codigo;
  
  late String nombre;
  late String direccion;
  String? telefono;
  late String responsable;
  late bool activo;
  
  // Para sincronización
  String? supabaseId;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool sincronizado = false;
  bool eliminado = false;
}


