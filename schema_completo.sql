-- Script SQL Completo para el Entorno de Supabase (Fuerza de Ventas)
-- Ejecuta este script en el "SQL Editor" de tu panel de Supabase.
-- Creará todas las tablas necesarias y sembrará los registros para que la app funcione al 100% con datos reales.

-- Limpiar y reiniciar esquema para evitar conflictos de columnas o restricciones obsoletas
DROP TABLE IF EXISTS public.ruta_visitas CASCADE;
DROP TABLE IF EXISTS public.documentos CASCADE;
DROP TABLE IF EXISTS public.solicitudes_credito CASCADE;
DROP TABLE IF EXISTS public.buro_credito CASCADE;
DROP TABLE IF EXISTS public.productos_activos CASCADE;
DROP TABLE IF EXISTS public.historial_crediticio CASCADE;
DROP TABLE IF EXISTS public.cartera_diaria CASCADE;
DROP TABLE IF EXISTS public.clientes CASCADE;
DROP TABLE IF EXISTS public.oficiales CASCADE;

-- =========================================================================
-- 1. TABLA: oficiales
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.oficiales (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    auth_user_id UUID UNIQUE, -- Se vincula a auth.users (puede ser nulo en pruebas)
    codigo_empleado VARCHAR(50) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    email VARCHAR(150) UNIQUE NOT NULL,
    estado VARCHAR(20) DEFAULT 'ACTIVO' NOT NULL
);

-- Asegurar que auth_user_id sea anulable si la tabla ya existía
ALTER TABLE public.oficiales ALTER COLUMN auth_user_id DROP NOT NULL;

