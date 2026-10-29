# Modelo de datos

## 1. Persistencia

- **Motor**: `SharedPreferences` (almacenamiento clave-valor local).
- **Formato**: cada colección se guarda como un **string JSON**.
- **Claves**:

| Clave | Contenido |
|---|---|
| `productos` | Lista de productos (JSON) |
| `categorias` | Lista de categorías (JSON) |
| `movimientos` | Lista de movimientos (JSON) |
| `responsable_nombre` | Nombre del responsable local (perfil) |

- **Offline por diseño**: todas las operaciones funcionan sin internet.
- **Datos demo**: en el primer arranque se siembran **3 categorías** y
  **15 productos** con su movimiento de entrada inicial (`_seedDemo()` en
  `core/storage/local_storage.dart`).

## 2. Relaciones

```
Categoria 1 ──── N Producto (Producto.categoriaId)
Producto  1 ──── N Movimiento (Movimiento.productoId)
```

- La relación es **lógica** (por id); no hay claves foráneas porque el
  almacenamiento es JSON.
- **Integridad**: un producto con movimientos nunca se elimina (regla de
  negocio), por lo que ningún movimiento queda huérfano.

## 3. Entidad: Producto

| Campo | Tipo | Regla |
|---|---|---|
| `id` | String (UUID v4) | Identificador interno único |
| `codigo` | String | **Código único** de negocio. Sin duplicados (CU-01/CU-03). Es lo que se codifica en Code 128 y QR |
| `nombre` | String | Obligatorio |
| `descripcion` | String? | Opcional |
| `categoriaId` | String? | Referencia a Categoria |
| `precioCompra` | double | ≥ 0. Base del valor del inventario |
| `precioVenta` | double | ≥ 0 |
| `stockActual` | int | **Solo se modifica mediante movimientos** |
| `stockMinimo` | int | ≥ 0. Alerta cuando `stockActual ≤ stockMinimo` |
| `fotoBase64` | String? | Fotografía opcional comprimida (base64) |
| `activo` | bool | Desactivación lógica (nunca borrado si hay movimientos) |

**Propiedades derivadas** (en la entidad, dominio):

- `stockBajo` → `stockActual <= stockMinimo`
- `valorInventario` → `stockActual * precioCompra` (estimación; sin métodos
  contables de valoración, según el enunciado).

## 4. Entidad: Categoria

| Campo | Tipo | Regla |
|---|---|---|
| `id` | String | `cat1..cat3` en el seed; `cat_<timestamp>` para nuevas |
| `nombre` | String | Único (comparación sin mayúsculas/minúsculas) |

## 5. Entidad: Movimiento

| Campo | Tipo | Regla |
|---|---|---|
| `id` | String (UUID v4) | Identificador único |
| `productoId` | String | Referencia al producto |
| `tipo` | String | `'entrada'` \| `'salida'` \| `'ajuste'` |
| `cantidad` | int | Entrada/salida: unidades movidas (> 0). Ajuste: cantidad **contada** (≥ 0) |
| `stockAnterior` | int | Existencias antes del movimiento |
| `stockResultante` | int | Existencias después del movimiento |
| `motivo` | String | Entrada/salida: motivo (compra, venta…). Ajuste: **justificación obligatoria** |
| `responsable` | String | Perfil local (o usuario autenticado si se implementa login) |
| `fecha` | DateTime (ISO 8601) | Fecha y hora del registro |

**Invariante de consistencia**: para entrada y salida,
`stockResultante = stockAnterior ± cantidad`; para ajuste,
`stockResultante = cantidad` (contada).

## 6. Entidad: Perfil (responsable)

| Campo | Tipo |
|---|---|
| `nombre` | String |

Alcance mínimo: un responsable local editable en `PerfilPage`. Si se
implementa inicio de sesión (ampliación opcional), el responsable debe
asociarse al usuario autenticado.

## 7. Objeto-valor: FiltroMovimientos

Usado por el caso de uso `ObtenerHistorial`:

| Campo | Tipo | Uso |
|---|---|---|
| `productoId` | String? | Historial de un producto |
| `tipo` | String? | entrada / salida / ajuste |
| `desde` | DateTime? | Fecha inicial (inclusive) |
| `hasta` | DateTime? | Fecha final (inclusive el día completo) |

## 8. Diagrama general

```
┌────────────┐      ┌─────────────────┐      ┌──────────────┐
│ Categoria  │ 1..N │    Producto     │ 1..N │  Movimiento  │
│ id, nombre │─────▶│ codigo (único)  │─────▶│ tipo         │
└────────────┘      │ stockActual     │      │ stockAnterior│
                    │ stockMinimo     │      │ stockResult. │
                    │ precios, foto   │      │ motivo       │
                    │ activo          │      │ responsable  │
                    └─────────────────┘      │ fecha        │
                                             └──────────────┘
```

## 9. Por qué no se guarda la cantidad dentro del QR

El código (barras/QR) identifica al producto; las existencias se consultan
en la base de datos. La cantidad disponible **cambia con cada movimiento**;
guardarla dentro del QR produciría etiquetas desactualizadas. Por eso el
contenido escaneable es **solo el código único del producto**.
