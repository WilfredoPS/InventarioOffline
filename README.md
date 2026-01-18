# Sistema de Inventario - Offline First

Sistema de gestión de Tienda Deportiva SportTrack  desarrollado en Flutter con Isar y Supabase.

## Características Principales

### 🎯 Funcionalidades Implementadas

- ✅ **Gestión de Productos**: Crear, editar y eliminar productos con categorías (pelotas, deportivos, canilleras, etc)
- ✅ **Gestión de Almacenes**: Administrar múltiples almacenes
- ✅ **Gestión de Tiendas**: Administrar múltiples tiendas
- ✅ **Gestión de Empleados**: Diferentes roles (admin, encargado_tienda, encargado_almacen, vendedor)
- ✅ **Sistema de Compras**: Registrar compras a proveedores con destino a almacenes/tiendas
- ✅ **Sistema de Ventas**: POS completo con gestión de clientes y métodos de pago
- ✅ **Transferencias**: Mover productos entre almacenes y tiendas
- ✅ **Inventario en Tiempo Real**: Visualizar stock por ubicación con alertas de stock bajo
- ✅ **Dashboard**: Ventas del día, ventas globales y accesos rápidos
- ✅ **Autenticación**: Sistema de login con permisos por rol
- ✅ **Sincronización**: Sync automático con Supabase cuando hay conexión

### 📊 Stack Tecnológico

- **Flutter**: Framework principal
- **Isar**: Base de datos local (offline-first)
- **Supabase**: Backend y sincronización
- **Provider**: State management
- **Material Design 3**: UI moderna

## Estructura del Proyecto

```
lib/
├── models/              # Modelos de datos Isar
│   ├── producto.dart
│   ├── almacen.dart
│   ├── tienda.dart
│   ├── empleado.dart
│   ├── inventario.dart
│   ├── compra.dart
│   ├── venta.dart
│   └── transferencia.dart
├── services/            # Lógica de negocio
│   ├── database_service.dart
│   ├── producto_service.dart
│   ├── almacen_service.dart
│   ├── tienda_service.dart
│   ├── empleado_service.dart
│   ├── inventario_service.dart
│   ├── compra_service.dart
│   ├── venta_service.dart
│   ├── transferencia_service.dart
│   ├── supabase_service.dart
│   ├── sync_service.dart
│   └── auth_service.dart
├── providers/           # State management
│   ├── auth_provider.dart
│   └── sync_provider.dart
├── screens/             # Pantallas de la app
│   ├── login_screen.dart
│   ├── home_screen.dart
│   ├── dashboard_screen.dart
│   ├── productos_screen.dart
│   ├── ventas_screen.dart
│   ├── inventario_screen.dart
│   └── ...
└── main.dart
```

## Instalación y Configuración

### 1. Prerrequisitos

- Flutter SDK 3.9.2 o superior
- Dart SDK
- Cuenta de Supabase (opcional para sincronización)

### 2. Instalar Dependencias

```bash
flutter pub get
```

### 3. Generar Código de Isar

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 4. Configurar Supabase (Opcional)

En `lib/main.dart`, descomenta y configura:

```dart
await SupabaseService().initialize(
  'TU_SUPABASE_URL',
  'TU_SUPABASE_ANON_KEY'
);
```

### 5. Ejecutar la Aplicación

```bash
flutter run
```

## Uso del Sistema

### Roles y Permisos

#### Administrador (`admin`)
- Acceso completo a todas las funcionalidades
- Gestión de productos, almacenes, tiendas y empleados
- Realizar compras, ventas y transferencias
- Ver reportes globales

#### Encargado de Tienda (`encargado_tienda`)
- Realizar ventas
- Solicitar transferencias
- Ver inventario de su tienda
- Ver reportes de su tienda

#### Encargado de Almacén (`encargado_almacen`)
- Realizar compras
- Gestionar transferencias
- Ver inventario de su almacén
- Ver reportes de su almacén

#### Vendedor (`vendedor`)
- Realizar ventas
- Ver inventario de su tienda

### Flujo de Trabajo Típico

1. **Login**: Ingresar con email y contraseña
2. **Dashboard**: Ver resumen de ventas del día
3. **Productos**: Gestionar catálogo de productos
4. **Compras**: Registrar compras a proveedores → Actualiza inventario automáticamente
5. **Ventas**: Realizar ventas → Descuenta inventario automáticamente
6. **Transferencias**: Mover productos entre ubicaciones
7. **Inventario**: Monitorear stock en tiempo real
8. **Sincronización**: Sync manual o automático con Supabase

## Base de Datos Supabase

### Estructura de Tablas (SQL)

