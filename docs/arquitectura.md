# Arquitectura — feature + domain

## 1. Objetivo

El proyecto usa **obligatoriamente** la arquitectura *feature + domain*: el
código se organiza por funcionalidades (features) y, dentro de cada una, se
separan las responsabilidades de **presentación**, **dominio** y **datos**.

## 2. Principio de dependencias

```
presentation  ──▶  domain  ──▶  data
     │                            ▲
     └──────────(solo contratos)──┘
```

- **Presentación** (páginas, widgets, providers) conoce al **dominio**
  (casos de uso y contratos). Nunca toca la capa de datos directamente.
- **Dominio** (entidades, casos de uso, reglas, contratos de repositorio)
  **no depende** de Flutter, de los widgets ni del almacenamiento. Es Dart puro.
- **Datos** (implementaciones de repositorios, datasource, LocalStorage)
  implementa los **contratos** definidos en el dominio.

> Regla verificable: ningún archivo de `domain/` importa nada de `data/`
> ni de `presentation/`.

## 3. Features

| Feature | Responsabilidad |
|---|---|
| `productos` | Entidades Producto/Categoría, CRUD, etiquetas, listado |
| `inventario` | Entidad Movimiento, entradas/salidas/ajustes, historial, reglas de stock |
| `escaner` | Lectura de códigos con cámara y búsqueda manual |
| `reportes` | Historial con filtros, resúmenes y exportación CSV |
| `inicio` | Resumen general y accesos rápidos |
| `perfil` | Responsable local que firma los movimientos |

`core/` contiene lo compartido: errores (`failures.dart`, `mensajes.dart`),
almacenamiento (`local_storage.dart`) y utilidades (`id_generator.dart`).

## 4. Estructura por feature (ejemplo: inventario)

```
features/inventario/
├── domain/
│   ├── entities/
│   │   ├── movimiento.dart            # Entidad
│   │   └── filtro_movimientos.dart    # Objeto-valor de filtros
│   ├── repositories/
│   │   └── movimiento_repository.dart # CONTRATO (abstract)
│   ├── services/
│   │   └── reglas_inventario.dart     # Reglas de negocio (servicio de dominio)
│   └── usecases/
│       ├── registrar_entrada.dart     # CU-07
│       ├── registrar_salida.dart      # CU-08
│       ├── registrar_ajuste.dart      # CU-09
│       ├── registrar_stock_inicial.dart # CU-05
│       └── obtener_historial.dart     # CU-10
├── data/
│   └── movimiento_repository_impl.dart # Implementa el contrato con LocalStorage
└── presentation/
    ├── pages/movimiento_page.dart
    └── providers/movimiento_provider.dart
```

## 5. Responsabilidades por capa

### Dominio
- **Entidades**: `Producto`, `Categoria`, `Movimiento`, `Perfil`,
  `FiltroMovimientos`. Incluyen reglas derivadas simples
  (`stockBajo`, `valorInventario`).
- **Casos de uso**: una clase por caso de uso, con método `call(...)`.
  Validan reglas de negocio y orquestan repositorios.
- **Servicio de dominio**: `ReglasInventario` centraliza las reglas
  (cantidad > 0, stock suficiente, motivo obligatorio, producto activo,
  construcción del movimiento). Es la clase que prueban los tests.
- **Contratos**: `ProductoRepository`, `CategoriaRepository`,
  `MovimientoRepository`. Abstractos, sin implementación.

### Datos
- `InventarioDataStore`: lectura/escritura JSON en SharedPreferences.
- `ProductoRepositoryImpl`, `CategoriaRepositoryImpl`,
  `MovimientoRepositoryImpl`: implementan los contratos.
- `MovimientoRepositoryImpl.registrarConActualizacionStock(...)`: guarda el
  movimiento y actualiza el producto **en una sola operación**, con
  **rollback** si falla la escritura (consistencia del requisito 4).

### Presentación
- **Páginas**: una por pantalla del enunciado (Inicio, Productos, Formulario,
  Detalle, Escáner, Movimiento, Historial, Perfil).
- **Providers** (`ChangeNotifier`): única estrategia de gestión de estado
  (paquete `provider`). Exponen `cargando`, `error` y listas; delegan en los
  casos de uso.
- **Widgets** reutilizables: `ProductoCard`, `EtiquetaWidget`.

## 6. Flujo de una operación (ejemplo: registrar salida)

1. `MovimientoPage` valida el formulario (cantidad > 0, etc.).
2. Llama a `MovimientoProvider.registrarSalida(...)`.
3. El provider ejecuta el caso de uso `RegistrarSalida(prodRepo, movRepo)`.
4. El caso de uso aplica `ReglasInventario` (reglas en el dominio).
5. `MovimientoRepositoryImpl.registrarConActualizacionStock(...)` escribe
   movimiento + producto en una sola operación (con rollback).
6. El provider recarga el estado y notifica; la UI se actualiza.
7. Si algo falla, la excepción sube y `mensajeAmigable(e)` la traduce a un
   SnackBar legible.

## 7. Inyección de dependencias

Sin frameworks: `main.dart` construye la capa de datos una sola vez
(`LocalStorage` → `InventarioDataStore` → repositorios) y la entrega a los
providers vía `MultiProvider`. Los casos de uso reciben sus repositorios por
constructor (inyección manual por constructor).

## 8. Comunicación entre features

Los casos de uso de inventario necesitan productos y viceversa. La
comunicación se hace **a través de los contratos del dominio**
(`ProductoRepository`, `MovimientoRepository`), nunca importando
implementaciones de datos de otro feature.
