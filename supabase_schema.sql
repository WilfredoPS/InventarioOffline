-- Schema para Supabase
-- Sistema de Inventario Offline-First

-- Habilitar extensión UUID
CREATE EXTENSION IF NOT EXISTS "uuid-ossp";

-- ============================================
-- TABLA: productos
-- ============================================
CREATE TABLE productos (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  descripcion TEXT,
  categoria VARCHAR(50) NOT NULL CHECK (categoria IN ('alfombras', 'piso flotante', 'pisopak', 'cielo falso', 'viniles')),
  unidad_medida VARCHAR(20) NOT NULL CHECK (unidad_medida IN ('m2', 'rollo', 'caja', 'pieza')),
  precio_compra DECIMAL(10,2) NOT NULL CHECK (precio_compra >= 0),
  precio_venta DECIMAL(10,2) NOT NULL CHECK (precio_venta >= 0),
  stock_minimo INTEGER DEFAULT 0 CHECK (stock_minimo >= 0),
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_productos_categoria ON productos(categoria);
CREATE INDEX idx_productos_codigo ON productos(codigo);
CREATE INDEX idx_productos_eliminado ON productos(eliminado);

-- ============================================
-- TABLA: almacenes
-- ============================================
CREATE TABLE almacenes (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  direccion VARCHAR(500) NOT NULL,
  telefono VARCHAR(20),
  responsable VARCHAR(200) NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_almacenes_activo ON almacenes(activo);
CREATE INDEX idx_almacenes_codigo ON almacenes(codigo);

-- ============================================
-- TABLA: tiendas
-- ============================================
CREATE TABLE tiendas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR(50) UNIQUE NOT NULL,
  nombre VARCHAR(200) NOT NULL,
  direccion VARCHAR(500) NOT NULL,
  telefono VARCHAR(20),
  responsable VARCHAR(200) NOT NULL,
  activo BOOLEAN DEFAULT TRUE,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_tiendas_activo ON tiendas(activo);
CREATE INDEX idx_tiendas_codigo ON tiendas(codigo);

-- ============================================
-- TABLA: empleados
-- ============================================
CREATE TABLE empleados (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  codigo VARCHAR(50) UNIQUE NOT NULL,
  nombres VARCHAR(100) NOT NULL,
  apellidos VARCHAR(100) NOT NULL,
  email VARCHAR(200) UNIQUE NOT NULL,
  telefono VARCHAR(20) NOT NULL,
  rol VARCHAR(50) NOT NULL CHECK (rol IN ('admin', 'encargado_tienda', 'encargado_almacen', 'vendedor')),
  tienda_id VARCHAR(50),
  almacen_id VARCHAR(50),
  activo BOOLEAN DEFAULT TRUE,
  supabase_user_id UUID,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_empleados_email ON empleados(email);
CREATE INDEX idx_empleados_rol ON empleados(rol);
CREATE INDEX idx_empleados_activo ON empleados(activo);
CREATE INDEX idx_empleados_supabase_user_id ON empleados(supabase_user_id);

-- ============================================
-- TABLA: inventarios
-- ============================================
CREATE TABLE inventarios (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  producto_id VARCHAR(50) NOT NULL,
  ubicacion_tipo VARCHAR(20) NOT NULL CHECK (ubicacion_tipo IN ('tienda', 'almacen')),
  ubicacion_id VARCHAR(50) NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (cantidad >= 0),
  ultima_actualizacion TIMESTAMPTZ DEFAULT NOW(),
  UNIQUE(producto_id, ubicacion_tipo, ubicacion_id)
);

CREATE INDEX idx_inventarios_producto ON inventarios(producto_id);
CREATE INDEX idx_inventarios_ubicacion ON inventarios(ubicacion_tipo, ubicacion_id);

-- ============================================
-- TABLA: compras
-- ============================================
CREATE TABLE compras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_compra VARCHAR(50) UNIQUE NOT NULL,
  fecha_compra TIMESTAMPTZ NOT NULL,
  proveedor VARCHAR(200) NOT NULL,
  numero_factura VARCHAR(100),
  destino_tipo VARCHAR(20) NOT NULL CHECK (destino_tipo IN ('tienda', 'almacen')),
  destino_id VARCHAR(50) NOT NULL,
  empleado_id VARCHAR(50) NOT NULL,
  subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  impuesto DECIMAL(10,2) NOT NULL CHECK (impuesto >= 0),
  total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
  estado VARCHAR(20) NOT NULL CHECK (estado IN ('pendiente', 'completada', 'anulada')),
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_compras_fecha ON compras(fecha_compra);
CREATE INDEX idx_compras_estado ON compras(estado);
CREATE INDEX idx_compras_destino ON compras(destino_tipo, destino_id);
CREATE INDEX idx_compras_numero ON compras(numero_compra);

-- ============================================
-- TABLA: detalle_compras
-- ============================================
CREATE TABLE detalle_compras (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  compra_id UUID NOT NULL REFERENCES compras(id) ON DELETE CASCADE,
  producto_id VARCHAR(50) NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL CHECK (cantidad > 0),
  precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario >= 0),
  subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0)
);

CREATE INDEX idx_detalle_compras_compra ON detalle_compras(compra_id);
CREATE INDEX idx_detalle_compras_producto ON detalle_compras(producto_id);

-- ============================================
-- TABLA: ventas
-- ============================================
CREATE TABLE ventas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_venta VARCHAR(50) UNIQUE NOT NULL,
  fecha_venta TIMESTAMPTZ NOT NULL,
  tienda_id VARCHAR(50) NOT NULL,
  empleado_id VARCHAR(50) NOT NULL,
  cliente VARCHAR(200) NOT NULL,
  cliente_documento VARCHAR(50),
  cliente_telefono VARCHAR(20),
  subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0),
  descuento DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (descuento >= 0),
  impuesto DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (impuesto >= 0),
  total DECIMAL(10,2) NOT NULL CHECK (total >= 0),
  metodo_pago VARCHAR(20) NOT NULL CHECK (metodo_pago IN ('efectivo', 'tarjeta', 'transferencia')),
  estado VARCHAR(20) NOT NULL CHECK (estado IN ('completada', 'anulada')),
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_ventas_fecha ON ventas(fecha_venta);
CREATE INDEX idx_ventas_tienda ON ventas(tienda_id);
CREATE INDEX idx_ventas_estado ON ventas(estado);
CREATE INDEX idx_ventas_numero ON ventas(numero_venta);

