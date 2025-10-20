import 'package:flutter/material.dart';
import '../models/producto.dart';
import '../models/inventario.dart';
import '../services/producto_service.dart';
import '../services/inventario_service.dart';
import '../widgets/product_image_widget.dart';
import '../widgets/image_picker_widget.dart';
import 'package:intl/intl.dart';

class ProductosScreen extends StatefulWidget {
  const ProductosScreen({super.key});

  @override
  State<ProductosScreen> createState() => _ProductosScreenState();
}

class _ProductosScreenState extends State<ProductosScreen> {
  final ProductoService _productoService = ProductoService();
  final InventarioService _inventarioService = InventarioService();
  final _searchController = TextEditingController();
  
  List<Producto> _productos = [];
  List<Producto> _productosFiltrados = [];
  Map<String, double> _stockProductos = {}; // productoId -> stock total
  bool _isLoading = true;
  String? _categoriaSeleccionada;

  final currencyFormat = NumberFormat.currency(symbol: 'Bs', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _loadProductos();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    // Recargar stock cuando se regresa a la pantalla
    _loadStockProductos();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadProductos() async {
    setState(() => _isLoading = true);
    try {
      _productos = await _productoService.getAll();
      await _loadStockProductos();
      _filtrarProductos();
    } catch (e) {
      _showError('Error cargando productos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadStockProductos() async {
    try {
      print('ProductosScreen._loadStockProductos: Recargando stock de productos');
      _stockProductos.clear();
      for (var producto in _productos) {
        final stock = await _inventarioService.getStockTotal(producto.codigo);
        _stockProductos[producto.codigo] = stock;
        print('ProductosScreen._loadStockProductos: ${producto.nombre} - Stock: $stock');
      }
      if (mounted) {
        setState(() {});
      }
    } catch (e) {
      print('Error cargando stock: $e');
    }
  }

  void _filtrarProductos() {
    setState(() {
      _productosFiltrados = _productos.where((p) {
        final matchBusqueda = _searchController.text.isEmpty ||
            p.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            p.codigo.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchCategoria = _categoriaSeleccionada == null ||
            p.categoria == _categoriaSeleccionada;

        return matchBusqueda && matchCategoria;
      }).toList();
    });
  }

  Future<void> _mostrarFormulario({Producto? producto}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _FormularioProducto(
        producto: producto,
        onProductoSaved: () => _loadStockProductos(),
      ),
    );

    if (resultado == true) {
      _loadProductos();
    }
  }

  Future<void> _eliminarProducto(Producto producto) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Producto'),
        content: Text('¿Está seguro de eliminar ${producto.nombre}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _productoService.eliminar(producto.id);
        _showSuccess('Producto eliminado');
        _loadProductos();
      } catch (e) {
        _showError('Error eliminando producto: $e');
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }

  Color _getStockColor(double stock) {
    if (stock <= 0) {
      return Colors.red; // Sin stock
    } else if (stock <= 5) {
      return Colors.orange; // Stock bajo
    } else {
      return Colors.green; // Stock normal
    }
  }

  Future<void> _refreshStock() async {
    await _loadStockProductos();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Productos'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshStock,
            tooltip: 'Actualizar Stock',
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre o código',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filtrarProductos();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _filtrarProductos(),
                ),
                const SizedBox(height: 8),
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      FilterChip(
                        label: const Text('Todas'),
                        selected: _categoriaSeleccionada == null,
                        onSelected: (selected) {
                          setState(() => _categoriaSeleccionada = null);
                          _filtrarProductos();
                        },
                      ),
                      const SizedBox(width: 8),
                      ...['alfombras', 'piso flotante', 'pisopak', 'cielo falso', 'viniles']
                          .map((categoria) => Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: FilterChip(
                                  label: Text(categoria),
                                  selected: _categoriaSeleccionada == categoria,
                                  onSelected: (selected) {
                                    setState(() {
                                      _categoriaSeleccionada = selected ? categoria : null;
                                    });
                                    _filtrarProductos();
                                  },
                                ),
                              )),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _productosFiltrados.isEmpty
                    ? const Center(child: Text('No hay productos'))
                    : ListView.builder(
                        itemCount: _productosFiltrados.length,
                        itemBuilder: (context, index) {
                          final producto = _productosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: ProductImageWidget(
                                imagePath: producto.imagenPath,
                                imageUrl: producto.imagenUrl,
                                categoria: producto.categoria,
                                width: 60,
                                height: 60,
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
                                  Row(
                                    children: [
                                      Text(
                                        'Precio: ${currencyFormat.format(producto.precioVenta)}',
                                        style: TextStyle(
                                          color: Colors.green.shade700,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(width: 16),
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getStockColor(_stockProductos[producto.codigo] ?? 0),
                                          borderRadius: BorderRadius.circular(12),
                                        ),
                                        child: Text(
                                          'Stock: ${(_stockProductos[producto.codigo] ?? 0).toInt()}',
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                              trailing: PopupMenuButton(
                                itemBuilder: (context) => [
                                  const PopupMenuItem(
                                    value: 'editar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.edit),
                                        SizedBox(width: 8),
                                        Text('Editar'),
                                      ],
                                    ),
                                  ),
                                  const PopupMenuItem(
                                    value: 'eliminar',
                                    child: Row(
                                      children: [
                                        Icon(Icons.delete, color: Colors.red),
                                        SizedBox(width: 8),
                                        Text('Eliminar', style: TextStyle(color: Colors.red)),
                                      ],
                                    ),
                                  ),
                                ],
                                onSelected: (value) {
                                  if (value == 'editar') {
                                    _mostrarFormulario(producto: producto);
                                  } else if (value == 'eliminar') {
                                    _eliminarProducto(producto);
                                  }
                                },
                              ),
                            ),
                          );
                        },
                      ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _mostrarFormulario(),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _FormularioProducto extends StatefulWidget {
  final Producto? producto;
  final VoidCallback? onProductoSaved;

  const _FormularioProducto({this.producto, this.onProductoSaved});

  @override
  State<_FormularioProducto> createState() => _FormularioProductoState();
}

class _FormularioProductoState extends State<_FormularioProducto> {
  final _formKey = GlobalKey<FormState>();
  final ProductoService _productoService = ProductoService();

  late TextEditingController _codigoController;
  late TextEditingController _nombreController;
  late TextEditingController _descripcionController;
  late TextEditingController _precioCompraController;
  late TextEditingController _precioVentaController;
  late TextEditingController _stockMinimoController;
  
  String _categoria = 'alfombras';
  String _unidadMedida = 'm2';
  String? _imagenPath;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.producto?.codigo ?? '');
    _nombreController = TextEditingController(text: widget.producto?.nombre ?? '');
    _descripcionController = TextEditingController(text: widget.producto?.descripcion ?? '');
    _precioCompraController = TextEditingController(
      text: widget.producto?.precioCompra.toString() ?? '',
    );
    _precioVentaController = TextEditingController(
      text: widget.producto?.precioVenta.toString() ?? '',
    );
    _stockMinimoController = TextEditingController(
      text: widget.producto?.stockMinimo.toString() ?? '0',
    );
    
    if (widget.producto != null) {
      _categoria = widget.producto!.categoria;
      _unidadMedida = widget.producto!.unidadMedida;
      _imagenPath = widget.producto!.imagenPath;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _descripcionController.dispose();
    _precioCompraController.dispose();
    _precioVentaController.dispose();
    _stockMinimoController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final producto = widget.producto ?? Producto();
      producto.codigo = _codigoController.text.trim();
      producto.nombre = _nombreController.text.trim();
      producto.descripcion = _descripcionController.text.trim();
      producto.categoria = _categoria;
      producto.unidadMedida = _unidadMedida;
      producto.precioCompra = double.parse(_precioCompraController.text);
      producto.precioVenta = double.parse(_precioVentaController.text);
      producto.stockMinimo = int.parse(_stockMinimoController.text);
      producto.imagenPath = _imagenPath;

      // Debug: Verificar que la imagen se está guardando
      print('Guardando producto con imagen: $_imagenPath');

      if (widget.producto == null) {
        await _productoService.crear(producto);
        print('Producto creado exitosamente');
      } else {
        await _productoService.actualizar(producto);
        print('Producto actualizado exitosamente');
      }

      // Recargar stock después de guardar
      if (widget.onProductoSaved != null) {
        widget.onProductoSaved!();
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      print('Error guardando producto: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  widget.producto == null ? 'Nuevo Producto' : 'Editar Producto',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _nombreController,
                  decoration: const InputDecoration(
                    labelText: 'Nombre',
                    border: OutlineInputBorder(),
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _descripcionController,
                  decoration: const InputDecoration(
                    labelText: 'Descripción',
                    border: OutlineInputBorder(),
                  ),
                  maxLines: 2,
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _categoria,
                  decoration: const InputDecoration(
                    labelText: 'Categoría',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'alfombras',
                    'piso flotante',
                    'pisopak',
                    'cielo falso',
                    'viniles'
                  ].map((cat) => DropdownMenuItem(value: cat, child: Text(cat))).toList(),
                  onChanged: (value) => setState(() => _categoria = value!),
                ),
                const SizedBox(height: 12),
                DropdownButtonFormField<String>(
                  value: _unidadMedida,
                  decoration: const InputDecoration(
                    labelText: 'Unidad de Medida',
                    border: OutlineInputBorder(),
                  ),
                  items: ['m2', 'rollo', 'caja', 'pieza']
                      .map((um) => DropdownMenuItem(value: um, child: Text(um)))
                      .toList(),
                  onChanged: (value) => setState(() => _unidadMedida = value!),
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _precioCompraController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Compra',
                          border: OutlineInputBorder(),
                          prefixText: 'Bs ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _precioVentaController,
                        decoration: const InputDecoration(
                          labelText: 'Precio Venta',
                          border: OutlineInputBorder(),
                          prefixText: 'Bs ',
                        ),
                        keyboardType: TextInputType.number,
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _stockMinimoController,
                  decoration: const InputDecoration(
                    labelText: 'Stock Mínimo',
                    border: OutlineInputBorder(),
                  ),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 16),
                ImagePickerWidget(
                  currentImagePath: _imagenPath,
                  categoria: _categoria,
                  onImageSelected: (imagePath) {
                    print('Imagen seleccionada: $imagePath');
                    setState(() {
                      _imagenPath = imagePath;
                    });
                    print('Imagen actualizada en estado: $_imagenPath');
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _isLoading ? null : () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton(
                      onPressed: _isLoading ? null : _guardar,
                      child: _isLoading
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Text('Guardar'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}




