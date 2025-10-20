import 'package:flutter/material.dart';
import '../models/almacen.dart';
import '../services/almacen_service.dart';

class AlmacenesScreen extends StatefulWidget {
  const AlmacenesScreen({super.key});

  @override
  State<AlmacenesScreen> createState() => _AlmacenesScreenState();
}

class _AlmacenesScreenState extends State<AlmacenesScreen> {
  final AlmacenService _almacenService = AlmacenService();
  final _searchController = TextEditingController();
  
  List<Almacen> _almacenes = [];
  List<Almacen> _almacenesFiltrados = [];
  bool _isLoading = true;
  bool _soloActivos = false;

  @override
  void initState() {
    super.initState();
    _loadAlmacenes();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadAlmacenes() async {
    print('AlmacenesScreen._loadAlmacenes: Iniciando carga de almacenes...');
    setState(() => _isLoading = true);
    try {
      _almacenes = await _almacenService.getAll();
      print('AlmacenesScreen._loadAlmacenes: Almacenes cargados: ${_almacenes.length}');
      for (int i = 0; i < _almacenes.length; i++) {
        print('AlmacenesScreen._loadAlmacenes: [$i] ${_almacenes[i].nombre} (${_almacenes[i].codigo})');
      }
      _filtrarAlmacenes();
    } catch (e) {
      print('AlmacenesScreen._loadAlmacenes: Error: $e');
      _showError('Error cargando almacenes: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filtrarAlmacenes() {
    print('AlmacenesScreen._filtrarAlmacenes: Filtrando ${_almacenes.length} almacenes');
    print('AlmacenesScreen._filtrarAlmacenes: Búsqueda: "${_searchController.text}"');
    print('AlmacenesScreen._filtrarAlmacenes: Solo activos: $_soloActivos');
    
    setState(() {
      _almacenesFiltrados = _almacenes.where((a) {
        final matchBusqueda = _searchController.text.isEmpty ||
            a.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            a.codigo.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            a.direccion.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchEstado = !_soloActivos || a.activo;

        return matchBusqueda && matchEstado;
      }).toList();
    });
    
    print('AlmacenesScreen._filtrarAlmacenes: Almacenes filtrados: ${_almacenesFiltrados.length}');
  }

  Future<void> _mostrarFormulario({Almacen? almacen}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _FormularioAlmacen(almacen: almacen),
    );

    if (resultado == true) {
      _loadAlmacenes();
    }
  }

  Future<void> _eliminarAlmacen(Almacen almacen) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Almacén'),
        content: Text('¿Está seguro de eliminar ${almacen.nombre}?'),
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
        await _almacenService.eliminar(almacen.id);
        _showSuccess('Almacén eliminado');
        _loadAlmacenes();
      } catch (e) {
        _showError('Error eliminando almacén: $e');
      }
    }
  }

  Future<void> _toggleEstado(Almacen almacen) async {
    try {
      almacen.activo = !almacen.activo;
      await _almacenService.actualizar(almacen);
      _showSuccess(almacen.activo ? 'Almacén activado' : 'Almacén desactivado');
      _loadAlmacenes();
    } catch (e) {
      _showError('Error actualizando estado: $e');
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
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar por nombre, código o dirección',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filtrarAlmacenes();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _filtrarAlmacenes(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text(_soloActivos ? 'Solo Activos' : 'Todos'),
                        selected: _soloActivos,
                        onSelected: (selected) {
                          setState(() => _soloActivos = selected);
                          _filtrarAlmacenes();
                        },
                        avatar: Icon(_soloActivos ? Icons.check_circle : Icons.radio_button_unchecked),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_almacenesFiltrados.length} almacenes'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _almacenesFiltrados.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.warehouse, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay almacenes'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _almacenesFiltrados.length,
                        itemBuilder: (context, index) {
                          final almacen = _almacenesFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: almacen.activo 
                                    ? Colors.blue.shade100 
                                    : Colors.red.shade100,
                                child: Icon(
                                  Icons.warehouse,
                                  color: almacen.activo 
                                      ? Colors.blue.shade700 
                                      : Colors.red.shade700,
                                ),
                              ),
                              title: Text(
                                almacen.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Código: ${almacen.codigo}'),
                                  Text('Dirección: ${almacen.direccion}'),
                                  if (almacen.telefono != null)
                                    Text('Teléfono: ${almacen.telefono}'),
                                  Text('Responsable: ${almacen.responsable}'),
                                  Row(
                                    children: [
                                      Icon(
                                        almacen.activo ? Icons.check_circle : Icons.cancel,
                                        size: 16,
                                        color: almacen.activo ? Colors.blue : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        almacen.activo ? 'Activo' : 'Inactivo',
                                        style: TextStyle(
                                          color: almacen.activo ? Colors.blue : Colors.red,
                                          fontWeight: FontWeight.bold,
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
                                  PopupMenuItem(
                                    value: 'toggle_estado',
                                    child: Row(
                                      children: [
                                        Icon(almacen.activo ? Icons.pause : Icons.play_arrow),
                                        const SizedBox(width: 8),
                                        Text(almacen.activo ? 'Desactivar' : 'Activar'),
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
                                    _mostrarFormulario(almacen: almacen);
                                  } else if (value == 'toggle_estado') {
                                    _toggleEstado(almacen);
                                  } else if (value == 'eliminar') {
                                    _eliminarAlmacen(almacen);
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

class _FormularioAlmacen extends StatefulWidget {
  final Almacen? almacen;

  const _FormularioAlmacen({this.almacen});

  @override
  State<_FormularioAlmacen> createState() => _FormularioAlmacenState();
}

class _FormularioAlmacenState extends State<_FormularioAlmacen> {
  final _formKey = GlobalKey<FormState>();
  final AlmacenService _almacenService = AlmacenService();

  late TextEditingController _codigoController;
  late TextEditingController _nombreController;
  late TextEditingController _direccionController;
  late TextEditingController _telefonoController;
  late TextEditingController _responsableController;
  
  bool _activo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.almacen?.codigo ?? '');
    _nombreController = TextEditingController(text: widget.almacen?.nombre ?? '');
    _direccionController = TextEditingController(text: widget.almacen?.direccion ?? '');
    _telefonoController = TextEditingController(text: widget.almacen?.telefono ?? '');
    _responsableController = TextEditingController(text: widget.almacen?.responsable ?? '');
    
    if (widget.almacen != null) {
      _activo = widget.almacen!.activo;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombreController.dispose();
    _direccionController.dispose();
    _telefonoController.dispose();
    _responsableController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final almacen = widget.almacen ?? Almacen();
      almacen.codigo = _codigoController.text.trim();
      almacen.nombre = _nombreController.text.trim();
      almacen.direccion = _direccionController.text.trim();
      almacen.telefono = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();
      almacen.responsable = _responsableController.text.trim();
      almacen.activo = _activo;

      if (widget.almacen == null) {
        await _almacenService.crear(almacen);
      } else {
        await _almacenService.actualizar(almacen);
      }

      if (mounted) {
        Navigator.pop(context, true);
      }
    } catch (e) {
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
                  widget.almacen == null ? 'Nuevo Almacén' : 'Editar Almacén',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: ALM001',
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
                    hintText: 'Ej: Almacén Central',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _direccionController,
                  decoration: const InputDecoration(
                    labelText: 'Dirección',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Calle Industrial #456',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _telefonoController,
                  decoration: const InputDecoration(
                    labelText: 'Teléfono (Opcional)',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: 555-1234',
                  ),
                  keyboardType: TextInputType.phone,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _responsableController,
                  decoration: const InputDecoration(
                    labelText: 'Responsable',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: María González',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Almacén Activo'),
                  subtitle: Text(_activo ? 'El almacén está operativo' : 'El almacén está inactivo'),
                  value: _activo,
                  onChanged: (value) {
                    setState(() {
                      _activo = value;
                    });
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