```sql
-- Productos
CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR UNIQUE NOT NULL,
  nombre VARCHAR NOT NULL,
  descripcion TEXT,
  categoria VARCHAR NOT NULL,
  unidad_medida VARCHAR NOT NULL,
  precio_compra DECIMAL(10,2) NOT NULL,
  precio_venta DECIMAL(10,2) NOT NULL,
  stock_minimo INTEGER DEFAULT 0,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Almacenes
CREATE TABLE almacenes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR UNIQUE NOT NULL,
  nombre VARCHAR NOT NULL,
  direccion VARCHAR NOT NULL,
  telefono VARCHAR,
  responsable VARCHAR NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Tiendas
CREATE TABLE tiendas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR UNIQUE NOT NULL,
  nombre VARCHAR NOT NULL,
  direccion VARCHAR NOT NULL,
  telefono VARCHAR,
  responsable VARCHAR NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Empleados
CREATE TABLE empleados (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR UNIQUE NOT NULL,
  nombres VARCHAR NOT NULL,
  apellidos VARCHAR NOT NULL,
  email VARCHAR UNIQUE NOT NULL,
  telefono VARCHAR NOT NULL,
  rol VARCHAR NOT NULL,
  tienda_id VARCHAR,
  almacen_id VARCHAR,
  activo BOOLEAN DEFAULT TRUE,
  supabase_user_id UUID,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Inventarios
CREATE TABLE inventarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  producto_id VARCHAR NOT NULL,
  ubicacion_tipo VARCHAR NOT NULL,
  ubicacion_id VARCHAR NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL DEFAULT 0,
  ultima_actualizacion TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(producto_id, ubicacion_tipo, ubicacion_id)
);

-- Compras
CREATE TABLE compras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_compra VARCHAR UNIQUE NOT NULL,
  fecha_compra TIMESTAMPTZ NOT NULL,
  proveedor VARCHAR NOT NULL,
  numero_factura VARCHAR,
  destino_tipo VARCHAR NOT NULL,
  destino_id VARCHAR NOT NULL,
  empleado_id VARCHAR NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL,
  impuesto DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  estado VARCHAR NOT NULL,
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Detalle Compras
CREATE TABLE detalle_compras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  compra_id UUID REFERENCES compras(id),
  producto_id VARCHAR NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL
);

-- Ventas
CREATE TABLE ventas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_venta VARCHAR UNIQUE NOT NULL,
  fecha_venta TIMESTAMPTZ NOT NULL,
  tienda_id VARCHAR NOT NULL,
  empleado_id VARCHAR NOT NULL,
  cliente VARCHAR NOT NULL,
  cliente_documento VARCHAR,
  cliente_telefono VARCHAR,
  subtotal DECIMAL(10,2) NOT NULL,
  descuento DECIMAL(10,2) NOT NULL,
  impuesto DECIMAL(10,2) NOT NULL,
  total DECIMAL(10,2) NOT NULL,
  metodo_pago VARCHAR NOT NULL,
  estado VARCHAR NOT NULL,
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Detalle Ventas
CREATE TABLE detalle_ventas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venta_id UUID REFERENCES ventas(id),
  producto_id VARCHAR NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL,
  precio_unitario DECIMAL(10,2) NOT NULL,
  descuento DECIMAL(10,2) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL
);

-- Transferencias
CREATE TABLE transferencias (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_transferencia VARCHAR UNIQUE NOT NULL,
  fecha_transferencia TIMESTAMPTZ NOT NULL,
  origen_tipo VARCHAR NOT NULL,
  origen_id VARCHAR NOT NULL,
  destino_tipo VARCHAR NOT NULL,
  destino_id VARCHAR NOT NULL,
  empleado_id VARCHAR NOT NULL,
  estado VARCHAR NOT NULL,
  fecha_recepcion TIMESTAMPTZ,
  empleado_recepcion_id VARCHAR,
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

-- Detalle Transferencias
CREATE TABLE detalle_transferencias (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transferencia_id UUID REFERENCES transferencias(id),
  producto_id VARCHAR NOT NULL,
  cantidad_enviada DECIMAL(10,2) NOT NULL,
  cantidad_recibida DECIMAL(10,2) NOT NULL
);
```

## Características Offline-First

- **Base de datos local Isar**: Todos los datos se almacenan localmente
- **Funcionamiento sin conexión**: La app funciona completamente offline
- **Sincronización inteligente**: Al detectar conexión, sincroniza cambios con Supabase
- **Resolución de conflictos**: Timestamps para determinar versión más reciente
- **Queue de sincronización**: Cambios pendientes se sincronizan en orden

## Próximas Funcionalidades

- [ ] Reportes avanzados con gráficos
- [ ] Exportación de datos a Excel/PDF
- [ ] Gestión completa de almacenes y tiendas
- [ ] Gestión completa de empleados
- [ ] Gestión completa de compras
- [ ] Gestión completa de transferencias
- [ ] Códigos de barras/QR
- [ ] Notificaciones push
- [ ] Backup automático
- [ ] Multi-idioma

## Desarrollo

### Generar Modelos Isar

Después de modificar los modelos, ejecutar:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### Limpiar Build

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
```

## Licencia

Propietario - Todos los derechos reservados

## Soporte

Para soporte o consultas, contactar al equipo de desarrollo.
