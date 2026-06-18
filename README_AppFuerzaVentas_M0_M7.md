
# README - App Fuerza de Ventas (Módulos M0 a M7)

## Descripción
Aplicación móvil para oficiales de crédito en campo de microfinanzas en Perú. Reemplaza el expediente físico, permite descargar la cartera diaria, registrar solicitudes de crédito, capturar documentos, consultar buró de crédito y listas negras, incluso sin conexión a internet.

**Flujo de negocio:**  
Pre-evaluación → Evaluación → Aprobación → Desembolso → Recuperación

**Tecnologías:** Flutter, Supabase Auth, Edge Functions, WorkManager, fl_chart, geolocator, camera, photo_view, SQLite local.

---

## Alcance
- Generar automáticamente los módulos **M0 a M7**.
- Incluir **todas las Historias de Usuario (HU) y Requerimientos Funcionales (RF)** de estos módulos.
- Ignorar los módulos **M8 a M11** para esta ejecución.
- Mantener consistencia en nombres de pantallas, validaciones, flujos offline y online según PDF.

---

## Módulos y Historias de Usuario

### M0 — Autenticación y Perfiles
| HU | Descripción | RF | Criterios de aceptación | Story Points |
|----|------------|----|------------------------|--------------|
| HU-01 | Login del asesor de negocios | RF-01 a RF-04 | Formulario login, persistencia, bloqueo por intentos fallidos | 5 |
| HU-02 | Perfiles de acceso diferenciados | RF-05 a RF-06 | Menú lateral adaptativo, roles y capacidades | 3 |
| HU-03 | Cierre de sesión y borrado de datos sensibles | RF-07 a RF-08 | Logout seguro, borrado datos sensibles, advertencia documentos pendientes | 3 |

### M1 — Cartera Diaria
| HU | Descripción | RF | Criterios de aceptación | Story Points |
|----|------------|----|------------------------|--------------|
| HU-04 | Ver lista de cartera | RF-09 a RF-12 | Consulta offline, indicadores de progreso, colores por tipo de gestión | 8 |
| HU-05 | Descarga nocturna | RF-13 a RF-14 | Tarea programada, notificaciones push, retries automáticos | 5 |
| HU-06 | Priorizar visitas | RF-15 a RF-16 | Puntaje automático, reordenamiento manual persistente | 5 |
| HU-07 | Marcar visita completada | RF-17 a RF-18 | Registro offline, sincronización en lote, actualización realtime | 5 |

### M2 — Planificación de Ruta
| HU | Descripción | RF | Criterios de aceptación | Story Points |
|----|------------|----|------------------------|--------------|
| HU-08 | Mapa de visitas | RF-19 a RF-22 | Marcadores por prioridad, optimización de ruta, integración Waze/Google Maps | 8 |
| HU-09 | Geocercas | RF-23 a RF-24 | Definir zonas por asesor, detectar visitas fuera de zona | 5 |
| HU-10 | Captura GPS | RF-25 a RF-26 | Geolocalización precisa, geocodificación inversa editable | 3 |

### M3 — Ficha del Cliente
| HU | Descripción | RF | Criterios de aceptación | Story Points |
|----|------------|----|------------------------|--------------|
| HU-11 | Ficha completa | RF-27 a RF-29 | Información completa del cliente, semáforo riesgo crediticio, llamada directa | 8 |
| HU-12 | Gráfico de pagos | RF-30 a RF-32 | Histórico de pagos 12 meses, indicadores calculados, offline | 5 |
| HU-13 | Oferta preaprobada | RF-33 a RF-34 | Mostrar monto máximo preaprobado, barra de confianza, prellenar solicitud | 5 |
| HU-14 | Alertas cartera | RF-35 a RF-36 | Suscripción realtime, insignia numérica, detalle alertas | 5 |

### M4 — Pre-evaluación y Prospección
| HU | Descripción | RF | Criterios de aceptación | Story Points |
|----|------------|----|------------------------|--------------|
| HU-15 | Pre-evaluar prospecto | RF-37 a RF-39 | Formulario básico, pre-evaluación offline, resultado APTO/REVISAR/NO PROCEDE | 8 |
| HU-16 | Gestionar campañas | RF-40 a RF-42 | Mostrar campañas activas, registro cliente desertor, expiración automática | 5 |

### M5 — Captura de Solicitud de Crédito
| HU | Descripción | RF | Criterios de aceptación | Story Points |
|----|------------|----|------------------------|--------------|
| HU-17 | Solicitud en 4 pasos | RF-43 a RF-48 | Formulario secuencial offline-first, validación campos, simulador en tiempo real, firma digital | 13 |
| HU-18 | Guardar y retomar borradores | RF-49 | Persistencia en SQLite, recuperación de borrador, borrado seguro | 3 |
| HU-19 | Simulador rápido | RF-50 | Cuota mensual y total, offline, reutilización en solicitud formal | 5 |
| HU-20 | Historial solicitudes | RF-51 a RF-52 | Lista por semana, indicadores, navegación al detalle | 3 |

### M6 — Captura de Documentos
| HU | Descripción | RF | Criterios de aceptación | Story Points |
|----|------------|----|------------------------|--------------|
| HU-21 | Fotografiar documentos | RF-53 a RF-54 | Validación nitidez, compresión automática, listado visual de estado | 8 |
| HU-22 | Revisar fotos | RF-55 a RF-56 | Reemplazo fotos, visor con zoom, confirmación eliminación | 3 |

### M7 — Consulta de Buró y Listas Negras
| HU | Descripción | RF | Criterios de aceptación | Story Points |
|----|------------|----|------------------------|--------------|
| HU-23 | Consultar buró | RF-57 a RF-59 | Firma digital de consentimiento, resultado JSON interpretado, semáforo financiero | 8 |
| HU-24 | Listas de restricción | RF-60 a RF-61 | Verificación en listas internas y externas, bloqueante si aplica, registro de auditoría | 3 |

---

## Instrucciones para Antigravity
1. Importar este README en el proyecto.  
2. Generar automáticamente todos los módulos y HU mencionados (**M0 a M7**) con sus RF correspondientes.  
3. Mantener flujos offline/online, validaciones, sincronización y notificaciones según el PDF de referencia.  
4. Paquetes recomendados:  
   - Flutter: camera, photo_view, geolocator, fl_chart, workmanager  
   - Backend / Supabase: Auth, Edge Functions, Storage, Realtime  
5. Ignorar módulos M8 a M11 en esta ejecución.
