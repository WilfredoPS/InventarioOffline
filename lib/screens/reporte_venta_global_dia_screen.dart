import 'package:flutter/material.dart';
import '../services/reportes_service.dart';

class ReporteVentaGlobalDiaScreen extends StatefulWidget {
  const ReporteVentaGlobalDiaScreen({super.key});

  @override
  State<ReporteVentaGlobalDiaScreen> createState() => _ReporteVentaGlobalDiaScreenState();
}

class _ReporteVentaGlobalDiaScreenState extends State<ReporteVentaGlobalDiaScreen> {
  final ReportesService _reportesService = ReportesService();
  
  Map<String, dynamic>? _reporte;
  bool _isLoading = true;
  DateTime _fechaSeleccionada = DateTime.now();

  @override
  void initState() {
    super.initState();
    _cargarReporte();
  }

  Future<void> _cargarReporte() async {
    setState(() => _isLoading = true);
    
    try {
      final reporte = await _reportesService.getReporteVentaGlobalDia(_fechaSeleccionada);
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

  Future<void> _seleccionarFecha() async {
    final fecha = await showDatePicker(
      context: context,
      initialDate: _fechaSeleccionada,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    
    if (fecha != null && fecha != _fechaSeleccionada) {
      setState(() {
        _fechaSeleccionada = fecha;
      });
      _cargarReporte();
    }
  }

  void _mostrarError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Venta Global del Día'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _cargarReporte,
            tooltip: 'Actualizar Reporte',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _reporte == null
              ? const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.error, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No se pudo cargar el reporte',
                        style: TextStyle(fontSize: 18, color: Colors.grey),
                      ),
                    ],
                  ),
                )
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Selector de fecha
                      Card(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Row(
                            children: [
                              const Icon(Icons.calendar_today, color: Colors.green),
                              const SizedBox(width: 12),
                              const Text(
                                'Fecha: ',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              TextButton(
                                onPressed: _seleccionarFecha,
                                child: Text(
                                  '${_fechaSeleccionada.day}/${_fechaSeleccionada.month}/${_fechaSeleccionada.year}',
                                  style: const TextStyle(fontSize: 16),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      
                      const SizedBox(height: 16),
                      
                      // Resumen principal
                      _buildResumenPrincipal(),
                      
                      const SizedBox(height: 16),
                      
                      // Ventas por tienda
                      _buildVentasPorTienda(),
                      
                      const SizedBox(height: 16),
                      
                      // Detalle de ventas
                      _buildDetalleVentas(),
                    ],
                  ),
                ),
    );
  }

  Widget _buildResumenPrincipal() {
    final totalVentas = (_reporte!['totalVentas'] as num).toDouble();
    final totalTransacciones = _reporte!['totalTransacciones'] as int;
    final totalProductos = _reporte!['totalProductos'] as int;
    final promedioVenta = (_reporte!['promedioVenta'] as num).toDouble();
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Resumen del Día',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaCard(
                    'Total Ventas',
                    'Bs ${totalVentas.toStringAsFixed(2)}',
                    Icons.attach_money,
                    Colors.green,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricaCard(
                    'Transacciones',
                    totalTransacciones.toString(),
                    Icons.receipt,
                    Colors.blue,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _buildMetricaCard(
                    'Productos Vendidos',
                    totalProductos.toString(),
                    Icons.inventory,
                    Colors.orange,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _buildMetricaCard(
                    'Promedio por Venta',
                    'Bs ${promedioVenta.toStringAsFixed(2)}',
                    Icons.trending_up,
                    Colors.purple,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricaCard(String titulo, String valor, IconData icono, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icono, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildVentasPorTienda() {
    final ventasPorTienda = _reporte!['ventasPorTienda'] as Map<String, int>;
    final ingresosPorTienda = _reporte!['ingresosPorTienda'] as Map<String, num>;
    
    if (ventasPorTienda.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              const Icon(Icons.store, size: 48, color: Colors.grey),
              const SizedBox(height: 8),
              const Text(
                'No hay ventas registradas para este día',
                style: TextStyle(fontSize: 16, color: Colors.grey),
              ),
            ],
          ),
        ),
      );
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Ventas por Tienda',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...ventasPorTienda.entries.map((entry) {
              final tienda = entry.key;
              final cantidadVentas = entry.value;
              final ingresos = (ingresosPorTienda[tienda] ?? 0).toDouble();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.store, color: Colors.green, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        tienda,
                        style: const TextStyle(fontWeight: FontWeight.w500),
                      ),
                    ),
                    Text(
                      '$cantidadVentas ventas',
                      style: TextStyle(color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 16),
                    Text(
                      'Bs ${ingresos.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildDetalleVentas() {
    final detalleVentas = _reporte!['detalleVentas'] as List<Map<String, dynamic>>;
    
    if (detalleVentas.isEmpty) {
      return const SizedBox.shrink();
    }
    
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Detalle de Ventas',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ...detalleVentas.take(10).map((item) {
              final venta = item['venta'];
              final tienda = item['tienda'];
              final totalVenta = (item['totalVenta'] as num).toDouble();
              
              return Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  children: [
                    const Icon(Icons.receipt, color: Colors.blue, size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Venta #${venta.numeroVenta}',
                            style: const TextStyle(fontWeight: FontWeight.w500),
                          ),
                          if (tienda != null)
                            Text(
                              tienda.nombre,
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey.shade600,
                              ),
                            ),
                        ],
                      ),
                    ),
                    Text(
                      'Bs ${totalVenta.toStringAsFixed(2)}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
            
            if (detalleVentas.length > 10)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: Text(
                  '... y ${detalleVentas.length - 10} ventas más',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
