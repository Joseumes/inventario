# Requisitos y reglas de negocio

## 1. Objetivo general

Construir una aplicación móvil en Flutter que permita identificar productos
mediante la cámara del dispositivo y actualizar el inventario de forma
organizada, validando las operaciones y conservando la información.

**Dirigida a**: una pequeña tienda o bodega que necesita consultar sus
existencias y mantener un historial de movimientos.

## 2. Alcance

- **Una tienda, una bodega y un dispositivo.**
- Operaciones principales **sin conexión a internet**.
- La sincronización entre dispositivos es una mejora opcional (no incluida).

## 3. Requisitos funcionales

### RF-1 Gestión de productos
- Registrar, consultar, editar y desactivar productos.
- Campos: código único, nombre, descripción, categoría, precio de compra,
  precio de venta, stock mínimo. Fotografía opcional.
- Las existencias iniciales se registran como **movimiento de entrada**
  (trazabilidad).

### RF-2 Generación de códigos
- Etiqueta con nombre, código y representación escaneable.
- **Code 128** a partir del código único + **QR** del mismo producto.
- Mostrar, compartir y exportar (PNG) para impresión.
- Sin códigos duplicados.

### RF-3 Lectura con la cámara
- Escanear barras o QR para buscar producto, ver datos/existencias y
  registrar entrada o salida.
- Mensaje cuando el código no esté registrado.
- Búsqueda manual por código o nombre.

### RF-4 Movimientos de inventario
- **Entrada**: aumenta existencias (cantidad + motivo).
- **Salida**: disminuye existencias (cantidad + motivo).
- **Ajuste**: corrige existencias tras conteo físico (cantidad contada +
  justificación obligatoria).
- Cada movimiento guarda: producto, fecha y hora, responsable, cantidad
  anterior y cantidad resultante.

### RF-5 Consultas y reportes
- Listado con existencias y alertas de stock ≤ mínimo.
- Historial filtrado por producto, tipo y fechas.
- Exportación del inventario a **CSV**.
- Valor del inventario = existencias × precio de compra (estimación).

## 4. Reglas de negocio

| # | Regla |
|---|---|
| RN-1 | Las cantidades de entrada y salida deben ser mayores que cero |
| RN-2 | No se permiten salidas superiores al stock disponible |
| RN-3 | Un producto con movimientos no se elimina definitivamente; se desactiva |
| RN-4 | Los movimientos confirmados no se editan ni eliminan; los errores se corrigen con un nuevo movimiento |
| RN-5 | El registro del movimiento y la actualización de existencias son una sola operación |
| RN-6 | El código identifica al producto; la cantidad no se guarda dentro del QR |
| RN-7 | Códigos de producto únicos |

Implementación: `features/inventario/domain/services/reglas_inventario.dart`,
casos de uso del dominio y `MovimientoRepositoryImpl` (operación única).

## 5. Requisitos técnicos

| Requisito | Cumplimiento |
|---|---|
| Flutter y Dart |  Flutter 3.x / Dart 3 |
| Arquitectura feature + domain |  Ver [arquitectura.md](arquitectura.md) |
| Estrategia consistente de estado |  `provider` + `ChangeNotifier` |
| Persistencia local |  SharedPreferences + JSON |
| Operaciones sin internet |  100% offline |
| Validaciones y manejo de errores |  Ver [validaciones_errores.md](validaciones_errores.md) |
| Estados de carga, confirmación y vacíos |  Spinners, SnackBars, estados vacíos |
| Prueba de escaneo en dispositivo físico |  Pendiente de la demostración (instalar el APK) |

## 6. Entregables y estado

| Entregable | Ubicación / estado |
|---|---|
| Código fuente en repositorio | Este proyecto (subir a GitHub/GitLab) |
| APK funcional | Ver [apk_compilacion.md](apk_compilacion.md) |
| README.md |  Raíz del proyecto |
| Documentación técnica .md |  Carpeta `docs/` |
| Manual de usuario en PDF | Fuente en `docs/manual_usuario.md` (+ HTML imprimible) |
| Datos de demostración |  15 productos y 3 categorías al primer arranque |
| Evidencia de pruebas |  `docs/pruebas.md` + `test/reglas_inventario_test.dart` |
| Presentación y demostración | Preparada con el flujo de aceptación |
