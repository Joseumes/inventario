# Inventario Inteligente

Aplicación móvil en **Flutter** para administrar productos, generar y leer
códigos de barras (Code 128) y códigos QR, y registrar entradas, salidas y
ajustes de inventario.

Dirigida a una pequeña tienda o bodega que necesita consultar sus existencias
y mantener un historial de movimientos, **sin conexión a internet**.

| | |
|---|---|
| **Curso** | Programación de Dispositivos Móviles II |
| **Proyecto** | Proyecto de cierre 1 — UMES, Segundo semestre 2026 |
| **Plataforma** | Flutter / Dart (Android APK) |
| **Estado** | Persistencia local (SharedPreferences + JSON) |

---

##  Documentación técnica

Todo el sistema está documentado en archivos `.md` dentro de [`docs/`](docs/):

| Documento | Contenido |
|---|---|
| [docs/requisitos.md](docs/requisitos.md) | Objetivo, alcance, requisitos y reglas de negocio |
| [docs/arquitectura.md](docs/arquitectura.md) | Arquitectura **feature + domain**, estructura de carpetas, responsabilidades y flujo de dependencias |
| [docs/modelo_datos.md](docs/modelo_datos.md) | Modelo de datos, diccionario de campos, relaciones y persistencia |
| [docs/funcionalidades.md](docs/funcionalidades.md) | Funcionalidades, casos de uso, gestión de estado y flujo de información |
| [docs/codigos_barras_qr.md](docs/codigos_barras_qr.md) | Generación y lectura de códigos, contenido codificado y permisos de cámara |
| [docs/validaciones_errores.md](docs/validaciones_errores.md) | Validaciones, manejo de errores y consistencia de los movimientos |
| [docs/pruebas.md](docs/pruebas.md) | Pruebas realizadas, pasos de reproducción, resultados y evidencias |
| [docs/apk_compilacion.md](docs/apk_compilacion.md) | Compilación del APK en FlutLab, limitaciones conocidas y mantenimiento |
| [docs/manual_usuario.md](docs/manual_usuario.md) | Manual de usuario (fuente del PDF entregable) |

> El **manual de usuario en PDF** se genera a partir de
> `docs/manual_usuario.md` / `docs/manual_usuario.html` (ver instrucciones
> dentro de cada archivo).

---

##  Instalación y ejecución

### Requisitos
- Flutter SDK **3.24 o superior** (probado con canal estable)
- Dart 3.x
- Android Studio / FlutLab (IDE en línea) para compilar el APK

### Pasos locales

```bash
# 1. Obtener dependencias
flutter pub get

# 2. Ejecutar en un dispositivo o emulador
flutter run

# 3. Ejecutar las pruebas de las reglas de inventario
flutter test

# 4. Compilar el APK de release
flutter build apk --release
```

### En FlutLab

1. Crea (o importa) el proyecto con esta misma carpeta — ver
   [docs/apk_compilacion.md](docs/apk_compilacion.md#importar-esta-carpeta-en-flutlab).
2. FlutLab resuelve las dependencias del `pubspec.yaml` automáticamente.
3. Usa **Build → APK (release)** para generar el instalable Android.

---

##  Estructura del proyecto

```
lib/
├── main.dart                  # Composición: datos + providers + app
├── app/
│   ├── app.dart               # MaterialApp + navegación por pestañas
│   └── tema.dart              # Tema Material 3
├── core/
│   ├── errors/                # Failures del dominio + mensajes amigables
│   ├── storage/               # LocalStorage (SharedPreferences + JSON)
│   └── utils/                 # Generador de IDs (UUID)
├── features/
│   ├── inicio/                # Página de inicio (resumen y accesos)
│   ├── productos/             # domain / data / presentation
│   ├── inventario/            # domain / data / presentation (movimientos)
│   ├── escaner/               # presentation (cámara + búsqueda manual)
│   ├── reportes/              # presentation (historial + CSV)
│   └── perfil/                # Responsable local de los movimientos
└── test/                      # Pruebas de las reglas de inventario
```

Cada feature sigue el patrón **feature + domain**:

```
features/<feature>/
├── domain/          # Entidades, casos de uso y CONTRATOS de repositorio
├── data/            # Implementaciones de repositorios + acceso a datos
└── presentation/    # Páginas, widgets y providers (estado)
```

---

##  Funcionalidades principales

- **Productos**: registrar, consultar, editar, desactivar/reactivar y eliminar
  (solo si no tiene movimientos). Foto opcional, categoría, precios y stock mínimo.
- **Etiquetas**: código de barras **Code 128** + **QR** por producto,
  compartibles como imagen PNG para impresión.
- **Escáner**: lectura con la cámara (mobile_scanner) y búsqueda manual por
  código o nombre. Si el código no existe, ofrece crear el producto.
- **Movimientos**: entradas, salidas y ajustes con motivo/justificación,
  responsable, stock anterior y resultante. Registro **atómico**.
- **Alertas**: stock igual o inferior al mínimo.
- **Historial**: filtrado por producto, tipo y fechas.
- **Exportación**: inventario y movimientos a **CSV**.
- **Datos de demostración**: 15 productos y 3 categorías al primer arranque.

---

##  Reglas de negocio implementadas

1. Las cantidades de entrada y salida deben ser **mayores que cero**.
2. **No se permiten salidas superiores al stock disponible.**
3. Un producto **con movimientos no se elimina**; se desactiva.
4. Los movimientos confirmados **no se editan ni eliminan**.
5. El registro del movimiento y la actualización de existencias se realizan
   **como una sola operación** (con rollback ante fallo de escritura).
6. Las existencias iniciales se registran como **movimiento de entrada**.
7. Los códigos de producto son **únicos** (sin duplicados).

Las reglas viven en el **dominio**
(`features/inventario/domain/services/reglas_inventario.dart` y los casos de
uso), no en los widgets ni en la base de datos. Ver
[docs/pruebas.md](docs/pruebas.md) para la evidencia.
