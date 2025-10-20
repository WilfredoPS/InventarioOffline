import 'package:flutter/material.dart';
import '../models/tienda.dart';
import '../models/almacen.dart';
import '../models/transferencia.dart';
import '../services/reportes_service.dart';

class ReportesTransferenciasScreen extends StatefulWidget {
  final List<Tienda> tiendas;
  final List<Almacen> almacenes;

  const ReportesTransferenciasScreen({
    super.key,
    required this.tiendas,
    required this.almacenes,
  });

  @override
  State<ReportesTransferenciasScreen> createState() => _ReportesTransferenciasScreenState();
}

class _ReportesTransferenciasScreenState extends State<ReportesTransferenciasScreen> {
  final ReportesService _reportesService = ReportesService();
  
  List<Map<String, dynamic>> _reporte = [];
  bool _isLoading = false;
  
  String? _origenTipo;
  String? _origenId;
  String? _destinoTipo;
  String? _destinoId;
  DateTime? _fechaInicio;
  DateTime? _fechaFin;
  String? _estadoSeleccionado;

  final List<String> _estados = ['todos', 'pendiente', 'en_transito', 'completada', 'anulada'];
  final List<String> _tiposUbicacion = ['todos', 'tienda', 'almacen'];

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() => _isLoading = true);
    
    try {
      final reporte = await _reportesService.getReporteTransferencias(
        origenTipo: _origenTipo,
        origenId: _origenId,
        destinoTipo: _destinoTipo,
        destinoId: _destinoId,
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
      _origenTipo = null;
      _origenId = null;
      _destinoTipo = null;
      _destinoId = null;
      _fechaInicio = null;
      _fechaFin = null;
      _estadoSeleccionado = 'todos';
    });
    _cargarReporte();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes de Transferencias'),
        backgroundColor: Colors.purple.shade700,
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
                            Icon(Icons.swap_horiz, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text(
                              'No hay transferencias que coincidan con los filtros',
                              style: TextStyle(fontSize: 18, color: Colors.grey),
                            ),
                          ],
                        ),
                      )
                    : _buildListaTransferencias(),
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
            
            // Filtro por origen
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _origenTipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo Origen',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._tiposUbicacion.skip(1).map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo == 'tienda' ? 'Tienda' : 'Almacén'),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _origenTipo = value;
                        _origenId = null;
                      });
                      _cargarReporte();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _origenId,
                    decoration: const InputDecoration(
                      labelText: 'Origen',
                      border: OutlineInputBorder(),
                    ),
                    items: _getUbicacionesOrigen(),
                    onChanged: (value) {
                      setState(() {
                        _origenId = value;
                      });
                      _cargarReporte();
                    },
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Filtro por destino
            Row(
              children: [
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _destinoTipo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo Destino',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on),
                    ),
                    items: [
                      const DropdownMenuItem(value: null, child: Text('Todos')),
                      ..._tiposUbicacion.skip(1).map((tipo) => DropdownMenuItem(
                        value: tipo,
                        child: Text(tipo == 'tienda' ? 'Tienda' : 'Almacén'),
                      )),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _destinoTipo = value;
                        _destinoId = null;
                      });
                      _cargarReporte();
                    },
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: DropdownButtonFormField<String>(
                    value: _destinoId,
                    decoration: const InputDecoration(
                      labelText: 'Destino',
                      border: OutlineInputBorder(),
                    ),
                    items: _getUbicacionesDestino(),
                    onChanged: (value) {
                      setState(() {
                        _destinoId = value;
                      });
                      _cargarReporte();
                    },
                  ),
                ),
              ],
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

  List<DropdownMenuItem<String>> _getUbicacionesOrigen() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: null, child: Text('Todas')),
    ];
    
    if (_origenTipo == 'tienda') {
      items.addAll(widget.tiendas.map((tienda) => DropdownMenuItem(
        value: tienda.codigo,
        child: Text(tienda.nombre),
      )));
    } else if (_origenTipo == 'almacen') {
      items.addAll(widget.almacenes.map((almacen) => DropdownMenuItem(
        value: almacen.codigo,
        child: Text(almacen.nombre),
      )));
    }
    
    return items;
  }

  List<DropdownMenuItem<String>> _getUbicacionesDestino() {
    final items = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: null, child: Text('Todas')),
    ];
    
    if (_destinoTipo == 'tienda') {
      items.addAll(widget.tiendas.map((tienda) => DropdownMenuItem(
        value: tienda.codigo,
        child: Text(tienda.nombre),
      )));
    } else if (_destinoTipo == 'almacen') {
      items.addAll(widget.almacenes.map((almacen) => DropdownMenuItem(
        value: almacen.codigo,
        child: Text(almacen.nombre),
      )));
    }
    
    return items;
  }

  Widget _buildListaTransferencias() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _reporte.length,
      itemBuilder: (context, index) {
        final item = _reporte[index];
        final transferencia = item['transferencia'] as Transferencia;
        final detalles = item['detalles'] as List<dynamic>;
        final origen = item['origen'];
        final destino = item['destino'];
        final empleado = item['empleado'];
        final totalProductos = item['totalProductos'] as int;
        final totalTransferencia = item['totalTransferencia'] as double;
        
        return Card(
          margin: const EdgeInsets.only(bottom: 8),
          child: ListTile(
            leading: CircleAvatar(
              backgroundColor: _getColorEstado(transferencia.estado),
              child: const Icon(
                Icons.swap_horiz,
                color: Colors.white,
              ),
            ),
            title: Text(
              'Transferencia #${transferencia.numeroTransferencia}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (origen != null) Text('Origen: ${origen.nombre}'),
                if (destino != null) Text('Destino: ${destino.nombre}'),
                if (empleado != null) Text('Empleado: ${empleado.nombres} ${empleado.apellidos}'),
                Text('Productos: $totalProductos'),
                Text('Fecha: ${_formatearFecha(transferencia.fechaTransferencia)}'),
                Text(
                  'Estado: ${transferencia.estado.toUpperCase()}',
                  style: TextStyle(
                    color: _getColorEstado(transferencia.estado),
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
                  '${totalTransferencia.toStringAsFixed(0)} uds',
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.purple,
                  ),
                ),
                Text(
                  'Unidades',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
            onTap: () => _mostrarDetalleTransferencia(item),
          ),
        );
      },
    );
  }

  Color _getColorEstado(String estado) {
    switch (estado) {
      case 'completada':
        return Colors.green;
      case 'en_transito':
        return Colors.orange;
      case 'pendiente':
        return Colors.blue;
      case 'anulada':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  String _formatearFecha(DateTime fecha) {
    return '${fecha.day}/${fecha.month}/${fecha.year} ${fecha.hour}:${fecha.minute.toString().padLeft(2, '0')}';
  }

  void _mostrarDetalleTransferencia(Map<String, dynamic> item) {
    final transferencia = item['transferencia'] as Transferencia;
    final detalles = item['detalles'] as List<dynamic>;
    final origen = item['origen'];
    final destino = item['destino'];
    final empleado = item['empleado'];
    
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Detalle Transferencia #${transferencia.numeroTransferencia}'),
        content: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              if (origen != null) Text('Origen: ${origen.nombre}'),
              if (destino != null) Text('Destino: ${destino.nombre}'),
              if (empleado != null) Text('Empleado: ${empleado.nombres} ${empleado.apellidos}'),
              Text('Fecha: ${_formatearFecha(transferencia.fechaTransferencia)}'),
              Text('Estado: ${transferencia.estado.toUpperCase()}'),
              if (transferencia.observaciones != null && transferencia.observaciones!.isNotEmpty)
                Text('Observaciones: ${transferencia.observaciones}'),
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
                    Text('Enviado: ${detalle.cantidadEnviada}'),
                    Text(' | Recibido: ${detalle.cantidadRecibida}'),
                  ],
                ),
              )),
              const Divider(),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'TOTAL ENVIADO:',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(
                    '${detalles.fold<double>(0, (sum, det) => sum + det.cantidadEnviada).toStringAsFixed(0)} unidades',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.purple,
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
