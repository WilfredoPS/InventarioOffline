import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../models/venta.dart';
import '../models/producto.dart';
import '../services/venta_service.dart';
import '../services/producto_service.dart';
import 'package:intl/intl.dart';

class VentasScreen extends StatefulWidget {
  const VentasScreen({super.key});

  @override
  State<VentasScreen> createState() => _VentasScreenState();
}

class _VentasScreenState extends State<VentasScreen> {
  final VentaService _ventaService = VentaService();
  List<Venta> _ventas = [];
  bool _isLoading = true;
  
  final currencyFormat = NumberFormat.currency(symbol: 'Bs', decimalDigits: 2);
  final dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    _loadVentas();
  }

  Future<void> _loadVentas() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      if (authProvider.tiendaActual != null) {
        _ventas = await _ventaService.getByTienda(authProvider.tiendaActual!);
      } else {
        _ventas = await _ventaService.getAll();
      }
      setState(() {});
    } catch (e) {
      _showError('Error cargando ventas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _nuevaVenta() async {
    final resultado = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const NuevaVentaScreen()),
    );
    
    if (resultado == true) {
      _loadVentas();
    }
  }

  Future<void> _eliminarVenta(Venta venta) async {
    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Venta'),
        content: Text('¿Está seguro de eliminar la venta ${venta.numeroVenta}?\n\nEsta acción no se puede deshacer.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Eliminar', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmar == true) {
      try {
        await _ventaService.eliminar(venta.id);
        _showSuccess('Venta eliminada exitosamente');
        _loadVentas();
      } catch (e) {
        _showError('Error eliminando venta: $e');
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _ventas.isEmpty
              ? const Center(child: Text('No hay ventas registradas'))
              : RefreshIndicator(
                  onRefresh: _loadVentas,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _ventas.length,
                    itemBuilder: (context, index) {
                      final venta = _ventas[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          title: Text(
                            venta.numeroVenta,
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Cliente: ${venta.cliente}'),
                              Text(dateFormat.format(venta.fechaVenta)),
                              Text(
                                currencyFormat.format(venta.total),
                                style: TextStyle(
                                  color: Colors.green.shade700,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Chip(
                                label: Text(venta.estado),
                                backgroundColor: venta.estado == 'completada'
                                    ? Colors.green.shade100
                                    : Colors.red.shade100,
                              ),
                              const SizedBox(width: 8),
                              IconButton(
                                onPressed: () => _eliminarVenta(venta),
                                icon: const Icon(Icons.delete, color: Colors.red),
                                tooltip: 'Eliminar venta',
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _nuevaVenta,
        icon: const Icon(Icons.add),
        label: const Text('Nueva Venta'),
      ),
    );
  }
}

class NuevaVentaScreen extends StatefulWidget {
  const NuevaVentaScreen({super.key});

  @override
  State<NuevaVentaScreen> createState() => _NuevaVentaScreenState();
}

class _NuevaVentaScreenState extends State<NuevaVentaScreen> {
  final _formKey = GlobalKey<FormState>();
  final VentaService _ventaService = VentaService();
  final ProductoService _productoService = ProductoService();
  
  final _clienteController = TextEditingController();
  final _documentoController = TextEditingController();
  final _telefonoController = TextEditingController();
  
  String _metodoPago = 'efectivo';
  final List<_ItemVenta> _items = [];
  bool _isLoading = false;
  
  final currencyFormat = NumberFormat.currency(symbol: 'Bs', decimalDigits: 2);

  @override
  void dispose() {
    _clienteController.dispose();
    _documentoController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  double get _subtotal => _items.fold(0.0, (sum, item) => sum + item.subtotal);
  double get _descuento => 0.0;
  double get _impuesto => _subtotal * 0.0; // Ajustar según necesidad
  double get _total => _subtotal - _descuento + _impuesto;

  Future<void> _agregarProducto() async {
    final productos = await _productoService.getAll();
    
    if (!mounted) return;
    
    final producto = await showDialog<Producto>(
      context: context,
      builder: (context) => _DialogoSeleccionProducto(productos: productos),
    );

    if (producto != null) {
      setState(() {
        _items.add(_ItemVenta(
          producto: producto,
          cantidad: 1,
          precioUnitario: producto.precioVenta,
        ));
      });
    }
  }

  Future<void> _guardarVenta() async {
    if (!_formKey.currentState!.validate()) return;
    if (_items.isEmpty) {
      _showError('Debe agregar al menos un producto');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final authProvider = context.read<AuthProvider>();
      final tiendaId = authProvider.tiendaActual;
      final empleadoId = authProvider.currentEmpleado?.codigo;

      if (tiendaId == null || empleadoId == null) {
        throw Exception('No se puede determinar tienda o empleado');
      }

      final numeroVenta = await _ventaService.generarNumeroVenta(tiendaId);
      
      final venta = Venta()
        ..numeroVenta = numeroVenta
        ..fechaVenta = DateTime.now()
        ..tiendaId = tiendaId
        ..empleadoId = empleadoId
        ..cliente = _clienteController.text.trim()
        ..clienteDocumento = _documentoController.text.trim()
        ..clienteTelefono = _telefonoController.text.trim()
        ..subtotal = _subtotal
        ..descuento = _descuento
        ..impuesto = _impuesto
        ..total = _total
        ..metodoPago = _metodoPago
        ..estado = 'completada';

      final detalles = _items.map((item) {
        return DetalleVenta()
          ..ventaId = numeroVenta
          ..productoId = item.producto.codigo
          ..cantidad = item.cantidad
          ..precioUnitario = item.precioUnitario
          ..descuento = 0
          ..subtotal = item.subtotal
          ..createdAt = DateTime.now()
          ..updatedAt = DateTime.now();
      }).toList();

      await _ventaService.crear(venta, detalles);

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
      _showError('Error guardando venta: $e');
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  Future<void> _mostrarDialogoCantidad(_ItemVenta item, int index) async {
    final cantidadController = TextEditingController(text: item.cantidad.toString());
    
    final resultado = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Cantidad de ${item.producto.nombre}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: cantidadController,
              decoration: const InputDecoration(
                labelText: 'Cantidad',
                border: OutlineInputBorder(),
                suffixText: 'unidades',
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                ElevatedButton(
                  onPressed: () {
                    final cantidad = double.tryParse(cantidadController.text);
                    if (cantidad != null && cantidad > 0) {
                      Navigator.pop(context, cantidad);
                    } else {
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Ingrese una cantidad válida mayor a 0'),
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  },
                  child: const Text('Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );

    if (resultado != null) {
      setState(() {
        item.cantidad = resultado;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Nueva Venta'),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Datos del Cliente',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                  ),
                            ),
                            const SizedBox(height: 12),
                            TextFormField(
                              controller: _clienteController,
                              decoration: const InputDecoration(
                                labelText: 'Nombre del Cliente',
                                border: OutlineInputBorder(),
                              ),
                              validator: (value) =>
                                  value?.isEmpty ?? true ? 'Requerido' : null,
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _documentoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Documento',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: TextFormField(
                                    controller: _telefonoController,
                                    decoration: const InputDecoration(
                                      labelText: 'Teléfono',
                                      border: OutlineInputBorder(),
                                    ),
                                    keyboardType: TextInputType.phone,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            DropdownButtonFormField<String>(
                              value: _metodoPago,
                              decoration: const InputDecoration(
                                labelText: 'Método de Pago',
                                border: OutlineInputBorder(),
                              ),
                              items: [
                                'efectivo',
                                'tarjeta',
                                'transferencia'
                              ].map((m) => DropdownMenuItem(value: m, child: Text(m))).toList(),
                              onChanged: (value) => setState(() => _metodoPago = value!),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Productos',
                          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                        ElevatedButton.icon(
                          onPressed: _agregarProducto,
                          icon: const Icon(Icons.add),
                          label: const Text('Agregar'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    if (_items.isEmpty)
                      const Card(
                        child: Padding(
                          padding: EdgeInsets.all(32),
                          child: Center(
                            child: Text('No hay productos agregados'),
                          ),
                        ),
                      )
                    else
                      ..._items.asMap().entries.map((entry) {
                        final index = entry.key;
                        final item = entry.value;
                        return Card(
                          margin: const EdgeInsets.only(bottom: 8),
                          child: ListTile(
                            title: Text(item.producto.nombre),
                            subtitle: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${currencyFormat.format(item.precioUnitario)} x ${item.cantidad.toStringAsFixed(1)}'),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    IconButton(
                                      icon: const Icon(Icons.remove_circle_outline),
                                      color: Colors.red,
                                      onPressed: () {
                                        setState(() {
                                          if (item.cantidad > 0.5) {
                                            item.cantidad -= 0.5;
                                          } else {
                                            _items.removeAt(index);
                                          }
                                        });
                                      },
                                    ),
                                    GestureDetector(
                                      onTap: () => _mostrarDialogoCantidad(item, index),
                                      child: Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                                        decoration: BoxDecoration(
                                          border: Border.all(color: Colors.grey.shade300),
                                          borderRadius: BorderRadius.circular(8),
                                        ),
                                        child: Text(
                                          item.cantidad.toStringAsFixed(1),
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: const Icon(Icons.add_circle_outline),
                                      color: Colors.green,
                                      onPressed: () {
                                        setState(() {
                                          item.cantidad += 0.5;
                                        });
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Text(
                                  currencyFormat.format(item.subtotal),
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(width: 8),
                                IconButton(
                                  icon: const Icon(Icons.delete),
                                  color: Colors.red,
                                  onPressed: () {
                                    setState(() => _items.removeAt(index));
                                  },
                                ),
                              ],
                            ),
                          ),
                        );
                      }),
                  ],
                ),
              ),
            ),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.grey.shade100,
                boxShadow: [
                  BoxShadow(
                    color: Colors.grey.shade300,
                    blurRadius: 4,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Subtotal:'),
                      Text(currencyFormat.format(_subtotal)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Descuento:'),
                      Text(currencyFormat.format(_descuento)),
                    ],
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Impuesto:'),
                      Text(currencyFormat.format(_impuesto)),
                    ],
                  ),
                  const Divider(),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'TOTAL:',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      Text(
                        currencyFormat.format(_total),
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green.shade700,
                            ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _isLoading ? null : _guardarVenta,
                    style: ElevatedButton.styleFrom(
                      minimumSize: const Size(double.infinity, 50),
                    ),
                    child: _isLoading
                        ? const CircularProgressIndicator()
                        : const Text('GUARDAR VENTA'),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ItemVenta {
  final Producto producto;
  double cantidad;
  double precioUnitario;

  _ItemVenta({
    required this.producto,
    required this.cantidad,
    required this.precioUnitario,
  });

  double get subtotal => cantidad * precioUnitario;
}

class _DialogoSeleccionProducto extends StatefulWidget {
  final List<Producto> productos;

  const _DialogoSeleccionProducto({required this.productos});

  @override
  State<_DialogoSeleccionProducto> createState() => _DialogoSeleccionProductoState();
}

class _DialogoSeleccionProductoState extends State<_DialogoSeleccionProducto> {
  final _searchController = TextEditingController();
  List<Producto> _productosFiltrados = [];

  @override
  void initState() {
    super.initState();
    _productosFiltrados = widget.productos;
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  void _filtrar() {
    setState(() {
      _productosFiltrados = widget.productos
          .where((p) =>
              p.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
              p.codigo.toLowerCase().contains(_searchController.text.toLowerCase()))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: const InputDecoration(
                hintText: 'Buscar producto',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _filtrar(),
            ),
          ),
          Expanded(
            child: ListView.builder(
              itemCount: _productosFiltrados.length,
              itemBuilder: (context, index) {
                final producto = _productosFiltrados[index];
                return ListTile(
                  title: Text(producto.nombre),
                  subtitle: Text(producto.codigo),
                  trailing: Text(
                    'Bs ${producto.precioVenta.toStringAsFixed(2)}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  onTap: () => Navigator.pop(context, producto),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}


