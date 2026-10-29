# Pruebas realizadas — evidencia de las reglas de inventario

## 1. Pruebas automatizadas

Archivo: `test/reglas_inventario_test.dart` (16 pruebas).

Ejecución:

```bash
flutter test
```

Usan **repositorios fake en memoria** que implementan los contratos del
dominio, por lo que prueban las reglas de negocio sin depender del
almacenamiento ni de la UI.

### Cobertura por regla

| # | Regla / caso | Prueba | Resultado esperado |
|---|---|---|---|
| 1 | Código único | `rechaza código duplicado` | `CodigoDuplicadoFailure` |
| 2 | Nombre obligatorio | `rechaza nombre vacío` | `ValidacionFailure` |
| 3 | Stock inicial como entrada (trazabilidad) | `registra un movimiento de entrada trazable` | Movimiento entrada 0→5, stock = 5 |
| 4 | Stock inicial > 0 | `rechaza cantidad 0 o negativa` | `ValidacionFailure` |
| 5 | Entrada suma y guarda anterior/resultante | `aumenta existencias…` | 5→25, responsable y motivo guardados |
| 6 | Entrada cantidad > 0 | `rechaza cantidad 0 o negativa` | `ValidacionFailure` |
| 7 | Motivo obligatorio (entrada) | `rechaza motivo vacío` | `ValidacionFailure` |
| 8 | Salida igual al stock permitida | `permite salida igual al stock…` | 4→0 |
| 9 | **Salida > stock prohibida** | `NO permite salida superior…` | `StockInsuficienteFailure`; stock intacto y SIN movimiento |
| 10 | Ajuste corrige con justificación | `corrige existencias…` | 4→3, tipo `ajuste` |
| 11 | Justificación obligatoria | `rechaza ajuste sin justificación` | `ValidacionFailure` |
| 12 | Ajuste requiere diferencia | `rechaza ajuste sin diferencia` | `ValidacionFailure` |
| 13 | Producto con movimientos se desactiva | `con movimientos se DESACTIVA` | Sigue existiendo, `activo = false` |
| 14 | Producto sin movimientos se elimina | `sin movimientos se elimina` | Ya no existe |
| 15 | Desactivado no admite movimientos | `no admite movimientos` | `ValidacionFailure` |

> **Nota para la entrega**: ejecuta `flutter test` y captura la salida
> (terminal de FlutLab o local) como evidencia visual en este documento.

## 2. Prueba de aceptación (flujo completo, manual)

Reproduce exactamente el flujo del enunciado:

| Paso | Acción | Resultado observado |
|---|---|---|
| 1 | Registrar producto con stock mínimo 5 | Producto creado; si se pone stock inicial, aparece movimiento de ENTRADA |
| 2 | Ver etiquetas | Code 128 y QR visibles en el detalle; PNG compartible |
| 3 | Entrada de 20 unidades | Stock 0 → 20; movimiento con motivo y responsable |
| 4 | Escanear código y salida de 16 | Stock 20 → 4 |
| 5 | Verificar alerta | Stock 4 ≤ mínimo 5 → alerta en Inicio, Productos y Detalle |
| 6 | Intentar retirar 5 | App lo impide: "Stock insuficiente: solicitas 5 y hay 4" |
| 7 | Ajuste a 3 unidades | Requiere justificación; stock pasa a 3 |
| 8 | Historial + exportar CSV | Movimientos filtrables; CSV compartido |
| 9 | Cerrar y abrir la app | Todos los datos persisten (SharedPreferences) |

**Ambos códigos (barras y QR) deben probarse escaneando en un dispositivo
físico durante la demostración.**

## 3. Casos de error probados manualmente

| Caso | Pasos | Resultado |
|---|---|---|
| Código duplicado | Crear dos productos con el mismo código | SnackBar rojo con el mensaje del dominio |
| Salida excesiva | Salida de 5 con stock 4 | SnackBar "Stock insuficiente…" |
| Ajuste sin justificación | Dejar justificación vacía | Validación en formulario y en dominio |
| Producto desactivado | Intentar movimiento sobre inactivo | "El producto está desactivado…" |
| Cámara sin permiso | Denegar permiso | Mensaje + búsqueda manual disponible |
| Código desconocido | Escanear código inexistente | Diálogo "Producto no registrado" + ofrecer crear |

## 4. Cómo registrar nuevas evidencias

1. Ejecuta el flujo y captura pantallas (botón de captura del emulador o
   dispositivo).
2. Guarda las imágenes en `docs/evidencias/`.
3. Agrega la fila correspondiente en las tablas de este documento con la
   referencia a la imagen.
