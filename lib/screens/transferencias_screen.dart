import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/transferencia.dart';
import '../models/producto.dart';
import '../models/almacen.dart';
import '../models/tienda.dart';
import '../services/transferencia_service.dart';
import '../services/producto_service.dart';
import '../services/almacen_service.dart';
import '../services/tienda_service.dart';
import '../providers/auth_provider.dart';
import '../utils/inventario_notifier.dart';

class TransferenciasScreen extends StatefulWidget {
  const TransferenciasScreen({super.key});

  @override
  State<TransferenciasScreen> createState() => _TransferenciasScreenState();
}

class _TransferenciasScreenState extends State<TransferenciasScreen> {
  final TransferenciaService _transferenciaService = TransferenciaService();
  final ProductoService _productoService = ProductoService();
  final AlmacenService _almacenService = AlmacenService();
  final TiendaService _tiendaService = TiendaService();

  List<Transferencia> _transferencias = [];
  List<Producto> _productos = [];
  List<Almacen> _almacenes = [];
  List<Tienda> _tiendas = [];
  bool _isLoading = true;
  String _filtroEstado = 'todos';
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final transferencias = await _transferenciaService.getAll();
      final productos = await _productoService.getAll();
      final almacenes = await _almacenService.getAll();
      final tiendas = await _tiendaService.getAll();
      
      setState(() {
        _transferencias = transferencias;
        _productos = productos;
        _almacenes = almacenes;
        _tiendas = tiendas;
        _isLoading = false;
      });
      
