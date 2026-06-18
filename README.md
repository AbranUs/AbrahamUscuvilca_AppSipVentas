# App Fuerza de Ventas - SIP (Módulos M0 a M7)

## Descripción
Aplicación móvil para oficiales de crédito en campo de microfinanzas en Perú. Reemplaza el expediente físico, permite descargar la cartera diaria, registrar solicitudes de crédito, capturar documentos, consultar buró de crédito y listas de restricción (listas negras), incluso sin conexión a internet (offline-first).

---

## Arquitectura y Flujo de Negocio
El flujo de negocio principal que sigue la aplicación para la prospección y colocación en campo es:
```
Pre-evaluación ➔ Evaluación ➔ Aprobación ➔ Desembolso ➔ Recuperación
```

### Tecnologías Clave:
*   **Frontend**: Flutter (Dart)
*   **Base de Datos**: Supabase (PostgreSQL, Realtime, RLS) & SQLite (Persistencia Local para Offline-First)
*   **Servicios Externos**: Equifax/Sentinel API (Buró), Supabase Storage (Expedientes)
*   **Herramientas**: WorkManager (Sincronización en segundo plano), geolocator, camera, photo_view, fl_chart.

---

## Módulos del Sistema e Historias de Usuario

### M0 — Autenticación y Perfiles
| HU | Descripción | RF | Criterios de Aceptación | Story Points |
| :--- | :--- | :--- | :--- | :---: |
| **HU-01** | Login del asesor | RF-01 a RF-04 | Formulario login, persistencia, bloqueo por intentos fallidos. | 5 |
| **HU-02** | Perfiles de acceso | RF-05 a RF-06 | Menú lateral adaptativo (Drawer), roles y capacidades de oficiales. | 3 |
| **HU-03** | Cierre de sesión | RF-07 a RF-08 | Logout seguro, borrado datos sensibles, advertencia de documentos pendientes. | 3 |

### M1 — Cartera Diaria
| HU | Descripción | RF | Criterios de Aceptación | Story Points |
| :--- | :--- | :--- | :--- | :---: |
| **HU-04** | Ver lista de cartera | RF-09 a RF-12 | Consulta offline, indicadores de progreso diario, colores por tipo de gestión. | 8 |
| **HU-05** | Descarga nocturna | RF-13 a RF-14 | Tarea programada, notificaciones push de carga, retries automáticos. | 5 |
| **HU-06** | Priorizar visitas | RF-15 a RF-16 | Puntaje automático por prioridad, reordenamiento manual persistente. | 5 |
| **HU-07** | Marcar visita completada | RF-17 a RF-18 | Registro offline en campo, sincronización en lote, actualización realtime. | 5 |

### M2 — Planificación de Ruta
| HU | Descripción | RF | Criterios de Aceptación | Story Points |
| :--- | :--- | :--- | :--- | :---: |
| **HU-08** | Mapa de visitas | RF-19 a RF-22 | Marcadores por prioridad, optimización de ruta de visitas, integración con Waze/Google Maps. | 8 |
| **HU-09** | Geocercas | RF-23 a RF-24 | Definición de zonas por asesor comercial, detección y alerta de visitas fuera de zona. | 5 |
| **HU-10** | Captura GPS | RF-25 a RF-26 | Geolocalización precisa del cliente, geocodificación inversa editable. | 3 |

### M3 — Ficha del Cliente
| HU | Descripción | RF | Criterios de Aceptación | Story Points |
| :--- | :--- | :--- | :--- | :---: |
| **HU-11** | Ficha completa | RF-27 a RF-29 | Datos completos del cliente, semáforo de riesgo crediticio, llamada directa. | 8 |
| **HU-12** | Gráfico de pagos | RF-30 a RF-32 | Histórico de pagos de últimos 12 meses, indicadores calculados de puntualidad, offline. | 5 |
| **HU-13** | Oferta preaprobada | RF-33 a RF-34 | Mostrar monto máximo preaprobado en campaña, barra de nivel de confianza, prellenado. | 5 |
| **HU-14** | Alertador de cartera | RF-35 a RF-36 | Suscripción realtime a avisos de mora de clientes, insignia numérica de notificaciones. | 5 |

### M4 — Pre-evaluación y Prospección
| HU | Descripción | RF | Criterios de Aceptación | Story Points |
| :--- | :--- | :--- | :--- | :---: |
| **HU-15** | Pre-evaluar prospecto | RF-37 a RF-39 | Formulario de prefiltrado básico, evaluación offline, resultado APTO/REVISAR/NO PROCEDE. | 8 |
| **HU-16** | Gestionar campañas | RF-40 a RF-42 | Mostrar campañas comerciales activas, registro de clientes desertores, expiración automática. | 5 |

### M5 — Captura de Solicitud de Crédito
| HU | Descripción | RF | Criterios de Aceptación | Story Points |
| :--- | :--- | :--- | :--- | :---: |
| **HU-17** | Solicitud en 4 pasos | RF-43 a RF-48 | Formulario secuencial offline-first, validaciones de negocio, simulador de cuotas, firma digital. | 13 |
| **HU-18** | Guardar y retomar borradores | RF-49 | Persistencia local en SQLite, recuperación rápida de borrador, borrado seguro. | 3 |
| **HU-19** | Simulador rápido | RF-50 | Cálculo rápido de cuota mensual y total offline, reutilización en solicitud formal. | 5 |
| **HU-20** | Historial solicitudes | RF-51 a RF-52 | Lista de solicitudes por semana, indicador de estado de aprobación, navegación al detalle. | 3 |

### M6 — Captura de Documentos
| HU | Descripción | RF | Criterios de Aceptación | Story Points |
| :--- | :--- | :--- | :--- | :---: |
| **HU-21** | Fotografiar documentos | RF-53 a RF-54 | Detección de nitidez/bordes, compresión automática, listado visual del estado del expediente. | 8 |
| **HU-22** | Revisar fotos | RF-55 a RF-56 | Reemplazo rápido de fotos borrosas, visor interactivo con zoom, confirmación de eliminación. | 3 |

### M7 — Consulta de Buró y Listas Negras
| HU | Descripción | RF | Criterios de Aceptación | Story Points |
| :--- | :--- | :--- | :--- | :---: |
| **HU-23** | Consultar buró | RF-57 a RF-59 | Firma digital de autorización de consulta, resultado JSON interpretado, semáforo financiero. | 8 |
| **HU-24** | Listas de restricción | RF-60 a RF-61 | Verificación en listas de prevención de lavado de activos, bloqueante si aplica, log de auditoría. | 3 |

---

## Nota
*Los módulos del M8 al M11 quedan fuera del alcance de esta versión actual.*
