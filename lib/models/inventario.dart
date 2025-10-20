import 'package:isar/isar.dart';

part 'inventario.g.dart';

@collection
class Inventario {
  Id id = Isar.autoIncrement;
  
  @Index(composite: [CompositeIndex('ubicacionTipo'), CompositeIndex('ubicacionId')])
  late String productoId;
  
  late String ubicacionTipo; // tienda, almacen
  late String ubicacionId; // ID de la tienda o almacén
  
  late double cantidad;
  late DateTime ultimaActualizacion;
  
  // Para sincronización
  String? supabaseId;
  bool sincronizado = false;
}

