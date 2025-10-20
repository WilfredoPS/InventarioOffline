import 'dart:io';
import 'package:image_picker/image_picker.dart';
import 'package:path_provider/path_provider.dart';
import 'package:path/path.dart' as path;

class ImageService {
  static final ImageService _instance = ImageService._internal();
  factory ImageService() => _instance;
  ImageService._internal();

  final ImagePicker _picker = ImagePicker();

  /// Seleccionar imagen desde galería
  Future<String?> pickImageFromGallery() async {
    try {
      print('Abriendo selector de galería...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      print('Imagen seleccionada de galería: ${image?.path}');
      
      if (image != null) {
        print('Guardando imagen en directorio local...');
        final String savedPath = await _saveImageToLocal(image.path);
        print('Imagen guardada en: $savedPath');
        return savedPath;
      }
      print('No se seleccionó imagen de galería');
      return null;
    } catch (e) {
      print('Error seleccionando imagen de galería: $e');
      return null;
    }
  }

  /// Capturar imagen desde cámara
  Future<String?> pickImageFromCamera() async {
    try {
      print('Abriendo cámara...');
      final XFile? image = await _picker.pickImage(
        source: ImageSource.camera,
        maxWidth: 1024,
        maxHeight: 1024,
        imageQuality: 85,
      );
      
      print('Imagen capturada: ${image?.path}');
      
      if (image != null) {
        print('Guardando imagen en directorio local...');
        final String savedPath = await _saveImageToLocal(image.path);
        print('Imagen guardada en: $savedPath');
        return savedPath;
      }
      print('No se capturó imagen');
      return null;
    } catch (e) {
      print('Error capturando imagen: $e');
      return null;
    }
  }

  /// Mostrar opciones para seleccionar imagen
  Future<String?> pickImage() async {
    // En una implementación real, aquí mostrarías un modal con opciones
    // Por ahora, usaremos galería por defecto
    return await pickImageFromGallery();
  }

  /// Guardar imagen en el directorio local de la app
  Future<String> _saveImageToLocal(String imagePath) async {
    try {
      print('Iniciando guardado de imagen: $imagePath');
      
      final Directory appDir = await getApplicationDocumentsDirectory();
      final String imagesDir = path.join(appDir.path, 'product_images');
      
      print('Directorio de imágenes: $imagesDir');
      
      // Crear directorio si no existe
      final Directory dir = Directory(imagesDir);
      if (!await dir.exists()) {
        print('Creando directorio de imágenes...');
        await dir.create(recursive: true);
        print('Directorio creado exitosamente');
      }

      // Generar nombre único para la imagen
      final String fileName = '${DateTime.now().millisecondsSinceEpoch}.jpg';
      final String newPath = path.join(imagesDir, fileName);
      
      print('Ruta de destino: $newPath');

      // Verificar que el archivo fuente existe
      final File sourceFile = File(imagePath);
      if (!await sourceFile.exists()) {
        throw Exception('El archivo fuente no existe: $imagePath');
      }
      
      print('Archivo fuente existe, copiando...');
      
      // Copiar imagen al directorio de la app
      final File newFile = await sourceFile.copy(newPath);
      
      print('Imagen copiada exitosamente a: ${newFile.path}');
      
      // Verificar que el archivo se copió correctamente
      if (await newFile.exists()) {
        print('Verificación exitosa: archivo existe en destino');
        return newFile.path;
      } else {
        throw Exception('Error: el archivo no se copió correctamente');
      }
    } catch (e) {
      print('Error guardando imagen: $e');
      rethrow;
    }
  }

  /// Eliminar imagen local
  Future<bool> deleteImage(String imagePath) async {
    try {
      if (imagePath.isNotEmpty) {
        final File file = File(imagePath);
        if (await file.exists()) {
          await file.delete();
          return true;
        }
      }
      return false;
    } catch (e) {
      print('Error eliminando imagen: $e');
      return false;
    }
  }

  /// Verificar si la imagen existe
  Future<bool> imageExists(String imagePath) async {
    if (imagePath.isEmpty) return false;
    
    try {
      final File file = File(imagePath);
      return await file.exists();
    } catch (e) {
      return false;
    }
  }

  /// Obtener imagen por defecto según la categoría
  String getDefaultImageForCategory(String categoria) {
    switch (categoria.toLowerCase()) {
      case 'alfombras':
        return 'assets/images/alfombra_default.png';
      case 'piso flotante':
        return 'assets/images/piso_flotante_default.png';
      case 'pisopak':
        return 'assets/images/pisopak_default.png';
      case 'cielo falso':
        return 'assets/images/cielo_falso_default.png';
      case 'viniles':
        return 'assets/images/viniles_default.png';
      default:
        return 'assets/images/producto_default.png';
    }
  }
}
