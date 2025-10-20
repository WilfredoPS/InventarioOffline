# 📦 Sistema de Inventario - Guía de Inicio Rápido

## ✅ Estado del Proyecto

**¡Sistema completamente funcional y listo para usar!**

Todos los archivos han sido generados correctamente y el sistema está listo para ejecutarse.

## 🚀 Pasos para Ejecutar

### 1. Verificar que todo está correcto

Los archivos de Isar ya se han generado. Si necesitas regenerarlos en el futuro:

```bash
flutter pub run build_runner build --delete-conflicting-outputs
```

### 2. Ejecutar la Aplicación

```bash
flutter run
```

O selecciona tu dispositivo/emulador en VS Code/Android Studio y presiona F5.

## 📱 Funcionalidades Implementadas

### ✅ Completamente Funcionales

1. **🔐 Sistema de Autenticación**
   - Login con email y password
   - Gestión de roles y permisos
   - Sesión persistente

2. **📊 Dashboard**
   - Ventas del día (por tienda)
   - Ventas globales (para admins)
   - Accesos rápidos

3. **📦 Gestión de Productos**
   - Crear, editar, eliminar productos
   - Búsqueda y filtros por categoría
   - Categorías: alfombras, piso flotante, pisopak, cielo falso, viniles
   - Unidades: m2, rollo, caja, pieza

4. **💰 Sistema de Ventas (POS)**
   - Crear nuevas ventas
   - Agregar productos
   - Gestión de cliente
   - Métodos de pago: efectivo, tarjeta, transferencia
   - Cálculo automático de totales
   - Descuento de inventario automático

5. **📊 Inventario en Tiempo Real**
   - Ver stock por ubicación
   - Alertas de stock bajo
   - Actualización automática con transacciones

6. **🔄 Sincronización Offline-First**
   - Base de datos local Isar
   - Sincronización con Supabase
   - Funciona sin conexión

### 🚧 Pantallas Stub (Para desarrollo futuro)

- Gestión de Almacenes
- Gestión de Tiendas
- Gestión de Empleados
- Gestión de Compras
- Gestión de Transferencias
- Reportes Avanzados

## 🎯 Roles y Permisos

### Administrador (`admin`)
- ✅ Ver dashboard global
- ✅ Gestionar productos
- ✅ Gestionar almacenes, tiendas, empleados
- ✅ Realizar compras, ventas, transferencias
- ✅ Ver reportes globales
- ✅ Ver inventario global

### Encargado de Tienda (`encargado_tienda`)
- ✅ Ver dashboard de su tienda
- ✅ Realizar ventas
- ✅ Solicitar transferencias
- ✅ Ver inventario de su tienda
- ✅ Ver reportes de su tienda

### Encargado de Almacén (`encargado_almacen`)
- ✅ Ver dashboard
- ✅ Realizar compras
- ✅ Gestionar transferencias
- ✅ Ver inventario de su almacén
- ✅ Ver reportes de su almacén

### Vendedor (`vendedor`)
- ✅ Realizar ventas
- ✅ Ver inventario de su tienda

## 🗄️ Configuración de Supabase

### 1. Crear Proyecto en Supabase

