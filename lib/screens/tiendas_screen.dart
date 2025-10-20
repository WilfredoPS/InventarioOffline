import 'package:flutter/material.dart';
import '../models/tienda.dart';
import '../services/tienda_service.dart';

class TiendasScreen extends StatefulWidget {
  const TiendasScreen({super.key});

  @override
  State<TiendasScreen> createState() => _TiendasScreenState();
}

class _TiendasScreenState extends State<TiendasScreen> {
  final TiendaService _tiendaService = TiendaService();
  final _searchController = TextEditingController();
  
  List<Tienda> _tiendas = [];
  List<Tienda> _tiendasFiltradas = [];
  bool _isLoading = true;
  bool _soloActivas = false;

  @override
  void initState() {
    super.initState();
    _loadTiendas();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _loadTiendas() async {
    setState(() => _isLoading = true);
    try {
      _tiendas = await _tiendaService.getAll();
      _filtrarTiendas();
    } catch (e) {
      _showError('Error cargando tiendas: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filtrarTiendas() {
    setState(() {
      _tiendasFiltradas = _tiendas.where((t) {
        final matchBusqueda = _searchController.text.isEmpty ||
            t.nombre.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            t.codigo.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            t.direccion.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchEstado = !_soloActivas || t.activo;

        return matchBusqueda && matchEstado;
      }).toList();
    });
  }

  Future<void> _mostrarFormulario({Tienda? tienda}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _FormularioTienda(tienda: tienda),
    );

    if (resultado == true) {
      _loadTiendas();
    }
  }

  Future<void> _eliminarTienda(Tienda tienda) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Tienda'),
        content: Text('¿Está seguro de eliminar ${tienda.nombre}?'),
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
        await _tiendaService.eliminar(tienda.id);
        _showSuccess('Tienda eliminada');
        _loadTiendas();
      } catch (e) {
        _showError('Error eliminando tienda: $e');
      }
    }
  }

  Future<void> _toggleEstado(Tienda tienda) async {
    try {
      tienda.activo = !tienda.activo;
      await _tiendaService.actualizar(tienda);
      _showSuccess(tienda.activo ? 'Tienda activada' : 'Tienda desactivada');
      _loadTiendas();
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
                              _filtrarTiendas();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _filtrarTiendas(),
                ),
                const SizedBox(height: 8),
                Row(
                  children: [
                    Expanded(
                      child: FilterChip(
                        label: Text(_soloActivas ? 'Solo Activas' : 'Todas'),
                        selected: _soloActivas,
                        onSelected: (selected) {
                          setState(() => _soloActivas = selected);
                          _filtrarTiendas();
                        },
                        avatar: Icon(_soloActivas ? Icons.check_circle : Icons.radio_button_unchecked),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_tiendasFiltradas.length} tiendas'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _tiendasFiltradas.isEmpty
                    ? const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.store, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay tiendas'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _tiendasFiltradas.length,
                        itemBuilder: (context, index) {
                          final tienda = _tiendasFiltradas[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: tienda.activo 
                                    ? Colors.green.shade100 
                                    : Colors.red.shade100,
                                child: Icon(
                                  Icons.store,
                                  color: tienda.activo 
                                      ? Colors.green.shade700 
                                      : Colors.red.shade700,
                                ),
                              ),
                              title: Text(
                                tienda.nombre,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Código: ${tienda.codigo}'),
                                  Text('Dirección: ${tienda.direccion}'),
                                  if (tienda.telefono != null)
                                    Text('Teléfono: ${tienda.telefono}'),
                                  Text('Responsable: ${tienda.responsable}'),
                                  Row(
                                    children: [
                                      Icon(
                                        tienda.activo ? Icons.check_circle : Icons.cancel,
                                        size: 16,
                                        color: tienda.activo ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
                                      Text(
                                        tienda.activo ? 'Activa' : 'Inactiva',
                                        style: TextStyle(
                                          color: tienda.activo ? Colors.green : Colors.red,
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
                                        Icon(tienda.activo ? Icons.pause : Icons.play_arrow),
                                        const SizedBox(width: 8),
                                        Text(tienda.activo ? 'Desactivar' : 'Activar'),
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
                                    _mostrarFormulario(tienda: tienda);
                                  } else if (value == 'toggle_estado') {
                                    _toggleEstado(tienda);
                                  } else if (value == 'eliminar') {
                                    _eliminarTienda(tienda);
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

class _FormularioTienda extends StatefulWidget {
  final Tienda? tienda;

  const _FormularioTienda({this.tienda});

  @override
  State<_FormularioTienda> createState() => _FormularioTiendaState();
}

class _FormularioTiendaState extends State<_FormularioTienda> {
  final _formKey = GlobalKey<FormState>();
  final TiendaService _tiendaService = TiendaService();

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
    _codigoController = TextEditingController(text: widget.tienda?.codigo ?? '');
    _nombreController = TextEditingController(text: widget.tienda?.nombre ?? '');
    _direccionController = TextEditingController(text: widget.tienda?.direccion ?? '');
    _telefonoController = TextEditingController(text: widget.tienda?.telefono ?? '');
    _responsableController = TextEditingController(text: widget.tienda?.responsable ?? '');
    
    if (widget.tienda != null) {
      _activo = widget.tienda!.activo;
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
      final tienda = widget.tienda ?? Tienda();
      tienda.codigo = _codigoController.text.trim();
      tienda.nombre = _nombreController.text.trim();
      tienda.direccion = _direccionController.text.trim();
      tienda.telefono = _telefonoController.text.trim().isEmpty ? null : _telefonoController.text.trim();
      tienda.responsable = _responsableController.text.trim();
      tienda.activo = _activo;

      if (widget.tienda == null) {
        await _tiendaService.crear(tienda);
      } else {
        await _tiendaService.actualizar(tienda);
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
                  widget.tienda == null ? 'Nueva Tienda' : 'Editar Tienda',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codigoController,
                  decoration: const InputDecoration(
                    labelText: 'Código',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: T001',
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
                    hintText: 'Ej: Tienda Centro',
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
                    hintText: 'Ej: Av. Principal #123',
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
                    hintText: 'Ej: Juan Pérez',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Tienda Activa'),
                  subtitle: Text(_activo ? 'La tienda está operativa' : 'La tienda está inactiva'),
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





