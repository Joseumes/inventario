# Funcionalidades, casos de uso y gestión de estado

## 1. Pantallas

| # | Pantalla | Archivo | Función |
|---|---|---|---|
| 1 | Inicio | `features/inicio/.../inicio_page.dart` | Resumen (productos, alertas, movimientos, valor), accesos rápidos |
| 2 | Productos | `features/productos/.../productos_page.dart` | Listado, búsqueda y filtros (stock bajo, inactivos) |
| 3 | Formulario de producto | `producto_form_page.dart` | Creación y edición; existencias iniciales como entrada |
| 4 | Detalle del producto | `producto_detalle_page.dart` | Datos, existencias, etiquetas Code 128/QR, historial del producto |
| 5 | Escáner | `features/escaner/.../escaner_page.dart` | Lectura de códigos + búsqueda manual |
| 6 | Movimiento | `features/inventario/.../movimiento_page.dart` | Registro de entrada, salida y ajuste |
| 7 | Historial y reportes | `features/reportes/.../historial_page.dart` | Filtros, resumen y exportación CSV |
| 8 | Perfil | `features/perfil/.../perfil_page.dart` | Nombre del responsable |

La navegación principal es un `BottomNavigationBar` con `IndexedStack`
(Inicio · Productos · Escáner · Historial); el resto son pantallas apiladas.

## 2. Casos de uso (dominio)

| CU | Caso de uso | Archivo | Reglas que aplica |
|---|---|---|---|
| CU-01 | Crear producto | `productos/domain/usecases/crear_producto.dart` | Código único, nombre obligatorio, precios ≥ 0 |
| CU-02 | Editar producto | `actualizar_producto.dart` | Sin duplicar código; no toca el stock |
| CU-03 | Desactivar / eliminar | `desactivar_producto.dart` | Con movimientos → desactiva; sin movimientos → elimina |
| CU-04 | Reactivar producto | `desactivar_producto.dart` (ReactivarProducto) | Vuelve a estar activo |
| CU-05 | Stock inicial como entrada | `inventario/.../registrar_stock_inicial.dart` | Trazabilidad del stock inicial |
| CU-06 | Obtener historial | `obtener_historial.dart` | Filtros por producto, tipo y fechas |
| CU-07 | Registrar entrada | `registrar_entrada.dart` | Cantidad > 0, motivo obligatorio, producto activo |
| CU-08 | Registrar salida | `registrar_salida.dart` | Cantidad > 0, **stock suficiente**, motivo obligatorio |
| CU-09 | Registrar ajuste | `registrar_ajuste.dart` | Justificación obligatoria, diferencia ≠ 0 |

Las reglas transversales viven en
`features/inventario/domain/services/reglas_inventario.dart`
(servicio de dominio `ReglasInventario`), de modo que **no dependen de
widgets ni de la base de datos**.

## 3. Gestión de estado

Estrategia única y consistente: **paquete `provider` con `ChangeNotifier`**.

| Provider | Estado expuesto |
|---|---|
| `ProductoProvider` | `productos`, `categorias`, `cargando`, `error`, `filtro`, `verInactivos`, `productosFiltrados`, `productosStockBajo`, `valorInventario` |
| `MovimientoProvider` | `movimientos`, `cargando`, `error`; filtros en memoria con `filtrar(...)` |
| `PerfilProvider` | `perfil` / `nombre` del responsable |

Patrón de cada operación:

```
UI (página) ──▶ Provider ──▶ Caso de uso ──▶ Repositorio (contrato)
     ▲                                          │
     └────────── notifyListeners() ◀────────────┘
```

- `cargando = true` → `notifyListeners()` → la UI muestra spinner.
- Éxito → se recargan los datos → `notifyListeners()`.
- Error → la excepción del dominio se propaga a la página, que muestra un
  `SnackBar` con `mensajeAmigable(e)`.

La lista completa de movimientos se mantiene en memoria y el filtrado se
aplica en presentación (`filtrar`), de modo que cambiar de pestaña no
pierde la lista sin filtrar.

## 4. Flujo de información del flujo de aceptación

1. **Registrar producto** (stock mínimo 5) → CU-01 + CU-05 (entrada inicial).
2. **Generar/ver códigos** → Detalle: Code 128 + QR a partir del código único.
3. **Entrada de 20** → CU-07: stock 0 → 20.
4. **Escanear y salida de 16** → Escáner → Detalle → CU-08: 20 → 4.
5. **Alerta** → `stockBajo` (4 ≤ 5) aparece en Inicio, Productos y Detalle.
6. **Retirar 5** → CU-08 lanza `StockInsuficienteFailure`; la UI lo impide.
7. **Ajuste a 3** → CU-09 con justificación obligatoria.
8. **Historial + exportar CSV** → Historial y reportes.
9. **Cerrar y abrir** → SharedPreferences restaura todo (persistencia).

## 5. Estados de UI cubiertos (requisito técnico)

- **Carga**: spinners en listados y botones deshabilitados al guardar.
- **Vacío**: mensajes claros en productos, historial y movimientos.
- **Confirmación**: SnackBars al crear/editar/registrar.
- **Error**: SnackBars rojos con mensajes legibles (validaciones, stock,
  cámara, almacenamiento).
