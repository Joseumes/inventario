# Manual de usuario — Inventario Inteligente

> **Cómo generar el PDF entregable:** abre `docs/manual_usuario.html` en
> cualquier navegador (Chrome/Edge) y usa **Imprimir → Guardar como PDF**.
> Toma las capturas de pantalla de tu app instalada e insértalas donde se
> indica `[CAPTURA: ...]` antes de exportar.

---

## 1. Introducción

**Inventario Inteligente** es una aplicación para teléfonos Android que
permite a una pequeña tienda o bodega:

- Registrar y consultar sus **productos** con existencias.
- Generar **etiquetas con código de barras (Code 128) y QR**.
- **Escanear** códigos con la cámara para encontrar productos rápido.
- Registrar **entradas, salidas y ajustes** de inventario.
- Ver **alertas de stock bajo**, revisar el **historial** y **exportar a CSV**.

La aplicación funciona **sin internet**: toda la información se guarda en el
propio teléfono.

## 2. Instalación y permisos

1. Instala el APK en tu teléfono (archivo `app-release.apk`).
2. Si Android pregunta, acepta "Instalar de origen desconocido".
3. Abre la app. Al primer uso verás datos de **demostración** (15 productos
   y 3 categorías) para que puedas practicar; puedes editarlos o desactivarlos.
4. **Permisos**: al usar el escáner por primera vez, la app pedirá permiso
   de **Cámara**. Acepta para poder escanear. Si lo niegas, aún puedes usar
   la **búsqueda manual**.

`[CAPTURA: pantalla de inicio con las 4 pestañas]`

## 3. Pantalla de inicio

La pestaña **Inicio** muestra:

- **Tarjetas de resumen**: cantidad de productos, alertas de stock bajo,
  movimientos registrados y valor total del inventario.
- **Accesos rápidos**: nuevo producto, ver productos, escanear e historial.
- **Alertas de stock bajo** con los productos que necesitan reabastecimiento.
- **Últimos movimientos** registrados.

Toca la **silueta de persona** (arriba a la derecha) para poner tu **nombre
como responsable**: aparecerá firmado en cada movimiento que registres.

`[CAPTURA: tarjeta de perfil]`

## 4. Gestión de productos

### 4.1 Crear un producto

1. Pestaña **Productos → botón Nuevo** (o acceso rápido en Inicio).
2. Completa el formulario:
   - **Código único**: identificador que se convertirá en código de barras y QR
     (ej. `ELE-006`). No puede repetirse.
   - **Nombre** (obligatorio), **descripción** y **categoría**.
   - **Precio de compra** y **precio de venta**.
   - **Stock mínimo**: cuando el stock llegue a este valor o menos, la app
     mostrará una alerta.
   - **Existencias iniciales**: se registran automáticamente como un
     **movimiento de ENTRADA** para mantener la trazabilidad.
   - **Foto** (opcional): toca el ícono de cámara para tomar una foto o
     elegir de la galería.
3. Toca **Guardar**.

`[CAPTURA: formulario de producto completo]`

### 4.2 Buscar y filtrar

En **Productos** puedes buscar por nombre, código o descripción, y usar los
filtros **Stock bajo** y **Mostrar inactivos**.

`[CAPTURA: listado con filtro de stock bajo activo]`

### 4.3 Editar

Abre el producto y toca el ícono **lápiz**. El stock actual **no se edita
a mano**: se cambia únicamente con movimientos (entrada, salida o ajuste).

### 4.4 Desactivar o eliminar

- Toca el ícono de **papelera** en el detalle:
  - Si el producto **tiene movimientos**, se **desactiva** (su historial se
    conserva y aparece con el filtro "Mostrar inactivos").
  - Si **no tiene movimientos**, se elimina.
- Un producto desactivado puede **reactivarse** desde su detalle
  (ícono de flecha circular).

## 5. Etiquetas: código de barras y QR

En el **detalle del producto**, sección **Etiquetas**, verás:

- El **código de barras Code 128** con tu código único.
- El **código QR** con el mismo código.
- Botones para **Compartir PNG** (imagen lista para imprimir) y
  **Compartir texto**.

`[CAPTURA: sección de etiquetas con ambos códigos]`

