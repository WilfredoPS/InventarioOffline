import 'package:flutter/material.dart';
import '../models/empleado.dart';
import '../services/empleado_service.dart';
import '../services/tienda_service.dart';
import '../services/almacen_service.dart';

class EmpleadosScreen extends StatefulWidget {
  const EmpleadosScreen({super.key});

  @override
  State<EmpleadosScreen> createState() => _EmpleadosScreenState();
}

class _EmpleadosScreenState extends State<EmpleadosScreen> {
  final EmpleadoService _empleadoService = EmpleadoService();
  final TiendaService _tiendaService = TiendaService();
  final AlmacenService _almacenService = AlmacenService();
  final _searchController = TextEditingController();
  
  List<Empleado> _empleados = [];
  List<Empleado> _empleadosFiltrados = [];
  List<dynamic> _tiendas = [];
  List<dynamic> _almacenes = [];
  bool _isLoading = true;
  bool _soloActivos = false;

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
      _empleados = await _empleadoService.getAll();
      _tiendas = await _tiendaService.getAll();
      _almacenes = await _almacenService.getAll();
      _filtrarEmpleados();
    } catch (e) {
      _showError('Error cargando datos: $e');
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _filtrarEmpleados() {
    setState(() {
      _empleadosFiltrados = _empleados.where((e) {
        final matchBusqueda = _searchController.text.isEmpty ||
            e.nombres.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            e.apellidos.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            e.email.toLowerCase().contains(_searchController.text.toLowerCase()) ||
            e.codigo.toLowerCase().contains(_searchController.text.toLowerCase());
        
        final matchEstado = !_soloActivos || e.activo;

        return matchBusqueda && matchEstado;
      }).toList();
    });
  }

  Future<void> _mostrarFormulario({Empleado? empleado}) async {
    final resultado = await showDialog<bool>(
      context: context,
      builder: (context) => _FormularioEmpleado(
        empleado: empleado,
        tiendas: _tiendas,
        almacenes: _almacenes,
      ),
    );

    if (resultado == true) {
      _loadData();
    }
  }

  Future<void> _eliminarEmpleado(Empleado empleado) async {
    final confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Eliminar Empleado'),
        content: Text('¿Está seguro de eliminar ${empleado.nombres} ${empleado.apellidos}?'),
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
        await _empleadoService.eliminar(empleado.id);
        _showSuccess('Empleado eliminado');
        _loadData();
      } catch (e) {
        _showError('Error eliminando empleado: $e');
      }
    }
  }

  Future<void> _toggleEstado(Empleado empleado) async {
    try {
      empleado.activo = !empleado.activo;
      await _empleadoService.actualizar(empleado);
      _showSuccess(empleado.activo ? 'Empleado activado' : 'Empleado desactivado');
      _loadData();
    } catch (e) {
      _showError('Error actualizando estado: $e');
    }
  }

  String _getUbicacion(Empleado empleado) {
    if (empleado.tiendaId != null) {
      try {
        final tienda = _tiendas.firstWhere(
          (t) => t.codigo == empleado.tiendaId,
        );
        return tienda.nombre;
      } catch (e) {
        return 'Tienda no encontrada';
      }
    } else if (empleado.almacenId != null) {
      try {
        final almacen = _almacenes.firstWhere(
          (a) => a.codigo == empleado.almacenId,
        );
        return almacen.nombre;
      } catch (e) {
        return 'Almacén no encontrado';
      }
    }
    return 'Sin ubicación';
  }

  Color _getRolColor(String rol) {
    switch (rol) {
      case 'admin':
        return Colors.red;
      case 'encargado_tienda':
        return Colors.blue;
      case 'encargado_almacen':
        return Colors.orange;
      case 'vendedor':
        return Colors.green;
      default:
        return Colors.grey;
    }
  }

  String _getRolDisplayName(String rol) {
    switch (rol) {
      case 'admin':
        return 'Administrador';
      case 'encargado_tienda':
        return 'Encargado Tienda';
      case 'encargado_almacen':
        return 'Encargado Almacén';
      case 'vendedor':
        return 'Vendedor';
      default:
        return rol;
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
                    hintText: 'Buscar por nombre, email o código',
                    prefixIcon: const Icon(Icons.search),
                    border: const OutlineInputBorder(),
                    suffixIcon: _searchController.text.isNotEmpty
                        ? IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () {
                              _searchController.clear();
                              _filtrarEmpleados();
                            },
                          )
                        : null,
                  ),
                  onChanged: (_) => _filtrarEmpleados(),
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
                          _filtrarEmpleados();
                        },
                        avatar: Icon(_soloActivos ? Icons.check_circle : Icons.radio_button_unchecked),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text('${_empleadosFiltrados.length} empleados'),
                  ],
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _empleadosFiltrados.isEmpty
                    ? const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
                            Icon(Icons.people, size: 64, color: Colors.grey),
                            SizedBox(height: 16),
                            Text('No hay empleados'),
                          ],
                        ),
                      )
                    : ListView.builder(
                        itemCount: _empleadosFiltrados.length,
                        itemBuilder: (context, index) {
                          final empleado = _empleadosFiltrados[index];
                          return Card(
                            margin: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 4,
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: empleado.activo 
                                    ? Colors.blue.shade100 
                                    : Colors.red.shade100,
                                child: Text(
                                  '${empleado.nombres[0]}${empleado.apellidos[0]}',
                                  style: TextStyle(
                                    color: empleado.activo 
                                        ? Colors.blue.shade700 
                                        : Colors.red.shade700,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                '${empleado.nombres} ${empleado.apellidos}',
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Código: ${empleado.codigo}'),
                                  Text('Email: ${empleado.email}'),
                                  if (empleado.telefono != null)
                                    Text('Teléfono: ${empleado.telefono}'),
                                  Text('Ubicación: ${_getUbicacion(empleado)}'),
                                  Row(
                                    children: [
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: _getRolColor(empleado.rol).withOpacity(0.1),
                                          borderRadius: BorderRadius.circular(12),
                                          border: Border.all(color: _getRolColor(empleado.rol)),
                                        ),
                                        child: Text(
                                          _getRolDisplayName(empleado.rol),
                                          style: TextStyle(
                                            color: _getRolColor(empleado.rol),
                                            fontSize: 12,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Icon(
                                        empleado.activo ? Icons.check_circle : Icons.cancel,
                                        size: 16,
                                        color: empleado.activo ? Colors.green : Colors.red,
                                      ),
                                      const SizedBox(width: 4),
          Text(
                                        empleado.activo ? 'Activo' : 'Inactivo',
                                        style: TextStyle(
                                          color: empleado.activo ? Colors.green : Colors.red,
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
                                        Icon(empleado.activo ? Icons.pause : Icons.play_arrow),
                                        const SizedBox(width: 8),
                                        Text(empleado.activo ? 'Desactivar' : 'Activar'),
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
                                    _mostrarFormulario(empleado: empleado);
                                  } else if (value == 'toggle_estado') {
                                    _toggleEstado(empleado);
                                  } else if (value == 'eliminar') {
                                    _eliminarEmpleado(empleado);
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

class _FormularioEmpleado extends StatefulWidget {
  final Empleado? empleado;
  final List<dynamic> tiendas;
  final List<dynamic> almacenes;

  const _FormularioEmpleado({
    this.empleado,
    required this.tiendas,
    required this.almacenes,
  });

  @override
  State<_FormularioEmpleado> createState() => _FormularioEmpleadoState();
}

class _FormularioEmpleadoState extends State<_FormularioEmpleado> {
  final _formKey = GlobalKey<FormState>();
  final EmpleadoService _empleadoService = EmpleadoService();

  late TextEditingController _codigoController;
  late TextEditingController _nombresController;
  late TextEditingController _apellidosController;
  late TextEditingController _emailController;
  late TextEditingController _telefonoController;
  
  String _rol = 'vendedor';
  String? _tiendaId;
  String? _almacenId;
  bool _activo = true;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _codigoController = TextEditingController(text: widget.empleado?.codigo ?? '');
    _nombresController = TextEditingController(text: widget.empleado?.nombres ?? '');
    _apellidosController = TextEditingController(text: widget.empleado?.apellidos ?? '');
    _emailController = TextEditingController(text: widget.empleado?.email ?? '');
    _telefonoController = TextEditingController(text: widget.empleado?.telefono ?? '');
    
    if (widget.empleado != null) {
      _rol = widget.empleado!.rol;
      _tiendaId = widget.empleado!.tiendaId;
      _almacenId = widget.empleado!.almacenId;
      _activo = widget.empleado!.activo;
    }
  }

  @override
  void dispose() {
    _codigoController.dispose();
    _nombresController.dispose();
    _apellidosController.dispose();
    _emailController.dispose();
    _telefonoController.dispose();
    super.dispose();
  }

  void _onRolChanged(String? value) {
    setState(() {
      _rol = value!;
      // Limpiar ubicación al cambiar rol
      _tiendaId = null;
      _almacenId = null;
    });
  }

  Future<void> _guardar() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final empleado = widget.empleado ?? Empleado();
      empleado.codigo = _codigoController.text.trim();
      empleado.nombres = _nombresController.text.trim();
      empleado.apellidos = _apellidosController.text.trim();
      empleado.email = _emailController.text.trim();
      empleado.telefono = _telefonoController.text.trim().isEmpty ? '' : _telefonoController.text.trim();
      empleado.rol = _rol;
      empleado.tiendaId = _tiendaId;
      empleado.almacenId = _almacenId;
      empleado.activo = _activo;

      if (widget.empleado == null) {
        await _empleadoService.crear(empleado);
      } else {
        await _empleadoService.actualizar(empleado);
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
                  widget.empleado == null ? 'Nuevo Empleado' : 'Editar Empleado',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _codigoController,
                        decoration: const InputDecoration(
                          labelText: 'Código',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: EMP001',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: TextFormField(
                        controller: _nombresController,
                        decoration: const InputDecoration(
                          labelText: 'Nombres',
                          border: OutlineInputBorder(),
                          hintText: 'Ej: Juan',
                        ),
                        validator: (value) =>
                            value?.isEmpty ?? true ? 'Requerido' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _apellidosController,
                  decoration: const InputDecoration(
                    labelText: 'Apellidos',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: Pérez García',
                  ),
                  validator: (value) =>
                      value?.isEmpty ?? true ? 'Requerido' : null,
                ),
                const SizedBox(height: 12),
                TextFormField(
                  controller: _emailController,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    border: OutlineInputBorder(),
                    hintText: 'Ej: juan@ejemplo.com',
                  ),
                  keyboardType: TextInputType.emailAddress,
                  validator: (value) {
                    if (value?.isEmpty ?? true) return 'Requerido';
                    if (!value!.contains('@')) return 'Email inválido';
                    return null;
                  },
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
                DropdownButtonFormField<String>(
                  value: _rol,
                  decoration: const InputDecoration(
                    labelText: 'Rol',
                    border: OutlineInputBorder(),
                  ),
                  items: [
                    'admin',
                    'encargado_tienda',
                    'encargado_almacen',
                    'vendedor',
                  ].map((rol) => DropdownMenuItem(
                    value: rol,
                    child: Text(rol.replaceAll('_', ' ').toUpperCase()),
                  )).toList(),
                  onChanged: _onRolChanged,
                ),
                const SizedBox(height: 12),
                if (_rol == 'encargado_tienda' || _rol == 'vendedor')
                  DropdownButtonFormField<String>(
                    value: _tiendaId,
                    decoration: const InputDecoration(
                      labelText: 'Tienda',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.tiendas.map<DropdownMenuItem<String>>((tienda) => DropdownMenuItem<String>(
                      value: tienda.codigo,
                      child: Text(tienda.nombre),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _tiendaId = value;
                        _almacenId = null;
                      });
                    },
                  ),
                if (_rol == 'encargado_almacen')
                  DropdownButtonFormField<String>(
                    value: _almacenId,
                    decoration: const InputDecoration(
                      labelText: 'Almacén',
                      border: OutlineInputBorder(),
                    ),
                    items: widget.almacenes.map<DropdownMenuItem<String>>((almacen) => DropdownMenuItem<String>(
                      value: almacen.codigo,
                      child: Text(almacen.nombre),
                    )).toList(),
                    onChanged: (value) {
                      setState(() {
                        _almacenId = value;
                        _tiendaId = null;
                      });
                    },
                  ),
                const SizedBox(height: 16),
                SwitchListTile(
                  title: const Text('Empleado Activo'),
                  subtitle: Text(_activo ? 'El empleado está activo' : 'El empleado está inactivo'),
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