      print('TransferenciasScreen._loadData: Cargadas ${_transferencias.length} transferencias');
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _isLoading = false);
      _showError('Error al cargar los datos: $e');
    }
  }

  List<Transferencia> _filtrarTransferencias() {
    var transferencias = _transferencias;
    
    // Filtrar por estado
    if (_filtroEstado != 'todos') {
      transferencias = transferencias.where((t) => t.estado == _filtroEstado).toList();
    }
    
    // Filtrar por búsqueda
    if (_searchController.text.isNotEmpty) {
      final searchTerm = _searchController.text.toLowerCase();
      transferencias = transferencias.where((t) {
        return t.numeroTransferencia.toLowerCase().contains(searchTerm) ||
               _getOrigenNombre(t).toLowerCase().contains(searchTerm) ||
               _getDestinoNombre(t).toLowerCase().contains(searchTerm);
      }).toList();
    }
    
    return transferencias;
  }

  String _getOrigenNombre(Transferencia transferencia) {
    if (transferencia.origenTipo == 'almacen') {
      final almacen = _almacenes.firstWhere(
        (a) => a.codigo == transferencia.origenId,
        orElse: () => Almacen()..nombre = 'Almacén no encontrado',
      );
      return almacen.nombre;
    } else {
      final tienda = _tiendas.firstWhere(
        (t) => t.codigo == transferencia.origenId,
        orElse: () => Tienda()..nombre = 'Tienda no encontrada',
      );
      return tienda.nombre;
    }
  }

  String _getDestinoNombre(Transferencia transferencia) {
    if (transferencia.destinoTipo == 'almacen') {
      final almacen = _almacenes.firstWhere(
        (a) => a.codigo == transferencia.destinoId,
        orElse: () => Almacen()..nombre = 'Almacén no encontrado',
      );
      return almacen.nombre;
    } else {
      final tienda = _tiendas.firstWhere(
        (t) => t.codigo == transferencia.destinoId,
        orElse: () => Tienda()..nombre = 'Tienda no encontrada',
      );
      return tienda.nombre;
    }
  }

  void _mostrarFormulario({Transferencia? transferencia}) {
    showDialog(
      context: context,
      builder: (context) => _FormularioTransferencia(
        transferencia: transferencia,
        productos: _productos,
        almacenes: _almacenes,
        tiendas: _tiendas,
        onTransferenciaSaved: () {
          Navigator.of(context).pop();
          _loadData();
        },
      ),
    );
  }

  void _completarTransferencia(Transferencia transferencia) async {
    try {
      await _transferenciaService.completarTransferencia(transferencia.id);
      _showSuccess('Transferencia completada exitosamente');
      _loadData();
      
      // Notificar cambio en inventario
      InventarioNotifier.notifyChange(context);
    } catch (e) {
      _showError('Error al completar transferencia: $e');
    }
  }

  void _anularTransferencia(Transferencia transferencia) async {
    try {
      await _transferenciaService.anularTransferencia(transferencia.id);
      _showSuccess('Transferencia anulada exitosamente');
      _loadData();
    } catch (e) {
      _showError('Error al anular transferencia: $e');
    }
  }

  Color _getEstadoColor(String estado) {
    switch (estado) {
      case 'pendiente':
        return Colors.orange;
      case 'en_transito':
        return Colors.blue;
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
      case 'en_transito':
        return 'En Tránsito';
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
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccess(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}';
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = Provider.of<AuthProvider>(context);
    final canManage = authProvider.hasPermission('realizar_transferencias');

    if (!canManage) {
      return const Scaffold(
        body: Center(
          child: Text('No tienes permisos para gestionar transferencias'),
        ),
      );
    }

    final transferenciasFiltradas = _filtrarTransferencias();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gestión de Transferencias'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                // Filtros
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      TextField(
                        controller: _searchController,
                        decoration: const InputDecoration(
                          labelText: 'Buscar transferencias',
                          prefixIcon: Icon(Icons.search),
                          border: OutlineInputBorder(),
                        ),
                        onChanged: (value) => setState(() {}),
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          const Text('Estado: '),
                          const SizedBox(width: 8),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _filtroEstado,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                                DropdownMenuItem(value: 'pendiente', child: Text('Pendiente')),
                                DropdownMenuItem(value: 'en_transito', child: Text('En Tránsito')),
                                DropdownMenuItem(value: 'completada', child: Text('Completada')),
                                DropdownMenuItem(value: 'anulada', child: Text('Anulada')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _filtroEstado = value ?? 'todos';
                                });
                              },
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                // Lista de transferencias
                Expanded(
                  child: transferenciasFiltradas.isEmpty
                      ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                              Icon(Icons.sync_alt, size: 64, color: Colors.grey),
                              SizedBox(height: 16),
                              Text('No hay transferencias registradas'),
                            ],
                          ),
                        )
                      : ListView.builder(
                          itemCount: transferenciasFiltradas.length,
                          itemBuilder: (context, index) {
                            final transferencia = transferenciasFiltradas[index];
                            return Card(
                              margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                              child: ListTile(
                                leading: CircleAvatar(
                                  backgroundColor: _getEstadoColor(transferencia.estado),
                                  child: Icon(
                                    Icons.sync_alt,
                                    color: Colors.white,
                                  ),
                                ),
                                title: Text(
                                  transferencia.numeroTransferencia,
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                                subtitle: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text('De: ${_getOrigenNombre(transferencia)}'),
                                    Text('A: ${_getDestinoNombre(transferencia)}'),
                                    Text('Fecha: ${_formatDate(transferencia.fechaTransferencia)}'),
                                    Text('Estado: ${_getEstadoDisplayName(transferencia.estado)}'),
                                  ],
                                ),
                                trailing: PopupMenuButton<String>(
                                  onSelected: (value) {
                                    switch (value) {
                                      case 'completar':
                                        _completarTransferencia(transferencia);
                                        break;
                                      case 'anular':
                                        _anularTransferencia(transferencia);
                                        break;
                                    }
                                  },
                                  itemBuilder: (context) => [
                                    if (transferencia.estado == 'pendiente')
                                      const PopupMenuItem(
                                        value: 'completar',
                                        child: Row(
                                          children: [
                                            Icon(Icons.check, color: Colors.green),
                                            SizedBox(width: 8),
                                            Text('Completar'),
                                          ],
                                        ),
                                      ),
                                    if (transferencia.estado != 'completada' && transferencia.estado != 'anulada')
                                      const PopupMenuItem(
                                        value: 'anular',
                                        child: Row(
                                          children: [
                                            Icon(Icons.cancel, color: Colors.red),
                                            SizedBox(width: 8),
                                            Text('Anular'),
                                          ],
                                        ),
                                      ),
                                  ],
                                ),
                                onTap: () {
                                  // Mostrar detalles de la transferencia
                                  _mostrarDetalles(transferencia);
                                },
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
        backgroundColor: Colors.purple.shade700,
      ),
    );
  }

  void _mostrarDetalles(Transferencia transferencia) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalles de ${transferencia.numeroTransferencia}'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Origen: ${_getOrigenNombre(transferencia)}'),
            Text('Destino: ${_getDestinoNombre(transferencia)}'),
            Text('Fecha: ${_formatDate(transferencia.fechaTransferencia)}'),
            Text('Estado: ${_getEstadoDisplayName(transferencia.estado)}'),
            if (transferencia.observaciones != null && transferencia.observaciones!.isNotEmpty)
              Text('Observaciones: ${transferencia.observaciones}'),
          const SizedBox(height: 16),
            const Text('Productos:', style: TextStyle(fontWeight: FontWeight.bold)),
            // Aquí se mostrarían los detalles de productos
            // Por simplicidad, solo mostramos el número de productos
            Text('${transferencia.numeroTransferencia} productos'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}