> El código identifica al producto. Las existencias **no** están dentro del
> QR: se consultan siempre en la base de datos, así la etiqueta nunca queda
> desactualizada.

## 6. Escanear códigos

1. Pestaña **Escáner** y apunta la cámara al código de barras o QR.
2. Al reconocer el código:
   - Si el producto **existe**: se abre su ficha con existencias y botones
     de entrada/salida/ajuste.
   - Si **no existe**: la app avisa "Producto no registrado" y ofrece
     **crear el producto** con el código ya escrito.
3. **Búsqueda manual**: si no puedes usar la cámara, escribe el código o el
   nombre en el campo inferior y toca la flecha.

`[CAPTURA: escáner con marco guía]`

## 7. Registrar movimientos

Desde el detalle del producto (o tras escanear), elige:

### Entrada (aumenta stock)
Cantidad **mayor que cero** + **motivo** (compra, devolución…). Usa los
botones rápidos para escribir el motivo con un toque.

### Salida (disminuye stock)
Cantidad **mayor que cero** + motivo (venta, daño…). La app **nunca permite
retirar más de lo que hay**: verás "Stock insuficiente".

### Ajuste (conteo físico)
Escribe la **cantidad contada** y una **justificación obligatoria**
(ej. "conteo físico mensual"). El stock pasará a ser la cantidad contada.

`[CAPTURA: pantalla de movimiento con tipo seleccionado]`

Cada movimiento guarda **fecha y hora, responsable, stock anterior y
resultante**. Los movimientos confirmados **no se pueden editar ni
eliminar**: si te equivocas, corrige con un nuevo movimiento.

## 8. Alertas de stock bajo

Cuando el stock de un producto es **igual o menor** que su stock mínimo:

- Aparece en **Inicio** en la sección de alertas.
- En **Productos** puedes filtrar solo los productos en alerta.
- En el **detalle** se muestra la franja naranja "Stock bajo".

`[CAPTURA: alerta de stock bajo]`

## 9. Historial y reportes

La pestaña **Historial** muestra todos los movimientos con:

- **Filtros**: tipo (entrada/salida/ajuste), producto y rango de fechas.
- **Resumen**: productos activos, alertas y valor del inventario.
- **Exportar CSV** (íconos de descarga arriba):
  - Inventario completo (código, nombre, stock, precios, valor).
  - Movimientos filtrados (tipo, producto, cantidades, motivo, responsable, fecha).

El CSV se comparte como archivo: envíalo por correo o WhatsApp, o ábrelo en
Excel/Google Sheets.

`[CAPTURA: historial con filtros aplicados]`

## 10. Mensajes comunes y cómo resolverlos

| Mensaje | Qué significa | Qué hacer |
|---|---|---|
| "El código X ya está asignado a…" | Otro producto usa ese código | Usa un código diferente |
| "Stock insuficiente: solicitas N y hay M" | Intentas retirar más de lo disponible | Registra una entrada o reduce la cantidad |
| "La justificación del ajuste es obligatoria" | Ajuste sin motivo | Explica el motivo del conteo |
| "El producto está desactivado…" | El producto está inactivo | Reactívalo desde su detalle |
| "Se necesita el permiso de cámara…" | Permiso denegado | Actívalo en Ajustes → Aplicaciones → Permisos, o usa la búsqueda manual |
| "La cámara no está disponible…" | Emulador/web o sin cámara | Usa la búsqueda manual |
| "No se pudo generar la imagen de la etiqueta" | Fallo puntual al capturar | Intenta de nuevo o comparte como texto |

## 11. Preguntas frecuentes

**¿Se borran mis datos si cierro la app?**
No. Todo queda guardado en el teléfono y se recarga al abrir.

**¿Puedo usar la app sin internet?**
Sí, todas las funciones funcionan sin conexión.

**¿Por qué no puedo borrar un producto con historial?**
Para conservar la trazabilidad del inventario se desactiva en lugar de
eliminarse.

**¿Cómo corrijo un movimiento equivocado?**
Registra un nuevo movimiento que lo corrija (por ejemplo, una entrada por
devolución). Los movimientos confirmados son inmutables.
