# Generación y lectura de códigos de barras y QR

## 1. Contenido codificado

**Ambos códigos contienen únicamente el código único del producto**
(p. ej. `ELE-001`).

- El código **identifica** al producto; las existencias se consultan en la
  base de datos al escanear.
- La cantidad disponible **NO se guarda dentro del QR**, porque cambia con
  cada movimiento (una etiqueta con cantidad quedaría desactualizada).

## 2. Generación (etiquetas)

| Tipo | Paquete | Simbología | Datos |
|---|---|---|---|
| Código de barras | `barcode_widget` | **Code 128** | Código único del producto |
| Código QR | `qr_flutter` | QR (versión auto) | Código único del producto |

Ubicación del código fuente:

- Widget reutilizable: `lib/features/productos/presentation/widgets/etiqueta_widget.dart`
- Vista en el detalle: `producto_detalle_page.dart` (sección **Etiquetas**).

Cada etiqueta muestra: **nombre del producto + código + Code 128 + QR**.

### Evitar códigos duplicados

- `CrearProducto` y `ActualizarProducto` (dominio) rechazan códigos ya
  asignados a otro producto (`CodigoDuplicadoFailure`).
- El escáner verifica existencia antes de ofrecer crear un producto nuevo.

## 3. Compartir y exportar para impresión

En el detalle del producto:

- **Compartir PNG**: la etiqueta se captura con `RepaintBoundary` +
  `toImage(pixelRatio: 3.0)` y se comparte como imagen PNG
  (`share_plus`), lista para imprimir o enviar por WhatsApp/correo.
- **Compartir texto**: alternativa con nombre, código y precio.

## 4. Lectura con la cámara

- Paquete: `mobile_scanner` (compatible con ML Kit; lee Code 128 y QR).
- Pantalla: `lib/features/escaner/presentation/pages/escaner_page.dart`.

Flujo de escaneo:

1. Se solicita el **permiso de cámara** con `permission_handler`.
2. `MobileScannerController` con `DetectionSpeed.noDuplicates` evita
   disparar varias veces con el mismo código.
3. Al detectar un código se **pausa la cámara**, se busca el producto:
   - **Existe** → se abre su detalle (datos, existencias y movimientos).
   - **No existe** → se muestra el mensaje *"Producto no registrado"* y se
     ofrece crear el producto **con el código ya prellenado**.
4. Al volver del detalle/formulario, la cámara se reanuda.

## 5. Búsqueda manual

Para cuando la cámara no está disponible (permisos denegados, emulador, web):

- Campo de texto que acepta **código o nombre**.
- Código exacto → abre el producto directamente.
- Nombre → lista de coincidencias para elegir.

## 6. Permisos de cámara

| Plataforma | Permiso | Configuración |
|---|---|---|
| Android | `CAMERA` | `android/app/src/main/AndroidManifest.xml` |
| iOS | `NSCameraUsageDescription` | `ios/Runner/Info.plist` |

En `AndroidManifest.xml` la cámara se declara con
`uses-feature android:required="false"` para permitir instalación en
dispositivos sin cámara (se usa búsqueda manual en ese caso).

## 7. Manejo de errores de cámara

- Permiso denegado → mensaje con instrucción y acceso a búsqueda manual.
- Permiso denegado permanentemente → se indica cómo habilitarlo en Ajustes.
- Fallo al iniciar la cámara → mensaje y búsqueda manual.
- Plataforma sin cámara (web) → mensaje claro desde el arranque.
