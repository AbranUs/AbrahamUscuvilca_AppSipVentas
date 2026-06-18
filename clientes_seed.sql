-- Script SQL Completo para Supabase (Creación, Inserción de Clientes y Asignación de Cartera Diaria)
-- Ejecuta este script en el "SQL Editor" de tu panel de Supabase.
-- Realizará:
--   1. Creación de la tabla 'clientes' (si no existe).
--   2. Inserción de 5 clientes semilla de prueba.
--   3. Asignación automática de los nuevos clientes a la cartera diaria del Oficial Lucía Fernández (OFI001) para la fecha de hoy.

-- =========================================================================
-- STEP 1: Creación de la tabla de clientes y políticas RLS
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

-- Habilitar RLS (Row Level Security)
ALTER TABLE public.clientes ENABLE ROW LEVEL SECURITY;

-- Eliminar políticas antiguas para evitar errores de duplicación de políticas
DROP POLICY IF EXISTS "Permitir lectura general de clientes" ON public.clientes;
DROP POLICY IF EXISTS "Permitir inserción de clientes a usuarios autenticados" ON public.clientes;
DROP POLICY IF EXISTS "Permitir actualización de clientes a usuarios autenticados" ON public.clientes;

-- Crear políticas de acceso
CREATE POLICY "Permitir lectura general de clientes" 
ON public.clientes FOR SELECT USING (true);

CREATE POLICY "Permitir inserción de clientes a usuarios autenticados" 
ON public.clientes FOR INSERT WITH CHECK (auth.role() = 'authenticated');

CREATE POLICY "Permitir actualización de clientes a usuarios autenticados" 
ON public.clientes FOR UPDATE USING (auth.role() = 'authenticated');


-- =========================================================================
-- STEP 2: Inserción de clientes semilla
-- =========================================================================
INSERT INTO public.clientes (dni, nombres, apellidos, telefono, direccion, latitud, longitud, estado)
VALUES 
('12345678', 'Juan Carlos', 'Pérez Gómez', '987654321', 'Av. Larco 456, Miraflores, Lima', -12.1221, -77.0298, 'ACTIVO'),
('87654321', 'María Elena', 'Rodríguez Ruíz', '912345678', 'Calle Las Flores 789, San Isidro, Lima', -12.0945, -77.0321, 'ACTIVO'),
('45678912', 'Carlos Alberto', 'Sánchez Díaz', '934567890', 'Av. Javier Prado Este 1230, San Borja, Lima', -12.0864, -77.0048, 'ACTIVO'),
('76543210', 'Ana Lucía', 'Torres Mendoza', '956789012', 'Jr. Carabaya 580, Cercado de Lima, Lima', -12.0464, -77.0315, 'ACTIVO'),
('23456789', 'Luis Miguel', 'Castro Villon', '945678123', 'Av. Alfredo Mendiola 3600, Los Olivos, Lima', -11.9912, -77.0624, 'ACTIVO')
ON CONFLICT (dni) DO NOTHING;


-- =========================================================================
-- STEP 3: Asignar estos clientes a la Cartera Diaria del Oficial OFI001 (Hoy)
-- =========================================================================
DO $$
DECLARE
    v_oficial_id UUID;
    v_cliente_id UUID;
    v_fecha DATE := CURRENT_DATE; -- Usa la fecha del servidor de base de datos
BEGIN
    -- 1. Obtener el ID del oficial Lucía Fernández (OFI001)
    SELECT id INTO v_oficial_id 
    FROM public.oficiales 
    WHERE codigo_empleado = 'OFI001' 
    LIMIT 1;

    IF v_oficial_id IS NULL THEN
        RAISE NOTICE 'Oficial OFI001 no encontrado. Saltando la asignación de cartera.';
        RETURN;
    END IF;

    -- 2. Asociar el cliente 'Juan Carlos Pérez Gómez' (DNI: 12345678)
    SELECT id INTO v_cliente_id FROM public.clientes WHERE dni = '12345678' LIMIT 1;
    IF v_cliente_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.cartera_diaria WHERE oficial_id = v_oficial_id AND cliente_id = v_cliente_id AND fecha = v_fecha) THEN
            INSERT INTO public.cartera_diaria (oficial_id, cliente_id, fecha, tipo_gestion, estado, prioridad, observacion)
            VALUES (v_oficial_id, v_cliente_id, v_fecha, 'NUEVO_CREDITO', 'PENDIENTE', 2, 'Cliente nuevo cargado desde semilla');
        END IF;
    END IF;

    -- 3. Asociar la cliente 'María Elena Rodríguez Ruíz' (DNI: 87654321)
    SELECT id INTO v_cliente_id FROM public.clientes WHERE dni = '87654321' LIMIT 1;
    IF v_cliente_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.cartera_diaria WHERE oficial_id = v_oficial_id AND cliente_id = v_cliente_id AND fecha = v_fecha) THEN
            INSERT INTO public.cartera_diaria (oficial_id, cliente_id, fecha, tipo_gestion, estado, prioridad, observacion)
            VALUES (v_oficial_id, v_cliente_id, v_fecha, 'RENOVACION_CREDITO', 'PENDIENTE', 3, 'Cliente excelente historial');
        END IF;
    END IF;

    -- 4. Asociar el cliente 'Carlos Alberto Sánchez Díaz' (DNI: 45678912)
    -- Si no está asignado para hoy, lo asignamos
    SELECT id INTO v_cliente_id FROM public.clientes WHERE dni = '45678912' LIMIT 1;
    IF v_cliente_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.cartera_diaria WHERE oficial_id = v_oficial_id AND cliente_id = v_cliente_id AND fecha = v_fecha) THEN
            INSERT INTO public.cartera_diaria (oficial_id, cliente_id, fecha, tipo_gestion, estado, prioridad, observacion)
            VALUES (v_oficial_id, v_cliente_id, v_fecha, 'RENOVACION_CREDITO', 'VISITADO', 2, 'Cliente con buen historial');
        END IF;
    END IF;

    -- 5. Asociar la cliente 'Ana Lucía Torres Mendoza' (DNI: 76543210)
    SELECT id INTO v_cliente_id FROM public.clientes WHERE dni = '76543210' LIMIT 1;
    IF v_cliente_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.cartera_diaria WHERE oficial_id = v_oficial_id AND cliente_id = v_cliente_id AND fecha = v_fecha) THEN
            INSERT INTO public.cartera_diaria (oficial_id, cliente_id, fecha, tipo_gestion, estado, prioridad, observacion)
            VALUES (v_oficial_id, v_cliente_id, v_fecha, 'NUEVO_CREDITO', 'PENDIENTE', 1, 'Visita de prospección');
        END IF;
    END IF;

    -- 6. Asociar el cliente 'Luis Miguel Castro Villon' (DNI: 23456789)
    SELECT id INTO v_cliente_id FROM public.clientes WHERE dni = '23456789' LIMIT 1;
    IF v_cliente_id IS NOT NULL THEN
        IF NOT EXISTS (SELECT 1 FROM public.cartera_diaria WHERE oficial_id = v_oficial_id AND cliente_id = v_cliente_id AND fecha = v_fecha) THEN
            INSERT INTO public.cartera_diaria (oficial_id, cliente_id, fecha, tipo_gestion, estado, prioridad, observacion)
            VALUES (v_oficial_id, v_cliente_id, v_fecha, 'NUEVO_CREDITO', 'PENDIENTE', 2, 'Verificar domicilio nuevo');
        END IF;
    END IF;

    RAISE NOTICE 'Asignación de cartera diaria para el oficial OFI001 realizada con éxito.';
END $$;
