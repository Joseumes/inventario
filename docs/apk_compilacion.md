# Compilación del APK, limitaciones y mantenimiento

## 1. Compilar el APK en FlutLab

1. Entra a tu proyecto en [FlutLab](https://flutlab.io).
2. Asegúrate de que el árbol de archivos coincida con este proyecto
   (especialmente `pubspec.yaml` y `lib/`).
3. Menú **Build → Build APK (Release)**.
4. Descarga el APK generado desde la pestaña de builds.

FlutLab resuelve automáticamente las dependencias de `pubspec.yaml`
(`flutter pub get` implícito en cada build).

## 2. Compilar el APK localmente

```bash
flutter pub get
flutter build apk --release
# APK en: build/app/outputs/flutter-apk/app-release.apk
```

Para un APK más liviano por arquitectura:

```bash
flutter build apk --release --split-per-abi
```

## 3. Requisitos del dispositivo de prueba

- Android 6.0+ (API 23+) — lo que exija la versión de Flutter usada.
- Cámara trasera para el escáner (probar en **dispositivo físico**,
  requisito del enunciado).
- Sin conexión a internet: todas las funciones funcionan offline.

## 4. Dependencias (pubspec.yaml)

| Paquete | Uso |
|---|---|
| `provider` | Gestión de estado (estrategia única del proyecto) |
| `shared_preferences` | Persistencia local (productos, categorías, movimientos, perfil) |
| `mobile_scanner` | Lectura de códigos de barras y QR con la cámara |
| `barcode_widget` | Generación de Code 128 |
| `qr_flutter` | Generación de QR |
| `uuid` | IDs únicos |
| `intl` | Formato de fechas |
| `csv` | Exportación CSV |
| `share_plus` | Compartir etiquetas (PNG/texto) y CSV |
| `path_provider` | Ruta temporal para los CSV |
| `permission_handler` | Permiso de cámara |
| `image_picker` | Fotografía opcional del producto |

## 5. Limitaciones conocidas

- **Un dispositivo / una bodega**: sin sincronización (mejora opcional).
- **SharedPreferences**: adecuado para el alcance mínimo (decenas/cientos
  de productos). Para miles de registros convendría migrar a `sqflite`
  o `drift` (los contratos de repositorio ya lo permiten sin tocar el dominio).
- **Fotos en base64**: comprimidas (600px, calidad 50) para no inflar el JSON.
- **CSV**: se comparte como archivo; no se abre dentro de la app.
- **El escáner web** (FlutLab preview) no tiene cámara: usar búsqueda manual.

## 6. Mantenimiento

- **Agregar un caso de uso**: crear la clase en
  `features/<feature>/domain/usecases/`, aplicando `ReglasInventario`
  cuando toque reglas de stock; exponerlo en el provider correspondiente.
- **Cambiar de almacenamiento** (p. ej. a SQLite): implementar de nuevo los
  contratos `ProductoRepository` / `MovimientoRepository` en `data/` y
  cambiar el wiring en `main.dart`. El dominio y la presentación no cambian.
- **Nuevas categorías**: `CategoriaRepositoryImpl.crearCategoria` evita
  duplicados por nombre.
- **Versión**: incrementar `version:` en `pubspec.yaml` en cada entrega.

## 7. Importar esta carpeta en FlutLab

FlutLab permite crear un proyecto a partir de esta carpeta:

1. Comprime el proyecto en **ZIP** incluyendo:
   `pubspec.yaml`, `analysis_options.yaml`, `lib/`, `test/`, `android/`,
   `docs/`, `README.md`, `.metadata`.
   - **Excluye**: `build/`, `.dart_tool/`, `ios/` (opcional; FlutLab puede
     regenerarlo) y archivos temporales.
2. En FlutLab: **Dashboard → Import Project → ZIP** (o súbelo a un repo
   GitHub y usa **Import from Git**).
3. Verifica que `pubspec.yaml` aparezca en la raíz del proyecto importado;
   FlutLab detectará el proyecto Flutter y ejecutará `pub get`.

> Alternativa: crear un proyecto nuevo en FlutLab con el mismo nombre de
> paquete (`inventario_flutter`) y reemplazar `lib/`, `test/`,
> `pubspec.yaml` y `android/app/src/main/AndroidManifest.xml` con los de
> esta carpeta.
