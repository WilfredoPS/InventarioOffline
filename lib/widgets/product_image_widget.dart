import 'package:flutter/material.dart';
import 'dart:io';

class ProductImageWidget extends StatelessWidget {
  final String? imagePath;
  final String? imageUrl;
  final String categoria;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  const ProductImageWidget({
    super.key,
    this.imagePath,
    this.imageUrl,
    required this.categoria,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        color: Colors.grey.shade100,
      ),
      child: ClipRRect(
        borderRadius: borderRadius ?? BorderRadius.circular(8),
        child: _buildImage(),
      ),
    );
  }

  Widget _buildImage() {
    print('ProductImageWidget - imagePath: $imagePath');
    print('ProductImageWidget - imageUrl: $imageUrl');
    print('ProductImageWidget - categoria: $categoria');
    
    // Prioridad: imagen local > imagen URL > imagen por defecto
    if (imagePath != null && imagePath!.isNotEmpty) {
      print('Usando imagen local: $imagePath');
      return _buildLocalImage();
    } else if (imageUrl != null && imageUrl!.isNotEmpty) {
      print('Usando imagen URL: $imageUrl');
      return _buildNetworkImage();
    } else {
      print('Usando imagen por defecto');
      return _buildDefaultImage();
    }
  }

  Widget _buildLocalImage() {
    print('Intentando cargar imagen local: $imagePath');
    final file = File(imagePath!);
    
    return Image.file(
      file,
      fit: fit,
      errorBuilder: (context, error, stackTrace) {
        print('Error cargando imagen local: $error');
        return _buildDefaultImage();
      },
    );
  }

  Widget _buildNetworkImage() {
    return Image.network(
      imageUrl!,
      fit: fit,
      loadingBuilder: (context, child, loadingProgress) {
        if (loadingProgress == null) return child;
        return const Center(
          child: CircularProgressIndicator(),
        );
      },
      errorBuilder: (context, error, stackTrace) {
        return _buildDefaultImage();
      },
    );
  }

  Widget _buildDefaultImage() {
    return Container(
      decoration: BoxDecoration(
        color: _getCategoryColor(),
        borderRadius: borderRadius ?? BorderRadius.circular(8),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              _getCategoryIcon(),
              size: ((height ?? 100) * 0.4).clamp(16.0, 40.0),
              color: Colors.white,
            ),
            if ((height ?? 100) > 50) ...[
              const SizedBox(height: 2),
              Text(
                _getCategoryName(),
                style: TextStyle(
                  color: Colors.white,
                  fontSize: ((height ?? 100) * 0.12).clamp(8.0, 12.0),
                  fontWeight: FontWeight.bold,
                ),
                textAlign: TextAlign.center,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ],
        ),
      ),
    );
  }

  Color _getCategoryColor() {
    switch (categoria.toLowerCase()) {
      case 'alfombras':
        return Colors.brown.shade400;
      case 'piso flotante':
        return Colors.amber.shade600;
      case 'pisopak':
        return Colors.blue.shade400;
      case 'cielo falso':
        return Colors.grey.shade500;
      case 'viniles':
        return Colors.purple.shade400;
      default:
        return Colors.grey.shade400;
    }
  }

  IconData _getCategoryIcon() {
    switch (categoria.toLowerCase()) {
      case 'alfombras':
        return Icons.room_preferences;
      case 'piso flotante':
        return Icons.view_in_ar;
      case 'pisopak':
        return Icons.square_foot;
      case 'cielo falso':
        return Icons.roofing;
      case 'viniles':
        return Icons.texture;
      default:
        return Icons.inventory_2;
    }
  }

  String _getCategoryName() {
    switch (categoria.toLowerCase()) {
      case 'alfombras':
        return 'ALFOMBRA';
      case 'piso flotante':
        return 'PISO';
      case 'pisopak':
        return 'PISOPAK';
      case 'cielo falso':
        return 'CIELO';
      case 'viniles':
        return 'VINIL';
      default:
        return 'PRODUCTO';
    }
  }
}
