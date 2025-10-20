import 'package:flutter/material.dart';
import '../models/tienda.dart';
import '../models/almacen.dart';
import '../models/compra.dart';
import '../services/reportes_service.dart';

class ReportesComprasScreen extends StatefulWidget {
  final List<Tienda> tiendas;
  final List<Almacen> almacenes;

  const ReportesComprasScreen({
    super.key,
    required this.tiendas,
    required this.almacenes,
  });

  @override
  State<ReportesComprasScreen> createState() => _ReportesComprasScreenState();
}

class _ReportesComprasScreenState extends State<ReportesComprasScreen> {
  final ReportesService _reportesService = ReportesService();
  
  List<Map<String, dynamic>> _reporte = [];
  bool _isLoading = false;
  
  String? _tiendaSeleccionada;
  String? _almacenSeleccionado;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _estadoSeleccionado;
  String _tipoDestino = 'todos'; // todos, tienda, almacen

  final List<String> _estados = ['todos', 'pendiente', 'completada', 'anulada'];

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() => _isLoading = true);
    
    try {
      final reporte = await _reportesService.getReporteCompras(
        tiendaId: _tipoDestino == 'tienda' ? _tiendaSeleccionada : null,
        almacenId: _tipoDestino == 'almacen' ? _almacenSeleccionado : null,
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
        estado: _estadoSeleccionado == 'todos' ? null : _estadoSeleccionado,
      );
      
      setState(() {
        _reporte = reporte;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando reporte: $e');
      setState(() => _isLoading = false);
      _mostrarError('Error cargando reporte: $e');
    }
  }

  Future<void> _seleccionarFechaInicio() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaInicio ?? DateTime.now(),
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaInicio = fecha;
      });
      _cargarReporte();
    }
  }

  Future<void> _seleccionarFechaFin() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaFin ?? DateTime.now(),
      firstDate: _fechaInicio ?? DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (fecha != null) {
      setState(() {
        _fechaFin = fecha;
      });
      _cargarReporte();
    }
  }

  void _mostrarError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _limpiarFiltros() {
    setState(() {
      _tiendaSeleccionada = null;
      _almacenSeleccionado = null;
      _fechaInicio = null;
      _fechaFin = null;
      _estadoSeleccionado = 'todos';
      _tipoDestino = 'todos';
    });
    _cargarReporte();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Compras'),
        backgroundColor: Colors.orange.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReporte,
            tooltip: 'Actualizar Reporte',
          ),
        ],
      ),
      body: Column(
        children: [
          // Filtros
          _buildFiltros(),
          
          // Contenido
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _reporte.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.shopping_bag, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay compras que coincidan con los filtros',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : _buildListaCompras(),
          ),
        ],
      ),
    );
  }

  Widget _buildFiltros() {
    return Card(
      margin: const EdgeInsets.all(16),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Filtros',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            
            // Filtro por tipo de destino
            DropdownButtonFormField<String>(
              value: _tipoDestino,
              decoration: const InputDecoration(
                labelText: 'Tipo de Destino',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.location_on),
              ),
              items: const [
                DropdownMenuItem(value: 'todos', child: Text('Todos')),
                DropdownMenuItem(value: 'tienda', child: Text('Tienda')),
                DropdownMenuItem(value: 'almacen', child: Text('Almacén')),
              ],
              onChanged: (value) {
                setState(() {
                  _tipoDestino = value!;
                  _tiendaSeleccionada = null;
                  _almacenSeleccionado = null;
                });
                _cargarReporte();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Filtro por tienda o almacén
            if (_tipoDestino == 'tienda')
              DropdownButtonFormField<String>(
                value: _tiendaSeleccionada,
                decoration: const InputDecoration(
                  labelText: 'Tienda',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.store),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todas las tiendas'),
                  ),
                  ...widget.tiendas.map((tienda) => DropdownMenuItem(
                    value: tienda.codigo,
                    child: Text(tienda.nombre),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _tiendaSeleccionada = value;
                  });
                  _cargarReporte();
                },
              )
            else if (_tipoDestino == 'almacen')
              DropdownButtonFormField<String>(
                value: _almacenSeleccionado,
                decoration: const InputDecoration(
                  labelText: 'Almacén',
                  border: OutlineInputBorder(),
                  prefixIcon: Icon(Icons.warehouse),
                ),
                items: [
                  const DropdownMenuItem(
                    value: null,
                    child: Text('Todos los almacenes'),
                  ),
                  ...widget.almacenes.map((almacen) => DropdownMenuItem(
                    value: almacen.codigo,
                    child: Text(almacen.nombre),
                  )),
                ],
                onChanged: (value) {
                  setState(() {
                    _almacenSeleccionado = value;
                  });
                  _cargarReporte();
                },
              ),
            
            const SizedBox(height: 16),
            
            // Filtro por fechas
            Row(
              children: [
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFechaInicio,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha Inicio',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _fechaInicio != null
                            ? '${_fechaInicio!.day}/${_fechaInicio!.month}/${_fechaInicio!.year}'
                            : 'Seleccionar fecha',
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: InkWell(
                    onTap: _seleccionarFechaFin,
                    child: InputDecorator(
                      decoration: const InputDecoration(
                        labelText: 'Fecha Fin',
                        border: OutlineInputBorder(),
                        prefixIcon: Icon(Icons.calendar_today),
                      ),
                      child: Text(
                        _fechaFin != null
                            ? '${_fechaFin!.day}/${_fechaFin!.month}/${_fechaFin!.year}'
                            : 'Seleccionar fecha',
                      ),
                    ),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Filtro por estado
            DropdownButtonFormField<String>(
              value: _estadoSeleccionado ?? 'todos',
              decoration: const InputDecoration(
                labelText: 'Estado',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.flag),
              ),
              items: _estados.map((estado) => DropdownMenuItem(
                value: estado,
                child: Text(estado.toUpperCase()),
              )).toList(),
              onChanged: (value) {
                setState(() {
                  _estadoSeleccionado = value;
                });
                _cargarReporte();
              },
            ),
            
            const SizedBox(height: 16),
            
            // Botón limpiar filtros
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton.icon(
                  onPressed: _limpiarFiltros,
                  icon: const Icon(Icons.clear),
                  label: const Text('Limpiar Filtros'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildListaCompras() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reporte.length,
      itemBuilder: (context, index) {
        final item = _reporte[index];
        final compra = item['compra'] as Compra;
        final detalles = item['detalles'] as List<dynamic>;
        final destino = item['destino'];
        final empleado = item['empleado'];
        final totalCompra = item['totalCompra'] as double;
        final totalProductos = item['totalProductos'] as int;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorEstado(compra.estado),
              child: Icon(
                compra.destinoTipo == 'tienda' ? Icons.store : Icons.warehouse,
                color: Colors.white,
              ),
            ),
            title: Text(
              'Compra #${compra.numeroCompra}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (destino != null) Text('Destino: ${destino.nombre}'),
                if (empleado != null) Text('Empleado: ${empleado.nombres} ${empleado.apellidos}'),
                Text('Proveedor: ${compra.proveedor}'),
                Text('Productos: $totalProductos'),
                Text('Fecha: ${_formatearFecha(compra.fechaCompra)}'),
                Text(
                  'Estado: ${compra.estado.toUpperCase()}',
                  style: TextStyle(
                    color: _getColorEstado(compra.estado),
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            trailing: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'Bs ${totalCompra.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange,
                  ),
                ),
                Text(
                  'Total',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            onTap: () => _mostrarDetalleCompra(item),
          ),
        );
      },
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'completada':
        return Colors.green;
      case 'pendiente':
        return Colors.orange;
      case 'anulada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  void _mostrarDetalleCompra(Map<String, dynamic> item) {
    final compra = item['compra'] as Compra;
    final detalles = item['detalles'] as List<dynamic>;
    final destino = item['destino'];
    final empleado = item['empleado'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle Compra #${compra.numeroCompra}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (destino != null) Text('Destino: ${destino.nombre}'),
              if (empleado != null) Text('Empleado: ${empleado.nombres} ${empleado.apellidos}'),
              Text('Proveedor: ${compra.proveedor}'),
              Text('Factura: ${compra.numeroFactura}'),
              Text('Fecha: ${_formatearFecha(compra.fechaCompra)}'),
              Text('Estado: ${compra.estado.toUpperCase()}'),
              if (compra.observaciones != null && compra.observaciones!.isNotEmpty)
                Text('Observaciones: ${compra.observaciones}'),
              const SizedBox(height: 16),
              const Text(
                'Productos:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              ...detalles.map((detalle) => Padding(
                padding: const EdgeInsets.only(bottom: 4),
                child: Row(
                  children: [
                    Expanded(child: Text(detalle.productoId)),
                    Text('${detalle.cantidad} x Bs ${detalle.precioUnitario}'),
                    Text(' = Bs ${(detalle.cantidad * detalle.precioUnitario).toStringAsFixed(2)}'),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal:'),
                  Text('Bs ${compra.subtotal.toStringAsFixed(2)}'),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('IVA (19%):'),
                  Text('Bs ${(compra.total - compra.subtotal).toStringAsFixed(2)}'),
                ],
              ),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Bs ${compra.total.toStringAsFixed(2)}',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.orange,
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
            child: const Text('Cerrar'),
          ),
        ],
      ),
    );
  }
}