class _FormularioTransferencia extends StatefulWidget {
  final Transferencia? transferencia;
  final List<Producto> productos;
  final List<Almacen> almacenes;
  final List<Tienda> tiendas;
  final VoidCallback onTransferenciaSaved;

  const _FormularioTransferencia({
    required this.transferencia,
    required this.productos,
    required this.almacenes,
    required this.tiendas,
    required this.onTransferenciaSaved,
  });

  @override
  State<_FormularioTransferencia> createState() => _FormularioTransferenciaState();
}

class _FormularioTransferenciaState extends State<_FormularioTransferencia> {
  final _formKey = GlobalKey<FormState>();
  final TransferenciaService _transferenciaService = TransferenciaService();
  
  String _origenTipo = 'almacen';
  String? _origenId;
  String _destinoTipo = 'tienda';
  String? _destinoId;
  String _observaciones = '';
  List<DetalleTransferencia> _detalles = [];

  @override
  void initState() {
    super.initState();
    if (widget.transferencia != null) {
      _origenTipo = widget.transferencia!.origenTipo;
      _origenId = widget.transferencia!.origenId;
      _destinoTipo = widget.transferencia!.destinoTipo;
      _destinoId = widget.transferencia!.destinoId;
      _observaciones = widget.transferencia!.observaciones ?? '';
      _detalles = []; // Los detalles se cargan por separado
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.8,
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Text(
              widget.transferencia == null ? 'Nueva Transferencia' : 'Editar Transferencia',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            Expanded(
              child: Form(
                key: _formKey,
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      // Origen
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _origenTipo,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Origen',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'almacen', child: Text('Almacén')),
                                DropdownMenuItem(value: 'tienda', child: Text('Tienda')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _origenTipo = value!;
                                  _origenId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _origenId,
                              decoration: InputDecoration(
                                labelText: _origenTipo == 'almacen' ? 'Almacén Origen' : 'Tienda Origen',
                                border: const OutlineInputBorder(),
                              ),
                              items: (_origenTipo == 'almacen' ? widget.almacenes : widget.tiendas)
                                  .map<DropdownMenuItem<String>>((item) {
                                    if (item is Almacen) {
                                      return DropdownMenuItem(
                                        value: item.codigo,
                                        child: Text(item.nombre),
                                      );
                                    } else if (item is Tienda) {
                                      return DropdownMenuItem(
                                        value: item.codigo,
                                        child: Text(item.nombre),
                                      );
                                    }
                                    return DropdownMenuItem(
                                      value: '',
                                      child: Text('Error'),
                                    );
                                  })
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _origenId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecciona un origen';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Destino
                      Row(
                        children: [
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _destinoTipo,
                              decoration: const InputDecoration(
                                labelText: 'Tipo de Destino',
                                border: OutlineInputBorder(),
                              ),
                              items: const [
                                DropdownMenuItem(value: 'almacen', child: Text('Almacén')),
                                DropdownMenuItem(value: 'tienda', child: Text('Tienda')),
                              ],
                              onChanged: (value) {
                                setState(() {
                                  _destinoTipo = value!;
                                  _destinoId = null;
                                });
                              },
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: DropdownButtonFormField<String>(
                              value: _destinoId,
                              decoration: InputDecoration(
                                labelText: _destinoTipo == 'almacen' ? 'Almacén Destino' : 'Tienda Destino',
                                border: const OutlineInputBorder(),
                              ),
                              items: (_destinoTipo == 'almacen' ? widget.almacenes : widget.tiendas)
                                  .map<DropdownMenuItem<String>>((item) {
                                    if (item is Almacen) {
                                      return DropdownMenuItem(
                                        value: item.codigo,
                                        child: Text(item.nombre),
                                      );
                                    } else if (item is Tienda) {
                                      return DropdownMenuItem(
                                        value: item.codigo,
                                        child: Text(item.nombre),
                                      );
                                    }
                                    return DropdownMenuItem(
                                      value: '',
                                      child: Text('Error'),
                                    );
                                  })
                                  .toList(),
                              onChanged: (value) {
                                setState(() {
                                  _destinoId = value;
                                });
                              },
                              validator: (value) {
                                if (value == null || value.isEmpty) {
                                  return 'Selecciona un destino';
                                }
                                return null;
                              },
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 16),
                      // Observaciones
                      TextFormField(
                        initialValue: _observaciones,
                        decoration: const InputDecoration(
                          labelText: 'Observaciones',
                          border: OutlineInputBorder(),
                        ),
                        maxLines: 3,
                        onChanged: (value) => _observaciones = value,
                      ),
                      const SizedBox(height: 16),
                      // Botón para agregar productos
                      ElevatedButton.icon(
                        onPressed: _agregarProducto,
                        icon: const Icon(Icons.add),
                        label: const Text('Agregar Producto'),
                      ),
                      const SizedBox(height: 16),
                      // Lista de productos
                      if (_detalles.isNotEmpty)
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Productos a transferir:', style: TextStyle(fontWeight: FontWeight.bold)),
                            const SizedBox(height: 8),
                            ..._detalles.asMap().entries.map((entry) {
                              final index = entry.key;
                              final detalle = entry.value;
                              final producto = widget.productos.firstWhere(
                                (p) => p.codigo == detalle.productoId,
                                orElse: () => Producto()..nombre = 'Producto no encontrado',
                              );
                              return Card(
                                child: ListTile(
                                  title: Text(producto.nombre),
                                  subtitle: Text('Cantidad: ${detalle.cantidadEnviada}'),
                                  trailing: IconButton(
                                    icon: const Icon(Icons.delete, color: Colors.red),
                                    onPressed: () {
                                      setState(() {
                                        _detalles.removeAt(index);
                                      });
                                    },
                                  ),
                                ),
                              );
                            }).toList(),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: const Text('Cancelar'),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  onPressed: _guardarTransferencia,
                  child: Text(widget.transferencia == null ? 'Crear' : 'Actualizar'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _agregarProducto() {
    showDialog(
      context: context,
      builder: (context) => _DialogoAgregarDetalle(
        productos: widget.productos,
        onDetalleAgregado: (detalle) {
          setState(() {
            _detalles.add(detalle);
          });
        },
      ),
    );
  }

  Future<void> _guardarTransferencia() async {
    if (!_formKey.currentState!.validate()) return;
    
    if (_detalles.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Debe agregar al menos un producto'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    try {
      if (widget.transferencia == null) {
        // Crear nueva transferencia
        final numeroTransferencia = await _transferenciaService.generarNumeroTransferencia();
        final transferencia = Transferencia()
          ..numeroTransferencia = numeroTransferencia
          ..origenTipo = _origenTipo
          ..origenId = _origenId!
          ..destinoTipo = _destinoTipo
          ..destinoId = _destinoId!
          ..fechaTransferencia = DateTime.now()
          ..estado = 'pendiente'
          ..observaciones = _observaciones
          ..empleadoId = 'EMP001' // Usuario actual
          ..sincronizado = false;

        // Crear detalles
        final detalles = _detalles.map((detalle) {
          final detalleTransferencia = DetalleTransferencia()
            ..transferenciaId = numeroTransferencia
            ..productoId = detalle.productoId
            ..cantidadEnviada = detalle.cantidadEnviada
            ..cantidadRecibida = detalle.cantidadRecibida;
          return detalleTransferencia;
        }).toList();

        await _transferenciaService.crear(transferencia, detalles);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transferencia creada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
        
        // Notificar cambio en inventario
        InventarioNotifier.notifyChange(context);
      } else {
        // Actualizar transferencia existente
        widget.transferencia!.origenTipo = _origenTipo;
        widget.transferencia!.origenId = _origenId!;
        widget.transferencia!.destinoTipo = _destinoTipo;
        widget.transferencia!.destinoId = _destinoId!;
        widget.transferencia!.observaciones = _observaciones;
        widget.transferencia!.sincronizado = false;

        await _transferenciaService.actualizar(widget.transferencia!);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Transferencia actualizada exitosamente'),
            backgroundColor: Colors.green,
          ),
        );
      }

      widget.onTransferenciaSaved();
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar transferencia: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}

class _DialogoAgregarDetalle extends StatefulWidget {
  final List<Producto> productos;
  final Function(DetalleTransferencia) onDetalleAgregado;

  const _DialogoAgregarDetalle({
    required this.productos,
    required this.onDetalleAgregado,
  });

  @override
  State<_DialogoAgregarDetalle> createState() => _DialogoAgregarDetalleState();
}

class _DialogoAgregarDetalleState extends State<_DialogoAgregarDetalle> {
  String? _productoId;
  double _cantidad = 1.0;

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Agregar Producto'),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _productoId,
            decoration: const InputDecoration(
              labelText: 'Producto',
              border: OutlineInputBorder(),
            ),
            items: widget.productos.map((producto) {
              return DropdownMenuItem(
                value: producto.codigo,
                child: Text(producto.nombre),
              );
            }).toList(),
            onChanged: (value) {
              setState(() {
                _productoId = value;
              });
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Selecciona un producto';
              }
              return null;
            },
          ),
          const SizedBox(height: 16),
          TextFormField(
            initialValue: _cantidad.toString(),
            decoration: const InputDecoration(
              labelText: 'Cantidad',
              border: OutlineInputBorder(),
            ),
            keyboardType: TextInputType.number,
            onChanged: (value) {
              _cantidad = double.tryParse(value) ?? 1.0;
            },
            validator: (value) {
              if (value == null || value.isEmpty) {
                return 'Ingresa una cantidad';
              }
              final cantidad = double.tryParse(value);
              if (cantidad == null || cantidad <= 0) {
                return 'La cantidad debe ser mayor a 0';
              }
              return null;
            },
          ),
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        ElevatedButton(
          onPressed: () {
            if (_productoId != null && _cantidad > 0) {
              final detalle = DetalleTransferencia()
                ..productoId = _productoId!
                ..cantidadEnviada = _cantidad
                ..cantidadRecibida = _cantidad;
              
              widget.onDetalleAgregado(detalle);
              Navigator.of(context).pop();
            }
          },
          child: const Text('Agregar'),
        ),
      ],
    );
  }
}