1. Ve a [supabase.com](https://supabase.com)
2. Crea una cuenta y un nuevo proyecto
3. Anota tu `URL` y `anon key`

### 2. Ejecutar el Schema

1. En tu proyecto de Supabase, ve a **SQL Editor**
2. Copia el contenido de `supabase_schema.sql`
3. Ejecuta el script
4. Esto creará todas las tablas, índices, triggers y datos de ejemplo

### 3. Configurar en la App

Edita `lib/main.dart` línea ~13:

```dart
// Descomentar y configurar:
await SupabaseService().initialize(
  'TU_URL_AQUI',
  'TU_ANON_KEY_AQUI'
);
```

## 👤 Usuario de Prueba

El script SQL crea un usuario admin de ejemplo:

```
Email: admin@ejemplo.com
Contraseña: [Configurar en Supabase Auth]
```

**Para configurar la contraseña:**

1. Ve a **Authentication** > **Users** en Supabase
2. Crea un usuario con email `admin@ejemplo.com`
3. Asigna una contraseña
4. Usa estas credenciales en el login

## 📖 Uso del Sistema

### Flujo Típico de Trabajo

#### 1. Gestión de Productos

```
Login → Menú → Productos → (+) → Llenar formulario → Guardar
```

- Código único del producto
- Nombre descriptivo
- Categoría (alfombras, piso flotante, etc.)
- Precios de compra y venta
- Stock mínimo

#### 2. Realizar una Venta

```
Login → Dashboard/Ventas → Nueva Venta
```

1. Ingresar datos del cliente
2. Seleccionar método de pago
3. Agregar productos (botón +)
4. Verificar totales
5. Guardar venta

**El sistema automáticamente:**
- ✅ Genera número de venta único
- ✅ Descuenta del inventario
- ✅ Actualiza reportes
- ✅ Marca para sincronización

#### 3. Ver Inventario

```
Login → Inventario
```

- Ver productos disponibles en tu ubicación
- Alertas rojas para stock bajo
- Cantidades en tiempo real

#### 4. Sincronizar Datos

- Clic en el icono de sincronización (⟳) en el AppBar
- O esperar a la sincronización automática
- Requiere conexión a internet

## 🔧 Desarrollo Futuro

### Para Implementar Pantallas Pendientes

Cada pantalla stub ya está conectada al sistema de navegación. Para implementarlas:

1. **Copiar el patrón de `productos_screen.dart`**
2. **Usar los servicios ya creados:**
   - `AlmacenService`
   - `TiendaService`
   - `EmpleadoService`
   - `CompraService`
   - `TransferenciaService`

3. **Seguir la estructura:**
   ```dart
   - Listar items
   - Buscar/Filtrar
   - Formulario crear/editar
   - Eliminar con confirmación
   - Actualizar inventario si aplica
   ```

### Reportes

Para reportes avanzados, usar:
- `VentaService.getByFechas()`
- `CompraService.getByFechas()`
- `TransferenciaService.getByFechas()`
- Agregar `fl_chart` para gráficos

## 🐛 Troubleshooting

### Error: "Isar not initialized"

```bash
flutter pub run build_runner clean
flutter pub run build_runner build --delete-conflicting-outputs
```

### Error: "Supabase not initialized"

Asegúrate de descomentar y configurar la inicialización en `lib/main.dart`

### Error de sincronización

- Verifica conexión a internet
- Verifica credenciales de Supabase
- Revisa la consola para errores específicos

### App no compila

```bash
flutter clean
flutter pub get
flutter pub run build_runner build --delete-conflicting-outputs
flutter run
```

## 📁 Estructura de Archivos Generados

Después del build, verás archivos `.g.dart` en `lib/models/`:

```
lib/models/
├── almacen.dart
├── almacen.g.dart          ← Generado
├── producto.dart
├── producto.g.dart         ← Generado
├── venta.dart
├── venta.g.dart            ← Generado
└── ...
```

**No edites los archivos `.g.dart`** - se regeneran automáticamente.

## 🎨 Personalización

### Cambiar Tema

Edita `lib/main.dart`:

```dart
theme: ThemeData(
  colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue), // Cambia el color
  useMaterial3: true,
  // ...
)
```

### Agregar Categorías de Productos

1. Edita `lib/models/producto.dart` (comentario de categorías)
2. Edita `lib/screens/productos_screen.dart` (chips de filtro)
3. Regenera código Isar

### Cambiar Logo

Reemplaza el icono en:
- `lib/screens/login_screen.dart`
- `lib/main.dart` (SplashScreen)

## 📞 Próximos Pasos Sugeridos

1. ✅ **Configurar Supabase** y probar sincronización
2. ✅ **Crear usuarios de prueba** para cada rol
3. ✅ **Agregar productos** al catálogo
4. ✅ **Realizar ventas de prueba**
5. 🔲 **Implementar pantallas pendientes** según prioridad
6. 🔲 **Agregar reportes avanzados**
7. 🔲 **Implementar transferencias completas**
8. 🔲 **Agregar códigos QR/barras**

## 🎉 ¡Sistema Listo!

El sistema está **100% funcional** para:
- Gestionar productos
- Realizar ventas
- Ver inventario en tiempo real
- Sincronizar con la nube

Las demás funcionalidades están preparadas y solo necesitan implementación de UI siguiendo los patrones ya establecidos.

---

**¿Necesitas ayuda?** Revisa el código de las pantallas ya implementadas como referencia.