-- =========================================================================
-- 2. TABLA: clientes
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.clientes (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    dni VARCHAR(20) UNIQUE NOT NULL,
    nombres VARCHAR(100) NOT NULL,
    apellidos VARCHAR(100) NOT NULL,
    telefono VARCHAR(20) NOT NULL,
    direccion TEXT NOT NULL,
    latitud NUMERIC,
    longitud NUMERIC,
    estado VARCHAR(20) DEFAULT 'ACTIVO' NOT NULL,
    fecha_registro TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 3. TABLA: cartera_diaria
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.cartera_diaria (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    oficial_id UUID REFERENCES public.oficiales(id) ON DELETE CASCADE,
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE CASCADE,
    fecha DATE NOT NULL,
    tipo_gestion VARCHAR(50) NOT NULL, -- e.g. 'NUEVO_CREDITO', 'RENOVACION_CREDITO'
    estado VARCHAR(50) DEFAULT 'PENDIENTE' NOT NULL, -- e.g. 'PENDIENTE', 'VISITADO'
    prioridad INTEGER DEFAULT 1 NOT NULL,
    observacion TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL,
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 4. TABLA: historial_crediticio
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.historial_crediticio (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE CASCADE,
    monto NUMERIC NOT NULL,
    fecha_desembolso DATE NOT NULL,
    plazo_meses INTEGER NOT NULL,
    estado VARCHAR(50) NOT NULL, -- e.g. 'PAGADO', 'MORA', 'CASTIGADO'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 5. TABLA: productos_activos
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.productos_activos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE CASCADE,
    nombre_producto VARCHAR(100) NOT NULL, -- e.g. 'Microcrédito Grupal', 'Crédito Personal Pyme'
    monto_original NUMERIC NOT NULL,
    saldo_pendiente NUMERIC NOT NULL,
    cuotas_totales INTEGER NOT NULL,
    cuotas_pagadas INTEGER NOT NULL,
    estado VARCHAR(50) DEFAULT 'ACTIVO' NOT NULL, -- e.g. 'ACTIVO', 'VENCIDO'
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 6. TABLA: buro_credito
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.buro_credito (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE CASCADE,
    oficial_id UUID REFERENCES public.oficiales(id) ON DELETE CASCADE,
    score INTEGER,
    resultado TEXT NOT NULL,
    proveedor VARCHAR(100) DEFAULT 'API_EXTERNA_PENDIENTE',
    estado_consulta VARCHAR(50) DEFAULT 'REGISTRADA' NOT NULL,
    payload_respuesta JSONB DEFAULT '{}'::jsonb,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 7. TABLA: solicitudes_credito
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.solicitudes_credito (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE CASCADE,
    oficial_id UUID REFERENCES public.oficiales(id) ON DELETE CASCADE,
    monto_solicitado NUMERIC NOT NULL,
    plazo_meses INTEGER NOT NULL,
    destino_credito VARCHAR(200) NOT NULL,
    estado VARCHAR(50) DEFAULT 'REGISTRADA' NOT NULL, -- e.g. 'REGISTRADA', 'ENVIADA', 'APROBADA', 'RECHAZADA'
    sync_status VARCHAR(50) DEFAULT 'SINCRONIZADO' NOT NULL,
    observacion_envio TEXT,
    fecha_envio TIMESTAMP WITH TIME ZONE,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 8. TABLA: documentos
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.documentos (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    solicitud_id UUID REFERENCES public.solicitudes_credito(id) ON DELETE CASCADE,
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE CASCADE,
    oficial_id UUID REFERENCES public.oficiales(id) ON DELETE CASCADE,
    tipo_documento VARCHAR(100) NOT NULL, -- e.g. 'DNI_FRONTAL', 'RECIBO_LUZ', 'FOTO_NEGOCIO'
    nombre_archivo VARCHAR(200) NOT NULL,
    storage_path TEXT NOT NULL,
    estado_subida VARCHAR(50) DEFAULT 'SUBIDO' NOT NULL,
    sync_status VARCHAR(50) DEFAULT 'SINCRONIZADO' NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);

-- =========================================================================
-- 9. TABLA: ruta_visitas
-- =========================================================================
CREATE TABLE IF NOT EXISTS public.ruta_visitas (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    cartera_id UUID REFERENCES public.cartera_diaria(id) ON DELETE CASCADE,
    cliente_id UUID REFERENCES public.clientes(id) ON DELETE CASCADE,
    oficial_id UUID REFERENCES public.oficiales(id) ON DELETE CASCADE,
    latitud NUMERIC NOT NULL,
    longitud NUMERIC NOT NULL,
    direccion TEXT NOT NULL,
    estado_visita VARCHAR(50) DEFAULT 'PENDIENTE' NOT NULL, -- 'PENDIENTE', 'COMPLETADO', 'RECHAZADO'
    fecha_visita DATE NOT NULL,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT timezone('utc'::text, now()) NOT NULL
);


-- =========================================================================
-- HABILITAR RLS (Row Level Security) EN TODAS LAS TABLAS
-- =========================================================================
ALTER TABLE public.oficiales ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.cartera_diaria ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.historial_crediticio ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.productos_activos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.buro_credito ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.solicitudes_credito ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.documentos ENABLE ROW LEVEL SECURITY;
ALTER TABLE public.ruta_visitas ENABLE ROW LEVEL SECURITY;

-- Crear políticas generales permisivas para pruebas (puedes restringirlas más tarde)
CREATE POLICY "Permitir lectura general oficiales" ON public.oficiales FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa oficiales" ON public.oficiales FOR ALL USING (true);

CREATE POLICY "Permitir lectura general clientes" ON public.clientes FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa clientes" ON public.clientes FOR ALL USING (true);

CREATE POLICY "Permitir lectura general cartera" ON public.cartera_diaria FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa cartera" ON public.cartera_diaria FOR ALL USING (true);

CREATE POLICY "Permitir lectura general historial" ON public.historial_crediticio FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa historial" ON public.historial_crediticio FOR ALL USING (true);

CREATE POLICY "Permitir lectura general productos" ON public.productos_activos FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa productos" ON public.productos_activos FOR ALL USING (true);

CREATE POLICY "Permitir lectura general buro" ON public.buro_credito FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa buro" ON public.buro_credito FOR ALL USING (true);

CREATE POLICY "Permitir lectura general solicitudes" ON public.solicitudes_credito FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa solicitudes" ON public.solicitudes_credito FOR ALL USING (true);

CREATE POLICY "Permitir lectura general documentos" ON public.documentos FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa documentos" ON public.documentos FOR ALL USING (true);

CREATE POLICY "Permitir lectura general ruta_visitas" ON public.ruta_visitas FOR SELECT USING (true);
CREATE POLICY "Permitir gestión completa ruta_visitas" ON public.ruta_visitas FOR ALL USING (true);


-- =========================================================================
-- SEMILLA DE DATOS (SEED DATA)
-- =========================================================================

-- Limpiar todas las tablas previas en el orden correcto para evitar conflictos de claves foráneas
DELETE FROM public.ruta_visitas;
DELETE FROM public.documentos;
DELETE FROM public.solicitudes_credito;
DELETE FROM public.buro_credito;
DELETE FROM public.productos_activos;
DELETE FROM public.historial_crediticio;
DELETE FROM public.cartera_diaria;
DELETE FROM public.clientes;
DELETE FROM public.oficiales;

-- 1. Insertar Oficial de Pruebas OFI001 (Lucía Fernández)
INSERT INTO public.oficiales (id, auth_user_id, codigo_empleado, nombres, apellidos, email, estado)
VALUES ('bd86ac36-985d-472f-ba8e-326373fd2df5', '86a99f7c-a892-4726-9daa-9affa0813cc5', 'OFI001', 'Lucía', 'Fernández', 'oficial001@sip.com', 'ACTIVO');

-- 2. Insertar Clientes
INSERT INTO public.clientes (id, dni, nombres, apellidos, telefono, direccion, latitud, longitud, estado)
VALUES 
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', '12345678', 'Juan Carlos', 'Pérez Gómez', '987654321', 'Av. Larco 456, Miraflores, Lima', -12.1221, -77.0298, 'ACTIVO'),
('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', '87654321', 'María Elena', 'Rodríguez Ruíz', '912345678', 'Calle Las Flores 789, San Isidro, Lima', -12.0945, -77.0321, 'ACTIVO'),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', '45678912', 'Carlos Alberto', 'Sánchez Díaz', '934567890', 'Av. Javier Prado Este 1230, San Borja, Lima', -12.0864, -77.0048, 'ACTIVO'),
('d4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', '76543210', 'Ana Lucía', 'Torres Mendoza', '956789012', 'Jr. Carabaya 580, Cercado de Lima, Lima', -12.0464, -77.0315, 'ACTIVO'),
('e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b', '23456789', 'Luis Miguel', 'Castro Villon', '945678123', 'Av. Alfredo Mendiola 3600, Los Olivos, Lima', -11.9912, -77.0624, 'ACTIVO')
ON CONFLICT (dni) DO UPDATE 
SET nombres = EXCLUDED.nombres, apellidos = EXCLUDED.apellidos, telefono = EXCLUDED.telefono, direccion = EXCLUDED.direccion;

-- 3. Insertar Cartera Diaria para el Oficial OFI001 (Hoy)
INSERT INTO public.cartera_diaria (oficial_id, cliente_id, fecha, tipo_gestion, estado, prioridad, observacion)
VALUES 
('bd86ac36-985d-472f-ba8e-326373fd2df5', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', CURRENT_DATE, 'NUEVO_CREDITO', 'PENDIENTE', 2, 'Cliente nuevo cargado desde semilla'),
('bd86ac36-985d-472f-ba8e-326373fd2df5', 'b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', CURRENT_DATE, 'RENOVACION_CREDITO', 'PENDIENTE', 3, 'Cliente excelente historial'),
('bd86ac36-985d-472f-ba8e-326373fd2df5', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', CURRENT_DATE, 'RENOVACION_CREDITO', 'VISITADO', 2, 'Cliente con buen historial'),
('bd86ac36-985d-472f-ba8e-326373fd2df5', 'd4e5f6a7-b8c9-0d1e-2f3a-4b5c6d7e8f9a', CURRENT_DATE, 'NUEVO_CREDITO', 'PENDIENTE', 1, 'Visita de prospección'),
('bd86ac36-985d-472f-ba8e-326373fd2df5', 'e5f6a7b8-c9d0-1e2f-3a4b-5c6d7e8f9a0b', CURRENT_DATE, 'NUEVO_CREDITO', 'PENDIENTE', 2, 'Verificar domicilio nuevo');

-- 4. Insertar Historial Crediticio para Clientes
INSERT INTO public.historial_crediticio (cliente_id, monto, fecha_desembolso, plazo_meses, estado)
VALUES
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 5000, CURRENT_DATE - INTERVAL '12 months', 12, 'PAGADO'),
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 10000, CURRENT_DATE - INTERVAL '6 months', 6, 'PAGADO'),
('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 15000, CURRENT_DATE - INTERVAL '18 months', 12, 'PAGADO'),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 3000, CURRENT_DATE - INTERVAL '8 months', 6, 'PAGADO'),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 5000, CURRENT_DATE - INTERVAL '3 months', 6, 'PAGADO');

-- 5. Insertar Productos Activos para Clientes
INSERT INTO public.productos_activos (cliente_id, nombre_producto, monto_original, saldo_pendiente, cuotas_totales, cuotas_pagadas, estado)
VALUES
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'Préstamo Capital de Trabajo Pyme', 15000.00, 7500.00, 12, 6, 'ACTIVO'),
('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'Crédito Campaña Escolar', 20000.00, 12000.00, 10, 4, 'ACTIVO'),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'Microcrédito Grupal Compartido', 5000.00, 1200.00, 6, 5, 'ACTIVO');

-- 6. Insertar Consultas Previas de Buró de Crédito
INSERT INTO public.buro_credito (cliente_id, oficial_id, score, resultado, proveedor, estado_consulta, payload_respuesta)
VALUES
('a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'bd86ac36-985d-472f-ba8e-326373fd2df5', 680, 'APROBADO CON RIESGO BAJO', 'EQUIFAX', 'COMPLETADA', '{"score": 680, "dictamen": "BUENO"}'::jsonb),
('b2c3d4e5-f6a7-8b9c-0d1e-2f3a4b5c6d7e', 'bd86ac36-985d-472f-ba8e-326373fd2df5', 720, 'APROBADO - EXCELENTE PERFIL', 'EQUIFAX', 'COMPLETADA', '{"score": 720, "dictamen": "EXCELENTE"}'::jsonb),
('c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'bd86ac36-985d-472f-ba8e-326373fd2df5', 590, 'OBSERVADO - RIESGO MEDIO', 'SENTINEL', 'COMPLETADA', '{"score": 590, "dictamen": "REGULAR"}'::jsonb);

-- 7. Insertar algunas Solicitudes de Crédito previas
INSERT INTO public.solicitudes_credito (id, cliente_id, oficial_id, monto_solicitado, plazo_meses, destino_credito, estado, sync_status)
VALUES
('f1a2b3c4-d5e6-7f8a-9b0c-1d2e3f4a5b6c', 'c3d4e5f6-a7b8-9c0d-1e2f-3a4b5c6d7e8f', 'bd86ac36-985d-472f-ba8e-326373fd2df5', 8000, 12, 'Compra de mercadería y vitrinas', 'APROBADA', 'SINCRONIZADO'),
('02a3b4c5-d6e7-8f9a-0b1c-2d3e4f5a6b7c', 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d', 'bd86ac36-985d-472f-ba8e-326373fd2df5', 12000, 18, 'Ampliación de local de abarrotes', 'REGISTRADA', 'SINCRONIZADO');

-- 8. Insertar visitas de ruta del día
INSERT INTO public.ruta_visitas (cartera_id, cliente_id, oficial_id, latitud, longitud, direccion, estado_visita, fecha_visita)
SELECT cd.id, cd.cliente_id, cd.oficial_id, 
       CASE WHEN cd.cliente_id = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d' THEN -12.1221 ELSE -12.0945 END,
       CASE WHEN cd.cliente_id = 'a1b2c3d4-e5f6-7a8b-9c0d-1e2f3a4b5c6d' THEN -77.0298 ELSE -77.0321 END,
       c.direccion, 'PENDIENTE', CURRENT_DATE
FROM public.cartera_diaria cd
JOIN public.clientes c ON cd.cliente_id = c.id
WHERE cd.estado = 'PENDIENTE'
LIMIT 2;
