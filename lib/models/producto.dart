import 'package:isar/isar.dart';

part 'producto.g.dart';

@collection
class Producto {
  Id id = Isar.autoIncrement;
  
  @Index(unique: true)
  late String codigo;
  
  late String nombre;
  String? descripcion;
  late String categoria; // alfombras, piso flotante, pisopak, cielo falso, viniles
  late String unidadMedida; // m2, rollo, caja, pieza
  late double precioCompra;
  late double precioVenta;
  int stockMinimo = 0;
  
  // Imagen del producto
  String? imagenPath; // Ruta local de la imagen
  String? imagenUrl; // URL de la imagen en Supabase (para sincronización)
  
  // Para sincronización
  String? supabaseId;
  late DateTime createdAt;
  late DateTime updatedAt;
  bool sincronizado = false;
  bool eliminado = false;
}


