import 'package:isar/isar.dart';

part 'tienda.g.dart';

@collection
class Tienda {
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


