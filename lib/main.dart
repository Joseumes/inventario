import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'app/app.dart';
import 'core/storage/local_storage.dart';
import 'features/productos/data/inventario_data_store.dart';
import 'features/productos/data/producto_repository_impl.dart';
import 'features/productos/presentation/providers/producto_provider.dart';
import 'features/inventario/data/movimiento_repository_impl.dart';
import 'features/inventario/presentation/providers/movimiento_provider.dart';
import 'features/perfil/data/perfil_repository_impl.dart';
import 'features/perfil/presentation/providers/perfil_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  try {
    final storage = LocalStorage();
    await storage.init();

    // CAPA DE DATOS: una sola fuente compartida para todos los features.
    final dataStore = InventarioDataStore(storage);
    final productoRepo = ProductoRepositoryImpl(dataStore);
    final movimientoRepo = MovimientoRepositoryImpl(storage);
    final perfilRepo = PerfilRepositoryImpl(storage);

    runApp(
      MultiProvider(
        providers: [
          // CAPA DE PRESENTACIÓN: providers que consumen los casos de
          // uso del dominio (arquitectura feature + domain).
          ChangeNotifierProvider(
            create: (_) => ProductoProvider(productoRepo, movimientoRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => MovimientoProvider(movimientoRepo, productoRepo),
          ),
          ChangeNotifierProvider(
            create: (_) => PerfilProvider(perfilRepo)..cargar(),
          ),
        ],
        child: const InventarioApp(),
      ),
    );
  } catch (e, st) {
    debugPrint('ERROR AL INICIAR: $e\n$st');
    runApp(_PantallaErrorInicial(error: e, detalle: st));
  }
}

/// Estado vacío de arranque: si el almacenamiento falla, la app no
/// muestra una pantalla gris, sino el error explicado al usuario.
class _PantallaErrorInicial extends StatelessWidget {
  final Object error;
  final StackTrace detalle;
  const _PantallaErrorInicial({required this.error, required this.detalle});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 48, color: Colors.red),
                  const SizedBox(height: 12),
                  const Text('Error al iniciar la aplicación',
                      style:
                          TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  const Text(
                    'No se pudo acceder al almacenamiento local del '
                    'dispositivo. Cierra la aplicación y vuelve a abrirla. '
                    'Si el problema persiste, reinstala la aplicación.',
                  ),
                  const SizedBox(height: 12),
                  Text('Detalle: $error',
                      style: const TextStyle(fontSize: 12)),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
