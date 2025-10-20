import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../services/inventario_service.dart';

class InventarioUbicacionScreen extends StatefulWidget {
  final String tipoUbicacion; // 'almacen' o 'tienda'
  final String ubicacionId;
  final String nombreUbicacion;

  const InventarioUbicacionScreen({
    super.key,
    required this.tipoUbicacion,
    required this.ubicacionId,
    required this.nombreUbicacion,
  });

  @override
  State<InventarioUbicacionScreen> createState() => _InventarioUbicacionScreenState();
}

class _InventarioUbicacionScreenState extends State<InventarioUbicacionScreen> {
  final InventarioService _inventarioService = InventarioService();
  
  List<Map<String, dynamic>> _inventario = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadInventario();
  }

  Future<void> _loadInventario() async {
    setState(() => _isLoading = true);
    
    try {
      List<Map<String, dynamic>> inventario;
      
      if (widget.tipoUbicacion == 'almacen') {
        inventario = await _inventarioService.getInventarioPorAlmacen(widget.ubicacionId);
      } else {
        inventario = await _inventarioService.getInventarioPorTienda(widget.ubicacionId);
      }
      
      setState(() {
        _inventario = inventario;
        _isLoading = false;
      });
      
      print('InventarioUbicacionScreen._loadInventario: Cargados ${_inventario.length} items en ${widget.nombreUbicacion}');
    } catch (e) {
      print('Error cargando inventario: $e');
      setState(() => _isLoading = false);
      _showError('Error cargando inventario: $e');
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Inventario - ${widget.nombreUbicacion}'),
        backgroundColor: widget.tipoUbicacion == 'almacen' ? Colors.orange.shade700 : Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadInventario,
            tooltip: 'Actualizar Inventario',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _inventario.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        widget.tipoUbicacion == 'almacen' ? Icons.warehouse : Icons.store,
                        size: 64,
                        color: Colors.grey,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'No hay productos en ${widget.nombreUbicacion}',
                        style: const TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadInventario,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _inventario.length,
                    itemBuilder: (context, index) {
                      final item = _inventario[index];
                      final producto = item['producto'] as Producto;
                      final stock = item['stock'] as double;
                      final bajoStock = item['bajoStock'] as bool;

                      return Card(
                        color: bajoStock ? Colors.red.shade50 : null,
                        margin: const EdgeInsets.only(bottom: 8),
                        child: ListTile(
                          leading: bajoStock
                              ? const Icon(Icons.warning, color: Colors.red)
                              : Icon(
                                  widget.tipoUbicacion == 'almacen' ? Icons.warehouse : Icons.store,
                                  color: widget.tipoUbicacion == 'almacen' ? Colors.orange : Colors.green,
                                ),
                          title: Text(
                            producto.nombre,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Código: ${producto.codigo}'),
                              Text('Categoría: ${producto.categoria}'),
                              if (bajoStock)
                                Text(
                                  'Stock mínimo: ${producto.stockMinimo}',
                                  style: const TextStyle(color: Colors.red),
                                ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${stock.toStringAsFixed(2)}',
                                style: TextStyle(
                                  fontSize: 20,
                                  fontWeight: FontWeight.bold,
                                  color: bajoStock ? Colors.red : Colors.green.shade700,
                                ),
                              ),
                              Text(
                                producto.unidadMedida,
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey.shade600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
