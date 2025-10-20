import 'package:flutter/material.dart';
import '../models/compra.dart';
import '../models/producto.dart';
import '../models/almacen.dart';
import '../models/tienda.dart';
import '../services/compra_service.dart';
import '../services/producto_service.dart';
import '../services/almacen_service.dart';
import '../services/tienda_service.dart';
import '../services/sugerencia_compra_service.dart';
import '../utils/inventario_notifier.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';

class ComprasScreen extends StatefulWidget {
  const ComprasScreen({super.key});

  @override
  State<ComprasScreen> createState() => _ComprasScreenState();
}

class _ComprasScreenState extends State<ComprasScreen> {
  final CompraService _compraService = CompraService();
  
  final _searchController = TextEditingController();
  
  List<Compra> _compras = [];
  List<Compra> _comprasFiltradas = [];
  bool _isLoading = true;
  String _filtroEstado = 'todos'; // todos, pendiente, completada, anulada

  @override
  void initState() {
    super.initState();
    print('ComprasScreen.initState: Inicializando pantalla de compras');
    _loadCompras();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadCompras() async {
    print('ComprasScreen._loadCompras: Iniciando carga de compras...');
    setState(() => _isLoading = true);
    try {
      _compras = await _compraService.getAll();
      print('ComprasScreen._loadCompras: Compras cargadas: ${_compras.length}');
      _filtrarCompras();
    } catch (e) {
      print('ComprasScreen._loadCompras: Error: $e');
      _showError('Error cargando compras: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filtrarCompras() {
    setState(() {
      _comprasFiltradas = _compras.where((c) {
        final matchBusqueda = _searchController.text.isEmpty ||
            c.numeroCompra.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            c.proveedor.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            (c.numeroFactura?.toLowerCase().contains(_searchController.text.toLowerCase()) ?? false);
        
        final matchEstado = _filtroEstado == 'todos' || c.estado == _filtroEstado;

        return matchBusqueda && matchEstado;
      }).toList();
    });
  }

  Future<void> _mostrarFormulario({Compra? compra}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _FormularioCompra(compra: compra),
    );

    if (resultado == true) {
      _loadCompras();
    }
  }

  Future<void> _mostrarSugerencias() async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => const _DialogoSugerencias(),
    );

    if (resultado == true) {
      _loadCompras();
    }
  }

