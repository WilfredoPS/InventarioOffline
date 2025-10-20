import 'package:flutter/material.dart';
import '../models/tienda.dart';
import '../models/almacen.dart';
import '../services/tienda_service.dart';
import '../services/almacen_service.dart';
import 'reportes_ventas_screen.dart';
import 'reportes_compras_screen.dart';
import 'reportes_transferencias_screen.dart';
import 'reporte_venta_global_dia_screen.dart';

class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final TiendaService _tiendaService = TiendaService();
  final AlmacenService _almacenService = AlmacenService();
  
  List<Tienda> _tiendas = [];
  List<Almacen> _almacenes = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    
    try {
      final tiendas = await _tiendaService.getAll();
      final almacenes = await _almacenService.getAll();
      
      setState(() {
        _tiendas = tiendas;
        _almacenes = almacenes;
        _isLoading = false;
      });
    } catch (e) {
      print('Error cargando datos: $e');
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes'),
        backgroundColor: Colors.purple.shade700,
        foregroundColor: Colors.white,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _loadData,
            tooltip: 'Actualizar Datos',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Reporte de Venta Global del Día
                  _buildReporteCard(
                    title: 'Venta Global del Día',
                    subtitle: 'Resumen de ventas del día actual',
                    icon: Icons.today,
                    color: Colors.green,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => const ReporteVentaGlobalDiaScreen(),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reportes de Ventas
                  _buildReporteCard(
                    title: 'Reportes de Ventas',
                    subtitle: 'Ventas filtradas por tienda y fecha',
                    icon: Icons.shopping_cart,
                    color: Colors.blue,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportesVentasScreen(
                            tiendas: _tiendas,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reportes de Compras
                  _buildReporteCard(
                    title: 'Reportes de Compras',
                    subtitle: 'Compras filtradas por tienda/almacén y fecha',
                    icon: Icons.shopping_bag,
                    color: Colors.orange,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportesComprasScreen(
                            tiendas: _tiendas,
                            almacenes: _almacenes,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // Reportes de Transferencias
                  _buildReporteCard(
                    title: 'Reportes de Transferencias',
                    subtitle: 'Transferencias entre almacenes y tiendas',
                    icon: Icons.swap_horiz,
                    color: Colors.purple,
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportesTransferenciasScreen(
                            tiendas: _tiendas,
                            almacenes: _almacenes,
                          ),
                        ),
                      );
                    },
                  ),
                  
                  const SizedBox(height: 32),
                  
                  // Resumen Rápido
                  _buildResumenRapido(),
                ],
              ),
            ),
    );
  }

  Widget _buildReporteCard({
    required String title,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildResumenRapido() {
    return Card(
      elevation: 4,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.analytics, color: Colors.purple.shade700),
                const SizedBox(width: 8),
                const Text(
                  'Resumen Rápido',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildResumenItem(
                    'Tiendas',
                    _tiendas.length.toString(),
                    Icons.store,
                    Colors.green,
                  ),
                ),
                Expanded(
                  child: _buildResumenItem(
                    'Almacenes',
                    _almacenes.length.toString(),
                    Icons.warehouse,
                    Colors.orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResumenItem(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      margin: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: [
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey.shade600,
            ),
          ),
        ],
      ),
    );
  }
}