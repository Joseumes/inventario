# Validaciones, manejo de errores y consistencia

## 1. Jerarquía de errores (dominio)

`lib/core/errors/failures.dart`:

| Clase | Cuándo se lanza |
|---|---|
| `ValidacionFailure` | Datos inválidos: campos vacíos, cantidad ≤ 0, justificación faltante, producto inexistente/desactivado |
| `StockInsuficienteFailure` | Salida mayor al stock disponible |
| `CodigoDuplicadoFailure` | Código de producto ya asignado |
| `AlmacenamientoFailure` | Fallo de escritura en el almacenamiento local (con rollback aplicado) |

`lib/core/errors/mensajes.dart` traduce cualquier excepción a texto legible
para el usuario (`mensajeAmigable`), usado en todas las SnackBars.

## 2. Validaciones de formulario (presentación)

| Formulario | Validaciones |
|---|---|
| Producto | Código y nombre requeridos; precios numéricos ≥ 0 (acepta coma decimal); stock mínimo ≥ 0; existencias iniciales ≥ 0 |
| Movimiento | Cantidad entera válida; entrada/salida > 0; salida ≤ stock actual (aviso inmediato); ajuste ≥ 0 y ≠ stock actual; motivo/justificación obligatorios |

La validación del formulario es **ayuda inmediata al usuario**; la regla
definitiva se aplica **otra vez en el dominio** (defensa en profundidad).

## 3. Reglas de negocio y dónde viven

Todas en el **dominio** (`ReglasInventario` + casos de uso):

1. Cantidades de entrada/salida **> 0**.
2. **No** se permiten salidas superiores al stock disponible.
3. Producto **con movimientos no se elimina**; se desactiva.
4. Movimientos confirmados **no se editan ni eliminan** (no existe ninguna
   operación de edición/borrado de movimientos en todo el código).
5. Productos desactivados **no admiten movimientos**.
6. Códigos de producto **únicos**.

## 4. Consistencia: operación única (requisito 4)

`MovimientoRepositoryImpl.registrarConActualizacionStock(...)`:

```
1. Guarda copias de seguridad de movimientos y productos.
2. Escribe el nuevo movimiento.
3. Escribe el producto con el stock resultante.
4. Si CUALQUIER paso falla → restaura las copias (rollback)
   y lanza AlmacenamientoFailure.
```

Garantiza que nunca quede un **movimiento registrado sin stock actualizado**
ni un **stock cambiado sin movimiento** (trazabilidad e integridad).

## 5. Errores de cámara y permisos

| Situación | Respuesta de la app |
|---|---|
| Permiso denegado | Mensaje + se sugiere búsqueda manual |
| Permiso denegado permanentemente | Instrucción para habilitar en Ajustes |
| Fallo al iniciar cámara | Mensaje + búsqueda manual |
| Plataforma sin cámara (web/emulador) | Mensaje claro, búsqueda manual disponible |
| Foto (image_picker) falla | SnackBar sugiriendo usar la galería |

## 6. Errores de almacenamiento

- `main.dart` captura fallos de inicialización y muestra una pantalla de
  error explicativa (no una pantalla gris).
- `LocalStorage._leerLista` tolera JSON corrupto: devuelve lista vacía en
  lugar de crashear.
- Escrituras atómicas de movimientos con rollback (sección 4).

## 7. Mensajes comunes y solución (resumen para el manual)

| Mensaje | Causa | Solución |
|---|---|---|
| "El código X ya está asignado a…" | Código duplicado | Usa otro código |
| "Stock insuficiente: solicitas N y hay M" | Salida > stock | Registra entrada o reduce la cantidad |
| "La justificación del ajuste es obligatoria" | Ajuste sin motivo | Escribe el motivo del conteo |
| "El producto está desactivado…" | Movimiento sobre inactivo | Reactiva el producto |
| "Se necesita el permiso de cámara…" | Permiso denegado | Habilita el permiso o usa búsqueda manual |