-- ============================================
-- TABLA: detalle_ventas
-- ============================================
CREATE TABLE detalle_ventas (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  venta_id UUID NOT NULL REFERENCES ventas(id) ON DELETE CASCADE,
  producto_id VARCHAR(50) NOT NULL,
  cantidad DECIMAL(10,2) NOT NULL CHECK (cantidad > 0),
  precio_unitario DECIMAL(10,2) NOT NULL CHECK (precio_unitario >= 0),
  descuento DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (descuento >= 0),
  subtotal DECIMAL(10,2) NOT NULL CHECK (subtotal >= 0)
);

CREATE INDEX idx_detalle_ventas_venta ON detalle_ventas(venta_id);
CREATE INDEX idx_detalle_ventas_producto ON detalle_ventas(producto_id);

-- ============================================
-- TABLA: transferencias
-- ============================================
CREATE TABLE transferencias (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  numero_transferencia VARCHAR(50) UNIQUE NOT NULL,
  fecha_transferencia TIMESTAMPTZ NOT NULL,
  origen_tipo VARCHAR(20) NOT NULL CHECK (origen_tipo IN ('tienda', 'almacen')),
  origen_id VARCHAR(50) NOT NULL,
  destino_tipo VARCHAR(20) NOT NULL CHECK (destino_tipo IN ('tienda', 'almacen')),
  destino_id VARCHAR(50) NOT NULL,
  empleado_id VARCHAR(50) NOT NULL,
  estado VARCHAR(20) NOT NULL CHECK (estado IN ('pendiente', 'en_transito', 'recibida', 'anulada')),
  fecha_recepcion TIMESTAMPTZ,
  empleado_recepcion_id VARCHAR(50),
  observaciones TEXT,
  eliminado BOOLEAN DEFAULT FALSE,
  created_at TIMESTAMPTZ DEFAULT NOW(),
  updated_at TIMESTAMPTZ DEFAULT NOW()
);

CREATE INDEX idx_transferencias_fecha ON transferencias(fecha_transferencia);
CREATE INDEX idx_transferencias_origen ON transferencias(origen_tipo, origen_id);
CREATE INDEX idx_transferencias_destino ON transferencias(destino_tipo, destino_id);
CREATE INDEX idx_transferencias_estado ON transferencias(estado);
CREATE INDEX idx_transferencias_numero ON transferencias(numero_transferencia);