  Future<void> _completarCompra(Compra compra) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Completar Compra'),
        content: Text('¿Está seguro de completar la compra ${compra.numeroCompra}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Completar'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _compraService.completarCompra(compra.numeroCompra);
        _showSuccess('Compra completada');
        _loadCompras();
        
        // Notificar cambio en inventario
        InventarioNotifier.notifyChange(context);
      } catch (e) {
        _showError('Error completando compra: $e');
      }
    }
  }

  Future<void> _anularCompra(Compra compra) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Anular Compra'),
        content: Text('¿Está seguro de anular la compra ${compra.numeroCompra}?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Anular'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        await _compraService.anularCompra(compra.numeroCompra);
        _showSuccess('Compra anulada');
        _loadCompras();
      } catch (e) {
        _showError('Error anulando compra: $e');
      }
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'completada':
        return Colors.green;
      case 'anulada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _getEstadoDisplayName(String estado) {
    switch (estado) {
      case 'pendiente':
        return 'Pendiente';
      case 'completada':
        return 'Completada';
      case 'anulada':
        return 'Anulada';
      default:
        return estado;
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

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  Future<void> _mostrarDetalles(Compra compra) async {
    final detalles = await _compraService.getDetalles(compra.numeroCompra);
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${compra.numeroCompra}'),
        content: SizedBox(
          width: double.maxFinite,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Proveedor: ${compra.proveedor}'),
              Text('Fecha: ${_formatDate(compra.fechaCompra)}'),
              Text('Total: Bs ${compra.total.toStringAsFixed(2)}'),
              const SizedBox(height: 16),
              const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...detalles.map((detalle) => ListTile(
                title: Text('Producto: ${detalle.productoId}'),
                subtitle: Text('Cantidad: ${detalle.cantidad} x Bs ${detalle.precioUnitario.toStringAsFixed(2)}'),
                trailing: Text('Bs ${detalle.subtotal.toStringAsFixed(2)}'),
              )),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    print('ComprasScreen.build: Construyendo pantalla de compras');
    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Compras'),
        backgroundColor: Colors.blue.shade700,
        foregroundColor: Colors.white,
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
                    hintText: 'Buscar por número, proveedor o factura',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filtrarCompras();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _filtrarCompras(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: DropdownButtonFormField<String>(
                        value: _filtroEstado,
                        decoration: const InputDecoration(
                          labelText: 'Estado',
                          border: OutlineInputBorder(),
                        ),
                        items: [
                          'todos',
                          'pendiente',
                          'completada',
                          'anulada',
                        ].map((estado) => DropdownMenuItem(
                          value: estado,
                          child: Text(estado == 'todos' ? 'Todos' : _getEstadoDisplayName(estado)),
                        )).toList(),
                        onChanged: (value) {
                          setState(() => _filtroEstado = value!);
                          _filtrarCompras();
                        },
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_comprasFiltradas.length} compras'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _comprasFiltradas.isEmpty
                    ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                            Icon(Icons.shopping_cart, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay compras'),
                            SizedBox(height: 8),
                            Text('Haz clic en + para crear una nueva compra'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _comprasFiltradas.length,
                        itemBuilder: (context, index) {
                          final compra = _comprasFiltradas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getEstadoColor(compra.estado).withOpacity(0.1),
                                child: Icon(
                                  Icons.shopping_cart,
                                  color: _getEstadoColor(compra.estado),
                                ),
                              ),
                              title: Text(
                                compra.numeroCompra,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Proveedor: ${compra.proveedor}'),
                                  if (compra.numeroFactura != null)
                                    Text('Factura: ${compra.numeroFactura}'),
                                  Text('Fecha: ${_formatDate(compra.fechaCompra)}'),
                                  Text('Total: Bs ${compra.total.toStringAsFixed(2)}'),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getEstadoColor(compra.estado).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _getEstadoColor(compra.estado)),
                                        ),
                                        child: Text(
                                          _getEstadoDisplayName(compra.estado),
                                          style: TextStyle(
                                            color: _getEstadoColor(compra.estado),
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
                                    value: 'ver',
                                    child: Row(
                                      children: [
                                        Icon(Icons.visibility),
                                        SizedBox(width: 8),
                                        Text('Ver Detalles'),
                                      ],
                                    ),
                                  ),
                                  if (compra.estado == 'pendiente') ...[
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
                                      value: 'completar',
                                      child: Row(
                                        children: [
                                          Icon(Icons.check, color: Colors.green),
                                          SizedBox(width: 8),
                                          Text('Completar', style: TextStyle(color: Colors.green)),
                                        ],
                                      ),
                                    ),
                                  ],
                                  if (compra.estado != 'anulada')
                                    const PopupMenuItem(
                                      value: 'anular',
                                      child: Row(
                                        children: [
                                          Icon(Icons.cancel, color: Colors.red),
                                          SizedBox(width: 8),
                                          Text('Anular', style: TextStyle(color: Colors.red)),
                                        ],
                                      ),
                                    ),
                                ],
                                onSelected: (value) {
                                  if (value == 'ver') {
                                    _mostrarDetalles(compra);
                                  } else if (value == 'editar') {
                                    _mostrarFormulario(compra: compra);
                                  } else if (value == 'completar') {
                                    _completarCompra(compra);
                                  } else if (value == 'anular') {
                                    _anularCompra(compra);
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
      floatingActionButton: Column(
        mainAxisAlignment: MainAxisAlignment.end,
        children: [
          FloatingActionButton.extended(
            onPressed: _mostrarSugerencias,
            heroTag: "sugerencias",
            icon: const Icon(Icons.lightbulb_outline),
            label: const Text('Sugerencias'),
            backgroundColor: Colors.orange,
            foregroundColor: Colors.white,
          ),
          const SizedBox(height: 8),
          FloatingActionButton(
            onPressed: () {
              print('ComprasScreen: Botón + presionado');
              _mostrarFormulario();
            },
            heroTag: "nueva_compra",
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }
}

class _FormularioCompra extends StatefulWidget {
  final Compra? compra;

  const _FormularioCompra({this.compra});

  @override
  State<_FormularioCompra> createState() => _FormularioCompraState();
}

class _FormularioCompraState extends State<_FormularioCompra> {
  final _formKey = GlobalKey<FormState>();
  final _proveedorController = TextEditingController();
  final _numeroFacturaController = TextEditingController();
  final _observacionesController = TextEditingController();
  
  final CompraService _compraService = CompraService();
  final ProductoService _productoService = ProductoService();
  final AlmacenService _almacenService = AlmacenService();
  final TiendaService _tiendaService = TiendaService();
  
  String _tipoDestino = 'almacen';
  String _destinoId = '';
  String _estado = 'pendiente';
  DateTime _fechaCompra = DateTime.now();
  
  List<Producto> _productos = [];
  List<Almacen> _almacenes = [];
  List<Tienda> _tiendas = [];
  
  final List<DetalleCompra> _detalles = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    if (widget.compra != null) {
      _cargarDatosCompra();
    }
  }

  @override
  void dispose() {
    _proveedorController.dispose();
    _numeroFacturaController.dispose();
    _observacionesController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final futures = await Future.wait([
        _productoService.getAll(),
        _almacenService.getAll(),
        _tiendaService.getAll(),
      ]);
      
      _productos = futures[0] as List<Producto>;
      _almacenes = futures[1] as List<Almacen>;
      _tiendas = futures[2] as List<Tienda>;
      
      if (_almacenes.isNotEmpty) {
        _destinoId = _almacenes.first.codigo;
      } else if (_tiendas.isNotEmpty) {
        _destinoId = _tiendas.first.codigo;
        _tipoDestino = 'tienda';
      }
    } catch (e) {
      _showError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _cargarDatosCompra() {
    final compra = widget.compra!;
    _proveedorController.text = compra.proveedor;
    _numeroFacturaController.text = compra.numeroFactura ?? '';
    _observacionesController.text = compra.observaciones ?? '';
    _estado = compra.estado;
    _fechaCompra = compra.fechaCompra;
    _tipoDestino = compra.destinoTipo;
    _destinoId = compra.destinoId;
  }

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaCompra,
      firstDate: DateTime(2020),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    
    if (fecha != null) {
      setState(() => _fechaCompra = fecha);
    }
  }

  void _agregarDetalle() {
    showDialog(
      context: context,
      builder: (context) => _DialogoAgregarDetalle(
        productos: _productos,
        onDetalleAgregado: (detalle) {
          setState(() {
            _detalles.add(detalle);
          });
        },
      ),
    );
  }

  void _eliminarDetalle(int index) {
    setState(() {
      _detalles.removeAt(index);
    });
  }

  double _calcularSubtotal() {
    return _detalles.fold(0.0, (sum, detalle) => sum + detalle.subtotal);
  }

  double _calcularImpuestos() {
    return _calcularSubtotal() * 0.19; // 19% IVA
  }

  double _calcularTotal() {
    return _calcularSubtotal() + _calcularImpuestos();
  }

  Future<void> _guardar() async {
    print('_FormularioCompra._guardar: Iniciando guardado de compra');
    if (!_formKey.currentState!.validate()) {
      print('_FormularioCompra._guardar: Validación del formulario falló');
      return;
    }
    
    if (_detalles.isEmpty) {
      print('_FormularioCompra._guardar: No hay productos agregados');
      _showError('Debe agregar al menos un producto');
      return;
    }

    try {
      // Generar número de compra si es nueva
      String numeroCompra = widget.compra?.numeroCompra ?? '';
      if (numeroCompra.isEmpty) {
        print('_FormularioCompra._guardar: Generando número de compra');
        numeroCompra = await _compraService.generarNumeroCompra();
        print('_FormularioCompra._guardar: Número generado: $numeroCompra');
      }

      print('_FormularioCompra._guardar: Creando objeto Compra');
      print('_FormularioCompra._guardar: numeroCompra: $numeroCompra');
      print('_FormularioCompra._guardar: proveedor: ${_proveedorController.text.trim()}');
      print('_FormularioCompra._guardar: fechaCompra: $_fechaCompra');
      print('_FormularioCompra._guardar: destinoTipo: $_tipoDestino');
      print('_FormularioCompra._guardar: destinoId: $_destinoId');
      print('_FormularioCompra._guardar: estado: $_estado');
      print('_FormularioCompra._guardar: subtotal: ${_calcularSubtotal()}');
      print('_FormularioCompra._guardar: impuesto: ${_calcularImpuestos()}');
      print('_FormularioCompra._guardar: total: ${_calcularTotal()}');

      final compra = Compra()
        ..numeroCompra = numeroCompra
        ..proveedor = _proveedorController.text.trim()
        ..numeroFactura = _numeroFacturaController.text.trim().isEmpty 
            ? null 
            : _numeroFacturaController.text.trim()
        ..fechaCompra = _fechaCompra
        ..destinoTipo = _tipoDestino
        ..destinoId = _destinoId
        ..empleadoId = 'EMP001' // TODO: Obtener del usuario actual
        ..estado = _estado
        ..observaciones = _observacionesController.text.trim().isEmpty 
            ? null 
            : _observacionesController.text.trim()
        ..subtotal = _calcularSubtotal()
        ..impuesto = _calcularImpuestos()
        ..total = _calcularTotal()
        ..createdAt = widget.compra?.createdAt ?? DateTime.now()
        ..updatedAt = DateTime.now()
        ..sincronizado = false;

      if (widget.compra == null) {
        print('_FormularioCompra._guardar: Creando nueva compra');
        // Asignar el compraId a todos los detalles
        for (var detalle in _detalles) {
          detalle.compraId = numeroCompra;
          print('_FormularioCompra._guardar: Detalle - productoId: ${detalle.productoId}, cantidad: ${detalle.cantidad}, precio: ${detalle.precioUnitario}, subtotal: ${detalle.subtotal}');
        }
        print('_FormularioCompra._guardar: Detalles asignados: ${_detalles.length}');
        print('_FormularioCompra._guardar: Llamando a compraService.crear');
        await _compraService.crear(compra, _detalles);
        print('_FormularioCompra._guardar: Compra creada exitosamente');
        _showSuccess('Compra creada');
        
        // Notificar cambio en inventario
        InventarioNotifier.notifyChange(context);
      } else {
        print('_FormularioCompra._guardar: Actualizando compra existente');
        await _compraService.actualizar(compra);
        print('_FormularioCompra._guardar: Compra actualizada exitosamente');
        _showSuccess('Compra actualizada');
      }

      Navigator.pop(context, true);
    } catch (e) {
      print('_FormularioCompra._guardar: Error: $e');
      _showError('Error guardando compra: $e');
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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text(
                  widget.compra == null ? 'Nueva Compra' : 'Editar Compra',
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : SingleChildScrollView(
                      child: Form(
                        key: _formKey,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: TextFormField(
                                    controller: _proveedorController,
                                    decoration: const InputDecoration(
                                      labelText: 'Proveedor *',
                                      border: OutlineInputBorder(),
                                    ),
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'El proveedor es requerido';
                                      }
                                      return null;
                                    },
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: TextFormField(
                                    controller: _numeroFacturaController,
                                    decoration: const InputDecoration(
                                      labelText: 'Número de Factura',
                                      border: OutlineInputBorder(),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: InkWell(
                                    onTap: _seleccionarFecha,
                                    child: InputDecorator(
                                      decoration: const InputDecoration(
                                        labelText: 'Fecha de Compra *',
                                        border: OutlineInputBorder(),
                                        suffixIcon: Icon(Icons.calendar_today),
                                      ),
                                      child: Text(
                                        '${_fechaCompra.day.toString().padLeft(2, '0')}/${_fechaCompra.month.toString().padLeft(2, '0')}/${_fechaCompra.year}',
                                      ),
                                    ),
                                  ),
                                ),
                                const SizedBox(width: 16),
                                Expanded(
                                  child: DropdownButtonFormField<String>(
                                    value: _tipoDestino,
                                    decoration: const InputDecoration(
                                      labelText: 'Destino *',
                                      border: OutlineInputBorder(),
                                    ),
                                    items: [
                                      DropdownMenuItem(
                                        value: 'almacen',
                                        child: Text('Almacén'),
                                      ),
                                      DropdownMenuItem(
                                        value: 'tienda',
                                        child: Text('Tienda'),
                                      ),
                                    ],
                                    onChanged: (value) {
                                      setState(() {
                                        _tipoDestino = value!;
                                        if (_tipoDestino == 'almacen' && _almacenes.isNotEmpty) {
                                          _destinoId = _almacenes.first.codigo;
                                        } else if (_tipoDestino == 'tienda' && _tiendas.isNotEmpty) {
                                          _destinoId = _tiendas.first.codigo;
                                        }
                                      });
                                    },
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            DropdownButtonFormField<String>(
                              value: _destinoId,
                              decoration: const InputDecoration(
                                labelText: 'Seleccionar Destino *',
                                border: OutlineInputBorder(),
                              ),
                              items: (_tipoDestino == 'almacen' 
                                  ? _almacenes.map<DropdownMenuItem<String>>((item) => DropdownMenuItem<String>(
                                        value: item.codigo,
                                        child: Text(item.nombre),
                                      ))
                                  : _tiendas.map<DropdownMenuItem<String>>((item) => DropdownMenuItem<String>(
                                        value: item.codigo,
                                        child: Text(item.nombre),
                                      ))).toList(),
                              onChanged: (value) {
                                setState(() => _destinoId = value!);
                              },
                            ),
                            const SizedBox(height: 16),
                            if (widget.compra == null) ...[
                              DropdownButtonFormField<String>(
                                value: _estado,
                                decoration: const InputDecoration(
                                  labelText: 'Estado',
                                  border: OutlineInputBorder(),
                                ),
                                items: [
                                  DropdownMenuItem(
                                    value: 'pendiente',
                                    child: Text('Pendiente'),
                                  ),
                                ],
                                onChanged: (value) {
                                  setState(() => _estado = value!);
                                },
                              ),
                              const SizedBox(height: 16),
                            ],
                            TextFormField(
                              controller: _observacionesController,
                              decoration: const InputDecoration(
                                labelText: 'Observaciones',
                                border: OutlineInputBorder(),
                              ),
                              maxLines: 2,
                            ),
                            const SizedBox(height: 24),
                            Row(
                              children: [
                                const Text(
                                  'Productos',
                                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                ),
                                const Spacer(),
                                ElevatedButton.icon(
                                  onPressed: _agregarDetalle,
                                  icon: const Icon(Icons.add),
                                  label: const Text('Agregar Producto'),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (_detalles.isEmpty)
                              const Center(
                                child: Padding(
                                  padding: EdgeInsets.all(32),
                                  child: Text(
                                    'No hay productos agregados',
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              )
                            else
                              ...List.generate(_detalles.length, (index) {
                                final detalle = _detalles[index];
                                final producto = _productos.firstWhere(
                                  (p) => p.codigo == detalle.productoId,
                                  orElse: () => Producto(),
                                );
                                
                                return Card(
                                  child: ListTile(
                                    title: Text(producto.nombre),
                                    subtitle: Text('Cantidad: ${detalle.cantidad} x Bs ${detalle.precioUnitario.toStringAsFixed(2)}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Text(
                                          'Bs ${detalle.subtotal.toStringAsFixed(2)}',
                                          style: const TextStyle(fontWeight: FontWeight.bold),
                                        ),
                                        IconButton(
                                          onPressed: () => _eliminarDetalle(index),
                                          icon: const Icon(Icons.delete, color: Colors.red),
                                        ),
                                      ],
                                    ),
                                  ),
                                );
                              }),
                            const SizedBox(height: 24),
                            Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade100,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                children: [
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Subtotal:'),
                                      Text('Bs ${_calcularSubtotal().toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text('Impuestos (19%):'),
                                      Text('Bs ${_calcularImpuestos().toStringAsFixed(2)}'),
                                    ],
                                  ),
                                  const Divider(),
                                  Row(
                                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                    children: [
                                      const Text(
                                        'Total:',
                                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                      Text(
                                        'Bs ${_calcularTotal().toStringAsFixed(2)}',
                                        style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
            ),
            const Divider(),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _guardar,
                  child: Text(widget.compra == null ? 'Crear' : 'Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DialogoAgregarDetalle extends StatefulWidget {
  final List<Producto> productos;
  final Function(DetalleCompra) onDetalleAgregado;

  const _DialogoAgregarDetalle({
    required this.productos,
    required this.onDetalleAgregado,
  });

  @override
  State<_DialogoAgregarDetalle> createState() => _DialogoAgregarDetalleState();
}

class _DialogoAgregarDetalleState extends State<_DialogoAgregarDetalle> {
  final _formKey = GlobalKey<FormState>();
  String _productoId = '';
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _agregar() {
    if (!_formKey.currentState!.validate()) return;
    if (_productoId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Seleccione un producto')),
      );
      return;
    }

    final detalle = DetalleCompra()
      ..compraId = '' // Se asignará al guardar la compra
      ..productoId = _productoId
      ..cantidad = double.parse(_cantidadController.text)
      ..precioUnitario = double.parse(_precioController.text)
      ..subtotal = double.parse(_cantidadController.text) * double.parse(_precioController.text);

    widget.onDetalleAgregado(detalle);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: Form(
        key: _formKey,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButtonFormField<String>(
              value: _productoId.isEmpty ? null : _productoId,
              decoration: const InputDecoration(
                labelText: 'Producto *',
                border: OutlineInputBorder(),
              ),
              items: widget.productos.map((producto) => DropdownMenuItem(
                value: producto.codigo,
                child: Text(producto.nombre),
              )).toList(),
              onChanged: (value) {
                setState(() => _productoId = value!);
              },
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: TextFormField(
                    controller: _cantidadController,
                    decoration: const InputDecoration(
                      labelText: 'Cantidad *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'La cantidad es requerida';
                      }
                      final cantidad = int.tryParse(value);
                      if (cantidad == null || cantidad <= 0) {
                        return 'La cantidad debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    controller: _precioController,
                    decoration: const InputDecoration(
                      labelText: 'Precio Unitario *',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'El precio es requerido';
                      }
                      final precio = double.tryParse(value);
                      if (precio == null || precio <= 0) {
                        return 'El precio debe ser mayor a 0';
                      }
                      return null;
                    },
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: _agregar,
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

class _DialogoSugerencias extends StatefulWidget {
  const _DialogoSugerencias();

  @override
  State<_DialogoSugerencias> createState() => _DialogoSugerenciasState();
}

class _DialogoSugerenciasState extends State<_DialogoSugerencias> {
  final SugerenciaCompraService _sugerenciaService = SugerenciaCompraService();
  final AlmacenService _almacenService = AlmacenService();
  final TiendaService _tiendaService = TiendaService();
  
  List<Map<String, dynamic>> _sugerencias = [];
  List<Map<String, dynamic>> _productosStockBajo = [];
  bool _isLoading = true;
  String _tipoSugerencia = 'ventas'; // ventas, stock_bajo
  String _destinoTipo = 'almacen';
  String _destinoId = '';
  String _proveedor = '';
  List<Almacen> _almacenes = [];
  List<Tienda> _tiendas = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final authProvider = context.read<AuthProvider>();
      final tiendaId = authProvider.tiendaActual;
      
      // Cargar ubicaciones
      final futures = await Future.wait([
        _almacenService.getAll(),
        _tiendaService.getAll(),
      ]);
      
      _almacenes = futures[0] as List<Almacen>;
      _tiendas = futures[1] as List<Tienda>;
      
      if (_almacenes.isNotEmpty) {
        _destinoId = _almacenes.first.codigo;
      } else if (_tiendas.isNotEmpty) {
        _destinoId = _tiendas.first.codigo;
        _destinoTipo = 'tienda';
      }
      
      // Cargar sugerencias
      await _cargarSugerencias(tiendaId);
    } catch (e) {
      _showError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _cargarSugerencias(String? tiendaId) async {
    try {
      if (_tipoSugerencia == 'ventas') {
        _sugerencias = await _sugerenciaService.generarSugerenciasCompra(
          diasAtras: 7,
          factorMultiplicador: 1.5,
          tiendaId: tiendaId,
        );
      } else {
        _productosStockBajo = await _sugerenciaService.getProductosStockBajo(
          tiendaId: tiendaId,
        );
      }
    } catch (e) {
      _showError('Error cargando sugerencias: $e');
    }
  }

  Future<void> _crearCompraAutomatica() async {
    if (_proveedor.trim().isEmpty) {
      _showError('Debe ingresar el nombre del proveedor');
      return;
    }

    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Crear Compra Automática'),
        content: Text('¿Crear compra automática con ${_tipoSugerencia == 'ventas' ? _sugerencias.length : _productosStockBajo.length} productos?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Crear'),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      try {
        final productos = _tipoSugerencia == 'ventas' ? _sugerencias : _productosStockBajo;
        final numeroCompra = await _sugerenciaService.crearCompraAutomatica(
          sugerencias: productos,
          destinoTipo: _destinoTipo,
          destinoId: _destinoId,
          proveedor: _proveedor.trim(),
          observaciones: 'Compra automática generada por ${_tipoSugerencia == 'ventas' ? 'análisis de ventas' : 'stock bajo'}',
        );

        if (numeroCompra != null) {
          _showSuccess('Compra creada: $numeroCompra');
          Navigator.pop(context, true);
        } else {
          _showError('Error creando la compra');
        }
      } catch (e) {
        _showError('Error creando compra: $e');
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
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.95,
        height: MediaQuery.of(context).size.height * 0.9,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                const Text(
                  'Sugerencias de Compra',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.close),
                ),
              ],
            ),
            const Divider(),
            
            // Controles
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _tipoSugerencia,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de Sugerencia',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'ventas',
                        child: Text('Basado en Ventas'),
                      ),
                      DropdownMenuItem(
                        value: 'stock_bajo',
                        child: Text('Stock Bajo'),
                      ),
                    ],
                    onChanged: (value) async {
                      setState(() => _tipoSugerencia = value!);
                      await _cargarSugerencias(context.read<AuthProvider>().tiendaActual);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _destinoTipo,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      border: OutlineInputBorder(),
                    ),
                    items: [
                      DropdownMenuItem(
                        value: 'almacen',
                        child: Text('Almacén'),
                      ),
                      DropdownMenuItem(
                        value: 'tienda',
                        child: Text('Tienda'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _destinoTipo = value!;
                        if (_destinoTipo == 'almacen' && _almacenes.isNotEmpty) {
                          _destinoId = _almacenes.first.codigo;
                        } else if (_destinoTipo == 'tienda' && _tiendas.isNotEmpty) {
                          _destinoId = _tiendas.first.codigo;
                        }
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _destinoId,
                    decoration: const InputDecoration(
                      labelText: 'Seleccionar Destino',
                      border: OutlineInputBorder(),
                    ),
                    items: (_destinoTipo == 'almacen' 
                        ? _almacenes.map<DropdownMenuItem<String>>((item) => DropdownMenuItem<String>(
                              value: item.codigo,
                              child: Text(item.nombre),
                            ))
                        : _tiendas.map<DropdownMenuItem<String>>((item) => DropdownMenuItem<String>(
                              value: item.codigo,
                              child: Text(item.nombre),
                            ))).toList(),
                    onChanged: (value) {
                      setState(() => _destinoId = value!);
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: TextFormField(
                    decoration: const InputDecoration(
                      labelText: 'Proveedor *',
                      border: OutlineInputBorder(),
                    ),
                    onChanged: (value) => _proveedor = value,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Lista de sugerencias
            Expanded(
              child: _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : (_tipoSugerencia == 'ventas' ? _sugerencias : _productosStockBajo).isEmpty
                      ? const Center(
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Icon(Icons.lightbulb_outline, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No hay sugerencias disponibles'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: (_tipoSugerencia == 'ventas' ? _sugerencias : _productosStockBajo).length,
                          itemBuilder: (context, index) {
                            final item = (_tipoSugerencia == 'ventas' ? _sugerencias : _productosStockBajo)[index];
                            final producto = item['producto'] as Producto;
                            
                            return Card(
                              margin: const EdgeInsets.only(bottom: 8),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: Colors.blue.shade100,
                                  child: Text(
                                    producto.nombre.substring(0, 1).toUpperCase(),
                                    style: TextStyle(
                                      color: Colors.blue.shade700,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                title: Text(
                                  producto.nombre,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('Código: ${producto.codigo}'),
                                    if (_tipoSugerencia == 'ventas') ...[
                                      Text('Vendido: ${item['cantidadVendida'].toStringAsFixed(1)} unidades'),
                                      Text('Stock actual: ${item['stockActual'].toStringAsFixed(1)}'),
                                    ] else ...[
                                      Text('Stock actual: ${item['stockActual'].toStringAsFixed(1)}'),
                                      Text('Stock mínimo: ${item['stockMinimo'].toStringAsFixed(1)}'),
                                    ],
                                    Text('Cantidad sugerida: ${item['cantidadNecesaria'].toStringAsFixed(1)}'),
                                  ],
                                ),
                                trailing: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      'Bs ${item['subtotalSugerido'].toStringAsFixed(2)}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                      decoration: BoxDecoration(
                                        color: Colors.orange.shade100,
                                        borderRadius: BorderRadius.circular(8),
                                      ),
                                      child: Text(
                                        'Prioridad: ${item['prioridad'].toStringAsFixed(1)}',
                                        style: TextStyle(
                                          fontSize: 10,
                                          color: Colors.orange.shade700,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
            ),
            
            const Divider(),
            
            // Botones de acción
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total: Bs ${((_tipoSugerencia == 'ventas' ? _sugerencias : _productosStockBajo)
                      .fold<double>(0.0, (sum, item) => sum + (item['subtotalSugerido'] as double))).toStringAsFixed(2)}',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                Row(
                  children: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                    const SizedBox(width: 8),
                    ElevatedButton.icon(
                      onPressed: _crearCompraAutomatica,
                      icon: const Icon(Icons.shopping_cart),
                      label: const Text('Crear Compra'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green,
                        foregroundColor: Colors.white,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}