-- ============================================
-- TABLA: detalle_transferencias
-- ============================================
CREATE TABLE detalle_transferencias (
  id UUID PRIMARY KEY DEFAULT uuid_generate_v4(),
  transferencia_id UUID NOT NULL REFERENCES transferencias(id) ON DELETE CASCADE,
  producto_id VARCHAR(50) NOT NULL,
  cantidad_enviada DECIMAL(10,2) NOT NULL CHECK (cantidad_enviada > 0),
  cantidad_recibida DECIMAL(10,2) NOT NULL DEFAULT 0 CHECK (cantidad_recibida >= 0)
);

CREATE INDEX idx_detalle_transferencias_transferencia ON detalle_transferencias(transferencia_id);
CREATE INDEX idx_detalle_transferencias_producto ON detalle_transferencias(producto_id);

-- ============================================
-- TRIGGERS para updated_at
-- ============================================

CREATE OR REPLACE FUNCTION update_updated_at_column()
RETURNS TRIGGER AS $$
BEGIN
  NEW.updated_at = NOW();
  RETURN NEW;
END;
$$ LANGUAGE plpgsql;

CREATE TRIGGER update_productos_updated_at BEFORE UPDATE ON productos
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_almacenes_updated_at BEFORE UPDATE ON almacenes
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_tiendas_updated_at BEFORE UPDATE ON tiendas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_empleados_updated_at BEFORE UPDATE ON empleados
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_compras_updated_at BEFORE UPDATE ON compras
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_ventas_updated_at BEFORE UPDATE ON ventas
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

CREATE TRIGGER update_transferencias_updated_at BEFORE UPDATE ON transferencias
  FOR EACH ROW EXECUTE FUNCTION update_updated_at_column();

-- ============================================
-- POLÍTICAS RLS (Row Level Security)
-- ============================================

-- Habilitar RLS en todas las tablas
ALTER TABLE productos ENABLE ROW LEVEL SECURITY;
ALTER TABLE almacenes ENABLE ROW LEVEL SECURITY;
ALTER TABLE tiendas ENABLE ROW LEVEL SECURITY;
ALTER TABLE empleados ENABLE ROW LEVEL SECURITY;
ALTER TABLE inventarios ENABLE ROW LEVEL SECURITY;
ALTER TABLE compras ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_compras ENABLE ROW LEVEL SECURITY;
ALTER TABLE ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_ventas ENABLE ROW LEVEL SECURITY;
ALTER TABLE transferencias ENABLE ROW LEVEL SECURITY;
ALTER TABLE detalle_transferencias ENABLE ROW LEVEL SECURITY;

-- Políticas básicas (ajustar según necesidades de seguridad)
-- Por ahora, permitir acceso autenticado

CREATE POLICY "Enable read access for authenticated users" ON productos
  FOR SELECT TO authenticated USING (true);

CREATE POLICY "Enable insert access for authenticated users" ON productos
  FOR INSERT TO authenticated WITH CHECK (true);

CREATE POLICY "Enable update access for authenticated users" ON productos
  FOR UPDATE TO authenticated USING (true);

-- Repetir para otras tablas según necesidades específicas
-- O usar políticas más específicas basadas en roles

-- ============================================
-- DATOS DE EJEMPLO (OPCIONAL)
-- ============================================

-- Insertar un empleado admin de ejemplo
INSERT INTO empleados (codigo, nombres, apellidos, email, telefono, rol, activo)
VALUES ('EMP001', 'Admin', 'Sistema', 'admin@ejemplo.com', '0000000000', 'admin', true);

-- Insertar productos de ejemplo
INSERT INTO productos (codigo, nombre, categoria, unidad_medida, precio_compra, precio_venta, stock_minimo)
VALUES 
  ('ALFA001', 'Alfombra Persa', 'alfombras', 'm2', 15.00, 25.00, 10),
  ('PISO001', 'Piso Flotante Roble', 'piso flotante', 'm2', 12.00, 20.00, 50),
  ('PISO002', 'Pisopak Premium', 'pisopak', 'caja', 30.00, 45.00, 20),
  ('CIEL001', 'Cielo Falso Blanco', 'cielo falso', 'm2', 8.00, 15.00, 30),
  ('VINI001', 'Vineles Decorativos', 'viniles', 'rollo', 20.00, 35.00, 15);

-- Insertar una tienda de ejemplo
INSERT INTO tiendas (codigo, nombre, direccion, telefono, responsable, activo)
VALUES ('TDA001', 'Tienda Central', 'Av. Principal #123', '5551234567', 'Juan Pérez', true);

-- Insertar un almacén de ejemplo
INSERT INTO almacenes (codigo, nombre, direccion, telefono, responsable, activo)
VALUES ('ALM001', 'Almacén Principal', 'Calle Industrial #456', '5557654321', 'María González', true);

